"""
Schemas para Predição de Dengue com IA (Keras LSTM)
====================================================

Pydantic models para validação de requests/responses da API de predições.
Implementa validação robusta de dados e tipagem forte.

Author: Dengo Team
Created: 2025-12-25
"""

from datetime import date as DateType, datetime
from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, Field, field_validator, ConfigDict


# ════════════════════════════════════════════════════════════════════════════
# ENUMS
# ════════════════════════════════════════════════════════════════════════════


class TrendType(str, Enum):
    """Classificação da tendência de casos de dengue."""
    
    ASCENDING = "ascending"      # Crescimento de casos
    DESCENDING = "descending"    # Queda de casos
    STABLE = "stable"            # Estável (variação < 5%)


class ConfidenceLevel(str, Enum):
    """Nível de confiança da predição."""
    
    HIGH = "high"        # > 80%
    MEDIUM = "medium"    # 60-80%
    LOW = "low"          # < 60%


# ════════════════════════════════════════════════════════════════════════════
# REQUEST SCHEMAS
# ════════════════════════════════════════════════════════════════════════════


class PredictionRequest(BaseModel):
    """
    Request para predição de casos de dengue.
    
    Attributes:
        geocode: Código IBGE do município (7 dígitos)
        weeks_ahead: Número de semanas a prever (1-12)
    
    Example:
        {
            "geocode": "4106902",
            "weeks_ahead": 4
        }
    """
    
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "geocode": "4106902",
                "weeks_ahead": 4
            }
        }
    )
    
    geocode: str = Field(
        ...,
        min_length=7,
        max_length=7,
        pattern=r"^\d{7}$",
        description="Código IBGE do município (7 dígitos numéricos)",
        examples=["4106902"]
    )
    
    weeks_ahead: int = Field(
        default=1,
        ge=1,
        le=12,  # AUMENTADO PARA 12 PARA SUPORTAR 90 DIAS
        description="Número de semanas a prever (1 a 12)",
        examples=[1, 12]
    )
    
    @field_validator("geocode")
    @classmethod
    def validate_geocode(cls, v: str) -> str:
        """Valida que geocode é numérico e válido."""
        if not v.isdigit():
            raise ValueError("Geocode deve conter apenas dígitos")
        
        # Validação básica: Paraná começa com 41
        if not v.startswith("41"):
            raise ValueError("Geocode inválido: deve ser do estado do Paraná (começar com 41)")
        
        return v


# ════════════════════════════════════════════════════════════════════════════
# RESPONSE SCHEMAS
# ════════════════════════════════════════════════════════════════════════════


class HistoricalWeek(BaseModel):
    """
    Dados históricos de uma semana epidemiológica.
    
    Representa casos confirmados de dengue em uma semana específica.
    Usado para exibir linha verde no gráfico (casos reais).
    
    Attributes:
        week_number: Semana epidemiológica (1-53)
        date: Data de início da semana (domingo)
        cases: Casos confirmados naquela semana
    """
    
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "week_number": 42,
                "date": "2025-10-19",
                "cases": 156
            }
        }
    )
    
    week_number: int = Field(
        ...,
        ge=1,
        le=53,
        description="Número da semana epidemiológica"
    )
    
    date: DateType = Field(
        ...,
        description="Data de início da semana (domingo)"
    )
    
    cases: int = Field(
        ...,
        ge=0,
        description="Casos confirmados de dengue"
    )


class WeekPrediction(BaseModel):
    """
    Predição para uma semana específica.
    
    Attributes:
        week_number: Semana epidemiológica (1-53)
        date: Data de início da semana
        predicted_cases: Casos estimados pela IA
        confidence: Nível de confiança
        lower_bound: Limite inferior (intervalo de confiança)
        upper_bound: Limite superior (intervalo de confiança)
    """
    
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "week_number": 1,
                "date": "2025-01-05",
                "predicted_cases": 245.8,
                "confidence": "high",
                "lower_bound": 220.0,
                "upper_bound": 270.0
            }
        }
    )
    
    week_number: int = Field(
        ...,
        ge=1,
        le=53,
        description="Número da semana epidemiológica"
    )
    
    date: DateType = Field(
        ...,
        description="Data de início da semana (domingo)"
    )
    
    predicted_cases: float = Field(
        ...,
        ge=0.0,
        description="Número estimado de casos pela IA"
    )
    
    confidence: ConfidenceLevel = Field(
        ...,
        description="Nível de confiança da predição"
    )
    
    lower_bound: Optional[float] = Field(
        None,
        ge=0.0,
        description="Limite inferior do intervalo de confiança (95%)"
    )
    
    upper_bound: Optional[float] = Field(
        None,
        ge=0.0,
        description="Limite superior do intervalo de confiança (95%)"
    )


class ModelMetadata(BaseModel):
    """Metadados do modelo de IA utilizado."""
    
    model_name: str = Field(
        default="DengoAI v1.0",
        description="Nome do modelo"
    )
    
    model_type: str = Field(
        default="LSTM Multivariado",
        description="Tipo de arquitetura"
    )
    
    training_period: str = Field(
        default="2015-2024",
        description="Período de treinamento"
    )
    
    accuracy: float = Field(
        default=0.91,
        ge=0.0,
        le=1.0,
        description="Acurácia validada em teste (0-1)"
    )
    
    mae: float = Field(
        default=27.0,
        ge=0.0,
        description="Mean Absolute Error (casos)"
    )


class PredictionResponse(BaseModel):
    """
    Resposta completa da API de predição.
    
    Attributes:
        city: Nome da cidade
        geocode: Código IBGE
        state: Sigla do estado
        historical_data: Dados históricos (últimas semanas com casos confirmados)
        predictions: Lista de predições semanais futuras
        trend: Tendência geral (ascendente/descendente/estável)
        trend_percentage: Variação percentual da tendência
        generated_at: Timestamp da geração
        model_metadata: Informações do modelo utilizado
    
    Example:
        {
            "city": "Curitiba",
            "geocode": "4106902",
            "state": "PR",
            "historical_data": [
                {"week_number": 42, "date": "2025-10-19", "cases": 156},
                {"week_number": 43, "date": "2025-10-26", "cases": 142}
            ],
            "predictions": [...],
            "trend": "descending",
            "trend_percentage": -12.5,
            "generated_at": "2025-12-25T10:30:00",
            "model_metadata": {...}
        }
    """
    
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "city": "Curitiba",
                "geocode": "4106902",
                "state": "PR",
                "historical_data": [
                    {
                        "week_number": 42,
                        "date": "2025-10-19",
                        "cases": 156
                    },
                    {
                        "week_number": 43,
                        "date": "2025-10-26",
                        "cases": 142
                    }
                ],
                "predictions": [
                    {
                        "week_number": 1,
                        "date": "2025-01-05",
                        "predicted_cases": 245.8,
                        "confidence": "high",
                        "lower_bound": 220.0,
                        "upper_bound": 270.0
                    }
                ],
                "trend": "descending",
                "trend_percentage": -12.5,
                "generated_at": "2025-12-25T10:30:00",
                "model_metadata": {
                    "model_name": "DengoAI v1.0",
                    "accuracy": 0.91,
                    "mae": 27.0
                }
            }
        }
    )
    
    city: str = Field(
        ...,
        min_length=1,
        description="Nome do município"
    )
    
    geocode: str = Field(
        ...,
        pattern=r"^\d{7}$",
        description="Código IBGE"
    )
    
    state: str = Field(
        default="PR",
        min_length=2,
        max_length=2,
        description="Sigla do estado"
    )
    
    historical_data: List[HistoricalWeek] = Field(
        default=[],
        description="Dados históricos das últimas 12 semanas (casos confirmados)"
    )
    
    predictions: List[WeekPrediction] = Field(
        ...,
        min_length=1,
        max_length=12,  # Ajustado também para permitir retornar até 12 predições
        description="Lista de predições semanais"
    )
    
    trend: TrendType = Field(
        ...,
        description="Tendência geral dos casos"
    )
    
    trend_percentage: float = Field(
        ...,
        description="Variação percentual da tendência (%)"
    )
    
    generated_at: datetime = Field(
        default_factory=datetime.now,
        description="Timestamp de geração da predição"
    )
    
    model_metadata: ModelMetadata = Field(
        default_factory=ModelMetadata,
        description="Metadados do modelo de IA"
    )


# ════════════════════════════════════════════════════════════════════════════
# ERROR SCHEMAS
# ════════════════════════════════════════════════════════════════════════════


class PredictionError(BaseModel):
    """Schema para erros na predição."""
    
    error_code: str = Field(
        ...,
        description="Código do erro"
    )
    
    message: str = Field(
        ...,
        description="Mensagem de erro amigável"
    )
    
    details: Optional[str] = Field(
        None,
        description="Detalhes técnicos do erro"
    )
    
    geocode: Optional[str] = Field(
        None,
        description="Geocode que causou o erro"
    )