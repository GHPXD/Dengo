"""
════════════════════════════════════════════════════════════════════════════
SCRIPT DE DIAGNÓSTICO DO MODELO ML
════════════════════════════════════════════════════════════════════════════
Analisa o modelo treinado e gera relatório de performance.
"""

import joblib
import json
from pathlib import Path

# Carrega modelo e metadata
MODEL_PATH = Path(__file__).parent / "models" / "dengo_model.joblib"
METADATA_PATH = Path(__file__).parent / "models" / "model_metadata.json"

print("=" * 80)
print("DIAGNÓSTICO DO MODELO ML")
print("=" * 80)

# 1. Metadata
with open(METADATA_PATH, 'r', encoding='utf-8') as f:
    metadata = json.load(f)

print("\n📊 INFORMAÇÕES DO MODELO:")
print(f"   Versão: {metadata['model_version']}")
print(f"   Treinado em: {metadata['trained_at']}")
print(f"   Cidade: {metadata['city']} ({metadata['geocode']})")
print(f"   Período: {metadata['data_period']['start']} até {metadata['data_period']['end']}")
print(f"   Tipo: {metadata['model_type']}")

print("\n📉 MÉTRICAS DE PERFORMANCE:")
print(f"   MAE:  {metadata['metrics']['mae']:.2f} casos")
print(f"   RMSE: {metadata['metrics']['rmse']:.2f} casos")
print(f"   R²:   {metadata['metrics']['r2']:.4f}")

# Diagnóstico
print("\n🔍 DIAGNÓSTICO:")
r2 = metadata['metrics']['r2']
mae = metadata['metrics']['mae']

if r2 < 0:
    print("   🔴 CRÍTICO: R² negativo - Modelo pior que baseline!")
    print("   Causas prováveis:")
    print("      1. Overfitting severo (dados de treino muito diferentes do teste)")
    print("      2. Ano de 2024 tem surto atípico de dengue")
    print("      3. Features não capturam padrões sazonais corretamente")
elif r2 < 0.3:
    print("   ⚠️  ALERTA: R² muito baixo - Modelo com pouco poder preditivo")
elif r2 < 0.7:
    print("   🟡 MODERADO: Modelo funcional mas pode melhorar")
else:
    print("   ✅ BOM: Modelo com boa capacidade preditiva")

if mae > 100:
    print(f"   🔴 CRÍTICO: MAE muito alto ({mae:.0f} casos)")
    print("      Erro médio maior que 100 casos por semana")
elif mae > 50:
    print(f"   ⚠️  ALERTA: MAE moderado ({mae:.0f} casos)")
elif mae > 20:
    print(f"   🟡 ACEITÁVEL: MAE razoável ({mae:.0f} casos)")
else:
    print(f"   ✅ EXCELENTE: MAE baixo ({mae:.0f} casos)")

# 2. Carrega modelo
artifact = joblib.load(MODEL_PATH)
model = artifact['model']
scaler = artifact['scaler']
feature_names = artifact['feature_names']

print(f"\n📋 FEATURES UTILIZADAS ({len(feature_names)}):")
for i, feat in enumerate(feature_names, 1):
    print(f"   {i:2d}. {feat}")

# Feature importance
if hasattr(model, 'feature_importances_'):
    print("\n📊 TOP 10 FEATURES MAIS IMPORTANTES:")
    importances = model.feature_importances_
    feature_importance = sorted(zip(feature_names, importances), key=lambda x: x[1], reverse=True)
    
    for feat, imp in feature_importance[:10]:
        bar = '█' * int(imp * 50)
        print(f"   {feat:30s} {bar} {imp:.4f}")

print("\n" + "=" * 80)
print("🚀 RECOMENDAÇÕES:")
print("=" * 80)

if r2 < 0:
    print("""
1. 🔧 RETREINAR com diferentes períodos de teste:
   - Usar 2023 como teste ao invés de 2024
   - Aumentar janela de treino (2010-2023)

2. 🎯 AJUSTAR FEATURES:
   - Adicionar indicadores de surto (variação >200%)
   - Incluir sazonalidade do ano anterior
   - Normalizar por população/densidade

3. 🧠 TESTAR OUTROS MODELOS:
   - Random Forest (mais robusto a outliers)
   - Prophet (bom para sazonalidade)
   - SARIMA (séries temporais clássicas)

4. ⚙️  USAR MODELO EM PRODUÇÃO COM CAUTELA:
   - Aplicar caps (min/max razoáveis)
   - Combinar com regras heurísticas
   - Alertar sobre baixa confiança quando R² < 0
""")
else:
    print("""
✅ Modelo funcional! Para melhorar:
   - Coletar mais dados históricos
   - Adicionar features climáticas (precipitação)
   - Testar ensemble de modelos
""")

print("=" * 80)
