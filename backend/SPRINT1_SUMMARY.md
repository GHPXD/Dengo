# ════════════════════════════════════════════════════════════════════════════
# SPRINT 1 - BACKEND ML CORE - CONCLUÍDA ✅
# ════════════════════════════════════════════════════════════════════════════
# Data: 2025-12-25
# Implementação: API de Predição com IA (Keras LSTM)
# ════════════════════════════════════════════════════════════════════════════

## 📦 ARTEFATOS CRIADOS

### 1. Schemas Pydantic (app/schemas/prediction.py)
✅ PredictionRequest - Validação de requests
✅ PredictionResponse - Resposta estruturada
✅ WeekPrediction - Predição semanal individual
✅ ModelMetadata - Metadados do modelo
✅ PredictionError - Erros formatados
✅ Enums: TrendType, ConfidenceLevel

**Características:**
- Validação rigorosa de geocode (7 dígitos, Paraná = 41*)
- Field validators com mensagens claras
- Examples em JSON Schema
- Tipagem forte com Generic Types

---

### 2. ML Service (app/services/ml_service.py)
✅ Singleton pattern thread-safe
✅ Lazy loading do modelo Keras
✅ Cache em memória (modelo + scaler)
✅ Validação de input shape (1, 4, 9)
✅ Normalização/desnormalização automática
✅ Cálculo de confiança baseado em CV
✅ Predição single-step e multi-step (recursivo)

**Características de Segurança:**
- Double-check locking pattern
- Validação de features obrigatórias
- Error handling granular (InsufficientDataError, PredictionError)
- Logging detalhado com Loguru
- Dependency injection para FastAPI

**Performance:**
- Modelo carregado apenas 1 vez (singleton)
- Compile=False para inferência (mais rápido)
- Input preparado sem cópias desnecessárias

---

### 3. Data Service (app/services/data_service.py)
✅ Estratégia híbrida (API → CSV → Cache)
✅ Fallback automático resiliente
✅ Cache Redis opcional (graceful degradation)
✅ LRU cache para dataset CSV
✅ Parsing de timestamp Unix (ms)

**Características:**
- Retry logic na API InfoDengue
- Timeout configurável (15s)
- Cache TTL de 1 hora
- Validação de colunas obrigatórias
- Error handling específico (GeocodeNotFoundError, DataNotFoundError)

**Fluxo de Dados:**
```
Request
  ↓
Redis Cache? ────→ HIT: Retorna
  ↓ MISS
API InfoDengue? ──→ OK: Cacheia + Retorna
  ↓ FAIL
CSV Local ────────→ Sempre funciona
```

---

### 4. Endpoint de Predição (app/api/v1/endpoints/predictions.py)
✅ POST /api/v1/predictions/predict
✅ GET /api/v1/predictions/health

**Features:**
- OpenAPI documentation completa
- Validação automática (Pydantic)
- Error handling com HTTP status corretos:
  - 404: Geocode não encontrado
  - 422: Dados insuficientes  
  - 500: Erro interno
- Cálculo de tendência (ascending/descending/stable)
- Intervalo de confiança (95%)
- Confiança ajustada por horizonte temporal
- Logging estruturado

**Response exemplo:**
```json
{
  "city": "Curitiba",
  "geocode": "4106902",
  "predictions": [
    {
      "week_number": 1,
      "date": "2025-01-05",
      "predicted_cases": 245.8,
      "confidence": "high",
      "lower_bound": 220.0,
      "upper_bound": 270.0
    }
  ],
  "trend": "descending",
  "trend_percentage": -12.5,
  "model_metadata": {
    "model_name": "DengoAI v1.0",
    "accuracy": 0.91,
    "mae": 27.0
  }
}
```

---

## 🔒 SEGURANÇA IMPLEMENTADA

1. **Validação de Entrada:**
   - Geocode: Apenas 7 dígitos, Paraná (41*)
   - Weeks ahead: 1-4 (previne abuse)
   - Type hints em todas as funções

2. **Rate Limiting:**
   - Herdado do main.py (20 req/min por IP)
   
3. **Error Handling:**
   - Exceptions customizadas
   - Logs detalhados (não expostos ao client)
   - Mensagens de erro amigáveis

4. **Thread Safety:**
   - Singleton com locks
   - Double-check locking
   - Sem race conditions

---

## 📊 BOAS PRÁTICAS APLICADAS

✅ **Clean Code:**
- Docstrings completas (Google style)
- Type hints obrigatórios
- Constantes em UPPER_CASE
- Funções puras quando possível

✅ **SOLID:**
- Single Responsibility (cada classe 1 propósito)
- Dependency Injection (FastAPI Depends)
- Interface Segregation (schemas específicos)

✅ **DRY:**
- Funções helper reutilizáveis
- LRU cache para dataset
- Singleton para serviços

✅ **Performance:**
- Lazy loading
- Cache em múltiplos níveis
- Processamento assíncrono

✅ **Observability:**
- Logging estruturado
- Timestamps em todas as operações
- Health check endpoint

---

## 📝 DEPENDÊNCIAS ADICIONADAS

```txt
tensorflow>=2.15.0
keras>=3.0.0
joblib>=1.4.0
numpy>=1.26.0,<2.0.0  # TensorFlow limitation
```

---

## 🚀 PRÓXIMOS PASSOS

### Sprint 2 - Testes e Validação
1. Instalar dependências: `pip install -r requirements.txt`
2. Testar carregamento do modelo
3. Validar predições com Postman
4. Corrigir mapeamento geocode → cidade (TODO no data_service)
5. Implementar testes unitários

### Sprint 3 - Frontend Flutter
1. Repository layer (predictions_repository.dart)
2. Use case (get_predictions.dart)
3. Widget de predição (prediction_screen.dart)
4. Gráfico de tendência (fl_chart)

### Sprint 4 - Deploy
1. Docker build
2. Cloud Run deployment
3. Monitoramento

---

## ⚠️ ISSUES CONHECIDOS

1. **Mapeamento Geocode → Cidade:**
   - data_service.py linha ~XXX: Hardcoded "Curitiba"
   - Solução: Criar tabela de lookup ou parser do CSV

2. **Predições Multi-Step:**
   - Usam abordagem recursiva (menos precisa)
   - Modelo foi treinado para single-step
   - Considerar retreinar com multi-output

3. **Redis Opcional:**
   - Sistema funciona sem Redis (fallback)
   - Performance degradada sem cache

---

## 📞 CONTATO

**Author:** Dengo Team  
**Date:** 2025-12-25  
**Version:** 1.0.0-sprint1
