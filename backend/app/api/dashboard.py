"""
API de Dashboard - Visão Geral por Cidade
=========================================

Agrega dados de múltiplas fontes para apresentar o painel principal:
- Dados climáticos (WeatherService)
- Predições de IA (PredictionService)
- Dados históricos reais (InfoDengueService)
- Informações demográficas (CitiesService)
"""

import logging
from typing import Optional

from fastapi import APIRouter, HTTPException, Query, Request
from slowapi import Limiter
from slowapi.util import get_remote_address

# Garante que o schema foi atualizado conforme correção anterior
from app.schemas.dashboard import DashboardResponse
from app.services.cities_service import cities_service
# CORREÇÃO AQUI: Importa infodengue_service (sem underscore extra)
from app.services.infodengue_service import infodengue_service
from app.services.prediction_service import prediction_service
from app.services.weather_service import weather_service
from app.core.config import settings

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Rate limiter
limiter = Limiter(key_func=get_remote_address)

# Router
router = APIRouter()


@router.get("", response_model=DashboardResponse)
@limiter.limit("20/minute")
async def get_dashboard(
    request: Request,
    city_id: str = Query(..., description="Código IBGE da cidade (7 dígitos)", min_length=7, max_length=7)
):
    """
    Retorna dados completos para o dashboard da cidade.
    
    Agrega:
    1. Clima atual (OpenWeather)
    2. Predição de risco (IA)
    3. Dados históricos (InfoDengue)
    4. Dados demográficos (IBGE)
    """
    logger.info(f"📊 Dashboard request: city_id={city_id}")

    # 1. Busca dados da cidade no serviço local (JSON)
    # Isso garante nome e população corretos (ex: Nova Tebas = ~6k hab)
    city_info = cities_service.get_city_by_ibge(city_id)
    
    if not city_info:
        # Se não achou no JSON, tenta buscar na API do IBGE ou retorna erro
        # Por enquanto, retorna 404 se não estiver na base local
        logger.warning(f"❌ Cidade {city_id} não encontrada na base local.")
        raise HTTPException(status_code=404, detail=f"Cidade {city_id} não encontrada.")

    city_name = city_info.get("nome", "Desconhecida")
    # Usa a população real do JSON, com fallback para 10k
    population = city_info.get("populacao", 10000) 
    state = city_info.get("uf", "PR")
    lat = city_info.get("latitude", -25.25)
    lon = city_info.get("longitude", -52.02)

    logger.info(f"📍 Cidade: {city_name} ({population} hab)")

    # 2. Busca Clima Atual
    try:
        weather = await weather_service.get_current_weather(lat, lon)
    except Exception as e:
        logger.error(f"Erro ao buscar clima: {e}")
        # Fallback de clima
        weather = {
            "temperatura_atual": 25.0,
            "temperatura_min": 20.0,
            "temperatura_max": 30.0,
            "umidade": 60,
            "descricao": "Dados indisponíveis",
            "icon": "01d",
            "fonte": "Offline"
        }

    # 3. Busca Dados Históricos (InfoDengue)
    try:
        # Busca últimas 16 semanas para suportar filtro de 12 semanas no frontend
        # CORREÇÃO: Aumentado de 8 para 16 semanas
        historical_df = await infodengue_service.get_historical_data(city_id, weeks=16)
        
        # Converte lista de dicts para lista de objetos compatíveis com schema
        # O Service já retorna lista de dicts, não DataFrame, então iteramos direto
        historical_data = []
        if historical_df:
            for row in historical_df:
                historical_data.append({
                    "week_number": int(row.get('semana_epidemiologica', 0)),
                    "date": row.get('data', '2024-01-01'),
                    "cases": int(row.get('casos', 0))
                })
    except Exception as e:
        logger.error(f"Erro ao buscar histórico: {e}")
        historical_data = []

    # 4. Gera Predição (IA)
    try:
        # Prepara dados para o modelo
        # IMPORTANTE: Usar semanas COMPLETAS para predição
        # historical_data[0] = semana atual (pode ser parcial!)
        # historical_data[1] = última semana completa
        # historical_data[2] = semana anterior à última
        
        # Filtra apenas semanas válidas (week_number > 0)
        valid_weeks = [h for h in historical_data if h.get('week_number', 0) > 0]
        
        # Usa índice 1 e 2 para pegar semanas COMPLETAS
        casos_semana_anterior = valid_weeks[1]['cases'] if len(valid_weeks) > 1 else 0
        casos_2sem_anterior = valid_weeks[2]['cases'] if len(valid_weeks) > 2 else 0
        
        logger.info(
            f"📊 Dados para predição: "
            f"sem_anterior={casos_semana_anterior}, "
            f"2sem_anterior={casos_2sem_anterior}"
        )

        prediction = prediction_service.predict(
            temperatura_media=weather.get("temperatura_atual", 25.0),
            temperatura_min=weather.get("temperatura_min", 20.0),
            temperatura_max=weather.get("temperatura_max", 30.0),
            umidade=weather.get("umidade", 60.0),
            precipitacao=50.0, # Valor médio estimado se não tiver realtime
            populacao_densidade=int(population / 100) if population else 100,
            casos_semana_anterior=casos_semana_anterior,
            casos_2sem_anterior=casos_2sem_anterior
        )
    except Exception as e:
        logger.error(f"Erro na predição: {e}")
        # Fallback
        prediction = {
            "casos_estimados": 0,
            "nivel_risco": "baixo",
            "confianca": 0.0,
            "tendencia": "estavel",
            "fonte": "Erro"
        }

    # 5. Monta Resposta Final
    return DashboardResponse(
        city=city_name,
        geocode=city_id,
        state=state,
        population=population,
        
        # Clima
        current_temp=weather.get("temperatura_atual"),
        min_temp=weather.get("temperatura_min"),
        max_temp=weather.get("temperatura_max"),
        weather_desc=weather.get("descricao"),
        weather_icon=weather.get("icon"),
        
        # Predição
        risk_level=prediction["nivel_risco"],
        predicted_cases=prediction["casos_estimados"],
        trend=prediction["tendencia"],
        
        # Histórico
        historical_data=historical_data,
        
        # Metadados
        last_updated=None 
    )