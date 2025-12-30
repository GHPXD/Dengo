"""
Schemas para o Heatmap de casos de dengue.

Usado para retornar dados geográficos com casos e nível de risco.
"""

from typing import List
from pydantic import BaseModel, Field


class CityHeatmapSchema(BaseModel):
    """Dados de uma cidade para o heatmap"""

    geocode: str = Field(..., description="Código IBGE da cidade", example="4106902")
    nome: str = Field(..., description="Nome da cidade", example="Curitiba")
    latitude: float = Field(
        ..., description="Latitude da cidade", example=-25.4284, ge=-90, le=90
    )
    longitude: float = Field(
        ..., description="Longitude da cidade", example=-49.2733, ge=-180, le=180
    )
    casos: int = Field(
        ..., description="Número total de casos confirmados", example=156, ge=0
    )
    populacao: int = Field(..., description="População da cidade", example=1963726, ge=0)
    incidencia: float = Field(
        ...,
        description="Incidência por 100mil habitantes",
        example=7.9,
        ge=0,
    )
    nivel_risco: str = Field(
        ...,
        description="Nível de risco (baixo/medio/alto)",
        example="baixo",
        pattern="^(baixo|medio|alto)$",
    )

    class Config:
        """Configurações do Pydantic"""

        json_schema_extra = {
            "example": {
                "geocode": "4106902",
                "nome": "Curitiba",
                "latitude": -25.4284,
                "longitude": -49.2733,
                "casos": 156,
                "populacao": 1963726,
                "incidencia": 7.9,
                "nivel_risco": "baixo",
            }
        }


class HeatmapResponseSchema(BaseModel):
    """Resposta do endpoint de heatmap"""

    estado: str = Field(..., description="Sigla do estado", example="PR")
    total_cidades: int = Field(
        ..., description="Total de cidades retornadas", example=399, ge=0
    )
    periodo: str = Field(
        ..., description="Período dos dados (week/month)", example="week"
    )
    cidades: List[CityHeatmapSchema] = Field(
        ..., description="Lista de cidades com dados geográficos"
    )

    class Config:
        """Configurações do Pydantic"""

        json_schema_extra = {
            "example": {
                "estado": "PR",
                "total_cidades": 399,
                "periodo": "week",
                "cidades": [
                    {
                        "geocode": "4106902",
                        "nome": "Curitiba",
                        "latitude": -25.4284,
                        "longitude": -49.2733,
                        "casos": 156,
                        "populacao": 1963726,
                        "incidencia": 7.9,
                        "nivel_risco": "baixo",
                    }
                ],
            }
        }
