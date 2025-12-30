"""
API para Heatmap de dengue - dados geográficos de casos.

Retorna informações de todas as cidades com coordenadas e nível de risco.
"""

import logging
from typing import Literal
from fastapi import APIRouter, HTTPException, Query, Request
from slowapi import Limiter
from slowapi.util import get_remote_address
import pandas as pd

from app.core.config import settings
from app.schemas.heatmap import HeatmapResponseSchema, CityHeatmapSchema

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Rate limiter
limiter = Limiter(key_func=get_remote_address)

# Router
router = APIRouter()


def _calculate_risk_level(incidencia: float) -> str:
    """
    Calcula nível de risco baseado em incidência.

    Critérios (OMS):
    - Baixo: < 100 casos/100mil hab
    - Médio: 100 a 300 casos/100mil hab
    - Alto: > 300 casos/100mil hab

    Args:
        incidencia: Taxa de incidência por 100mil habitantes

    Returns:
        Nível de risco: "baixo", "medio" ou "alto"
    """
    if incidencia < 100:
        return "baixo"
    elif incidencia < 300:
        return "medio"
    else:
        return "alto"


def _get_period_weeks(period: str) -> int:
    """
    Retorna número de semanas para o período.

    Args:
        period: "week" ou "month"

    Returns:
        Número de semanas
    """
    if period == "week":
        return 1
    elif period == "month":
        return 4
    return 1


@router.get("", response_model=HeatmapResponseSchema)
@limiter.limit("30/minute")
async def get_heatmap(
    request: Request,
    state: str = Query(
        "PR",
        description="Sigla do estado",
        min_length=2,
        max_length=2,
        pattern="^[A-Z]{2}$",
    ),
    period: Literal["week", "month"] = Query(
        "week", description="Período de dados (week ou month)"
    ),
) -> HeatmapResponseSchema:
    """
    Retorna dados geográficos de todas as cidades para o heatmap.

    **Funcionamento:**
    1. Lê dados do CSV do dataset de treinamento
    2. Filtra por estado (apenas PR suportado)
    3. Calcula casos por cidade no período especificado
    4. Classifica nível de risco (baixo/médio/alto)
    5. Retorna lista com coordenadas e estatísticas

    **Níveis de Risco (OMS):**
    - Baixo: < 100 casos/100mil hab
    - Médio: 100-300 casos/100mil hab
    - Alto: > 300 casos/100mil hab

    **Rate Limit:** 30 requisições por minuto

    Args:
        state: Sigla do estado (padrão: PR)
        period: Período - "week" (1 semana) ou "month" (4 semanas)

    Returns:
        HeatmapResponseSchema com lista de cidades e dados geográficos

    Raises:
        HTTPException 400: Estado não suportado
        HTTPException 404: Dados não encontrados
        HTTPException 500: Erro ao processar dados
    """
    try:
        logger.info(f"Gerando heatmap para {state} - período: {period}")

        # Valida estado
        if state != "PR":
            raise HTTPException(
                status_code=400,
                detail=f"Estado {state} não suportado. Apenas PR disponível.",
            )

        # Carrega dataset
        csv_path = settings.CSV_PATH
        logger.info(f"Lendo CSV: {csv_path}")

        df = pd.read_csv(csv_path, low_memory=False)

        # Valida colunas necessárias
        required_cols = [
            "municipio_geocodigo",
            "municipio_nome",
            "municipio_latitude",
            "municipio_longitude",
            "casos_novos",
            "populacao",
        ]
        missing_cols = [col for col in required_cols if col not in df.columns]
        if missing_cols:
            raise HTTPException(
                status_code=500,
                detail=f"Colunas ausentes no dataset: {missing_cols}",
            )

        # Filtra Paraná (geocode inicia com "41")
        df["municipio_geocodigo"] = df["municipio_geocodigo"].astype(str)
        df_pr = df[df["municipio_geocodigo"].str.startswith("41")].copy()

        if df_pr.empty:
            raise HTTPException(
                status_code=404, detail="Nenhum dado encontrado para o Paraná"
            )

        # Calcula semanas para o período
        weeks = _get_period_weeks(period)

        # Ordena por data e pega últimas N semanas
        if "epidemiological_week" in df_pr.columns:
            df_pr = df_pr.sort_values("epidemiological_week", ascending=False)
            max_week = df_pr["epidemiological_week"].max()
            min_week = max_week - weeks + 1
            df_period = df_pr[
                (df_pr["epidemiological_week"] >= min_week)
                & (df_pr["epidemiological_week"] <= max_week)
            ]
        else:
            # Se não tiver semana epidemiológica, usa últimas N linhas por cidade
            df_period = df_pr.groupby("municipio_geocodigo").tail(weeks)

        # Agrupa por cidade e soma casos
        grouped = (
            df_period.groupby(
                [
                    "municipio_geocodigo",
                    "municipio_nome",
                    "municipio_latitude",
                    "municipio_longitude",
                    "populacao",
                ]
            )
            .agg({"casos_novos": "sum"})
            .reset_index()
        )

        # Remove linhas com coordenadas inválidas
        grouped = grouped.dropna(subset=["municipio_latitude", "municipio_longitude"])
        grouped = grouped[
            (grouped["municipio_latitude"] >= -90)
            & (grouped["municipio_latitude"] <= 90)
            & (grouped["municipio_longitude"] >= -180)
            & (grouped["municipio_longitude"] <= 180)
        ]

        # Calcula incidência e nível de risco
        grouped["incidencia"] = (grouped["casos_novos"] / grouped["populacao"]) * 100000
        grouped["nivel_risco"] = grouped["incidencia"].apply(_calculate_risk_level)

        # Converte para lista de CityHeatmapSchema
        cidades = []
        for _, row in grouped.iterrows():
            try:
                cidade = CityHeatmapSchema(
                    geocode=str(row["municipio_geocodigo"]),
                    nome=str(row["municipio_nome"]),
                    latitude=float(row["municipio_latitude"]),
                    longitude=float(row["municipio_longitude"]),
                    casos=int(row["casos_novos"]),
                    populacao=int(row["populacao"]),
                    incidencia=round(float(row["incidencia"]), 2),
                    nivel_risco=str(row["nivel_risco"]),
                )
                cidades.append(cidade)
            except Exception as e:
                logger.warning(
                    f"Erro ao processar cidade {row.get('municipio_nome', 'desconhecida')}: {e}"
                )
                continue

        if not cidades:
            raise HTTPException(
                status_code=404,
                detail="Nenhuma cidade com dados válidos encontrada",
            )

        logger.info(f"Heatmap gerado com sucesso: {len(cidades)} cidades")

        return HeatmapResponseSchema(
            estado=state,
            total_cidades=len(cidades),
            periodo=period,
            cidades=cidades,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao gerar heatmap: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500, detail=f"Erro ao processar dados do heatmap: {str(e)}"
        )
