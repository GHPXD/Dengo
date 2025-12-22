"""Schemas Pydantic para o endpoint /api/dashboard."""

from typing import List
from pydantic import BaseModel, Field


class CidadeSchema(BaseModel):
    """Informações da cidade."""

    ibge_codigo: str = Field(..., description="Código IBGE da cidade")
    nome: str = Field(..., description="Nome da cidade")
    populacao: int = Field(..., description="População estimada")


class DadoHistoricoSchema(BaseModel):
    """Dados históricos de um período específico."""

    data: str = Field(..., description="Data no formato YYYY-MM-DD")
    casos: int = Field(..., description="Número de casos confirmados")
    temperatura_media: float = Field(..., description="Temperatura média (°C)")
    umidade_media: float = Field(..., description="Umidade média (%)")


class PredicaoSchema(BaseModel):
    """Predição de casos futuros."""

    casos_estimados: int = Field(..., description="Número estimado de casos")
    nivel_risco: str = Field(..., description="Nível de risco: baixo, medio, alto, muito_alto")
    tendencia: str = Field(..., description="Tendência: subindo, estavel, caindo")
    confianca: float = Field(..., ge=0, le=1, description="Confiança da predição (0-1)")


class DashboardResponseSchema(BaseModel):
    """Resposta completa do endpoint /api/dashboard."""

    cidade: CidadeSchema
    dados_historicos: List[DadoHistoricoSchema]
    predicao: PredicaoSchema

    class Config:
        """Configurações do schema."""

        json_schema_extra = {
            "example": {
                "cidade": {
                    "ibge_codigo": "3550308",
                    "nome": "São Paulo",
                    "populacao": 12252023,
                },
                "dados_historicos": [
                    {
                        "data": "2024-12-01",
                        "casos": 245,
                        "temperatura_media": 24.5,
                        "umidade_media": 72.3,
                    },
                    {
                        "data": "2024-12-02",
                        "casos": 267,
                        "temperatura_media": 25.1,
                        "umidade_media": 68.9,
                    },
                ],
                "predicao": {
                    "casos_estimados": 1250,
                    "nivel_risco": "alto",
                    "tendencia": "subindo",
                    "confianca": 0.85,
                },
            }
        }
