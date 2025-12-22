"""
════════════════════════════════════════════════════════════════════════════
CACHE SERVICE - REDIS SMART CACHING
════════════════════════════════════════════════════════════════════════════

Gerencia cache de dados do dashboard usando Upstash Redis (serverless).

Features:
    - Cache de dados do dashboard (economiza API calls)
    - TTL configurável (padrão: 3600s = 1 hora)
    - Graceful degradation (retorna None se Redis falhar)
    - Async/await com redis.asyncio

Uso:
    cache = CacheService()
    await cache.connect()
    
    # Get cached data
    data = await cache.get_dashboard_data(city_id="3550308")
    
    # Set cache
    await cache.set_dashboard_data(city_id="3550308", data={...})

Autor: Dengo Team
Data: 2025-12-09
════════════════════════════════════════════════════════════════════════════
"""

import json
from typing import Any, Optional

import redis.asyncio as redis

from app.core.config import settings
from app.core.logger import logger


class CacheService:
    """
    Serviço de cache usando Redis (Upstash).
    
    Implementa graceful degradation: se Redis falhar, retorna None
    ao invés de crashar a aplicação.
    """

    def __init__(self):
        """Inicializa o serviço (conexão criada no connect())."""
        self.redis_client: Optional[redis.Redis] = None
        self.is_connected: bool = False

    async def connect(self) -> None:
        """
        Conecta ao Redis usando URL do .env.
        
        URL format: rediss://default:password@host:port
        (rediss = Redis over TLS/SSL)
        """
        try:
            logger.info("🔌 Conectando ao Redis...")
            logger.debug(f"   Redis URL: {settings.redis_url[:30]}...")

            self.redis_client = redis.from_url(
                settings.redis_url,
                encoding="utf-8",
                decode_responses=True,
                socket_timeout=5,
                socket_connect_timeout=5,
            )

            # Testa conexão
            await self.redis_client.ping()
            self.is_connected = True

            logger.success("✓ Redis conectado com sucesso!")

        except redis.RedisError as e:
            logger.error(f"❌ Erro ao conectar no Redis: {e}")
            logger.warning("⚠️  Continuando sem cache (graceful degradation)")
            self.is_connected = False
        except Exception as e:
            logger.error(f"❌ Erro inesperado ao conectar no Redis: {e}")
            self.is_connected = False

    async def disconnect(self) -> None:
        """Fecha conexão com Redis."""
        if self.redis_client:
            try:
                await self.redis_client.close()
                logger.info("🔌 Redis desconectado")
            except Exception as e:
                logger.error(f"❌ Erro ao desconectar Redis: {e}")

    async def get_dashboard_data(self, city_id: str) -> Optional[dict]:
        """
        Busca dados do dashboard no cache.

        Args:
            city_id: Código IBGE da cidade (ex: "3550308")

        Returns:
            dict: Dados do dashboard (se existir no cache)
            None: Se não existir ou Redis estiver offline

        Cache Key Format:
            dashboard:{city_id}
            Exemplo: dashboard:3550308
        """
        if not self.is_connected or not self.redis_client:
            logger.debug("⚠️  Redis offline - pulando cache GET")
            return None

        cache_key = f"dashboard:{city_id}"

        try:
            cached_data = await self.redis_client.get(cache_key)

            if cached_data:
                logger.info(f"✓ Cache HIT: {cache_key}")
                return json.loads(cached_data)
            else:
                logger.debug(f"⚠ Cache MISS: {cache_key}")
                return None

        except redis.RedisError as e:
            logger.error(f"❌ Redis GET error: {e}")
            return None
        except json.JSONDecodeError as e:
            logger.error(f"❌ JSON decode error: {e}")
            return None
        except Exception as e:
            logger.error(f"❌ Unexpected error in cache GET: {e}")
            return None

    async def set_dashboard_data(
        self, city_id: str, data: dict, ttl: int = 3600
    ) -> bool:
        """
        Salva dados do dashboard no cache.

        Args:
            city_id: Código IBGE da cidade
            data: Dados do dashboard (dict serializável em JSON)
            ttl: Time To Live em segundos (padrão: 3600s = 1 hora)

        Returns:
            bool: True se salvou com sucesso, False caso contrário

        Cache Strategy:
            TTL = 1 hora → Dados climáticos mudam lentamente
            Economia: Reduz 99% das chamadas para APIs externas
        """
        if not self.is_connected or not self.redis_client:
            logger.debug("⚠️  Redis offline - pulando cache SET")
            return False

        cache_key = f"dashboard:{city_id}"

        try:
            json_data = json.dumps(data, ensure_ascii=False)

            await self.redis_client.setex(
                name=cache_key, time=ttl, value=json_data
            )

            logger.success(f"✓ Cache SET: {cache_key} (TTL: {ttl}s)")
            return True

        except redis.RedisError as e:
            logger.error(f"❌ Redis SET error: {e}")
            return False
        except (TypeError, ValueError) as e:
            logger.error(f"❌ JSON serialization error: {e}")
            return False
        except Exception as e:
            logger.error(f"❌ Unexpected error in cache SET: {e}")
            return False

    async def delete(self, city_id: str) -> bool:
        """
        Remove dados do cache.

        Args:
            city_id: Código IBGE da cidade

        Returns:
            bool: True se removeu com sucesso
        """
        if not self.is_connected or not self.redis_client:
            return False

        cache_key = f"dashboard:{city_id}"

        try:
            await self.redis_client.delete(cache_key)
            logger.info(f"🗑️  Cache DELETE: {cache_key}")
            return True
        except Exception as e:
            logger.error(f"❌ Error deleting cache: {e}")
            return False

    async def exists(self, city_id: str) -> bool:
        """
        Verifica se existe dados em cache para uma cidade.

        Args:
            city_id: Código IBGE da cidade

        Returns:
            bool: True se existe cache
        """
        if not self.is_connected or not self.redis_client:
            return False

        cache_key = f"dashboard:{city_id}"

        try:
            exists = await self.redis_client.exists(cache_key)
            return bool(exists)
        except Exception as e:
            logger.error(f"❌ Error checking cache existence: {e}")
            return False

    async def get_ttl(self, city_id: str) -> Optional[int]:
        """
        Retorna tempo restante (TTL) do cache em segundos.

        Args:
            city_id: Código IBGE da cidade

        Returns:
            int: Segundos restantes (ou -1 se não tiver TTL)
            None: Se erro ou Redis offline
        """
        if not self.is_connected or not self.redis_client:
            return None

        cache_key = f"dashboard:{city_id}"

        try:
            ttl = await self.redis_client.ttl(cache_key)
            return ttl
        except Exception as e:
            logger.error(f"❌ Error getting TTL: {e}")
            return None


# ════════════════════════════════════════════════════════════════════════════
# SINGLETON INSTANCE (será injetado no main.py)
# ════════════════════════════════════════════════════════════════════════════

cache_service = CacheService()
