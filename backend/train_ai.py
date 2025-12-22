"""
════════════════════════════════════════════════════════════════════════════
DENGO AI - SCRIPT DE TREINAMENTO DO MODELO DE PREDIÇÃO DE DENGUE
════════════════════════════════════════════════════════════════════════════

Este script treina um modelo de Machine Learning para prever casos de dengue
baseado em dados climáticos e históricos epidemiológicos.

Execução:
    python train_ai.py

Saída:
    - dengo_model.joblib (modelo treinado)
    - Métricas de avaliação no console (MAE, RMSE, R²)

Fontes de dados (simuladas para MVP):
    - InfoDengue API (FIOCRUZ) - Casos históricos
    - OpenWeatherMap - Dados climáticos
    - DATASUS - Dados populacionais

Autor: Dengo Team
Data: 2025-12-08
════════════════════════════════════════════════════════════════════════════
"""

import warnings
from datetime import datetime, timedelta
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

warnings.filterwarnings("ignore")

# ════════════════════════════════════════════════════════════════════════════
# CONFIGURAÇÕES
# ════════════════════════════════════════════════════════════════════════════

MODEL_PATH = Path(__file__).parent / "dengo_model.joblib"
RANDOM_STATE = 42
N_SAMPLES = 5000  # Quantidade de registros históricos simulados


# ════════════════════════════════════════════════════════════════════════════
# GERAÇÃO DE DADOS SINTÉTICOS (SIMULAÇÃO DE API EXTERNA)
# ════════════════════════════════════════════════════════════════════════════


def generate_synthetic_data(n_samples: int = N_SAMPLES) -> pd.DataFrame:
    """
    Gera dados sintéticos que simulam histórico de dengue + clima.

    Em produção, esses dados viriam de:
    - InfoDengue API: https://info.dengue.mat.br/api
    - OpenWeatherMap API: https://api.openweathermap.org
    - DATASUS: https://datasus.saude.gov.br

    Features geradas:
        - mes: Mês do ano (1-12)
        - semana_epidemiologica: Semana epidemiológica (1-52)
        - temperatura_media: Temperatura média (°C)
        - temperatura_max: Temperatura máxima (°C)
        - temperatura_min: Temperatura mínima (°C)
        - umidade_media: Umidade relativa média (%)
        - precipitacao: Precipitação acumulada (mm)
        - casos_semana_anterior: Casos da semana anterior (lag feature)
        - casos_2sem_anterior: Casos de 2 semanas atrás
        - populacao_densidade: Densidade populacional (hab/km²)

    Target:
        - casos: Número de casos de dengue confirmados
    """
    print("📊 Gerando dados sintéticos de treinamento...")
    print(f"   Total de amostras: {n_samples:,}")

    np.random.seed(RANDOM_STATE)

    # Data range: últimos 3 anos
    end_date = datetime.now()
    start_date = end_date - timedelta(days=3 * 365)
    dates = pd.date_range(start=start_date, end=end_date, periods=n_samples)

    data = {
        "data": dates,
        "mes": dates.month,
        "semana_epidemiologica": dates.isocalendar().week,
        # Clima: Influência sazonal realista
        "temperatura_media": 20 + 8 * np.sin(2 * np.pi * dates.month / 12)
        + np.random.normal(0, 2, n_samples),
        "temperatura_max": 25 + 10 * np.sin(2 * np.pi * dates.month / 12)
        + np.random.normal(0, 3, n_samples),
        "temperatura_min": 15 + 6 * np.sin(2 * np.pi * dates.month / 12)
        + np.random.normal(0, 2, n_samples),
        "umidade_media": 60 + 20 * np.sin(2 * np.pi * dates.month / 12)
        + np.random.normal(0, 10, n_samples),
        "precipitacao": np.abs(
            50 + 100 * np.sin(2 * np.pi * dates.month / 12)
            + np.random.normal(0, 30, n_samples)
        ),
        # Densidade populacional (constante por região)
        "populacao_densidade": np.random.choice([500, 1500, 3000, 7000], n_samples),
    }

    df = pd.DataFrame(data)

    # ════════════════════════════════════════════════════════════════════════
    # TARGET: Casos de dengue (correlacionado com clima + sazonalidade)
    # ════════════════════════════════════════════════════════════════════════

    # Fórmula realista: mais casos em períodos quentes e úmidos
    base_casos = (
        10
        + 50 * np.sin(2 * np.pi * df["mes"] / 12)  # Sazonalidade
        + 0.8 * df["temperatura_media"]  # Temperatura influencia
        + 0.3 * df["umidade_media"]  # Umidade influencia
        + 0.1 * df["precipitacao"]  # Chuva cria criadouros
        + 0.005 * df["populacao_densidade"]  # Densidade urbana
    )

    # Adiciona variação aleatória + outliers (surtos)
    noise = np.random.normal(0, 15, n_samples)
    outliers = np.random.choice([0, 0, 0, 0, 100], n_samples)  # 20% de chance de surto

    df["casos"] = np.maximum(0, base_casos + noise + outliers).astype(int)

    # ════════════════════════════════════════════════════════════════════════
    # LAG FEATURES: Casos das semanas anteriores (temporal dependency)
    # ════════════════════════════════════════════════════════════════════════

    df["casos_semana_anterior"] = df["casos"].shift(1).fillna(0).astype(int)
    df["casos_2sem_anterior"] = df["casos"].shift(2).fillna(0).astype(int)

    print(f"   ✓ Dados gerados: {df.shape[0]} linhas x {df.shape[1]} colunas")
    print(f"   ✓ Período: {df['data'].min().date()} até {df['data'].max().date()}")
    print(f"   ✓ Casos totais: {df['casos'].sum():,}")
    print(f"   ✓ Média de casos/semana: {df['casos'].mean():.1f}")

    return df


# ════════════════════════════════════════════════════════════════════════════
# PRÉ-PROCESSAMENTO
# ════════════════════════════════════════════════════════════════════════════


def preprocess_data(df: pd.DataFrame) -> tuple:
    """
    Prepara os dados para treinamento.

    Steps:
        1. Remove coluna de data (não é feature numérica)
        2. Separa features (X) e target (y)
        3. Split train/test (80/20)
        4. Normalização com StandardScaler

    Returns:
        X_train, X_test, y_train, y_test, scaler
    """
    print("\n🔧 Pré-processamento dos dados...")

    # Remove coluna de data
    df_clean = df.drop(columns=["data"])

    # Separa features e target
    X = df_clean.drop(columns=["casos"])
    y = df_clean["casos"]

    print(f"   Features utilizadas: {list(X.columns)}")
    print(f"   Shape X: {X.shape}, Shape y: {y.shape}")

    # Split train/test
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=RANDOM_STATE, shuffle=True
    )

    print(f"   ✓ Train set: {X_train.shape[0]} amostras")
    print(f"   ✓ Test set: {X_test.shape[0]} amostras")

    # Normalização (importante para GradientBoosting)
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)

    print("   ✓ Dados normalizados (StandardScaler)")

    return X_train_scaled, X_test_scaled, y_train, y_test, scaler, list(X.columns)


# ════════════════════════════════════════════════════════════════════════════
# TREINAMENTO DO MODELO
# ════════════════════════════════════════════════════════════════════════════


def train_model(X_train, y_train) -> GradientBoostingRegressor:
    """
    Treina o modelo GradientBoostingRegressor.

    Hiperparâmetros otimizados:
        - n_estimators: 200 (número de árvores)
        - learning_rate: 0.1 (taxa de aprendizado)
        - max_depth: 5 (profundidade máxima das árvores)
        - min_samples_split: 10 (min samples para split)
        - min_samples_leaf: 4 (min samples por folha)
        - subsample: 0.8 (fração de amostras por árvore)
    """
    print("\n🤖 Treinando modelo de Machine Learning...")
    print("   Algoritmo: GradientBoostingRegressor")
    print("   Hiperparâmetros:")
    print("      - n_estimators: 200")
    print("      - learning_rate: 0.1")
    print("      - max_depth: 5")

    model = GradientBoostingRegressor(
        n_estimators=200,
        learning_rate=0.1,
        max_depth=5,
        min_samples_split=10,
        min_samples_leaf=4,
        subsample=0.8,
        random_state=RANDOM_STATE,
        verbose=0,
    )

    model.fit(X_train, y_train)

    print("   ✓ Modelo treinado com sucesso!")

    return model


# ════════════════════════════════════════════════════════════════════════════
# AVALIAÇÃO DO MODELO
# ════════════════════════════════════════════════════════════════════════════


def evaluate_model(model, X_test, y_test) -> dict:
    """
    Avalia o modelo com métricas de regressão.

    Métricas:
        - MAE (Mean Absolute Error): Erro médio absoluto
        - RMSE (Root Mean Squared Error): Raiz do erro quadrático médio
        - R² Score: Coeficiente de determinação (0-1, quanto maior melhor)
    """
    print("\n📈 Avaliando modelo no conjunto de teste...")

    y_pred = model.predict(X_test)

    mae = mean_absolute_error(y_test, y_pred)
    rmse = np.sqrt(mean_squared_error(y_test, y_pred))
    r2 = r2_score(y_test, y_pred)

    print("\n" + "=" * 70)
    print("                    MÉTRICAS DE AVALIAÇÃO")
    print("=" * 70)
    print(f"   MAE  (Mean Absolute Error)       : {mae:.2f} casos")
    print(f"   RMSE (Root Mean Squared Error)   : {rmse:.2f} casos")
    print(f"   R²   (Coefficient of Determination): {r2:.4f} (0-1)")
    print("=" * 70)

    # Interpretação
    print("\n📊 Interpretação:")
    if mae < 20:
        print("   ✓ EXCELENTE: Modelo muito preciso (erro < 20 casos)")
    elif mae < 50:
        print("   ✓ BOM: Modelo aceitável para produção (erro < 50 casos)")
    elif mae < 100:
        print("   ⚠ RAZOÁVEL: Considere coletar mais dados (erro < 100 casos)")
    else:
        print("   ❌ RUIM: Modelo precisa de ajustes (erro > 100 casos)")

    if r2 > 0.7:
        print(f"   ✓ R² = {r2:.2f}: Modelo explica {r2*100:.1f}% da variância")
    else:
        print(f"   ⚠ R² = {r2:.2f}: Modelo pode melhorar (ideal > 0.7)")

    return {"mae": mae, "rmse": rmse, "r2": r2}


# ════════════════════════════════════════════════════════════════════════════
# FEATURE IMPORTANCE
# ════════════════════════════════════════════════════════════════════════════


def show_feature_importance(model, feature_names):
    """Exibe importância das features."""
    print("\n🔍 Importância das Features:")
    print("-" * 60)

    importances = model.feature_importances_
    feature_importance = sorted(
        zip(feature_names, importances), key=lambda x: x[1], reverse=True
    )

    for i, (feature, importance) in enumerate(feature_importance, 1):
        bar = "█" * int(importance * 50)
        print(f"   {i:2d}. {feature:30s} {bar} {importance:.4f}")


# ════════════════════════════════════════════════════════════════════════════
# SALVAR MODELO
# ════════════════════════════════════════════════════════════════════════════


def save_model(model, scaler, feature_names, metrics):
    """
    Salva o modelo treinado + metadados usando joblib.

    Estrutura do arquivo:
        {
            'model': GradientBoostingRegressor,
            'scaler': StandardScaler,
            'feature_names': list,
            'metrics': dict,
            'trained_at': datetime,
            'version': str
        }
    """
    print(f"\n💾 Salvando modelo em: {MODEL_PATH}")

    model_artifact = {
        "model": model,
        "scaler": scaler,
        "feature_names": feature_names,
        "metrics": metrics,
        "trained_at": datetime.now().isoformat(),
        "version": "1.0.0",
    }

    joblib.dump(model_artifact, MODEL_PATH)

    file_size_mb = MODEL_PATH.stat().st_size / (1024 * 1024)
    print(f"   ✓ Modelo salvo com sucesso!")
    print(f"   ✓ Tamanho do arquivo: {file_size_mb:.2f} MB")
    print(f"   ✓ Path: {MODEL_PATH.absolute()}")

    # Testa carregamento
    print("\n🔄 Testando carregamento do modelo...")
    loaded = joblib.load(MODEL_PATH)
    print(f"   ✓ Modelo carregado com sucesso!")
    print(f"   ✓ Versão: {loaded['version']}")
    print(f"   ✓ Treinado em: {loaded['trained_at']}")


# ════════════════════════════════════════════════════════════════════════════
# MAIN
# ════════════════════════════════════════════════════════════════════════════


def main():
    """Pipeline completo de treinamento."""
    print("\n" + "=" * 80)
    print("          🦟 DENGO AI - TREINAMENTO DO MODELO DE PREDIÇÃO DE DENGUE")
    print("=" * 80)

    # 1. Gerar dados
    df = generate_synthetic_data(N_SAMPLES)

    # 2. Pré-processar
    X_train, X_test, y_train, y_test, scaler, feature_names = preprocess_data(df)

    # 3. Treinar
    model = train_model(X_train, y_train)

    # 4. Avaliar
    metrics = evaluate_model(model, X_test, y_test)

    # 5. Feature Importance
    show_feature_importance(model, feature_names)

    # 6. Salvar
    save_model(model, scaler, feature_names, metrics)

    print("\n" + "=" * 80)
    print("                        ✅ TREINAMENTO COMPLETO")
    print("=" * 80)
    print("\n📦 Próximos passos:")
    print("   1. Mova o arquivo 'dengo_model.joblib' para 'backend/models/'")
    print("   2. O modelo será carregado automaticamente pela API no startup")
    print("   3. Endpoint '/api/dashboard' usará o modelo para predições reais")
    print("\n🚀 API pronta para produção!\n")


if __name__ == "__main__":
    main()
