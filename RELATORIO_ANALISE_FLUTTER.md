# 📋 RELATÓRIO DE ANÁLISE - FLUTTER FRONTEND
**Data:** 2025-12-25  
**Objetivo:** Avaliar código atual antes de implementar integração com API de Predições IA

---

## 🔍 1. ANÁLISE GERAL

### ✅ Pontos Positivos
- **Clean Architecture**: Código bem estruturado (Domain/Data/Presentation)
- **Riverpod**: State management moderno e reativo
- **Dio + ApiClient**: HTTP client configurado e funcional
- **NetworkInfo**: Verificação de conectividade implementada
- **Error Handling**: Either<Failure, Success> com Dartz

### ⚠️ Problemas Identificados

#### **CRÍTICO - Dados Mock/Hardcoded:**

1. **Dashboard Mock Completo** (imagem fornecida mostra)
   - Tela "Previsões - Curitiba" com dados fictícios
   - Gráfico de tendência não vem da API real
   - Alertas de surto (Londrina +85%, Maringá +45%) são mock
   - Botões "7 Dias / 30 Dias / 90 Dias" não integrados

2. **API Endpoint Desatualizado**
   ```dart
   // dashboard_remote_datasource.dart (linha 48)
   final response = await apiClient.dio.get(
     '/dashboard',  // ❌ ENDPOINT ANTIGO
     queryParameters: {'city_id': cityId},
   );
   ```
   - **Problema**: Backend atual não tem `/dashboard`
   - **Temos agora**: `/predictions/predict` (POST)

3. **Schema de Dados Incompatível**
   ```dart
   // prediction_data_model.dart (linhas 11-17)
   /// JSON REAL retornado pela API:
   /// ```json
   /// {
   ///   "casos_estimados": 30,      // ❌ SCHEMA ANTIGO
   ///   "nivel_risco": "baixo",
   ///   "tendencia": "estavel",
   ///   "confianca": 0.5
   /// }
   ```
   
   **Schema NOVO da API** (implementado Sprint 1):
   ```json
   {
     "city": "Curitiba",
     "geocode": "4106902",
     "state": "PR",
     "predictions": [
       {
         "week_number": 50,
         "date": "2025-12-14",
         "predicted_cases": 28.4,
         "confidence": "high",          // ✅ NOVO: enum (high/medium/low)
         "lower_bound": 27.6,           // ✅ NOVO: intervalo de confiança
         "upper_bound": 29.2
       }
     ],
     "trend": "stable",                  // ✅ NOVO: enum (ascending/descending/stable)
     "trend_percentage": 0.0,
     "generated_at": "2025-12-25T17:30:00",
     "model_metadata": {
       "model_name": "DengoAI v1.0",
       "model_type": "LSTM Multivariado",
       "accuracy": 0.91,
       "mae": 27.0
     }
   }
   ```

4. **DashboardData Entity Incompatível**
   - Estrutura atual não suporta múltiplas predições semanais
   - Falta `lower_bound`/`upper_bound` (intervalo de confiança)
   - Falta `model_metadata` (informações do modelo)
   - Campo `trend` usa string em vez de enum

5. **Dados Históricos Mock**
   ```dart
   // dashboard_data_model.dart (comentário)
   /// "dados_historicos": [...]  // ❌ NÃO EXISTE NA API NOVA
   ```
   - API de predições não retorna dados históricos
   - Precisamos decidir: buscar de outro endpoint ou remover?

---

## 🎯 2. MAPEAMENTO: TELA vs API

### Tela "Previsões - Curitiba" (da imagem)

| **Elemento da UI** | **Campo da API** | **Status** |
|-------------------|------------------|------------|
| "Previsões - Curitiba" (título) | `city` | ✅ Disponível |
| "Powered by Machine Learning" | `model_metadata.model_name` | ✅ Disponível |
| Botões "7 Dias / 30 Dias / 90 Dias" | `weeks_ahead` (request) | ⚠️ API suporta 1-4 semanas |
| Gráfico de Tendência | `predictions[]` + `trend` | ✅ Disponível |
| "Casos Reais" (linha azul) | ❌ Não disponível | ⚠️ Precisa outro endpoint |
| "Previsão IA" (linha tracejada) | `predictions[].predicted_cases` | ✅ Disponível |
| Alerta "A IA prevê aumento de 23%" | `trend_percentage` | ✅ Disponível |
| **Alertas de Surto Iminente** | | |
| "Londrina +85%" | ❌ Mock | ⚠️ Precisa endpoint `/predictions/predict` para outras cidades |
| "Maringá +45%" | ❌ Mock | ⚠️ Precisa endpoint `/predictions/predict` para outras cidades |
| Indicador "IA" (badge) | `model_metadata` | ✅ Disponível |

---

## 📊 3. ESTRUTURA ATUAL vs NECESSÁRIA

### **Atual:**
```
lib/features/dashboard/
├── data/
│   ├── models/
│   │   ├── dashboard_data_model.dart       ❌ Schema antigo
│   │   ├── prediction_data_model.dart      ❌ Incompatível
│   │   └── historical_data_model.dart      ❌ Não usado
│   ├── datasources/
│   │   └── dashboard_remote_datasource.dart ❌ Endpoint /dashboard
│   └── repositories/
│       └── dashboard_repository_impl.dart   ✅ Estrutura OK
├── domain/
│   ├── entities/
│   │   ├── dashboard_data.dart              ❌ Incompatível
│   │   └── prediction_data.dart             ❌ Incompatível
│   └── repositories/
│       └── dashboard_repository.dart        ✅ Interface OK
└── presentation/
    ├── providers/
    │   └── dashboard_data_provider.dart     ✅ Lógica OK
    └── screens/
        └── dashboard_screen.dart            ⚠️ UI usa dados mock
```

### **Necessário:**
```
lib/features/predictions/              // ✅ NOVA FEATURE
├── data/
│   ├── models/
│   │   ├── prediction_request_model.dart    // ✅ CRIAR
│   │   ├── prediction_response_model.dart   // ✅ CRIAR
│   │   ├── week_prediction_model.dart       // ✅ CRIAR
│   │   └── model_metadata_model.dart        // ✅ CRIAR
│   ├── datasources/
│   │   └── predictions_remote_datasource.dart // ✅ CRIAR
│   └── repositories/
│       └── predictions_repository_impl.dart   // ✅ CRIAR
├── domain/
│   ├── entities/
│   │   ├── prediction_response.dart         // ✅ CRIAR
│   │   ├── week_prediction.dart             // ✅ CRIAR
│   │   └── model_metadata.dart              // ✅ CRIAR
│   ├── repositories/
│   │   └── predictions_repository.dart      // ✅ CRIAR
│   └── usecases/
│       ├── get_predictions.dart             // ✅ CRIAR
│       └── get_multi_city_predictions.dart  // ✅ CRIAR (para alertas)
└── presentation/
    ├── providers/
    │   └── predictions_provider.dart        // ✅ CRIAR
    ├── widgets/
    │   ├── predictions_chart.dart           // ✅ CRIAR
    │   ├── trend_indicator.dart             // ✅ CRIAR
    │   ├── confidence_badge.dart            // ✅ CRIAR
    │   └── outbreak_alert_card.dart         // ✅ CRIAR
    └── screens/
        └── predictions_screen.dart          // ✅ CRIAR (substituir dashboard_screen?)
```

---

## 🚨 4. PROBLEMAS ESPECÍFICOS IDENTIFICADOS

### **A. Dashboard Screen (linha 215+)**
```dart
final newCases = dashboardData.currentWeek.cases;  // ❌ currentWeek não existe mais
final trend = dashboardData.prediction.trend;      // ❌ prediction é objeto diferente
```

### **B. Prediction Data Model (linha 11)**
```dart
// Comentário desatualizado
/// JSON REAL retornado pela API:
/// {
///   "casos_estimados": 30,  // ❌ Campo não existe
```

### **C. City Detail Screen (linha 250+)**
```dart
final population = dashboardData.cityPopulation;  // ⚠️ Pode não estar disponível
final cases = dashboardData.currentWeek.cases;    // ❌ currentWeek removido
```

### **D. Dashboard Repository (linha 32)**
```dart
final model = await remoteDataSource.getDashboardData(cityId);
// ❌ getDashboardData não existe mais, precisa ser getPredictions
```

---

## 📦 5. DEPENDÊNCIAS FLUTTER ATUAIS

### ✅ Já Instaladas (pubspec.yaml verificado anteriormente)
- `dio: ^5.7.0` - HTTP client
- `flutter_riverpod: ^2.6.1` - State management
- `freezed: ^2.5.7` - Immutable classes
- `dartz: ^0.10.1` - Functional programming (Either)
- `equatable: ^2.0.7` - Value comparison
- `fl_chart: ^0.70.2` - **✅ GRÁFICOS (já instalado!)**

### ⚠️ Podem ser Necessárias
- `intl: ^0.20.2` - Formatação de datas (para semanas epidemiológicas)
- `shimmer: ^3.0.0` - Skeleton loading states (UX)

---

## 🎯 6. PLAN DE IMPLEMENTAÇÃO

### **Sprint 2A - Backend Preparation (0.5h)**
1. ✅ Criar endpoint `/dashboard` (compatibility layer)
   - Aceita `city_id` como antes
   - Internamente chama `/predictions/predict`
   - Retorna schema compatível com frontend antigo
   - **OU** migrar completamente para novo schema

### **Sprint 2B - Flutter Core (3-4h)**
1. Criar feature `predictions/`
2. Implementar models (Freezed + JSON serialization)
3. Criar repository + datasource
4. Implementar usecases
5. Criar providers (Riverpod)

### **Sprint 2C - Flutter UI (3-4h)**
1. Widget de gráfico de tendência (fl_chart)
2. Card de predição semanal
3. Badge de confiança
4. Alertas de surto (múltiplas cidades)
5. Tela de predições completa

### **Sprint 2D - Integration (2h)**
1. Conectar dashboard_screen com predictions_provider
2. Remover dados mock
3. Error handling + loading states
4. Testes (unit + widget)

### **Sprint 2E - Polish (1-2h)**
1. Animações de transição
2. Pull-to-refresh
3. Skeleton loaders
4. Documentação

---

## 🔧 7. DECISÕES ARQUITETURAIS

### **Opção A: Criar Nova Feature `predictions/` (RECOMENDADO)**
**Vantagens:**
- ✅ Clean separation of concerns
- ✅ Reutilizável em outras telas
- ✅ Não quebra dashboard existente
- ✅ Testável isoladamente

**Desvantagens:**
- ⚠️ Mais código inicial
- ⚠️ Dashboard + Predictions podem ter overlap

### **Opção B: Refatorar Dashboard Existente**
**Vantagens:**
- ✅ Menos código novo
- ✅ Mantém estrutura familiar

**Desvantagens:**
- ❌ Quebraria tela existente temporariamente
- ❌ Mistura conceitos (dashboard ≠ predictions)
- ❌ Mais difícil de testar

### **✅ RECOMENDAÇÃO: Opção A**
- Criar `lib/features/predictions/`
- Dashboard fica como "overview geral"
- Predictions fica como "análise detalhada IA"

---

## 📝 8. CHECKLIST PRÉ-IMPLEMENTAÇÃO

### Backend (FastAPI)
- [ ] **Decidir**: Criar endpoint `/dashboard` compatível **OU** frontend migra 100%?
- [ ] Se criar `/dashboard`: Mapear `PredictionResponse` → `DashboardDataModel` (antigo)
- [ ] Se migrar: Documentar breaking changes no README

### Frontend (Flutter)
- [x] Analisar código atual ✅
- [ ] Definir arquitetura final (Opção A vs B)
- [ ] Criar branch `feature/predictions-integration`
- [ ] Rodar `flutter pub get` para garantir deps
- [ ] Rodar `flutter analyze` para ver warnings atuais
- [ ] Backup da tela dashboard atual (screenshot)

### Dados
- [ ] Definir fonte de "Casos Reais" (linha azul do gráfico)
  - **Opção 1**: InfoDengue API (histórico)
  - **Opção 2**: CSV local (DATASET_PARA_IA.csv)
  - **Opção 3**: Remover e mostrar apenas predições
- [ ] Definir como buscar alertas de outras cidades
  - **Opção 1**: Loop de requests (1 por cidade)
  - **Opção 2**: Backend cria endpoint `/predictions/batch`
  - **Opção 3**: Frontend cacheia últimas predições

---

## 🎨 9. MOCKUP vs REALIDADE

### **Mockup Atual (imagem fornecida)**
```
┌─────────────────────────────────────────┐
│ 🔺 Previsões - Curitiba                │
│    Powered by Machine Learning          │
├─────────────────────────────────────────┤
│  [ 7 Dias ]  [30 Dias]  [ 90 Dias ]   │ ← Precisa ajustar (API = 1-4 semanas)
├─────────────────────────────────────────┤
│  Tendência de Casos - Curitiba    🏛️ IA │
│  Previsão dos próximos 30 dias         │
│                                         │
│  ● Casos Reais   ● Previsão IA         │ ← "Casos Reais" = ?
│  ╱╲                  ╱╲                 │
│ ╱  ╲                ╱  ╲╌╌╌╌╌           │
│╱    ╲──────────────╱    ╲               │
│                                         │
│  ⓘ A IA prevê aumento de 23% nos      │ ← ✅ trend_percentage
│     casos na próxima semana            │
├─────────────────────────────────────────┤
│ ⚠️ Alertas de Surto Iminente           │
│                                         │
│ 📈 Londrina           +85%      >      │ ← ❌ Mock
│    Previsão: 450 casos em 7 dias       │
│                                         │
│ 📈 Maringá            +45%      >      │ ← ❌ Mock
│    Previsão: 180 casos em 10 dias      │
└─────────────────────────────────────────┘
```

### **Dados Reais Disponíveis (API)**
```json
{
  "city": "Curitiba",
  "predictions": [
    {"week_number": 50, "predicted_cases": 28.4, "confidence": "high"},
    {"week_number": 51, "predicted_cases": 27.1, "confidence": "high"},
    {"week_number": 52, "predicted_cases": 25.8, "confidence": "high"},
    {"week_number": 1,  "predicted_cases": 24.2, "confidence": "medium"}
  ],
  "trend": "descending",        // ✅ "Tendência decrescente"
  "trend_percentage": -14.8,    // ✅ "-14.8% nos casos"
  "model_metadata": {
    "accuracy": 0.91,            // ✅ "91% de acurácia"
    "mae": 27.0                  // ✅ "Erro médio: 27 casos"
  }
}
```

---

## ⚡ 10. PRÓXIMOS PASSOS IMEDIATOS

### **Antes de Começar:**
1. ✅ Ler este relatório completo
2. ⬜ Decidir: Opção A (nova feature) vs Opção B (refactor)
3. ⬜ Decidir: Criar `/dashboard` no backend **OU** migrar frontend?
4. ⬜ Definir fonte de "Casos Reais" para o gráfico

### **Se Opção A (RECOMENDADO):**
```bash
# 1. Criar estrutura
mkdir -p lib/features/predictions/{data/{models,datasources,repositories},domain/{entities,repositories,usecases},presentation/{providers,widgets,screens}}

# 2. Gerar arquivos base
flutter pub run build_runner build --delete-conflicting-outputs

# 3. Iniciar implementação (ordem sugerida)
# - models (Freezed)
# - datasource (Dio)
# - repository (Either)
# - entities (Equatable)
# - usecases (business logic)
# - providers (Riverpod)
# - widgets (UI components)
# - screen (tela final)
```

---

## 📊 11. RESUMO EXECUTIVO

### **Estado Atual:**
- ❌ Frontend usa dados **100% mock/hardcoded**
- ❌ Schema de API **completamente incompatível**
- ❌ Endpoint `/dashboard` **não existe** no backend
- ✅ Arquitetura Flutter **bem estruturada** (Clean + Riverpod)
- ✅ Backend API de Predições **funcionando perfeitamente**

### **Trabalho Estimado:**
- **Backend**: 1-2h (criar endpoint compatibility layer)
- **Frontend Core**: 3-4h (models, repository, usecases)
- **Frontend UI**: 3-4h (widgets, tela, gráficos)
- **Integration**: 2h (conectar tudo, remover mocks)
- **Polish**: 1-2h (UX, loading states, error handling)
- **TOTAL**: **10-14 horas**

### **Risco de Quebra:**
- 🟢 **Baixo** se criar nova feature `predictions/`
- 🟡 **Médio** se refatorar dashboard existente
- 🔴 **Alto** se tentar "patch" rápido sem refactor

---

## ✅ RECOMENDAÇÃO FINAL

**Implementar Opção A: Nova Feature `predictions/`**

**Motivos:**
1. Backend já está pronto e testado ✅
2. Schema novo é superior (confidence intervals, metadata)
3. Isola mudanças (não quebra tela existente)
4. Permite iteração gradual
5. Reutilizável em outras telas futuras

**Próximo Passo:**
Aguardar sua decisão sobre:
- [ ] Criar `/dashboard` no backend (compatibilidade) **OU**
- [x] **✅ APROVADO**: Migrar frontend 100% para `/predictions/predict`
- [x] **✅ APROVADO**: Mostrar AMBOS (casos reais em verde + predições IA em azul)

---

## 📈 DECISÃO: GRÁFICO COM HISTÓRICO + PREDIÇÕES

### **Implementação Aprovada:**

Mostrar no gráfico:
- **Linha Verde (contínua)**: Casos reais históricos (últimas 8-12 semanas)
- **Linha Azul (contínua)**: Predições IA (próximas 1-4 semanas)
- **Transição suave**: Sem quebra visual entre histórico e predição

### **Backend - Opção A (RECOMENDADA):**

Estender `PredictionResponse` para incluir dados históricos:

```python
# backend/app/schemas/prediction.py
class HistoricalWeek(BaseModel):
    week_number: int
    date: DateType
    cases: int  # Casos reais confirmados

class PredictionResponse(BaseModel):
    city: str
    geocode: str
    state: str
    
    # ✅ NOVO - Dados históricos
    historical_data: List[HistoricalWeek] = Field(
        default=[],
        description="Últimas semanas com casos confirmados"
    )
    
    # ✅ Predições futuras (já existe)
    predictions: List[WeekPrediction]
    
    trend: TrendType
    trend_percentage: float
    generated_at: datetime
    model_metadata: ModelMetadata
```

**Modificar endpoint `/predictions/predict`:**
```python
# backend/app/api/v1/endpoints/predictions.py

@router.post("/predict")
async def predict_dengue_cases(...):
    # ... código existente ...
    
    # ✅ ADICIONAR: Buscar dados históricos
    historical_weeks = []
    for i in range(12, 0, -1):  # Últimas 12 semanas
        week_data = historical_data.iloc[-i] if len(historical_data) >= i else None
        if week_data is not None:
            historical_weeks.append(
                HistoricalWeek(
                    week_number=week_data['data_iniSE'].isocalendar()[1],
                    date=week_data['data_iniSE'].date(),
                    cases=int(week_data['casos_est'])
                )
            )
    
    response = PredictionResponse(
        city=city_name,
        geocode=geocode,
        state="PR",
        historical_data=historical_weeks,  # ✅ NOVO
        predictions=predictions,
        # ... resto igual ...
    )
```

**Vantagens:**
- ✅ 1 único request (mais rápido)
- ✅ Dados sincronizados (mesma fonte - CSV)
- ✅ Backend já tem acesso ao CSV
- ✅ Frontend não precisa lógica extra

### **Frontend - Gráfico fl_chart:**

```dart
// lib/features/predictions/presentation/widgets/predictions_chart.dart

LineChart(
  LineChartData(
    lineBarsData: [
      // Linha Verde - Casos Reais
      LineChartBarData(
        spots: historicalData.map((week) => 
          FlSpot(week.weekNumber.toDouble(), week.cases.toDouble())
        ).toList(),
        color: Colors.green,
        isCurved: true,
        dotData: FlDotData(show: true),
      ),
      
      // Linha Azul - Predições IA
      LineChartBarData(
        spots: predictions.map((pred) => 
          FlSpot(pred.weekNumber.toDouble(), pred.predictedCases)
        ).toList(),
        color: Colors.blue,
        isCurved: true,
        dotData: FlDotData(show: true),
        dashArray: [5, 5], // Linha tracejada
      ),
    ],
  ),
)
```

### **Alternativa - Opção B (se backend não quiser mudar):**

Frontend faz 2 requests:
```dart
// 1. Buscar dados históricos
final historical = await dataService.getHistoricalData(geocode, weeks: 12);

// 2. Buscar predições
final predictions = await predictionsRepository.getPredictions(
  geocode: geocode, 
  weeksAhead: 4
);

// 3. Combinar no gráfico
```

**Desvantagens:**
- ⚠️ 2 requests HTTP (mais lento)
- ⚠️ Precisa criar novo endpoint `/historical`
- ⚠️ Mais complexo no frontend

---

## ✅ PLANO ATUALIZADO

### **Backend (Sprint 2A - 1h):**
1. Adicionar `HistoricalWeek` model em `prediction.py`
2. Modificar `PredictionResponse` (adicionar `historical_data`)
3. No endpoint `/predict`, buscar últimas 12 semanas do CSV
4. Testar com Postman

### **Frontend (Sprint 2B - 4h):**
1. Criar `lib/features/predictions/`
2. Models com Freezed (`HistoricalWeek`, `PredictionResponse`)
3. Repository + DataSource
4. Provider (Riverpod)

### **Frontend UI (Sprint 2C - 3h):**
1. Widget `PredictionsChart` com fl_chart
   - Linha verde (histórico)
   - Linha azul tracejada (predições)
2. Legend customizada
3. Tooltips com detalhes
4. Tela completa

### **Total Estimado: 8 horas**

Estou pronto para começar assim que você aprovar! 🚀
