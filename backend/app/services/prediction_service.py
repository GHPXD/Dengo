"""
════════════════════════════════════════════════════════════════════════════
PREDICTION SERVICE - MACHINE LEARNING PREDICTIONS
════════════════════════════════════════════════════════════════════════════

Carrega modelo ML e faz predições de casos de dengue.

Features:
    - Carrega modelo treinado (dengo_model.joblib)
    - Predições baseadas em clima + histórico
    - Classificação de risco (Verde/Amarelo/Vermelho)
    - Fallback seguro se modelo não existir

Model Input:
    - mes: Mês (1-12)
    - semana_epidemiologica: Semana (1-52)
    - temperatura_media: Temperatura média (°C)
    - temperatura_max: Temperatura máxima (°C)
    - temperatura_min: Temperatura mínima (°C)
    - umidade_media: Umidade (%)
    - precipitacao: Precipitação (mm)
    - populacao_densidade: Densidade populacional
    - casos_semana_anterior: Casos semana anterior
    - casos_2sem_anterior: Casos 2 semanas atrás

Autor: Dengo Team
Data: 2025-12-09
════════════════════════════════════════════════════════════════════════════
"""

from datetime import datetime
from pathlib import Path
from typing import Optional

import joblib
import numpy as np
import pandas as pd

from app.core.logger import logger


class PredictionService:
    """
    Serviço de predição usando modelo de Machine Learning.
    
    Carrega modelo treinado e faz predições de casos de dengue.
    """

    def __init__(self):
        """Inicializa o serviço (modelo carregado no load_model())."""
        self.model = None
        self.scaler = None
        self.feature_names = None
        self.is_loaded = False
        self.model_path = Path(__file__).parent.parent.parent / "models" / "dengo_model.joblib"

    def load_model(self) -> bool:
        """
        Carrega modelo ML do disco.

        Returns:
            bool: True se carregou com sucesso, False caso contrário

        Arquivo esperado:
            backend/models/dengo_model.joblib
        """
        try:
            logger.info("🤖 Carregando modelo de Machine Learning...")
            logger.debug(f"   Path: {self.model_path}")

            if not self.model_path.exists():
                logger.error(f"❌ Modelo não encontrado: {self.model_path}")
                logger.warning("⚠️  Continuando sem predições ML (fallback mode)")
                return False

            # Carrega artefato do modelo
            artifact = joblib.load(self.model_path)

            self.model = artifact["model"]
            self.scaler = artifact["scaler"]
            self.feature_names = artifact["feature_names"]

            # Metadados
            version = artifact.get("version", "unknown")
            trained_at = artifact.get("trained_at", "unknown")
            metrics = artifact.get("metrics", {})

            logger.success("✓ Modelo carregado com sucesso!")
            logger.info(f"   Versão: {version}")
            logger.info(f"   Treinado em: {trained_at}")
            logger.info(f"   MAE: {metrics.get('mae', 'N/A'):.2f} casos")
            logger.info(f"   R²: {metrics.get('r2', 'N/A'):.4f}")

            self.is_loaded = True
            return True

        except FileNotFoundError:
            logger.error(f"❌ Arquivo do modelo não encontrado: {self.model_path}")
            return False
        except Exception as e:
            logger.error(f"❌ Erro ao carregar modelo: {e}")
            return False

    def predict(
        self,
        temperatura_media: float,
        temperatura_min: float,
        temperatura_max: float,
        umidade: float,
        precipitacao: float = 50.0,
        populacao_densidade: int = 3000,
        casos_semana_anterior: int = 0,
        casos_2sem_anterior: int = 0,
    ) -> dict:
        """
        Faz predição de casos de dengue.

        Args:
            temperatura_media: Temperatura média (°C)
            temperatura_min: Temperatura mínima (°C)
            temperatura_max: Temperatura máxima (°C)
            umidade: Umidade relativa (%)
            precipitacao: Precipitação acumulada (mm)
            populacao_densidade: Densidade populacional (hab/km²)
            casos_semana_anterior: Casos da semana anterior
            casos_2sem_anterior: Casos de 2 semanas atrás

        Returns:
            dict: Predição
                {
                    "casos_estimados": int,
                    "nivel_risco": str,
                    "confianca": float,
                    "fonte": str
                }

        Níveis de Risco:
            - baixo: < 50 casos
            - medio: 50-150 casos
            - alto: 150-300 casos
            - muito_alto: > 300 casos
        """
        if not self.is_loaded:
            logger.warning("⚠️  Modelo não carregado - usando fallback")
            return self._get_fallback_prediction(temperatura_media)

        try:
            # Features para o modelo (baseado no treinamento do ETL pipeline)
            now = datetime.now()
            semana_do_ano = now.isocalendar()[1]  # Semana do ano (1-52)
            
            # Sazonalidade (componentes trigonométricas)
            sazonalidade_sen = np.sin(2 * np.pi * semana_do_ano / 52)
            sazonalidade_cos = np.cos(2 * np.pi * semana_do_ano / 52)
            
            # Médias móveis (simplificadas para tempo real)
            casos_media_4sem = (casos_semana_anterior + casos_2sem_anterior) / 2
            temp_media_movel_4sem = temperatura_media
            umid_media_movel_4sem = umidade
            
            # Amplitude térmica e de umidade (estimativas)
            amplitude_termica = temperatura_max - temperatura_min
            amplitude_umidade = 20.0  # Valor padrão
            
            # Tendência (sequencial - usar número da semana)
            tendencia = semana_do_ano
            
            # Interação temperatura × umidade
            temp_umid_interacao = temperatura_media * umidade

            # Monta DataFrame com features (na ordem esperada pelo modelo)
            input_data = pd.DataFrame(
                [
                    {
                        "tempmin": temperatura_min,
                        "tempmed": temperatura_media,
                        "tempmax": temperatura_max,
                        "umidmin": umidade - 10,  # Estimativa
                        "umidmed": umidade,
                        "umidmax": umidade + 10,  # Estimativa
                        "casos_semana_anterior": casos_semana_anterior,
                        "casos_2sem_anterior": casos_2sem_anterior,
                        "casos_3sem_anterior": 0,  # Não temos histórico suficiente
                        "casos_4sem_anterior": 0,  # Não temos histórico suficiente
                        "casos_media_4sem": casos_media_4sem,
                        "temp_media_movel_4sem": temp_media_movel_4sem,
                        "umid_media_movel_4sem": umid_media_movel_4sem,
                        "sazonalidade_sen": sazonalidade_sen,
                        "sazonalidade_cos": sazonalidade_cos,
                        "amplitude_termica": amplitude_termica,
                        "amplitude_umidade": amplitude_umidade,
                        "tendencia": tendencia,
                        "temp_umid_interacao": temp_umid_interacao,
                        "semana_do_ano": semana_do_ano,
                    }
                ]
            )

            # Normaliza dados (StandardScaler)
            input_scaled = self.scaler.transform(input_data)

            # Predição
            prediction = self.model.predict(input_scaled)[0]
            casos_estimados_raw = max(0, int(prediction))  # Não pode ser negativo

            # SAFEGUARD: Se modelo tem R² negativo, aplica caps e ajustes
            # Baseado nas métricas reais do modelo (MAE ~700, R² -0.25)
            # Isso evita previsões absurdas como 3000+ casos em uma semana
            
            # Cap máximo baseado em histórico real de Curitiba (pico ~200 casos/semana)
            MAX_CASOS_SEMANAL = 300
            MIN_CASOS_SEMANAL = 0
            
            # Aplica blend com heurística se casos_semana_anterior disponível
            if casos_semana_anterior > 0:
                # Blend: 70% modelo + 30% persistência (semana anterior)
                # Isso suaviza previsões extremas
                casos_estimados = int(
                    0.7 * min(casos_estimados_raw, MAX_CASOS_SEMANAL) +
                    0.3 * casos_semana_anterior
                )
            else:
                casos_estimados = min(casos_estimados_raw, MAX_CASOS_SEMANAL)
            
            casos_estimados = max(MIN_CASOS_SEMANAL, casos_estimados)

            logger.info(
                f"🎯 Predição ML: {casos_estimados} casos "
                f"(raw: {casos_estimados_raw}, capped: {casos_estimados_raw > MAX_CASOS_SEMANAL})"
            )

            # Classifica nível de risco
            nivel_risco = self._classify_risk_level(casos_estimados)

            # Calcula confiança baseada nas métricas reais do modelo
            # R² = -0.25 indica modelo com baixa confiança
            # Confiança ajustada: 0.50 (baixa, pois R² < 0)
            confianca = 0.50 if self.is_loaded else 0.30

            return {
                "casos_estimados": casos_estimados,
                "nivel_risco": nivel_risco,
                "confianca": confianca,
                "tendencia": self._get_trend(
                    casos_estimados, casos_semana_anterior
                ),
                "fonte": "ML (XGBoost) com safeguards",
                "observacao": "Modelo com R² negativo. Previsão ajustada com heurísticas." if self.is_loaded else None,
            }

        except Exception as e:
            logger.error(f"❌ Erro ao fazer predição: {e}")
            return self._get_fallback_prediction(temperatura_media)

    def _classify_risk_level(self, casos: int) -> str:
        """
        Classifica nível de risco baseado no número de casos.

        Args:
            casos: Número estimado de casos

        Returns:
            str: "baixo" | "medio" | "alto" | "muito_alto"

        Critérios:
            - Baixo: < 50 casos
            - Médio: 50-150 casos
            - Alto: 150-300 casos
            - Muito Alto: > 300 casos
        """
        if casos < 50:
            return "baixo"
        elif casos < 150:
            return "medio"
        elif casos < 300:
            return "alto"
        else:
            return "muito_alto"

    def _get_trend(self, casos_atual: int, casos_anterior: int) -> str:
        """
        Determina tendência dos casos.

        Args:
            casos_atual: Casos estimados atual
            casos_anterior: Casos da semana anterior

        Returns:
            str: "subindo" | "estavel" | "caindo"
        """
        if casos_anterior == 0:
            return "estavel"

        variacao = (casos_atual - casos_anterior) / casos_anterior

        if variacao > 0.1:  # +10%
            return "subindo"
        elif variacao < -0.1:  # -10%
            return "caindo"
        else:
            return "estavel"

    def _get_fallback_prediction(self, temperatura_media: float) -> dict:
        """
        Predição de fallback (quando modelo não está disponível).

        Usa regra simples baseada em temperatura:
            - Temp > 25°C → Maior risco
            - Temp 20-25°C → Risco médio
            - Temp < 20°C → Risco baixo

        Args:
            temperatura_media: Temperatura média

        Returns:
            dict: Predição simplificada
        """
        logger.warning("⚠️  Usando predição de fallback (sem ML)")

        # Regra simples baseada em temperatura
        if temperatura_media > 28:
            casos_estimados = 250
            nivel_risco = "alto"
        elif temperatura_media > 25:
            casos_estimados = 120
            nivel_risco = "medio"
        elif temperatura_media > 20:
            casos_estimados = 60
            nivel_risco = "medio"
        else:
            casos_estimados = 30
            nivel_risco = "baixo"

        return {
            "casos_estimados": casos_estimados,
            "nivel_risco": nivel_risco,
            "confianca": 0.5,  # Baixa confiança (sem ML)
            "tendencia": "estavel",
            "fonte": "Fallback (regra baseada em temperatura)",
        }

    def get_model_info(self) -> Optional[dict]:
        """
        Retorna informações sobre o modelo carregado.

        Returns:
            dict: Informações do modelo ou None se não carregado
        """
        if not self.is_loaded:
            return None

        return {
            "is_loaded": self.is_loaded,
            "model_path": str(self.model_path),
            "feature_names": self.feature_names,
            "model_type": str(type(self.model).__name__),
        }


# ════════════════════════════════════════════════════════════════════════════
# SINGLETON INSTANCE
# ════════════════════════════════════════════════════════════════════════════

prediction_service = PredictionService()
