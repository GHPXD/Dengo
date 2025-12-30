"""
Schemas para estatísticas estaduais de dengue.

Usado para retornar médias e agregações a nível de estado.
"""

from pydantic import BaseModel, Field


class StateStatisticsSchema(BaseModel):
    """Estatísticas agregadas de um estado"""

    estado: str = Field(
        ..., description="Sigla do estado (ex: PR, SP)", example="PR"
    )
    total_municipios: int = Field(
        ..., description="Número total de municípios com dados", example=399, ge=0
    )
    incidencia_media: float = Field(
        ...,
        description="Incidência média por 100mil habitantes no estado",
        example=28.3,
        ge=0,
    )
    taxa_crescimento: float = Field(
        ...,
        description="Taxa de crescimento médio de casos (%) nos últimos 7 dias",
        example=8.0,
    )
    taxa_recuperacao: float = Field(
        ...,
        description="Taxa de recuperação média (%)",
        example=82.0,
        ge=0,
        le=100,
    )
    casos_totais: int = Field(
        ..., description="Total de casos confirmados no estado", example=12450, ge=0
    )
    populacao_total: int = Field(
        ..., description="População total do estado", example=11516840, ge=0
    )

    class Config:
        """Configurações do Pydantic"""

        json_schema_extra = {
            "example": {
                "estado": "PR",
                "total_municipios": 399,
                "incidencia_media": 28.3,
                "taxa_crescimento": 8.0,
                "taxa_recuperacao": 82.0,
                "casos_totais": 3265,
                "populacao_total": 11516840,
            }
        }
