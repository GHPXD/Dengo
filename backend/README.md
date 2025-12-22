# 🦟 Dengo API - Backend Python

API REST para previsão de casos de dengue usando Machine Learning.

## 📋 O que é?

Backend FastAPI que fornece dados de dengue para o app Flutter **Dengo**. Usa Smart Caching (Redis) para reduzir custos de APIs externas.

**Stack:** FastAPI + Redis + Supabase + Google Cloud Run

---

## 🏗️ Arquitetura

```
Flutter App → FastAPI → [Redis Cache] → InfoDengue API + OpenWeather API
                     ↓
                  Supabase (PostgreSQL)
```

**Smart Caching:** Dados em cache por 24h = custo zero em APIs externas.

---

## 📂 Estrutura

```
backend/
├── app/
│   ├── main.py              # FastAPI app
│   ├── core/                # Config + Logs
│   ├── api/                 # Endpoints
│   └── schemas/             # Pydantic models
├── Dockerfile
├── requirements.txt
└── .env                     # Configurações (não commitar!)
```

---

## 🚀 Como Rodar

### 1. Instalar dependências
```bash
pip install -r requirements.txt
cd backend
```

### 2. Crie ambiente virtual
```bash
python -m venv venv

# Windows
venv\Scripts\activate

# Linux/Mac
source venv/bin/activate
```

### 3. Instale dependências
```bash
pip install -r requirements.txt
```

### 4. Configure variáveis de ambiente
```bash
cp .env.example .env
# Edite .env com suas credenciais
```

### 5. Execute a API
```bash
uvicorn app.main:app --reload --port 8080
```

**Acesse:**
- API: http://localhost:8080
- Docs (Swagger): http://localhost:8080/docs
- ReDoc: http://localhost:8080/redoc

---

## 🐳 Docker (Local)

### Build
```bash
docker build -t dengue-predict-api .
```

```

### 2. Configurar variáveis de ambiente
Edite o arquivo `.env` com suas credenciais reais (já configurado)

### 3. Rodar servidor
```bash
uvicorn app.main:app --reload --port 8000
```

Acesse: `http://localhost:8000/docs`

---

## 🐋 Docker (Opcional)

```bash
# Build
docker build -t dengo-api .

# Run
docker run -p 8000:8000 --env-file .env dengo-api
```

---

## 📡 Endpoints

### `GET /api/dashboard?city_id={ibge_code}`
Retorna dados completos para o dashboard do Flutter.

**Exemplo:**
```
GET /api/dashboard?city_id=3550308
```

**Response:**
```json
{
  "cidade": {
    "ibge_codigo": "3550308",
    "nome": "São Paulo",
    "populacao": 12252023
  },
  "dados_historicos": [...],
  "predicao": {
    "casos_estimados": 1250,
    "nivel_risco": "alto",
    "tendencia": "subindo"
  }
}
```

### `GET /health`
Health check para Cloud Run.

---

## 🚀 Deploy (Google Cloud Run)

```bash
# Build e deploy
gcloud run deploy dengo-api \
  --source . \
  --region us-central1 \
  --allow-unauthenticated
```

---

## 📚 Mais Informações

- Detalhes técnicos: Ver `ARCHITECTURE.md`
- API contract: Ver `ARQUITETURA_API_BACKEND.md`
- Análise de código: Ver `ANALISE_REFATORACAO.md`

  },
  "dados_historicos": [...],
  "predicao": {
    "casos_previstos": 320,
    "nivel_risco": "high",
    "confianca": 0.87,
    "data_predicao": "2024-12-09",
    "fatores_risco": ["Alta umidade", "Temperatura ideal"]
  }
}
```

### `GET /api/v1/history?city_id=3550308`
Retorna histórico de casos.

### `GET /api/v1/cities`
Lista cidades disponíveis.

---

## 🧪 Testes

```bash
pytest tests/ -v
```

---

## 📝 TODO (Próximas Tarefas)

- [ ] Implementar `prediction_service.py` (Smart Caching)
