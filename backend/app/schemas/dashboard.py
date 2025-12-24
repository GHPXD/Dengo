"""
════════════════════════════════════════════════════════════════════════════
SCHEMAS - DASHBOARD ENDPOINT (PRODUCTION)
════════════════════════════════════════════════════════════════════════════

Pydantic schemas para validação e serialização do endpoint /api/v1/dashboard.

Estrutura de Dados:
    DashboardResponseSchema
    ├── CidadeSchema (cidade)
    ├── DadosHistoricosSchema[] (dados_historicos)
    └── PredicaoSchema (predicao)
"""

from typing import List

from pydantic import BaseModel, Field


# ════════════════════════════════════════════════════════════════════════════
# NESTED SCHEMAS
# ════════════════════════════════════════════════════════════════════════════


class CidadeSchema(BaseModel):
    """Informações básicas da cidade"""

    ibge_codigo: str = Field(
        ..., description="Código IBGE da cidade (7 dígitos)", example="3550308"
    )
    nome: str = Field(..., description="Nome da cidade", example="São Paulo")
    populacao: int = Field(
        ..., description="População estimada", example=12252023, ge=0
    )


class DadosHistoricosSchema(BaseModel):
    """Dados históricos de dengue para um dia específico"""

    data: str = Field(
        ...,
        description="Data no formato YYYY-MM-DD",
        example="2024-01-15",
        pattern=r"^\d{4}-\d{2}-\d{2}$",
    )
    casos: int = Field(..., description="Casos confirmados no dia", example=42, ge=0)
    temperatura_media: float = Field(
        ..., description="Temperatura média (°C)", example=28.5, ge=-50, le=60
    )
    umidade_media: float = Field(
        ..., description="Umidade média (%)", example=75.0, ge=0, le=100
    )


class PredicaoSchema(BaseModel):
    """Predição de casos para a próxima semana"""

    casos_estimados: int = Field(
        ..., description="Casos estimados para próxima semana", example=120, ge=0
    )
    nivel_risco: str = Field(
        ...,
        description="Nível de risco: baixo, moderado, alto, muito_alto",
        example="moderado",
        pattern=r"^(baixo|moderado|alto|muito_alto)$",
    )
    tendencia: str = Field(
        ...,
        description="Tendência: estavel, subindo, caindo",
        example="subindo",
        pattern=r"^(estavel|subindo|caindo)$",
    )
    confianca: float = Field(
        ...,
        description="Confiança da predição (0-1)",
        example=0.75,
        ge=0.0,
        le=1.0,
    )


# ════════════════════════════════════════════════════════════════════════════
# MAIN RESPONSE SCHEMA
# ════════════════════════════════════════════════════════════════════════════


class DashboardResponseSchema(BaseModel):
    """
    Response completo do endpoint /api/v1/dashboard

    Exemplo de uso:
        >>> response = DashboardResponseSchema(
        ...     cidade={
        ...         "ibge_codigo": "3550308",
        ...         "nome": "São Paulo",
        ...         "populacao": 12252023
        ...     },
        ...     dados_historicos=[...],
        ...     predicao={...}
        ... )
    """

    cidade: CidadeSchema = Field(..., description="Informações da cidade")
    dados_historicos: List[DadosHistoricosSchema] = Field(
        ...,
        description="Histórico dos últimos 5 dias",
        min_length=5,
        max_length=5,
    )
    predicao: PredicaoSchema = Field(..., description="Predição para próxima semana")

    class Config:
        """Configurações do Pydantic"""

        json_schema_extra = {
            "example": {
                "cidade": {
                    "ibge_codigo": "3550308",
                    "nome": "São Paulo",
                    "populacao": 12252023,
                },
                "dados_historicos": [
                    {
                        "data": "2024-01-10",
                        "casos": 35,
                        "temperatura_media": 27.8,
                        "umidade_media": 72.5,
                    },
                    {
                        "data": "2024-01-11",
                        "casos": 42,
                        "temperatura_media": 28.2,
                        "umidade_media": 75.0,
                    },
                    {
                        "data": "2024-01-12",
                        "casos": 38,
                        "temperatura_media": 27.5,
                        "umidade_media": 70.0,
                    },
                    {
                        "data": "2024-01-13",
                        "casos": 45,
                        "temperatura_media": 29.0,
                        "umidade_media": 78.0,
                    },
                    {
                        "data": "2024-01-14",
                        "casos": 50,
                        "temperatura_media": 29.5,
                        "umidade_media": 80.0,
                    },
                ],
                "predicao": {
                    "casos_estimados": 120,
                    "nivel_risco": "moderado",
                    "tendencia": "subindo",
                    "confianca": 0.75,
                },
            }
        }
