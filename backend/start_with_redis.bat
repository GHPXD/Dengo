@echo off
echo ====================================
echo  Dengo Backend - Startup Script
echo ====================================
echo.

REM Verifica se Redis Docker esta rodando
echo [1/3] Verificando Redis...
docker ps --filter "name=dengo-redis" --format "{{.Status}}" | findstr "Up" >nul
if errorlevel 1 (
    echo Redis nao encontrado. Iniciando container...
    docker start dengo-redis >nul 2>&1
    if errorlevel 1 (
        echo Criando novo container Redis...
        docker run --name dengo-redis -p 6379:6379 -v redis-data:/data --restart unless-stopped -d redis:7-alpine
    )
    timeout /t 2 /nobreak >nul
) else (
    echo Redis OK - Container rodando
)

echo.
echo [2/3] Navegando para backend...
cd /d C:\Projects\Dengo\backend

echo.
echo [3/3] Iniciando servidor FastAPI...
echo Backend: http://127.0.0.1:8000
echo Docs: http://127.0.0.1:8000/docs
echo.
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
