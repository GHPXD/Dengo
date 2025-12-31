"""
SCHEMAS - DASHBOARD ENDPOINT
=========================================

Define a estrutura de dados retornada pelo endpoint /dashboard.
Alinhado com o modelo do Frontend (Flutter).
"""

from typing import List, Optional
from pydantic import BaseModel, Field


class HistoricalDataPoint(BaseModel):
    """Um ponto de dados no gráfico histórico (uma semana)."""
    
    week_number: int = Field(..., description="Número da semana do ano")
    date: str = Field(..., description="Data de referência (YYYY-MM-DD)")
    cases: int = Field(..., description="Número de casos confirmados/estimados")


class DashboardResponse(BaseModel):
    """
    Modelo de resposta plana para o Dashboard.
    Compatível com o DashboardDataModel do Flutter.
    """

    # --- Informações Demográficas ---
    city: str = Field(..., description="Nome da cidade")
    geocode: str = Field(..., description="Código IBGE")
    state: str = Field(..., description="UF")
    population: int = Field(..., description="População estimada")

    # --- Dados Climáticos ---
    current_temp: Optional[float] = Field(None, description="Temperatura atual (°C)")
    min_temp: Optional[float] = Field(None, description="Temperatura mínima (°C)")
    max_temp: Optional[float] = Field(None, description="Temperatura máxima (°C)")
    weather_desc: Optional[str] = Field(None, description="Descrição do clima (ex: nublado)")
    weather_icon: Optional[str] = Field(None, description="Ícone do OpenWeather")

    # --- Predição de Risco ---
    risk_level: str = Field(..., description="Nível de risco (baixo, moderado, alto, muito_alto)")
    predicted_cases: int = Field(..., description="Casos previstos para próxima semana")
    trend: str = Field(..., description="Tendência (subindo, estavel, caindo)")

    # --- Histórico ---
    historical_data: List[HistoricalDataPoint] = Field(
        default=[], 
        description="Lista de dados históricos para o gráfico"
    )

    # --- Metadados ---
    last_updated: Optional[str] = Field(None, description="Timestamp da última atualização")

    class Config:
        json_schema_extra = {
            "example": {
                "city": "Curitiba",
                "geocode": "4106902",
                "state": "PR",
                "population": 1963726,
                "current_temp": 24.5,
                "min_temp": 18.0,
                "max_temp": 28.0,
                "weather_desc": "céu limpo",
                "weather_icon": "01d",
                "risk_level": "alto",
                "predicted_cases": 150,
                "trend": "subindo",
                "historical_data": [
                    {"week_number": 42, "date": "2024-10-15", "cases": 45},
                    {"week_number": 43, "date": "2024-10-22", "cases": 60}
                ]
            }
        }