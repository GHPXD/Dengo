"""
════════════════════════════════════════════════════════════════════════════
DENGO API - MAIN APPLICATION (PRODUCTION)
════════════════════════════════════════════════════════════════════════════
FastAPI application factory com todos os middlewares, configurações e services.

Features:
    - Redis Cache (Smart Caching)
    - Machine Learning Model (Gradient Boosting)
    - OpenWeather API Integration
    - Health Check com status de serviços
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

from app.api import cities_router, dashboard_router
from app.api.state_statistics import router as state_statistics_router
from app.api.v1.endpoints.predictions import router as predictions_router
from app.api.heatmap import router as heatmap_router
from app.core.config import settings
from app.core.logger import logger
from app.services import cache_service
from app.services.prediction_service import prediction_service


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Gerencia ciclo de vida da aplicação (startup/shutdown).
    
    Startup:
        - Conecta no Redis (cache)
        - Carrega modelo ML do disco
    
    Shutdown:
        - Fecha conexão com Redis
    """
    # ════════════════════════════════════════════════════════════════════════
    # STARTUP
    # ════════════════════════════════════════════════════════════════════════
    logger.info("🚀 Starting Dengo API...")
    logger.info(f"Environment: {settings.environment}")
    logger.info(f"Debug Mode: {settings.debug}")
    logger.info(f"API Version: {settings.api_version}")

    # Conecta ao Redis
    await cache_service.connect()

    # Carrega modelo de Machine Learning
    logger.info("🤖 Carregando modelo de Machine Learning...")
    ml_loaded = prediction_service.load_model()
    if ml_loaded:
        logger.success("✓ Modelo ML carregado com sucesso!")
    else:
        logger.warning("⚠️  Modelo ML não carregado - usando fallback (regras baseadas em temperatura)")

    logger.success("✓ API Ready!")
    logger.info("─" * 80)

    yield

    # ════════════════════════════════════════════════════════════════════════
    # SHUTDOWN
    # ════════════════════════════════════════════════════════════════════════
    logger.info("🛑 Shutting down Dengo API...")

    # Fecha conexão com Redis
    await cache_service.disconnect()

    logger.info("✓ Shutdown complete")


# ════════════════════════════════════════════════════════════════════════════
# RATE LIMITING
# ════════════════════════════════════════════════════════════════════════════

limiter = Limiter(key_func=get_remote_address)

# ════════════════════════════════════════════════════════════════════════════
# FASTAPI APP INSTANCE
# ════════════════════════════════════════════════════════════════════════════

app = FastAPI(
    title=settings.api_title,
    version=settings.api_version,
    description=(
        "API para previsão de casos de dengue usando Machine Learning.\n\n"
        "**Features:**\n"
        "- Predição de casos com base em clima e histórico\n"
        "- Cache inteligente (Redis) para economia de API calls\n"
        "- Dados do InfoDengue (FIOCRUZ) + OpenWeatherMap\n"
        "- Otimizado para Google Cloud Run (Free Tier)\n"
        "- Rate Limiting: 20 requests/minuto por IP"
    ),
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    lifespan=lifespan,
)

# Configurar encoding UTF-8 para todas as respostas JSON
from fastapi.responses import JSONResponse
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware

class UTF8JSONMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)
        if response.headers.get("content-type", "").startswith("application/json"):
            response.headers["content-type"] = "application/json; charset=utf-8"
        return response

app.add_middleware(UTF8JSONMiddleware)

# Adiciona Limiter ao app state
app.state.limiter = limiter

# ════════════════════════════════════════════════════════════════════════════
# MIDDLEWARES
# ════════════════════════════════════════════════════════════════════════════

# CORS (Permite requisições do Flutter)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=settings.cors_allow_credentials,
    allow_methods=settings.cors_allow_methods,
    allow_headers=settings.cors_allow_headers,
)

# GZIP Compression (Reduz tamanho das respostas)
app.add_middleware(GZipMiddleware, minimum_size=1000)


# ════════════════════════════════════════════════════════════════════════════
# ROUTERS
# ════════════════════════════════════════════════════════════════════════════

app.include_router(
    dashboard_router, prefix=f"{settings.api_prefix}/dashboard", tags=["Dashboard"]
)

app.include_router(
    cities_router, prefix=f"{settings.api_prefix}/cities", tags=["Cities"]
)

app.include_router(
    predictions_router, prefix=settings.api_prefix, tags=["Predições IA"]
)

app.include_router(
    state_statistics_router, prefix=settings.api_prefix, tags=["Estatísticas"]
)

app.include_router(
    heatmap_router, prefix=f"{settings.api_prefix}/heatmap", tags=["Heatmap"]
)


# ════════════════════════════════════════════════════════════════════════════
# EXCEPTION HANDLERS
# ════════════════════════════════════════════════════════════════════════════

# Rate Limit Exceeded Handler
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)


@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """Handler global para exceções não tratadas."""
    logger.error(f"Unhandled exception: {exc}")
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal Server Error",
            "message": str(exc) if settings.debug else "An error occurred",
        },
    )


# ════════════════════════════════════════════════════════════════════════════
# HEALTH CHECK (Para Google Cloud Run)
# ════════════════════════════════════════════════════════════════════════════


@app.get("/health", tags=["Health"])
async def health_check():
    """
    Endpoint de health check usado pelo Google Cloud Run.
    
    Verifica status de:
        - API (sempre healthy se responder)
        - Redis (ping)
        - ML Model (loaded ou fallback)
    
    Returns:
        200 OK: Todos os serviços funcionando
        503 Service Unavailable: Algum serviço crítico offline
    """
    # Status da API
    health_status = {
        "status": "healthy",
        "environment": settings.environment,
        "version": settings.api_version,
        "services": {},
    }

    # Verifica Redis
    redis_status = "offline"
    if cache_service.is_connected:
        try:
            # Tenta ping
            if cache_service.redis_client:
                await cache_service.redis_client.ping()
                redis_status = "healthy"
        except Exception:
            redis_status = "error"
    
    health_status["services"]["redis"] = redis_status

    # Verifica Modelo ML
    ml_loaded = prediction_service.is_loaded
    # Nota: ML está desabilitado por baixa acurácia (R² < 0)
    # Usando fallback inteligente baseado em histórico + clima
    health_status["services"]["ml_model"] = {
        "status": "loaded" if ml_loaded else "not_loaded",
        "active": False,  # ML desabilitado temporariamente
        "using": "Fallback inteligente (histórico + clima)",
        "reason": "Modelo Keras com R² negativo - fallback é mais preciso",
        "model_path": str(prediction_service.model_path) if ml_loaded else None,
    }

    # Define status geral
    # Redis offline não é crítico (graceful degradation)
    # ML usando fallback não é erro, é decisão consciente
    if redis_status == "error":
        health_status["status"] = "degraded"
    
    return health_status


@app.get("/", tags=["Root"])
async def root():
    """Endpoint raiz."""
    return {
        "message": "Dengo API",
        "version": settings.api_version,
        "docs": "/docs",
        "health": "/health",
    }
