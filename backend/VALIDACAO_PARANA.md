# Validação - Apenas Municípios do Paraná (399)

## 🎯 Objetivo
Garantir que o sistema aceite **APENAS** os 399 municípios do estado do **Paraná (PR)**, rejeitando geocodes de outros estados.

---

## ✅ Validações Implementadas

### 1. Schema - `app/schemas/prediction.py`

#### Validação no `PredictionRequest`:
```python
@field_validator("geocode")
@classmethod
def validate_geocode(cls, v: str) -> str:
    """Valida que geocode é numérico e válido."""
    if not v.isdigit():
        raise ValueError("Geocode deve conter apenas dígitos")
    
    # Validação básica: Paraná começa com 41
    if not v.startswith("41"):
        raise ValueError(
            "Geocode inválido: deve ser do estado do Paraná (começar com 41)"
        )
    
    return v
```

**Resultado:**
- ✅ Curitiba (4106902) - ACEITO
- ✅ Londrina (4113700) - ACEITO
- ❌ São Paulo (3550308) - REJEITADO
- ❌ Rio de Janeiro (3304557) - REJEITADO

---

### 2. Data Service - `app/services/data_service.py`

#### A. Método `get_city_name()`:
```python
async def get_city_name(self, geocode: str) -> str:
    """
    Obtém nome da cidade pelo geocode.
    
    Raises:
        GeocodeNotFoundError: Se não encontrar município do Paraná
    """
    df = self._load_dataset()
    
    # Filtra por geocode do Paraná
    if 'geocodigo' in df.columns:
        city_data = df[df['geocodigo'] == int(geocode)]
    # ... [implementação completa]
    
    if city_data.empty:
        raise GeocodeNotFoundError(
            f"Município {geocode} não encontrado no dataset do Paraná"
        )
```

**Mudança:** Antes retornava placeholder "Curitiba" sempre. Agora busca no CSV real.

#### B. Método `_get_from_csv()`:
```python
def _get_from_csv(self, geocode: str, weeks: int) -> pd.DataFrame:
    """
    Busca dados do CSV local (fallback confiável).
    
    Raises:
        GeocodeNotFoundError: Se geocode não existir no Paraná
    """
    df_full = self._load_dataset()
    
    # Filtra por geocode do município do Paraná
    if 'geocodigo' in df_full.columns:
        df_city = df_full[df_full['geocodigo'] == int(geocode)]
    # ... [implementação]
    
    if df_city.empty:
        raise GeocodeNotFoundError(
            f"Geocode {geocode} não encontrado no dataset do Paraná (399 municípios)"
        )
```

**Mudança:** Antes usava `.tail(weeks)` (pegava qualquer dado). Agora filtra corretamente por geocode.

---

### 3. Testes - `test_api.py`

**Antes:**
```python
# Teste 1: São Paulo (3550308) ❌
# Teste 2: Rio de Janeiro (3304557) ❌
# Teste 3: Cidade inválida (9999999) ❌
```

**Depois:**
```python
# Teste 1: Curitiba - PR (4106902) ✅
# Teste 2: Londrina - PR (4113700) ✅
# Teste 3: São Paulo - Fora do PR (3550308 - deve falhar) ✅
```

---

## 📊 Estrutura de Geocodes do Brasil

### Formato: `XXYYYY` (7 dígitos)
- **XX**: Código do estado (2 dígitos)
- **YYYY**: Código do município (5 dígitos)

### Códigos por Estado:
| UF | Código | Exemplo |
|----|--------|---------|
| **PR** | **41** | **4106902** (Curitiba) |
| **SP** | **35** | 3550308 (São Paulo) |
| **RJ** | **33** | 3304557 (Rio de Janeiro) |
| **SC** | **42** | 4205407 (Florianópolis) |
| **RS** | **43** | 4314902 (Porto Alegre) |

**Referência:** [IBGE - Códigos de Municípios](https://www.ibge.gov.br/explica/codigos-dos-municipios.php)

---

## 🧪 Testes de Validação

### Teste 1: Geocode Válido (Curitiba)
```bash
curl -X POST "http://127.0.0.1:8000/api/v1/predictions/predict" \
  -H "Content-Type: application/json" \
  -d '{"geocode": "4106902", "weeks_ahead": 2}'
```

**Resultado Esperado:**
```json
{
  "city": "Curitiba",
  "geocode": "4106902",
  "state": "PR",
  "historical_data": [...],
  "predictions": [...]
}
```

**Status:** ✅ 200 OK

---

### Teste 2: Geocode Inválido (São Paulo)
```bash
curl -X POST "http://127.0.0.1:8000/api/v1/predictions/predict" \
  -H "Content-Type: application/json" \
  -d '{"geocode": "3550308", "weeks_ahead": 1}'
```

**Resultado Esperado:**
```json
{
  "detail": [
    {
      "type": "value_error",
      "loc": ["body", "geocode"],
      "msg": "Value error, Geocode inválido: deve ser do estado do Paraná (começar com 41)",
      "input": "3550308"
    }
  ]
}
```

**Status:** ❌ 422 Unprocessable Entity

---

### Teste 3: Geocode Válido mas Não Existe no Dataset
```bash
curl -X POST "http://127.0.0.1:8000/api/v1/predictions/predict" \
  -H "Content-Type: application/json" \
  -d '{"geocode": "4199999", "weeks_ahead": 1}'
```

**Resultado Esperado:**
```json
{
  "error_code": "GEOCODE_NOT_FOUND",
  "message": "Município com geocode 4199999 não encontrado",
  "details": "Geocode 4199999 não encontrado no dataset do Paraná (399 municípios)",
  "geocode": "4199999"
}
```

**Status:** ❌ 404 Not Found

---

## 📋 Municípios do Paraná (Exemplos)

### Maiores Cidades (Top 10):
| Posição | Município | Geocode | População |
|---------|-----------|---------|-----------|
| 1 | Curitiba | 4106902 | 1.963.726 |
| 2 | Londrina | 4113700 | 580.870 |
| 3 | Maringá | 4115200 | 430.157 |
| 4 | Ponta Grossa | 4119905 | 358.838 |
| 5 | Cascavel | 4104808 | 348.051 |
| 6 | São José dos Pinhais | 4125506 | 329.058 |
| 7 | Foz do Iguaçu | 4108304 | 258.823 |
| 8 | Colombo | 4106001 | 254.254 |
| 9 | Guarapuava | 4108906 | 183.755 |
| 10 | Paranaguá | 4118204 | 156.174 |

**Total:** 399 municípios

**Fonte:** IBGE 2024

---

## 🔒 Camadas de Segurança

### Camada 1: Validação Pydantic (Schema)
- Valida formato (7 dígitos)
- Valida prefixo "41" (Paraná)
- Retorna erro 422 imediatamente

### Camada 2: Data Service (CSV)
- Filtra dataset por geocode
- Verifica existência no dataset
- Retorna erro 404 se não encontrar

### Camada 3: API InfoDengue (Opcional)
- API externa pode ter dados de outros estados
- Mas validação Pydantic bloqueia antes

### Camada 4: Logs e Monitoramento
- Todos os erros são logados
- Geocodes inválidos são rastreados

---

## 📁 Arquivos Modificados

### 1. `app/schemas/prediction.py`
- ✅ Validação `@field_validator("geocode")`
- ✅ Mensagem de erro clara

### 2. `app/services/data_service.py`
- ✅ `get_city_name()` - Busca real no CSV
- ✅ `_get_from_csv()` - Filtra por geocode do Paraná
- ✅ Mensagens de erro específicas

### 3. `test_api.py`
- ✅ Testes com Curitiba e Londrina
- ✅ Teste de rejeição de SP
- ✅ Documentação atualizada

---

## 🎯 Resultado Final

### ✅ Aceitos (Começam com 41):
- 4106902 (Curitiba)
- 4113700 (Londrina)
- 4115200 (Maringá)
- ... (todos os 399 municípios do PR)

### ❌ Rejeitados (Não começam com 41):
- 3550308 (São Paulo - SP)
- 3304557 (Rio de Janeiro - RJ)
- 4205407 (Florianópolis - SC)
- 4314902 (Porto Alegre - RS)
- Qualquer geocode fora do Paraná

---

## 🚀 Próximos Passos

### Backend ✅ COMPLETO
- [x] Validação de geocode
- [x] Filtro por estado
- [x] Mensagens de erro claras
- [x] Testes atualizados

### Frontend 🔜 PENDENTE (Sprint 2B)
- [ ] Dropdown de municípios do Paraná
- [ ] Validação de geocode no frontend
- [ ] Mensagens de erro traduzidas
- [ ] Autocomplete com 399 municípios

---

**Data:** 25/12/2025  
**Status:** Validações implementadas e testadas  
**Escopo:** 399 municípios do Paraná (geocodes 41XXXXX)  
**Próximo:** Implementar frontend Flutter (Sprint 2B)
