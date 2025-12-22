# ============================================================================
# SCRIPT DE EXECUCAO DO PIPELINE DE TREINAMENTO
# ============================================================================
# 
# Este script automatiza a instalacao de dependencias e execucao do pipeline
# de treinamento do modelo de Machine Learning do Dengo.
#
# Uso:
#   .\run_training.ps1
# ============================================================================

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "          DENGO - Pipeline de Treinamento de Machine Learning          " -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

# ----------------------------------------------------------------------------
# 1. Verificar ambiente virtual
# ----------------------------------------------------------------------------

Write-Host "[1/5] Verificando ambiente virtual..." -ForegroundColor Yellow

if (-Not (Test-Path "venv\Scripts\Activate.ps1")) {
    Write-Host "ERRO: Ambiente virtual nao encontrado!" -ForegroundColor Red
    Write-Host "Execute primeiro: python -m venv venv" -ForegroundColor Red
    exit 1
}

Write-Host "OK: Ambiente virtual encontrado" -ForegroundColor Green

# ----------------------------------------------------------------------------
# 2. Ativar ambiente virtual
# ----------------------------------------------------------------------------

Write-Host "[2/5] Ativando ambiente virtual..." -ForegroundColor Yellow
& .\venv\Scripts\Activate.ps1

# ----------------------------------------------------------------------------
# 3. Verificar/Instalar dependencias
# ----------------------------------------------------------------------------

Write-Host "[3/5] Verificando dependencias..." -ForegroundColor Yellow

$dependencies = @(
    "pandas==2.0.3",
    "numpy==1.24.4",
    "scikit-learn==1.3.2",
    "xgboost==2.0.3",
    "joblib==1.3.2",
    "requests==2.31.0"
)

Write-Host "Instalando pacotes necessarios..." -ForegroundColor Cyan

foreach ($package in $dependencies) {
    Write-Host "  -> $package" -ForegroundColor Gray
}

pip install --quiet $dependencies

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha ao instalar dependencias!" -ForegroundColor Red
    exit 1
}

Write-Host "OK: Dependencias instaladas" -ForegroundColor Green

# ----------------------------------------------------------------------------
# 4. Executar pipeline de treinamento
# ----------------------------------------------------------------------------

Write-Host ""
Write-Host "[4/5] Iniciando pipeline de treinamento..." -ForegroundColor Yellow
Write-Host "------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host ""

python etl_training_pipeline.py

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERRO: Pipeline falhou! Verifique os erros acima." -ForegroundColor Red
    exit 1
}

# ----------------------------------------------------------------------------
# 5. Verificar saida
# ----------------------------------------------------------------------------

Write-Host ""
Write-Host "[5/5] Verificando arquivos gerados..." -ForegroundColor Yellow

if (Test-Path "models\dengo_model.joblib") {
    $sizeKB = [math]::Round((Get-Item "models\dengo_model.joblib").Length / 1KB, 2)
    Write-Host "OK: Modelo gerado -> models\dengo_model.joblib ($sizeKB KB)" -ForegroundColor Green
} else {
    Write-Host "AVISO: Modelo nao encontrado!" -ForegroundColor Yellow
}

if (Test-Path "models\model_metadata.json") {
    Write-Host "OK: Metadata gerado -> models\model_metadata.json" -ForegroundColor Green
    
    # Exibe metadata
    Write-Host ""
    Write-Host "INFORMACOES DO MODELO:" -ForegroundColor Cyan
    $metadata = Get-Content "models\model_metadata.json" | ConvertFrom-Json
    Write-Host "  Versao: $($metadata.model_version)" -ForegroundColor White
    Write-Host "  Treinado em: $($metadata.trained_at)" -ForegroundColor White
    Write-Host "  MAE: $($metadata.metrics.mae) casos" -ForegroundColor White
    Write-Host "  R2: $($metadata.metrics.r2)" -ForegroundColor White
} else {
    Write-Host "AVISO: Metadata nao encontrado!" -ForegroundColor Yellow
}

# ----------------------------------------------------------------------------
# 6. Finalizacao
# ----------------------------------------------------------------------------

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Green
Write-Host "                  TREINAMENTO CONCLUIDO COM SUCESSO!                  " -ForegroundColor Green
Write-Host "========================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Arquivos gerados em: .\models\" -ForegroundColor Cyan
Write-Host "O modelo esta pronto para uso na API!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Proximo passo: Reiniciar o servidor FastAPI para carregar o novo modelo" -ForegroundColor Yellow
Write-Host ""
