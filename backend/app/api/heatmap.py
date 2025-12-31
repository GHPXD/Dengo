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
import numpy as np
import unicodedata

from app.core.config import settings
from app.schemas.heatmap import HeatmapResponseSchema, CityHeatmapSchema
from app.services.cities_service import cities_service

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Rate limiter
limiter = Limiter(key_func=get_remote_address)

# Router
router = APIRouter()


def normalize_text(text: str) -> str:
    """Normaliza texto para comparação (remove acentos e caixa baixa)."""
    if not isinstance(text, str):
        return str(text)
    nfkd = unicodedata.normalize('NFD', text)
    text_without_accents = ''.join([c for c in nfkd if not unicodedata.combining(c)])
    return text_without_accents.lower().strip()


def _calculate_risk_level(incidencia: float) -> str:
    """
    Calcula nível de risco baseado em incidência.
    Critérios (OMS): Baixo < 100, Moderado 100-300, Alto > 300.
    """
    if incidencia < 100:
        return "baixo"
    elif incidencia < 300:
        return "moderado"
    else:
        return "alto"


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
    Retorna dados geográficos para o heatmap.
    Realiza o merge entre o CSV de Casos e o JSON de Cidades (Geo).
    """
    try:
        logger.info(f"Gerando heatmap para {state} - período: {period}")

        if state != "PR":
            raise HTTPException(
                status_code=400,
                detail=f"Estado {state} não suportado. Apenas PR disponível.",
            )

        # 1. Carrega dados geográficos do CitiesService (JSON)
        # Isso garante Lat/Lon corretos mesmo que o CSV não tenha
        cities_data = cities_service.get_cities_by_uf("PR")
        
        # Cria mapa para busca rápida: { "nome_normalizado": dados_cidade }
        geo_map = {
            normalize_text(c['nome']): c 
            for c in cities_data
        }

        # 2. Carrega CSV de dados históricos (Casos)
        csv_path = settings.csv_path
        logger.info(f"Lendo CSV: {csv_path}")

        try:
            df = pd.read_csv(csv_path, low_memory=False)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Erro ao ler CSV: {str(e)}")

        # Verifica se as colunas essenciais do SEU dataset existem
        # Baseado no seu snippet: 'cidade', 'casos', 'data' ou 'SE'
        if "cidade" not in df.columns or "casos" not in df.columns:
             raise HTTPException(
                status_code=500, 
                detail=f"CSV inválido. Colunas esperadas: 'cidade', 'casos'. Encontradas: {list(df.columns)}"
            )

        # 3. Filtra pelo período solicitado
        # Se tiver coluna de data ou semana, filtra os últimos registros
        # Se não tiver data clara, assume que o arquivo está ordenado e pega o final
        
        weeks_to_fetch = 4 if period == "month" else 1
        
        # Agrupa por cidade e pega as últimas N linhas de cada cidade
        # Isso funciona assumindo que o CSV está ordenado por tempo
        df_filtered = df.groupby("cidade").tail(weeks_to_fetch)

        # 4. Agrupa e Soma os casos
        grouped = (
            df_filtered.groupby("cidade")
            .agg({
                "casos": "sum",
                "pop": "max" # Tenta pegar população do CSV, se tiver
            })
            .reset_index()
        )

        # 5. Merge e Montagem da Resposta
        final_cities = []
        
        for _, row in grouped.iterrows():
            city_name_raw = row["cidade"]
            city_norm = normalize_text(city_name_raw)
            
            # Busca dados geográficos no mapa do sistema
            geo_info = geo_map.get(city_norm)
            
            if not geo_info:
                # Tenta busca parcial se não achar exato
                continue

            # Dados do CSV
            casos = int(row["casos"])
            
            # Dados Geo (Prioridade: JSON do sistema)
            populacao = int(geo_info["populacao"])
            lat = float(geo_info["latitude"])
            lon = float(geo_info["longitude"])
            geocode = str(geo_info["ibge_codigo"])

            # Cálculo de Risco
            incidencia = 0.0
            if populacao > 0:
                incidencia = (casos / populacao) * 100000
            
            risk = _calculate_risk_level(incidencia)

            final_cities.append(CityHeatmapSchema(
                geocode=geocode,
                nome=geo_info["nome"], # Nome bonito do JSON
                latitude=lat,
                longitude=lon,
                casos=casos,
                populacao=populacao,
                incidencia=round(incidencia, 2),
                nivel_risco=risk
            ))

        if not final_cities:
            logger.warning("Nenhuma cidade correspondida entre CSV e Base Geo.")
            return HeatmapResponseSchema(
                estado=state,
                total_cidades=0,
                periodo=period,
                cidades=[]
            )

        logger.info(f"Heatmap gerado com sucesso: {len(final_cities)} cidades")

        return HeatmapResponseSchema(
            estado=state,
            total_cidades=len(final_cities),
            periodo=period,
            cidades=final_cities,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao gerar heatmap: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500, detail=f"Erro interno heatmap: {str(e)}"
        )