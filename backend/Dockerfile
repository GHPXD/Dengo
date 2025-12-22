# ════════════════════════════════════════════════════════════════════════════
# DENGUE PREDICT API - DOCKERFILE
# Multi-stage build otimizado para Google Cloud Run
# Imagem final: ~150MB (vs ~1GB sem otimização)
# ════════════════════════════════════════════════════════════════════════════

# ────────────────────────────────────────────────────────────────────────────
# STAGE 1: BUILDER (Compilação de dependências)
# ────────────────────────────────────────────────────────────────────────────
FROM python:3.11-slim as builder

# Variáveis de ambiente para otimização
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Instala dependências do sistema necessárias para compilação
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Cria diretório de trabalho
WORKDIR /build

# Copia apenas requirements.txt primeiro (cache de camadas Docker)
COPY requirements.txt .

# Instala dependências Python em /install
RUN pip install --prefix=/install --no-warn-script-location -r requirements.txt

# ────────────────────────────────────────────────────────────────────────────
# STAGE 2: RUNTIME (Imagem final leve)
# ────────────────────────────────────────────────────────────────────────────
FROM python:3.11-slim

# Variáveis de ambiente
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/install/bin:$PATH" \
    PYTHONPATH="/app" \
    PORT=8080

# Instala apenas dependências runtime (PostgreSQL client)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Cria usuário não-root para segurança
RUN useradd -m -u 1000 appuser && \
    mkdir -p /app && \
    chown -R appuser:appuser /app

# Copia dependências instaladas do stage builder
COPY --from=builder /install /install

# Define diretório de trabalho
WORKDIR /app

# Copia código da aplicação
COPY --chown=appuser:appuser ./app ./app
COPY --chown=appuser:appuser ./app/ml ./app/ml

# Muda para usuário não-root
USER appuser

# Healthcheck (Cloud Run usa isso para monitorar a saúde da API)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${PORT}/health || exit 1

# Expõe porta (Cloud Run usa PORT via variável de ambiente)
EXPOSE 8080

# Comando de inicialização otimizado para Cloud Run
# - workers: 1 (Cloud Run escala horizontalmente via containers)
# - worker-class: uvicorn.workers.UvicornWorker (async)
# - timeout: 300s (5min para operações pesadas de ML)
# - graceful-timeout: 30s
# - keep-alive: 5s
CMD exec uvicorn app.main:app \
    --host 0.0.0.0 \
    --port ${PORT} \
    --workers 1 \
    --loop uvloop \
    --log-level info \
    --no-access-log \
    --proxy-headers \
    --forwarded-allow-ips='*'

# ────────────────────────────────────────────────────────────────────────────
# BUILD & RUN COMMANDS
# ────────────────────────────────────────────────────────────────────────────
# 
# Local (Desenvolvimento):
#   docker build -t dengue-predict-api .
#   docker run -p 8080:8080 --env-file .env dengue-predict-api
#
# Google Cloud Run (Produção):
#   gcloud builds submit --tag gcr.io/PROJECT_ID/dengue-predict-api
#   gcloud run deploy dengue-predict-api \
#     --image gcr.io/PROJECT_ID/dengue-predict-api \
#     --platform managed \
#     --region us-central1 \
#     --allow-unauthenticated \
#     --memory 512Mi \
#     --cpu 1 \
#     --timeout 300 \
#     --max-instances 10 \
#     --min-instances 0 \
#     --concurrency 80
# ────────────────────────────────────────────────────────────────────────────
