"""
ML Service - Serviço de Machine Learning para Predição de Dengue
==================================================================

Gerencia o carregamento e inferência do modelo Keras LSTM treinado.
Implementa singleton pattern, lazy loading e cache para performance.

Arquitetura do Modelo:
- Input: (1, 4, 9) - 1 amostra, 4 semanas lookback, 9 features
- LSTM(64) + Dropout(0.2)
- LSTM(32) + Dropout(0.2)
- Dense(1) - Predição de casos_est

Features (ordem obrigatória):
    0. casos_est (Target)
    1. tempmed
    2. tempmin
    3. tempmax
    4. umidmed
    5. umidmin
    6. umidmax
    7. receptivo
    8. Rt

Author: Dengo Team
Created: 2025-12-25
"""

import os
from pathlib import Path
from typing import Optional, Tuple
import threading

import numpy as np
import pandas as pd
import joblib
from loguru import logger

# Lazy import para evitar erro se TensorFlow não estiver instalado
try:
    import tensorflow as tf
    from tensorflow import keras
    TF_AVAILABLE = True
except ImportError:
    TF_AVAILABLE = False
    logger.warning("TensorFlow não instalado - predições não disponíveis")


# ════════════════════════════════════════════════════════════════════════════
# CONSTANTS
# ════════════════════════════════════════════════════════════════════════════

# Features obrigatórias em ordem exata
REQUIRED_FEATURES = [
    "casos_est",
    "tempmed",
    "tempmin",
    "tempmax",
    "umidmed",
    "umidmin",
    "umidmax",
    "receptivo",
    "Rt",
]

# Configurações do modelo
LOOKBACK_WEEKS = 4  # Janela temporal
INPUT_SHAPE = (1, 4, 9)  # (samples, timesteps, features)

# Caminhos dos artefatos
MODELS_DIR = Path(__file__).parent.parent.parent / "models"
MODEL_PATH = MODELS_DIR / "dengo_ai.keras"
SCALER_PATH = MODELS_DIR / "scaler_treinado.pkl"


# ════════════════════════════════════════════════════════════════════════════
# EXCEPTIONS
# ════════════════════════════════════════════════════════════════════════════


class ModelNotFoundError(Exception):
    """Erro quando modelo não é encontrado."""
    pass


class PredictionError(Exception):
    """Erro durante a predição."""
    pass


class InsufficientDataError(Exception):
    """Erro quando não há dados suficientes para predição."""
    pass


# ════════════════════════════════════════════════════════════════════════════
# ML SERVICE (SINGLETON)
# ════════════════════════════════════════════════════════════════════════════


class MLService:
    """
    Serviço singleton para gerenciar modelo de ML.
    
    Thread-safe com lazy loading para otimizar inicialização.
    Cache em memória do modelo e scaler.
    
    Attributes:
        model: Modelo Keras LSTM carregado
        scaler: MinMaxScaler treinado
        is_ready: Indica se modelo está carregado e pronto
    
    Example:
        >>> ml_service = MLService.get_instance()
        >>> prediction = await ml_service.predict_next_week(
        ...     historical_data=df_last_4_weeks
        ... )
    """
    
    _instance: Optional["MLService"] = None
    _lock = threading.Lock()
    
    def __init__(self):
        """Construtor privado - use get_instance()."""
        self.model: Optional[keras.Model] = None
        self.scaler: Optional[object] = None
        self.is_ready: bool = False
        self._load_lock = threading.Lock()
        
    @classmethod
    def get_instance(cls) -> "MLService":
        """
        Retorna instância singleton (thread-safe).
        
        Returns:
            Instância única do MLService
        """
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = cls()
        return cls._instance
    
    def _ensure_tensorflow(self) -> None:
        """Valida que TensorFlow está disponível."""
        if not TF_AVAILABLE:
            raise RuntimeError(
                "TensorFlow não está instalado. "
                "Execute: pip install tensorflow>=2.15.0"
            )
    
    def _load_artifacts(self) -> None:
        """
        Carrega modelo e scaler (lazy loading com lock).
        
        Raises:
            ModelNotFoundError: Se artefatos não forem encontrados
            RuntimeError: Se TensorFlow não estiver instalado
        """
        if self.is_ready:
            return
        
        with self._load_lock:
            # Double-check locking pattern
            if self.is_ready:
                return
            
            self._ensure_tensorflow()
            
            logger.info("🤖 Carregando modelo de IA...")
            
            # Valida existência dos arquivos
            if not MODEL_PATH.exists():
                raise ModelNotFoundError(
                    f"Modelo não encontrado: {MODEL_PATH}"
                )
            
            if not SCALER_PATH.exists():
                raise ModelNotFoundError(
                    f"Scaler não encontrado: {SCALER_PATH}"
                )
            
            try:
                # Carrega modelo Keras
                self.model = keras.models.load_model(
                    str(MODEL_PATH),
                    compile=False  # Não precisa compilar para inferência
                )
                logger.success(f"✅ Modelo carregado: {MODEL_PATH.name}")
                
                # Carrega scaler
                self.scaler = joblib.load(str(SCALER_PATH))
                logger.success(f"✅ Scaler carregado: {SCALER_PATH.name}")
                
                self.is_ready = True
                logger.info("🎯 ML Service pronto para predições")
                
            except Exception as e:
                logger.error(f"❌ Erro ao carregar artefatos: {e}")
                raise RuntimeError(f"Falha ao carregar modelo: {e}") from e
    
    def _validate_input_data(self, data: pd.DataFrame) -> None:
        """
        Valida que dados de entrada estão no formato correto.
        
        Args:
            data: DataFrame com últimas N semanas
        
        Raises:
            InsufficientDataError: Se não houver dados suficientes
            ValueError: Se features estiverem faltando
        """
        if len(data) < LOOKBACK_WEEKS:
            raise InsufficientDataError(
                f"São necessárias {LOOKBACK_WEEKS} semanas de dados. "
                f"Recebido: {len(data)} semanas"
            )
        
        missing_features = set(REQUIRED_FEATURES) - set(data.columns)
        if missing_features:
            raise ValueError(
                f"Features faltando: {missing_features}. "
                f"Necessárias: {REQUIRED_FEATURES}"
            )
    
    def _prepare_input(self, data: pd.DataFrame) -> np.ndarray:
        """
        Prepara dados para inferência (normalização + reshape).
        
        Args:
            data: DataFrame com últimas 4+ semanas
        
        Returns:
            Array numpy com shape (1, 4, 9) normalizado
        """
        # Pega últimas 4 semanas
        recent_data = data.tail(LOOKBACK_WEEKS).copy()
        
        # Ordena colunas conforme modelo espera
        recent_data = recent_data[REQUIRED_FEATURES]
        
        # Normaliza com scaler treinado
        normalized = self.scaler.transform(recent_data.values)
        
        # Reshape para (1, 4, 9)
        input_array = normalized.reshape(INPUT_SHAPE)
        
        logger.debug(f"Input preparado - Shape: {input_array.shape}")
        
        return input_array
    
    def _denormalize_prediction(self, prediction: float) -> float:
        """
        Desnormaliza predição do modelo.
        
        Args:
            prediction: Valor normalizado (0-1)
        
        Returns:
            Valor real de casos estimados
        """
        # casos_est é a primeira coluna (índice 0)
        casos_est_idx = 0
        
        # Cria array dummy com shape correto
        dummy = np.zeros((1, len(REQUIRED_FEATURES)))
        dummy[0, casos_est_idx] = prediction
        
        # Desnormaliza
        denormalized = self.scaler.inverse_transform(dummy)
        
        return float(denormalized[0, casos_est_idx])
    
    async def predict_next_week(
        self,
        historical_data: pd.DataFrame
    ) -> Tuple[float, float]:
        """
        Prediz casos de dengue para próxima semana.
        
        Args:
            historical_data: DataFrame com últimas semanas (min 4)
                           Deve conter todas as features obrigatórias
        
        Returns:
            Tupla (predicted_cases, confidence)
            - predicted_cases: Número estimado de casos
            - confidence: Nível de confiança (0-1)
        
        Raises:
            InsufficientDataError: Se dados insuficientes
            PredictionError: Se erro durante predição
        
        Example:
            >>> df_last_4_weeks = get_historical_data("4106902", weeks=4)
            >>> cases, confidence = await ml_service.predict_next_week(df_last_4_weeks)
            >>> print(f"Predição: {cases:.1f} casos (confiança: {confidence:.0%})")
        """
        # Garante que modelo está carregado
        self._load_artifacts()
        
        try:
            # Valida dados
            self._validate_input_data(historical_data)
            
            # Prepara input
            X = self._prepare_input(historical_data)
            
            # Predição
            logger.debug("🔮 Executando predição...")
            prediction_normalized = self.model.predict(X, verbose=0)[0][0]
            
            # Desnormaliza
            predicted_cases = self._denormalize_prediction(prediction_normalized)
            
            # Garante que não seja negativo
            predicted_cases = max(0.0, predicted_cases)
            
            # Calcula confiança baseado na estabilidade das últimas semanas
            # (Se casos recentes variam muito, confiança é menor)
            recent_cases = historical_data["casos_est"].tail(LOOKBACK_WEEKS).values
            std_dev = np.std(recent_cases)
            mean_cases = np.mean(recent_cases)
            
            # Coeficiente de variação (CV)
            cv = std_dev / mean_cases if mean_cases > 0 else 1.0
            
            # Mapeia CV para confiança (0-1)
            # CV baixo = alta confiança
            confidence = max(0.0, min(1.0, 1.0 - (cv / 2.0)))
            
            logger.success(
                f"✅ Predição: {predicted_cases:.1f} casos "
                f"(confiança: {confidence:.1%})"
            )
            
            return predicted_cases, confidence
            
        except (InsufficientDataError, ValueError) as e:
            logger.error(f"❌ Erro de validação: {e}")
            raise
        
        except Exception as e:
            logger.error(f"❌ Erro durante predição: {e}")
            raise PredictionError(f"Falha na predição: {e}") from e
    
    async def predict_multiple_weeks(
        self,
        historical_data: pd.DataFrame,
        weeks_ahead: int = 4
    ) -> list[Tuple[float, float]]:
        """
        Prediz múltiplas semanas à frente (iterativo).
        
        ATENÇÃO: O modelo foi treinado para single-step.
        Predições múltiplas usam abordagem recursiva (menos precisa).
        
        Args:
            historical_data: DataFrame com últimas semanas
            weeks_ahead: Quantas semanas prever (1-4)
        
        Returns:
            Lista de tuplas [(cases, confidence), ...]
        """
        if weeks_ahead < 1 or weeks_ahead > 4:
            raise ValueError("weeks_ahead deve estar entre 1 e 4")
        
        predictions = []
        current_data = historical_data.copy()
        
        for week in range(weeks_ahead):
            # Prediz próxima semana
            cases, confidence = await self.predict_next_week(current_data)
            predictions.append((cases, confidence))
            
            # Para predição recursiva, adiciona predição como nova linha
            # (confiança diminui em predições futuras)
            if week < weeks_ahead - 1:
                # Cria nova linha com valores médios (simplificação)
                last_row = current_data.iloc[-1].copy()
                last_row["casos_est"] = cases
                
                # Adiciona e remove primeira linha (mantém janela de 4)
                current_data = pd.concat([
                    current_data.iloc[1:],
                    pd.DataFrame([last_row])
                ], ignore_index=True)
                
                logger.debug(f"Predição recursiva semana {week + 2}")
        
        return predictions


# ════════════════════════════════════════════════════════════════════════════
# DEPENDENCY INJECTION
# ════════════════════════════════════════════════════════════════════════════


def get_ml_service() -> MLService:
    """
    Dependency injection para FastAPI.
    
    Returns:
        Instância singleton do MLService
    
    Example:
        @router.post("/predict")
        async def predict(
            ml_service: MLService = Depends(get_ml_service)
        ):
            ...
    """
    return MLService.get_instance()
