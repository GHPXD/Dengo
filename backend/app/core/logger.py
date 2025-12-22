"""
════════════════════════════════════════════════════════════════════════════
DENGUE PREDICT API - LOGGING CONFIGURATION
════════════════════════════════════════════════════════════════════════════
Configuração centralizada de logs usando Loguru (mais simples que logging nativo)
"""

import sys
from pathlib import Path

from loguru import logger

from app.core.config import settings

# Remove handler padrão
logger.remove()

# ════════════════════════════════════════════════════════════════════════════
# CONFIGURAÇÃO DE LOGS
# ════════════════════════════════════════════════════════════════════════════

# Console (STDOUT) - Usado pelo Google Cloud Run
logger.add(
    sys.stdout,
    level=settings.log_level,
    format=(
        "<green>{time:YYYY-MM-DD HH:mm:ss}</green> | "
        "<level>{level: <8}</level> | "
        "<cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> | "
        "<level>{message}</level>"
    ),
    colorize=True,
    backtrace=True,
    diagnose=True,
)

# Arquivo (apenas em desenvolvimento)
if settings.environment == "development":
    log_path = Path("logs")
    log_path.mkdir(exist_ok=True)

    logger.add(
        log_path / "dengue_api_{time:YYYY-MM-DD}.log",
        rotation="00:00",  # Nova arquivo à meia-noite
        retention="7 days",  # Mantém logs por 7 dias
        compression="zip",  # Comprime logs antigos
        level="DEBUG",
        format=(
            "{time:YYYY-MM-DD HH:mm:ss} | "
            "{level: <8} | "
            "{name}:{function}:{line} | "
            "{message}"
        ),
    )


# ════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ════════════════════════════════════════════════════════════════════════════


def log_request(method: str, path: str, status_code: int, duration: float):
    """Log de requisições HTTP."""
    logger.info(
        f"{method} {path} - Status: {status_code} - Duration: {duration:.3f}s"
    )


def log_cache_hit(key: str):
    """Log de cache hit (economia de API calls)."""
    logger.success(f"CACHE HIT: {key} (Custo Zero ✓)")


def log_cache_miss(key: str):
    """Log de cache miss (nova chamada à API)."""
    logger.warning(f"CACHE MISS: {key} (API Call necessária)")


def log_external_api_call(api_name: str, endpoint: str):
    """Log de chamadas a APIs externas."""
    logger.info(f"External API Call → {api_name}: {endpoint}")
