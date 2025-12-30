"""
Data Service - Gerenciamento Híbrido de Dados para Predição
=============================================================

Implementa estratégia híbrida de obtenção de dados:
1. Tenta API InfoDengue (dados em tempo real)
2. Fallback para CSV local (DATASET_PARA_IA.csv)
3. Cache Redis para otimização

Garante resiliência e disponibilidade mesmo com APIs externas instáveis.

Author: Dengo Team
Created: 2025-12-25
"""

import asyncio
import io
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional, Dict, Any
from functools import lru_cache

import pandas as pd
import httpx
from loguru import logger

try:
    from redis import asyncio as aioredis
    REDIS_AVAILABLE = True
except ImportError:
    REDIS_AVAILABLE = False
    logger.warning("Redis não instalado - cache desabilitado")


# ════════════════════════════════════════════════════════════════════════════
# CONSTANTS
# ════════════════════════════════════════════════════════════════════════════

# Paths
MODELS_DIR = Path(__file__).parent.parent.parent / "models"
DATASET_PATH = MODELS_DIR / "DATASET_PARA_IA.csv"

# API InfoDengue
INFODENGUE_BASE_URL = "https://info.dengue.mat.br/api/alertcity"
INFODENGUE_TIMEOUT = 15  # segundos
INFODENGUE_MAX_RETRIES = 2

# Cache
CACHE_TTL = 3600  # 1 hora
CACHE_KEY_PREFIX = "dengo:data:"

# Features obrigatórias do dataset
REQUIRED_COLUMNS = [
    "data_iniSE",
    "SE",
    "casos_est",
    "casos",
    "tempmed",
    "tempmin",
    "tempmax",
    "umidmed",
    "umidmin",
    "umidmax",
    "receptivo",
    "Rt",
    "cidade",
]


# ════════════════════════════════════════════════════════════════════════════
# EXCEPTIONS
# ════════════════════════════════════════════════════════════════════════════


class DataNotFoundError(Exception):
    """Erro quando dados não são encontrados."""
    pass


class GeocodeNotFoundError(Exception):
    """Erro quando geocode é inválido."""
    pass


# ════════════════════════════════════════════════════════════════════════════
# DATA SERVICE
# ════════════════════════════════════════════════════════════════════════════


class DataService:
    """
    Serviço para obtenção de dados históricos de dengue.
    
    Estratégia híbrida:
    1. Cache Redis (se disponível e válido)
    2. API InfoDengue (dados recentes)
    3. CSV local (fallback confiável)
    
    Attributes:
        redis_client: Cliente Redis assíncrono (opcional)
        dataset_cache: Cache em memória do CSV
    
    Example:
        >>> data_service = DataService()
        >>> df = await data_service.get_historical_data("4106902", weeks=4)
        >>> print(df.tail())
    """
    
    def __init__(self, redis_url: Optional[str] = None):
        """
        Inicializa DataService.
        
        Args:
            redis_url: URL do Redis (ex: redis://localhost:6379)
                      Se None, cache é desabilitado
        """
        self.redis_client: Optional[aioredis.Redis] = None
        self.dataset_cache: Optional[pd.DataFrame] = None
        
        if redis_url and REDIS_AVAILABLE:
            try:
                self.redis_client = aioredis.from_url(
                    redis_url,
                    decode_responses=False  # Vamos armazenar pickle
                )
                logger.info(f"✅ Redis conectado: {redis_url}")
            except Exception as e:
                logger.warning(f"⚠️ Redis indisponível: {e}")
    
    @lru_cache(maxsize=1)
    def _load_dataset(self) -> pd.DataFrame:
        """
        Carrega dataset CSV (com cache em memória).
        
        Returns:
            DataFrame completo do DATASET_PARA_IA.csv
        
        Raises:
            FileNotFoundError: Se CSV não existir
        """
        if not DATASET_PATH.exists():
            raise FileNotFoundError(
                f"Dataset não encontrado: {DATASET_PATH}"
            )
        
        logger.info(f"📊 Carregando dataset: {DATASET_PATH.name}...")
        
        df = pd.read_csv(DATASET_PATH)
        
        # Converte data_iniSE de timestamp Unix (ms) para datetime
        df["data_iniSE"] = pd.to_datetime(df["data_iniSE"], unit="ms")
        
        # Ordena por cidade e data
        df = df.sort_values(["cidade", "data_iniSE"]).reset_index(drop=True)
        
        logger.success(
            f"✅ Dataset carregado: {len(df)} registros, "
            f"{df['cidade'].nunique()} cidades"
        )
        
        return df
    
    async def _get_from_cache(self, cache_key: str) -> Optional[pd.DataFrame]:
        """
        Busca dados do cache Redis.
        
        Args:
            cache_key: Chave do cache
        
        Returns:
            DataFrame se encontrado, None caso contrário
        """
        if not self.redis_client:
            return None
        
        try:
            cached = await self.redis_client.get(cache_key)
            if cached:
                # Desserializa pickle
                df = pd.read_pickle(io.BytesIO(cached))
                logger.debug(f"✅ Cache HIT: {cache_key}")
                return df
        except Exception as e:
            logger.warning(f"⚠️ Erro ao ler cache: {e}")
        
        return None
    
    async def _set_cache(self, cache_key: str, df: pd.DataFrame) -> None:
        """
        Armazena dados no cache Redis.
        
        Args:
            cache_key: Chave do cache
            df: DataFrame a cachear
        """
        if not self.redis_client:
            return
        
        try:
            import io
            buffer = io.BytesIO()
            df.to_pickle(buffer)
            
            await self.redis_client.setex(
                cache_key,
                CACHE_TTL,
                buffer.getvalue()
            )
            logger.debug(f"💾 Cache salvo: {cache_key}")
        except Exception as e:
            logger.warning(f"⚠️ Erro ao salvar cache: {e}")
    
    async def _fetch_from_api(
        self,
        geocode: str,
        weeks: int
    ) -> Optional[pd.DataFrame]:
        """
        Tenta buscar dados da API InfoDengue.
        
        Args:
            geocode: Código IBGE
            weeks: Número de semanas a buscar
        
        Returns:
            DataFrame se sucesso, None se falhar
        """
        try:
            logger.debug(f"🌐 Tentando API InfoDengue para {geocode}...")
            
            # Calcula período
            end_year = datetime.now().year
            start_year = end_year - 1  # Últimos 2 anos
            
            url = (
                f"{INFODENGUE_BASE_URL}"
                f"?geocode={geocode}"
                f"&disease=dengue"
                f"&format=json"
                f"&ew_start=1"
                f"&ew_end=53"
                f"&ey_start={start_year}"
                f"&ey_end={end_year}"
            )
            
            async with httpx.AsyncClient(timeout=INFODENGUE_TIMEOUT) as client:
                response = await client.get(url)
                response.raise_for_status()
                
                data = response.json()
                
                if not data:
                    logger.warning("API retornou dados vazios")
                    return None
                
                df = pd.DataFrame(data)
                
                # Converte data
                df["data_iniSE"] = pd.to_datetime(df["data_iniSE"], unit="ms")
                
                # Ordena e pega últimas N semanas
                df = df.sort_values("data_iniSE").tail(weeks)
                
                logger.success(f"✅ API InfoDengue: {len(df)} semanas")
                
                return df
                
        except httpx.TimeoutException:
            logger.warning(f"⏱️ Timeout na API InfoDengue")
            return None
        except httpx.HTTPStatusError as e:
            logger.warning(f"⚠️ API InfoDengue erro HTTP {e.response.status_code}")
            return None
        except Exception as e:
            logger.warning(f"⚠️ Erro inesperado na API: {e}")
            return None
    
    def _get_from_csv(
        self,
        geocode: str,
        weeks: int
    ) -> pd.DataFrame:
        """
        Busca dados do CSV local (fallback confiável).
        
        Args:
            geocode: Código IBGE (deve começar com 41 - Paraná)
            weeks: Número de semanas
        
        Returns:
            DataFrame com últimas N semanas do município do Paraná
        
        Raises:
            GeocodeNotFoundError: Se geocode não existir no Paraná
            DataNotFoundError: Se não houver dados suficientes
        """
        # Carrega dataset completo (usa cache)
        df_full = self._load_dataset()
        
        # Filtra por geocode do município do Paraná
        if 'geocodigo' in df_full.columns:
            df_city = df_full[df_full['geocodigo'] == int(geocode)]
        elif 'municipio_geocodigo' in df_full.columns:
            df_city = df_full[df_full['municipio_geocodigo'] == int(geocode)]
        else:
            # Fallback: se não tem coluna geocode, usa todos os dados
            # (assumindo CSV com dados de uma única cidade)
            logger.warning(
                f"CSV não possui coluna geocodigo, usando todos os dados disponíveis"
            )
            df_city = df_full
        
        if df_city.empty:
            raise GeocodeNotFoundError(
                f"Geocode {geocode} não encontrado no dataset do Paraná (399 municípios)"
            )
        
        # Ordena por data e pega últimas N semanas
        df_city = df_city.sort_values('data_iniSE').tail(weeks)
        
        if len(df_city) < weeks:
            raise DataNotFoundError(
                f"Dados insuficientes para município {geocode}: "
                f"Encontrado {len(df_city)} semanas, necessário {weeks}"
            )
        
        logger.success(f"✅ CSV Local (Paraná): {len(df_city)} semanas")
        
        return df_city
    
    async def get_historical_data(
        self,
        geocode: str,
        weeks: int = 4
    ) -> pd.DataFrame:
        """
        Obtém dados históricos com estratégia híbrida.
        
        Ordem de tentativa:
        1. Cache Redis
        2. API InfoDengue
        3. CSV Local (fallback)
        
        Args:
            geocode: Código IBGE do município (7 dígitos)
            weeks: Número de semanas históricas (default: 4)
        
        Returns:
            DataFrame com colunas obrigatórias ordenado por data
        
        Raises:
            GeocodeNotFoundError: Se geocode inválido
            DataNotFoundError: Se não houver dados
        
        Example:
            >>> df = await data_service.get_historical_data("4106902", weeks=4)
            >>> print(df[["data_iniSE", "casos_est", "tempmed"]].tail())
        """
        cache_key = f"{CACHE_KEY_PREFIX}{geocode}:w{weeks}"
        
        # 1. Tenta cache
        cached_data = await self._get_from_cache(cache_key)
        if cached_data is not None:
            logger.info(f"📦 Dados do cache: {geocode}")
            return cached_data
        
        # 2. Tenta API InfoDengue
        api_data = await self._fetch_from_api(geocode, weeks)
        if api_data is not None and len(api_data) >= weeks:
            await self._set_cache(cache_key, api_data)
            logger.info(f"🌐 Dados da API: {geocode}")
            return api_data
        
        # 3. Fallback para CSV
        logger.info(f"💾 Usando CSV como fallback: {geocode}")
        csv_data = self._get_from_csv(geocode, weeks)
        
        await self._set_cache(cache_key, csv_data)
        
        return csv_data
    
    async def get_city_name(self, geocode: str) -> str:
        """
        Obtém nome da cidade pelo geocode.
        
        Args:
            geocode: Código IBGE (deve começar com 41 - Paraná)
        
        Returns:
            Nome da cidade
        
        Raises:
            GeocodeNotFoundError: Se não encontrar município do Paraná
        """
        try:
            df = self._load_dataset()
            
            # Filtra por geocode - assume coluna 'geocodigo' ou 'municipio_geocodigo'
            if 'geocodigo' in df.columns:
                city_data = df[df['geocodigo'] == int(geocode)]
            elif 'municipio_geocodigo' in df.columns:
                city_data = df[df['municipio_geocodigo'] == int(geocode)]
            else:
                # Fallback: busca na coluna 'cidade' se for texto
                logger.warning("CSV não possui coluna geocodigo, usando nome da cidade")
                city_data = df.head(1)  # Retorna primeira linha
            
            if city_data.empty:
                raise GeocodeNotFoundError(
                    f"Município {geocode} não encontrado no dataset do Paraná"
                )
            
            # Pega nome da cidade (primeira ocorrência)
            city_name = str(city_data['cidade'].iloc[0]) if 'cidade' in city_data.columns else "Município"
            
            logger.debug(f"🏙️ Geocode {geocode} -> {city_name}")
            return city_name
            
        except GeocodeNotFoundError:
            raise
        except Exception as e:
            logger.error(f"Erro ao buscar nome da cidade: {e}")
            raise GeocodeNotFoundError(
                f"Geocode {geocode} não encontrado no dataset"
            ) from e
    
    async def close(self) -> None:
        """Fecha conexões (cleanup)."""
        if self.redis_client:
            await self.redis_client.close()
            logger.info("Redis desconectado")


# ════════════════════════════════════════════════════════════════════════════
# DEPENDENCY INJECTION
# ════════════════════════════════════════════════════════════════════════════


_data_service_instance: Optional[DataService] = None


def get_data_service() -> DataService:
    """
    Dependency injection para FastAPI.
    
    Returns:
        Instância singleton do DataService
    """
    global _data_service_instance
    
    if _data_service_instance is None:
        # TODO: Pegar redis_url do config
        _data_service_instance = DataService(redis_url=None)
    
    return _data_service_instance
