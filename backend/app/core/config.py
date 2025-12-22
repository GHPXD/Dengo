"""
════════════════════════════════════════════════════════════════════════════
DENGUE PREDICT API - CONFIGURAÇÕES PRINCIPAIS
════════════════════════════════════════════════════════════════════════════
Gerenciamento centralizado de variáveis de ambiente usando Pydantic Settings.
Todas as configurações sensíveis vêm do arquivo .env
"""

from functools import lru_cache
from typing import List, Optional

from pydantic import Field, validator
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Configurações da aplicação carregadas de variáveis de ambiente."""

    # ════════════════════════════════════════════════════════════════════════
    # AMBIENTE
    # ════════════════════════════════════════════════════════════════════════
    environment: str = Field(default="development", alias="ENVIRONMENT")
    debug: bool = Field(default=True, alias="DEBUG")
    log_level: str = Field(default="INFO", alias="LOG_LEVEL")

    # ════════════════════════════════════════════════════════════════════════
    # API
    # ════════════════════════════════════════════════════════════════════════
    api_title: str = Field(default="DenguePredict API", alias="API_TITLE")
    api_version: str = Field(default="1.0.0", alias="API_VERSION")
    api_prefix: str = Field(default="/api/v1", alias="API_PREFIX")
    port: int = Field(default=8080, alias="PORT")

    # ════════════════════════════════════════════════════════════════════════
    # SUPABASE (PostgreSQL) - Opcional para MVP
    # ════════════════════════════════════════════════════════════════════════
    supabase_url: str = Field(default="https://mock.supabase.co", alias="SUPABASE_URL")
    supabase_key: str = Field(default="mock_key", alias="SUPABASE_KEY")
    supabase_service_key: str = Field(default="mock_service_key", alias="SUPABASE_SERVICE_KEY")
    database_url: str = Field(default="postgresql://mock:mock@localhost:5432/mock", alias="DATABASE_URL")

    # ════════════════════════════════════════════════════════════════════════
    # REDIS (Upstash Serverless) - Opcional para MVP
    # ════════════════════════════════════════════════════════════════════════
    redis_url: str = Field(default="redis://localhost:6379", alias="REDIS_URL")
    redis_ttl: int = Field(default=86400, alias="REDIS_TTL")  # 24h

    # ════════════════════════════════════════════════════════════════════════
    # APIS EXTERNAS
    # ════════════════════════════════════════════════════════════════════════
    # APIS EXTERNAS - Opcional para MVP
    # ════════════════════════════════════════════════════════════════════════
    openweather_api_key: str = Field(default="mock_api_key", alias="OPENWEATHER_API_KEY")
    openweather_base_url: str = Field(
        default="https://api.openweathermap.org/data/2.5",
        alias="OPENWEATHER_BASE_URL",
    )
    infodengue_base_url: str = Field(
        default="https://info.dengue.mat.br/api",
        alias="INFODENGUE_BASE_URL",
    )

    # ════════════════════════════════════════════════════════════════════════
    # CORS
    # ════════════════════════════════════════════════════════════════════════
    cors_origins: List[str] = Field(
        default=["http://localhost:3000", "http://localhost:8080"],
        alias="CORS_ORIGINS",
    )
    cors_allow_credentials: bool = Field(default=True, alias="CORS_ALLOW_CREDENTIALS")
    cors_allow_methods: List[str] = Field(
        default=["GET", "POST", "PUT", "DELETE"],
        alias="CORS_ALLOW_METHODS",
    )
    cors_allow_headers: List[str] = Field(default=["*"], alias="CORS_ALLOW_HEADERS")

    # ════════════════════════════════════════════════════════════════════════
    # SEGURANÇA - Com valores padrão para MVP
    # ════════════════════════════════════════════════════════════════════════
    secret_key: str = Field(default="mock_secret_key_for_development_only", alias="SECRET_KEY")
    algorithm: str = Field(default="HS256", alias="ALGORITHM")
    access_token_expire_minutes: int = Field(
        default=30,
        alias="ACCESS_TOKEN_EXPIRE_MINUTES",
    )

    # ════════════════════════════════════════════════════════════════════════
    # SENTRY (Opcional)
    # ════════════════════════════════════════════════════════════════════════
    sentry_dsn: Optional[str] = Field(default=None, alias="SENTRY_DSN")

    # ════════════════════════════════════════════════════════════════════════
    # VALIDAÇÕES
    # ════════════════════════════════════════════════════════════════════════
    @validator("cors_origins", pre=True)
    def parse_cors_origins(cls, v):
        """Converte string JSON para lista."""
        if isinstance(v, str):
            import json

            return json.loads(v)
        return v

    class Config:
        """Configuração do Pydantic Settings."""

        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False
        extra = "ignore"


@lru_cache()
def get_settings() -> Settings:
    """
    Retorna instância única (singleton) das configurações.
    Usa @lru_cache para cachear e evitar múltiplas leituras do .env
    """
    return Settings()


# Instância global para importação rápida
settings = get_settings()
