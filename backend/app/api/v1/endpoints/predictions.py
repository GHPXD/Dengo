"""
Predictions Endpoint - API de Predição de Dengue com IA
=========================================================

Endpoint REST para predições de casos de dengue usando modelo LSTM.
Implementa validação robusta, error handling e logging.

Author: Dengo Team
Created: 2025-12-25
"""

from typing import List
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from loguru import logger

from app.schemas.prediction import (
    PredictionRequest,
    PredictionResponse,
    WeekPrediction,
    HistoricalWeek,
    PredictionError,
    TrendType,
    ConfidenceLevel,
    ModelMetadata,
)
from app.services.ml_service import (
    MLService,
    get_ml_service,
    InsufficientDataError,
    PredictionError as MLPredictionError,
)
from app.services.data_service import (
    DataService,
    get_data_service,
    GeocodeNotFoundError,
    DataNotFoundError,
)


# ════════════════════════════════════════════════════════════════════════════
# ROUTER CONFIGURATION
# ════════════════════════════════════════════════════════════════════════════

router = APIRouter(
    prefix="/predictions",
    tags=["Predições IA"],
    responses={
        404: {"description": "Município não encontrado"},
        422: {"description": "Dados insuficientes para predição"},
        500: {"description": "Erro interno do servidor"},
    },
)


# ════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ════════════════════════════════════════════════════════════════════════════


def _calculate_trend(predictions: List[WeekPrediction]) -> tuple[TrendType, float]:
    """
    Calcula tendência geral das predições.
    
    Args:
        predictions: Lista de predições semanais
    
    Returns:
        Tupla (trend_type, percentage_change)
    """
    if len(predictions) < 2:
        return TrendType.STABLE, 0.0
    
    first_value = predictions[0].predicted_cases
    last_value = predictions[-1].predicted_cases
    
    if first_value == 0:
        return TrendType.STABLE, 0.0
    
    percentage_change = ((last_value - first_value) / first_value) * 100
    
    # Define thresholds
    if percentage_change > 5.0:
        trend = TrendType.ASCENDING
    elif percentage_change < -5.0:
        trend = TrendType.DESCENDING
    else:
        trend = TrendType.STABLE
    
    return trend, percentage_change


def _map_confidence_to_level(confidence: float) -> ConfidenceLevel:
    """
    Mapeia valor de confiança (0-1) para enum.
    
    Args:
        confidence: Valor entre 0 e 1
    
    Returns:
        ConfidenceLevel enum
    """
    if confidence >= 0.80:
        return ConfidenceLevel.HIGH
    elif confidence >= 0.60:
        return ConfidenceLevel.MEDIUM
    else:
        return ConfidenceLevel.LOW


def _calculate_confidence_interval(
    predicted_cases: float,
    confidence: float
) -> tuple[float, float]:
    """
    Calcula intervalo de confiança (95%).
    
    Aproximação simples baseada na confiança do modelo.
    
    Args:
        predicted_cases: Casos preditos
        confidence: Confiança (0-1)
    
    Returns:
        Tupla (lower_bound, upper_bound)
    """
    # Margem de erro inversamente proporcional à confiança
    # Confiança alta = margem baixa
    margin_percentage = (1 - confidence) * 0.30  # Máximo 30%
    margin = predicted_cases * margin_percentage
    
    lower = max(0.0, predicted_cases - margin)
    upper = predicted_cases + margin
    
    return lower, upper


# ════════════════════════════════════════════════════════════════════════════
# ENDPOINTS
# ════════════════════════════════════════════════════════════════════════════


@router.post(
    "/predict",
    response_model=PredictionResponse,
    status_code=status.HTTP_200_OK,
    summary="Predição de Casos de Dengue",
    description="""
    Prediz casos de dengue para as próximas semanas usando IA (LSTM).
    
    **Modelo:** DengoAI v1.0 - LSTM Multivariado  
    **Treinamento:** 2015-2024 (399 municípios do Paraná)  
    **Acurácia validada:** 91% (Curitiba 2025)  
    **MAE:** ~27 casos  
    
    **Features utilizadas:**
    - Casos históricos (4 semanas)
    - Temperatura (min/med/max)
    - Umidade (min/med/max)
    - Receptividade ambiental
    - Taxa de transmissão (Rt)
    
    **Limitações:**
    - Requer 4 semanas de dados históricos
    - Predições múltiplas (>1 semana) são recursivas (menor precisão)
    - Confiança diminui com horizonte temporal
    """,
    responses={
        200: {
            "description": "Predição gerada com sucesso",
            "content": {
                "application/json": {
                    "example": {
                        "city": "Curitiba",
                        "geocode": "4106902",
                        "state": "PR",
                        "historical_data": [
                            {
                                "week_number": 40,
                                "date": "2025-10-05",
                                "cases": 189,
                            },
                            {
                                "week_number": 41,
                                "date": "2025-10-12",
                                "cases": 203,
                            },
                            {
                                "week_number": 42,
                                "date": "2025-10-19",
                                "cases": 245,
                            },
                        ],
                        "predictions": [
                            {
                                "week_number": 1,
                                "date": "2025-01-05",
                                "predicted_cases": 245.8,
                                "confidence": "high",
                                "lower_bound": 220.0,
                                "upper_bound": 270.0,
                            }
                        ],
                        "trend": "descending",
                        "trend_percentage": -12.5,
                        "generated_at": "2025-12-25T10:30:00",
                        "model_metadata": {
                            "model_name": "DengoAI v1.0",
                            "accuracy": 0.91,
                            "mae": 27.0,
                        },
                    }
                }
            },
        },
    },
)
async def predict_dengue_cases(
    request: PredictionRequest,
    ml_service: MLService = Depends(get_ml_service),
    data_service: DataService = Depends(get_data_service),
) -> PredictionResponse:
    """
    Endpoint principal de predição.
    
    Args:
        request: Dados da requisição (geocode + weeks_ahead)
        ml_service: Serviço de ML (injetado)
        data_service: Serviço de dados (injetado)
    
    Returns:
        PredictionResponse com predições e metadados
    
    Raises:
        HTTPException 404: Município não encontrado
        HTTPException 422: Dados insuficientes
        HTTPException 500: Erro interno
    """
    geocode = request.geocode
    weeks_ahead = request.weeks_ahead
    
    logger.info(
        f"🎯 Nova requisição de predição: "
        f"geocode={geocode}, weeks={weeks_ahead}"
    )
    
    try:
        # ────────────────────────────────────────────────────────────────
        # 1. Busca dados históricos
        # ────────────────────────────────────────────────────────────────
        logger.debug(f"📊 Buscando dados históricos para {geocode}...")
        
        # Busca últimas 12 semanas para gráfico (linha verde)
        historical_data_full = await data_service.get_historical_data(
            geocode=geocode,
            weeks=12  # Últimas 12 semanas para exibir no gráfico
        )
        
        # Últimas 4 semanas para input do modelo
        historical_data = await data_service.get_historical_data(
            geocode=geocode,
            weeks=4  # Modelo requer 4 semanas
        )
        
        city_name = await data_service.get_city_name(geocode)
        
        logger.success(f"✅ Dados históricos carregados: {len(historical_data_full)} semanas (gráfico), {len(historical_data)} semanas (modelo)")
        
        # ────────────────────────────────────────────────────────────────
        # 2. Formata dados históricos para resposta (linha verde)
        # ────────────────────────────────────────────────────────────────
        historical_weeks: List[HistoricalWeek] = []
        
        # Ordena por data
        historical_sorted = historical_data_full.sort_values("data_iniSE")
        
        for _, row in historical_sorted.iterrows():
            week_date = row["data_iniSE"]
            week_number = week_date.isocalendar()[1]
            cases = int(row["casos_est"]) if "casos_est" in row else 0
            
            historical_weeks.append(
                HistoricalWeek(
                    week_number=week_number,
                    date=week_date.date(),
                    cases=cases,
                )
            )
        
        logger.debug(f"📈 Dados históricos formatados: {len(historical_weeks)} semanas")
        
        # ────────────────────────────────────────────────────────────────
        # 3. Executa predições
        # ────────────────────────────────────────────────────────────────
        logger.debug(f"🤖 Executando predições ({weeks_ahead} semanas)...")
        
        if weeks_ahead == 1:
            # Single-step (mais preciso)
            cases, confidence = await ml_service.predict_next_week(historical_data)
            predictions_raw = [(cases, confidence)]
        else:
            # Multi-step (recursivo)
            predictions_raw = await ml_service.predict_multiple_weeks(
                historical_data,
                weeks_ahead=weeks_ahead
            )
        
        # ────────────────────────────────────────────────────────────────
        # 4. Formata resposta de predições (linha azul)
        # ────────────────────────────────────────────────────────────────
        predictions: List[WeekPrediction] = []
        
        # Data base (última semana + 1)
        last_date = historical_data["data_iniSE"].max()
        next_date = last_date + timedelta(days=7)
        
        for week_idx, (cases, conf) in enumerate(predictions_raw, start=1):
            # Calcula data da semana
            week_date = next_date + timedelta(days=7 * (week_idx - 1))
            
            # Semana epidemiológica
            week_number = week_date.isocalendar()[1]
            
            # Intervalo de confiança
            lower, upper = _calculate_confidence_interval(cases, conf)
            
            # Confiança decai em predições futuras
            adjusted_confidence = conf * (0.95 ** (week_idx - 1))
            
            predictions.append(
                WeekPrediction(
                    week_number=week_number,
                    date=week_date.date(),
                    predicted_cases=round(cases, 1),
                    confidence=_map_confidence_to_level(adjusted_confidence),
                    lower_bound=round(lower, 1),
                    upper_bound=round(upper, 1),
                )
            )
        
        # ────────────────────────────────────────────────────────────────
        # 5. Calcula tendência
        # ────────────────────────────────────────────────────────────────
        trend, trend_pct = _calculate_trend(predictions)
        
        # ────────────────────────────────────────────────────────────────
        # 6. Monta resposta completa
        # ────────────────────────────────────────────────────────────────
        response = PredictionResponse(
            city=city_name,
            geocode=geocode,
            state="PR",
            historical_data=historical_weeks,  # Linha verde
            predictions=predictions,  # Linha azul
            trend=trend,
            trend_percentage=round(trend_pct, 2),
            generated_at=datetime.now(),
            model_metadata=ModelMetadata(),
        )
        
        logger.success(
            f"✅ Predição concluída: {city_name} - "
            f"Tendência: {trend.value} ({trend_pct:+.1f}%)"
        )
        
        return response
        
    except GeocodeNotFoundError as e:
        logger.error(f"❌ Geocode não encontrado: {geocode}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=PredictionError(
                error_code="GEOCODE_NOT_FOUND",
                message=f"Município com geocode {geocode} não encontrado",
                details=str(e),
                geocode=geocode,
            ).dict(),
        )
    
    except (InsufficientDataError, DataNotFoundError) as e:
        logger.error(f"❌ Dados insuficientes: {e}")
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=PredictionError(
                error_code="INSUFFICIENT_DATA",
                message="Dados históricos insuficientes para predição",
                details=str(e),
                geocode=geocode,
            ).dict(),
        )
    
    except MLPredictionError as e:
        logger.error(f"❌ Erro na predição: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=PredictionError(
                error_code="PREDICTION_ERROR",
                message="Erro ao executar predição",
                details=str(e),
                geocode=geocode,
            ).dict(),
        )
    
    except Exception as e:
        logger.exception(f"❌ Erro inesperado: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=PredictionError(
                error_code="INTERNAL_ERROR",
                message="Erro interno do servidor",
                details="Entre em contato com o suporte",
                geocode=geocode,
            ).dict(),
        )


@router.get(
    "/health",
    status_code=status.HTTP_200_OK,
    summary="Health Check do Modelo",
    description="Verifica se modelo está carregado e pronto",
)
async def health_check(
    ml_service: MLService = Depends(get_ml_service),
) -> dict:
    """
    Health check do serviço de predição.
    
    Returns:
        Status do modelo e serviços
    """
    try:
        # Força carregamento do modelo
        ml_service._load_artifacts()
        
        return {
            "status": "healthy",
            "model_loaded": ml_service.is_ready,
            "model_name": "DengoAI v1.0",
            "timestamp": datetime.now().isoformat(),
        }
    except Exception as e:
        logger.error(f"Health check falhou: {e}")
        return {
            "status": "unhealthy",
            "model_loaded": False,
            "error": str(e),
            "timestamp": datetime.now().isoformat(),
        }
