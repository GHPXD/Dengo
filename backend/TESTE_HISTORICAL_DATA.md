# Teste Backend - Dados Históricos + Predições

## Sprint 2A - Modificações Backend (✅ COMPLETO)

### Objetivo
Adicionar dados históricos (últimas 12 semanas) à resposta do endpoint `/predictions/predict` para exibir gráfico dual-line no Flutter.

---

## 📝 Modificações Realizadas

### 1. Schema - `backend/app/schemas/prediction.py`

#### ✅ Adicionado modelo `HistoricalWeek`
```python
class HistoricalWeek(BaseModel):
    """
    Dados históricos de uma semana epidemiológica.
    Representa casos confirmados de dengue em uma semana específica.
    Usado para exibir linha verde no gráfico (casos reais).
    """
    
    week_number: int = Field(..., ge=1, le=53)
    date: DateType = Field(...)
    cases: int = Field(..., ge=0)
```

#### ✅ Adicionado campo `historical_data` em `PredictionResponse`
```python
class PredictionResponse(BaseModel):
    # ... outros campos
    
    historical_data: List[HistoricalWeek] = Field(
        default=[],
        description="Dados históricos das últimas 12 semanas"
    )
    
    predictions: List[WeekPrediction] = Field(...)
```

---

### 2. Endpoint - `backend/app/api/v1/endpoints/predictions.py`

#### ✅ Modificações:

1. **Import** de `HistoricalWeek`
2. **Busca de dados**: Agora busca 12 semanas para gráfico (além das 4 para modelo)
3. **Formatação**: Cria lista de `HistoricalWeek` com week_number, date, cases
4. **Resposta**: Inclui `historical_data` no `PredictionResponse`

```python
# Busca 12 semanas para gráfico (linha verde)
historical_data_full = await data_service.get_historical_data(
    geocode=geocode,
    weeks=12
)

# Formata para HistoricalWeek
for _, row in historical_sorted.iterrows():
    week_date = row["data_iniSE"]
    week_number = week_date.isocalendar()[1]
    cases = int(row["casos_est"])
    
    historical_weeks.append(HistoricalWeek(...))

# Adiciona à resposta
response = PredictionResponse(
    historical_data=historical_weeks,  # Linha verde
    predictions=predictions,  # Linha azul
    ...
)
```

---

## ✅ Teste de Validação

### Comando PowerShell
```powershell
$body = @{geocode='4106902'; weeks_ahead=2} | ConvertTo-Json
Invoke-WebRequest `
  -Uri 'http://127.0.0.1:8000/api/v1/predictions/predict' `
  -Method POST `
  -Body $body `
  -ContentType 'application/json' | 
  Select-Object -ExpandProperty Content | 
  ConvertFrom-Json | 
  ConvertTo-Json -Depth 10
```

### Resposta Obtida (Curitiba - 2 semanas)

```json
{
  "city": "Curitiba",
  "geocode": "4106902",
  "state": "PR",
  "historical_data": [
    {"week_number": 38, "date": "2025-09-21", "cases": 36},
    {"week_number": 39, "date": "2025-09-28", "cases": 54},
    {"week_number": 40, "date": "2025-10-05", "cases": 40},
    {"week_number": 41, "date": "2025-10-12", "cases": 49},
    {"week_number": 42, "date": "2025-10-19", "cases": 58},
    {"week_number": 43, "date": "2025-10-26", "cases": 39},
    {"week_number": 44, "date": "2025-11-02", "cases": 52},
    {"week_number": 45, "date": "2025-11-09", "cases": 65},
    {"week_number": 46, "date": "2025-11-16", "cases": 50},
    {"week_number": 47, "date": "2025-11-23", "cases": 58},
    {"week_number": 48, "date": "2025-11-30", "cases": 48},
    {"week_number": 49, "date": "2025-12-07", "cases": 33}
  ],
  "predictions": [
    {
      "week_number": 50,
      "date": "2025-12-14",
      "predicted_cases": 28.4,
      "confidence": "high",
      "lower_bound": 27.6,
      "upper_bound": 29.2
    },
    {
      "week_number": 51,
      "date": "2025-12-21",
      "predicted_cases": 23.4,
      "confidence": "high",
      "lower_bound": 22.4,
      "upper_bound": 24.4
    }
  ],
  "trend": "descending",
  "trend_percentage": -17.61,
  "generated_at": "2025-12-25T17:59:12.643789",
  "model_metadata": {
    "model_name": "DengoAI v1.0",
    "accuracy": 0.91,
    "mae": 27.0
  }
}
```

---

## 📊 Análise dos Dados

### Dados Históricos (Linha Verde - Casos Reais)
- **Total de semanas**: 12 (semanas 38-49 de 2025)
- **Período**: 21/09/2025 a 07/12/2025
- **Casos (máximo)**: 65 casos (semana 45)
- **Casos (mínimo)**: 33 casos (semana 49)
- **Tendência real**: Decrescente (de 36 → 33 casos)

### Predições IA (Linha Azul - Casos Futuros)
- **Total de semanas**: 2 (semanas 50-51)
- **Período**: 14/12/2025 a 21/12/2025
- **Casos preditos**: 28.4 → 23.4 (decrescente)
- **Confiança**: Alta (high)
- **Tendência IA**: Descending (-17.61%)
- **Intervalo de confiança**: ±0.8-1.0 casos

### ✅ Validações
- ✅ historical_data contém 12 semanas
- ✅ Dados ordenados cronologicamente
- ✅ week_number sequencial (38-49)
- ✅ Datas corretas (início de cada semana)
- ✅ Casos não-negativos
- ✅ predictions sequenciais após histórico (50-51)
- ✅ Tendência coerente (descending)

---

## 🎨 Próximos Passos (Sprint 2B - Frontend)

Agora que o backend está completo, os próximos passos são:

### 1. Criar feature Flutter `lib/features/predictions/`
```
lib/features/predictions/
├── data/
│   ├── models/
│   │   ├── historical_week_model.dart
│   │   └── prediction_response_model.dart
│   ├── datasources/
│   │   └── predictions_remote_datasource.dart
│   └── repositories/
│       └── predictions_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── historical_week.dart
│   │   └── prediction_response.dart
│   └── repositories/
│       └── predictions_repository.dart
└── presentation/
    ├── providers/
    │   └── predictions_provider.dart
    ├── widgets/
    │   ├── predictions_chart.dart
    │   └── trend_indicator.dart
    └── screens/
        └── predictions_screen.dart
```

### 2. Implementar gráfico dual-line com `fl_chart`
```dart
LineChart(
  lineBarsData: [
    // Linha Verde - Dados Históricos (sólida)
    LineChartBarData(
      spots: historicalData.map((h) => 
        FlSpot(h.weekNumber.toDouble(), h.cases.toDouble())
      ).toList(),
      color: Colors.green,
      isCurved: true,
      dotData: FlDotData(show: true),
    ),
    
    // Linha Azul - Predições IA (tracejada)
    LineChartBarData(
      spots: predictions.map((p) => 
        FlSpot(p.weekNumber.toDouble(), p.predictedCases)
      ).toList(),
      color: Colors.blue,
      isCurved: true,
      dashArray: [5, 5],  // Linha tracejada
      dotData: FlDotData(show: true),
    ),
  ],
)
```

### 3. Adicionar à navegação (3º ícone)
- Ícone: `Icons.analytics` ou `Icons.show_chart`
- Label: "Predições"
- Rota: `/predictions`

---

## 📈 Resumo

### ✅ Backend Sprint 2A - COMPLETO (100%)
- [x] Criar modelo `HistoricalWeek`
- [x] Adicionar campo `historical_data` em `PredictionResponse`
- [x] Modificar endpoint para buscar 12 semanas
- [x] Formatar dados históricos
- [x] Testar resposta completa

### ⏳ Frontend Sprint 2B - PENDENTE (0%)
- [ ] Criar estrutura `lib/features/predictions/`
- [ ] Implementar models/entities
- [ ] Criar data sources e repositories
- [ ] Implementar providers com Riverpod
- [ ] Criar widget de gráfico dual-line
- [ ] Adicionar à navegação bottom bar

---

## 🎯 Resultado Esperado no Flutter

**Tela de Predições:**
```
┌─────────────────────────────────────────┐
│ Predições - Curitiba                    │
├─────────────────────────────────────────┤
│                                         │
│   70┤      ●                            │
│   60┤   ●     ●                         │
│   50┤●     ●     ●   ●   ●              │
│   40┤                  ●   ●  ●         │
│   30┤                           ● - - ● │
│   20┤                                   │
│      ────────────────────────────────   │
│      Set  Out  Nov  Dez   (2025)        │
│                                         │
│  ● Casos Reais      ● · · Predições IA  │
│                                         │
│ Tendência: ↓ Descending (-17.6%)        │
│ Confiança: Alta (91%)                   │
│ Próximas 2 semanas: 28 → 23 casos       │
└─────────────────────────────────────────┘
```

---

**Data:** 25/12/2025  
**Status:** Backend completo, aguardando frontend  
**Próximo passo:** Implementar Sprint 2B (Flutter)
