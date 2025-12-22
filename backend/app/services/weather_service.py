"""
════════════════════════════════════════════════════════════════════════════
WEATHER SERVICE - OPENWEATHERMAP API INTEGRATION
════════════════════════════════════════════════════════════════════════════

Busca dados climáticos do OpenWeatherMap API.

Features:
    - Clima atual por coordenadas (lat/lon)
    - Tratamento de erros com fallback seguro
    - Rate limiting awareness (60 calls/min free tier)
    - Async/await com httpx

API Docs:
    https://openweathermap.org/current

Endpoints usados:
    GET /weather?lat={lat}&lon={lon}&appid={api_key}&units=metric&lang=pt_br

Autor: Dengo Team
Data: 2025-12-09
════════════════════════════════════════════════════════════════════════════
"""

import json
from typing import Dict, List, Optional

import httpx

from app.core.config import settings
from app.core.logger import logger


class WeatherService:
    """
    Serviço para buscar dados climáticos do OpenWeatherMap.
    
    Implementa graceful degradation: retorna dados padrão se API falhar.
    Smart Grid Cache: Agrupa cidades próximas (~11km) para economizar API calls.
    """

    def __init__(self):
        """Inicializa o serviço."""
        self.base_url = settings.openweather_base_url
        self.api_key = settings.openweather_api_key
        self.timeout = 10  # segundos
    
    def _get_grid_key(self, lat: float, lon: float) -> str:
        """
        Gera chave de cache compartilhada para coordenadas próximas.
        
        Arredonda coordenadas para 1 casa decimal (~11km de raio).
        Isso permite que cidades vizinhas compartilhem o mesmo dado climático.
        
        Args:
            lat: Latitude (-90 a 90)
            lon: Longitude (-180 a 180)
        
        Returns:
            str: Chave de cache no formato "weather:grid:{lat_rounded}:{lon_rounded}"
        
        Exemplo:
            São Paulo: lat=-23.5505, lon=-46.6333
            Grid Key: "weather:grid:-23.6:-46.6"
            
            Guarulhos: lat=-23.4543, lon=-46.5333
            Grid Key: "weather:grid:-23.5:-46.5" (diferente, mas próximo)
            
        Economia:
            - Antes: 5.570 cidades = 5.570 cache keys
            - Depois: ~100-200 grids habitados = ~100-200 cache keys
            - Redução: ~97% menos API calls
        """
        lat_rounded = round(lat, 1)  # -25.4284 -> -25.4
        lon_rounded = round(lon, 1)  # -49.2733 -> -49.3
        return f"weather:grid:{lat_rounded}:{lon_rounded}"

    async def get_current_weather(
        self, lat: float, lon: float, use_cache: bool = True
    ) -> dict:
        """
        Busca clima atual por coordenadas geográficas com Smart Grid Cache.

        Args:
            lat: Latitude (-90 a 90)
            lon: Longitude (-180 a 180)
            use_cache: Se True, usa cache compartilhado por região (default: True)

        Returns:
            dict: Dados climáticos
                {
                    "temperatura_atual": float,
                    "temperatura_min": float,
                    "temperatura_max": float,
                    "umidade": float,
                    "descricao": str,
                    "icon": str,
                    "fonte": str
                }

        Exemplo:
            weather = await service.get_current_weather(-23.5505, -46.6333)
            # São Paulo: lat=-23.5505, lon=-46.6333
        
        Smart Grid Cache:
            - Cidades num raio de ~11km compartilham o mesmo dado climático
            - TTL: 7200s (2 horas - clima não muda rapidamente)
            - Economia: 97% menos API calls para OpenWeatherMap
        """
        logger.info(f"🌦️  Buscando clima atual (lat={lat}, lon={lon})...")
        
        # ════════════════════════════════════════════════════════════════════
        # SMART GRID CACHE CHECK
        # ════════════════════════════════════════════════════════════════════
        if use_cache:
            grid_key = self._get_grid_key(lat, lon)
            
            try:
                from app.services import cache_service
                
                if cache_service.is_connected:
                    cached_weather = await cache_service.redis_client.get(grid_key)
                    if cached_weather:
                        logger.success(f"✓ Cache HIT (Grid: {grid_key})")
                        return json.loads(cached_weather)
                    else:
                        logger.info(f"⚠ Cache MISS (Grid: {grid_key})")
            except Exception as e:
                logger.warning(f"⚠️  Cache check failed: {e}")

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(
                    f"{self.base_url}/weather",
                    params={
                        "lat": lat,
                        "lon": lon,
                        "appid": self.api_key,
                        "units": "metric",  # Celsius
                        "lang": "pt_br",
                    },
                )

                # Valida status code
                if response.status_code == 401:
                    logger.error("❌ OpenWeather API: Chave inválida (401)")
                    return self._get_fallback_weather()

                if response.status_code == 429:
                    logger.error("❌ OpenWeather API: Rate limit excedido (429)")
                    return self._get_fallback_weather()

                if response.status_code != 200:
                    logger.error(
                        f"❌ OpenWeather API error: HTTP {response.status_code}"
                    )
                    return self._get_fallback_weather()

                # Parse JSON
                data = response.json()

                # Extrai dados relevantes
                weather_data = {
                    "temperatura_atual": data["main"]["temp"],
                    "temperatura_min": data["main"]["temp_min"],
                    "temperatura_max": data["main"]["temp_max"],
                    "umidade": data["main"]["humidity"],
                    "descricao": data["weather"][0]["description"],
                    "icon": data["weather"][0]["icon"],
                    "fonte": "OpenWeatherMap",
                }

                logger.success(
                    f"✓ Clima obtido: {weather_data['temperatura_atual']}°C, "
                    f"{weather_data['descricao']}"
                )
                
                # ════════════════════════════════════════════════════════════
                # SMART GRID CACHE SAVE
                # ════════════════════════════════════════════════════════════
                if use_cache:
                    try:
                        from app.services import cache_service
                        
                        if cache_service.is_connected:
                            grid_key = self._get_grid_key(lat, lon)
                            # TTL: 2 horas (7200s) - clima não muda rapidamente
                            await cache_service.redis_client.setex(
                                grid_key, 7200, json.dumps(weather_data)
                            )
                            logger.info(f"✓ Cache SAVED (Grid: {grid_key}, TTL: 2h)")
                    except Exception as e:
                        logger.warning(f"⚠️  Cache save failed: {e}")

                return weather_data

        except httpx.TimeoutException:
            logger.error("❌ OpenWeather API timeout (10s)")
            return self._get_fallback_weather()

        except httpx.HTTPError as e:
            logger.error(f"❌ OpenWeather HTTP error: {e}")
            return self._get_fallback_weather()

        except KeyError as e:
            logger.error(f"❌ OpenWeather response parsing error: {e}")
            return self._get_fallback_weather()

        except Exception as e:
            logger.error(f"❌ Unexpected error fetching weather: {e}")
            return self._get_fallback_weather()

    async def get_weather_by_city_name(self, city_name: str, state: str) -> dict:
        """
        Busca clima por nome da cidade (fallback se não tiver coordenadas).

        Args:
            city_name: Nome da cidade (ex: "São Paulo")
            state: Sigla do estado (ex: "SP")

        Returns:
            dict: Dados climáticos (mesmo formato de get_current_weather)

        Endpoint:
            GET /weather?q={city},{state_code},BR&appid={key}
        """
        logger.info(f"🌦️  Buscando clima por nome: {city_name}, {state}")

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(
                    f"{self.base_url}/weather",
                    params={
                        "q": f"{city_name},{state},BR",
                        "appid": self.api_key,
                        "units": "metric",
                        "lang": "pt_br",
                    },
                )

                if response.status_code != 200:
                    logger.error(
                        f"❌ OpenWeather API error: HTTP {response.status_code}"
                    )
                    return self._get_fallback_weather()

                data = response.json()

                weather_data = {
                    "temperatura_atual": data["main"]["temp"],
                    "temperatura_min": data["main"]["temp_min"],
                    "temperatura_max": data["main"]["temp_max"],
                    "umidade": data["main"]["humidity"],
                    "descricao": data["weather"][0]["description"],
                    "icon": data["weather"][0]["icon"],
                    "fonte": "OpenWeatherMap",
                }

                logger.success(f"✓ Clima obtido para {city_name}")

                return weather_data

        except Exception as e:
            logger.error(f"❌ Error fetching weather by city name: {e}")
            return self._get_fallback_weather()

    def _get_fallback_weather(self) -> dict:
        """
        Retorna dados climáticos padrão quando API falha.

        Usa valores médios históricos para Brasil tropical.
        Melhor retornar dados aproximados do que crashar a aplicação.

        Returns:
            dict: Dados climáticos genéricos
        """
        logger.warning("⚠️  Usando dados climáticos de fallback")

        return {
            "temperatura_atual": 25.0,  # Média Brasil
            "temperatura_min": 20.0,
            "temperatura_max": 30.0,
            "umidade": 70.0,  # Média tropical
            "descricao": "Dados indisponíveis (usando média histórica)",
            "icon": "01d",  # Clear sky icon
            "fonte": "Fallback (API indisponível)",
        }

    async def get_forecast_5_days(self, lat: float, lon: float) -> List[Dict]:
        """
        Busca previsão de 5 dias (3h intervals).

        Args:
            lat: Latitude
            lon: Longitude

        Returns:
            list[dict]: Lista com previsões de 3 em 3 horas

        Endpoint:
            GET /forecast?lat={lat}&lon={lon}&appid={key}

        Note:
            Free tier: 5 day / 3 hour forecast
            Retorna ~40 pontos de dados (5 dias * 8 pontos/dia)
        """
        logger.info(f"📅 Buscando previsão 5 dias (lat={lat}, lon={lon})...")

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(
                    f"{self.base_url}/forecast",
                    params={
                        "lat": lat,
                        "lon": lon,
                        "appid": self.api_key,
                        "units": "metric",
                        "lang": "pt_br",
                    },
                )

                if response.status_code != 200:
                    logger.error(
                        f"❌ OpenWeather Forecast API error: HTTP {response.status_code}"
                    )
                    return []

                data = response.json()

                # Processa lista de previsões
                forecasts = []
                for item in data["list"]:
                    forecasts.append(
                        {
                            "timestamp": item["dt"],
                            "data_hora": item["dt_txt"],
                            "temperatura": item["main"]["temp"],
                            "umidade": item["main"]["humidity"],
                            "descricao": item["weather"][0]["description"],
                        }
                    )

                logger.success(f"✓ Previsão obtida: {len(forecasts)} pontos")

                return forecasts

        except Exception as e:
            logger.error(f"❌ Error fetching forecast: {e}")
            return []


# ════════════════════════════════════════════════════════════════════════════
# COORDENADAS DAS PRINCIPAIS CIDADES (CACHE ESTÁTICO)
# ════════════════════════════════════════════════════════════════════════════

CITY_COORDINATES = {
    "3550308": {"name": "São Paulo", "lat": -23.5505, "lon": -46.6333},
    "3304557": {"name": "Rio de Janeiro", "lat": -22.9068, "lon": -43.1729},
    "3106200": {"name": "Belo Horizonte", "lat": -19.9167, "lon": -43.9345},
    "4106902": {"name": "Curitiba", "lat": -25.4284, "lon": -49.2733},
    "4314902": {"name": "Porto Alegre", "lat": -30.0346, "lon": -51.2177},
    "5300108": {"name": "Brasília", "lat": -15.8267, "lon": -47.9218},
    "2927408": {"name": "Salvador", "lat": -12.9714, "lon": -38.5014},
    "2611606": {"name": "Recife", "lat": -8.0476, "lon": -34.8770},
    "2304400": {"name": "Fortaleza", "lat": -3.7172, "lon": -38.5434},
    "1302603": {"name": "Manaus", "lat": -3.1190, "lon": -60.0217},
}


# ════════════════════════════════════════════════════════════════════════════
# SINGLETON INSTANCE
# ════════════════════════════════════════════════════════════════════════════

weather_service = WeatherService()
