"""
════════════════════════════════════════════════════════════════════════════
ETL & ML TRAINING PIPELINE - DENGO PROJECT
════════════════════════════════════════════════════════════════════════════
Pipeline completo de coleta, tratamento e treinamento do modelo de predição
de casos de dengue usando dados históricos do InfoDengue (DATASUS/FIOCRUZ).

Autor: Dengo Team
Data: Dezembro 2025
Versão: 2.0.0 (Production-Ready)

Pipeline:
    1. ETL: Extração de dados históricos (InfoDengue API)
    2. Feature Engineering: Criação de variáveis preditivas
    3. ML Training: Treinamento com XGBoost
    4. Validation: Métricas de performance (MAE, RMSE, R²)
    5. Export: Modelo + Metadata para produção
"""

import json
import warnings
from datetime import datetime
from pathlib import Path
from typing import Dict, Tuple

import joblib
import numpy as np
import pandas as pd
import requests
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.model_selection import TimeSeriesSplit, cross_val_score
from sklearn.preprocessing import StandardScaler
from xgboost import XGBRegressor

warnings.filterwarnings("ignore")

# ════════════════════════════════════════════════════════════════════════════
# CONFIGURAÇÕES
# ════════════════════════════════════════════════════════════════════════════

# Geocódigo IBGE de Curitiba
GEOCODE = "4106902"

# Período de coleta (10 anos de histórico)
START_DATE = "2015-01-01"
END_DATE = "2024-12-31"

# URL da API InfoDengue (FIOCRUZ/DATASUS)
API_URL = f"https://info.dengue.mat.br/api/alertcity"

# Caminhos de saída
OUTPUT_DIR = Path(__file__).parent / "models"
MODEL_PATH = OUTPUT_DIR / "dengo_model.joblib"
METADATA_PATH = OUTPUT_DIR / "model_metadata.json"

# Hiperparâmetros do modelo
RANDOM_STATE = 42
TEST_YEAR = 2024
MIN_SAMPLES_TRAIN = 100


# ════════════════════════════════════════════════════════════════════════════
# ETAPA 1: ETL - EXTRAÇÃO DE DADOS
# ════════════════════════════════════════════════════════════════════════════


def fetch_historical_data(geocode: str, start_year: int, end_year: int) -> pd.DataFrame:
    """
    Baixa dados históricos de dengue da API InfoDengue.

    A API do InfoDengue fornece dados semanais de:
    - Casos notificados de dengue
    - Temperatura média/min/max
    - Umidade relativa
    - Precipitação acumulada
    - Nível de alerta epidemiológico

    Args:
        geocode: Código IBGE da cidade (ex: 4106902 = Curitiba)
        start_year: Ano inicial da coleta
        end_year: Ano final da coleta

    Returns:
        DataFrame com dados históricos consolidados
    """
    print("=" * 80)
    print("ETAPA 1: EXTRAÇÃO DE DADOS (ETL)")
    print("=" * 80)
    print(f"📥 Coletando dados de dengue para {geocode} ({start_year}-{end_year})...")
    print(f"🌐 API: InfoDengue (FIOCRUZ/DATASUS)")

    all_data = []

    for year in range(start_year, end_year + 1):
        print(f"  → Baixando dados de {year}...", end=" ")

        try:
            # InfoDengue API endpoint
            url = f"{API_URL}?geocode={geocode}&disease=dengue&format=json&ew_start=1&ew_end=53&ey_start={year}&ey_end={year}"

            response = requests.get(url, timeout=30)
            response.raise_for_status()

            year_data = response.json()

            if year_data:
                all_data.extend(year_data)
                print(f"✓ {len(year_data)} registros")
            else:
                print("⚠ Sem dados")

        except requests.exceptions.RequestException as e:
            print(f"✗ Erro: {e}")
            continue

    if not all_data:
        raise ValueError("❌ Nenhum dado foi coletado. Verifique a API ou o geocode.")

    df = pd.DataFrame(all_data)
    print(f"\n✅ Total coletado: {len(df)} semanas epidemiológicas")
    print(f"📊 Período: {df['data_iniSE'].min()} até {df['data_iniSE'].max()}")

    return df


# ════════════════════════════════════════════════════════════════════════════
# ETAPA 2: DATA CLEANING & FEATURE ENGINEERING
# ════════════════════════════════════════════════════════════════════════════


def clean_and_engineer_features(df: pd.DataFrame) -> pd.DataFrame:
    """
    Limpa dados e cria features de engenharia para ML.

    Transformações aplicadas:
        1. Conversão de tipos de dados
        2. Tratamento de valores ausentes
        3. Criação de lags (séries temporais)
        4. Médias móveis
        5. Sazonalidade (trigonométrica)
        6. Features climáticas agregadas

    Args:
        df: DataFrame bruto da API

    Returns:
        DataFrame limpo e enriquecido com features
    """
    print("\n" + "=" * 80)
    print("ETAPA 2: LIMPEZA E FEATURE ENGINEERING")
    print("=" * 80)

    # ────────────────────────────────────────────────────────────────────────
    # 2.1 Conversão de tipos
    # ────────────────────────────────────────────────────────────────────────
    print("🧹 Convertendo tipos de dados...")

    df = df.copy()
    # Converter timestamp Unix (milissegundos) para datetime
    df["data_iniSE"] = pd.to_datetime(df["data_iniSE"], unit="ms")
    df = df.sort_values("data_iniSE").reset_index(drop=True)

    # Converte colunas numéricas
    numeric_cols = [
        "casos_est",
        "casos",
        "tempmin",
        "tempmed",
        "tempmax",
        "umidmin",
        "umidmed",
        "umidmax",
        "SE",
    ]

    for col in numeric_cols:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce")

    # ────────────────────────────────────────────────────────────────────────
    # 2.2 Tratamento de valores ausentes
    # ────────────────────────────────────────────────────────────────────────
    print("🔧 Tratando valores ausentes...")

    # Preenche casos com 0 (ausência de notificação = sem casos)
    df["casos"] = df["casos"].fillna(0)
    df["casos_est"] = df["casos_est"].fillna(0)

    # Preenche temperatura com média da semana anterior
    df["tempmin"] = df["tempmin"].fillna(method="ffill").fillna(df["tempmin"].mean())
    df["tempmed"] = df["tempmed"].fillna(method="ffill").fillna(df["tempmed"].mean())
    df["tempmax"] = df["tempmax"].fillna(method="ffill").fillna(df["tempmax"].mean())

    # Preenche umidade com média da semana anterior
    df["umidmin"] = df["umidmin"].fillna(method="ffill").fillna(df["umidmin"].mean())
    df["umidmed"] = df["umidmed"].fillna(method="ffill").fillna(df["umidmed"].mean())
    df["umidmax"] = df["umidmax"].fillna(method="ffill").fillna(df["umidmax"].mean())

    # ────────────────────────────────────────────────────────────────────────
    # 2.3 Feature Engineering
    # ────────────────────────────────────────────────────────────────────────
    print("🔬 Criando features de engenharia...")

    # LAG FEATURES (séries temporais)
    df["casos_semana_anterior"] = df["casos"].shift(1).fillna(0)
    df["casos_2sem_anterior"] = df["casos"].shift(2).fillna(0)
    df["casos_3sem_anterior"] = df["casos"].shift(3).fillna(0)
    df["casos_4sem_anterior"] = df["casos"].shift(4).fillna(0)

    # ROLLING MEANS (médias móveis)
    df["casos_media_4sem"] = df["casos"].rolling(window=4, min_periods=1).mean()
    df["temp_media_movel_4sem"] = df["tempmed"].rolling(window=4, min_periods=1).mean()
    df["umid_media_movel_4sem"] = df["umidmed"].rolling(window=4, min_periods=1).mean()

    # SAZONALIDADE (componentes trigonométricas)
    df["semana_do_ano"] = df["SE"]
    df["sazonalidade_sen"] = np.sin(2 * np.pi * df["semana_do_ano"] / 52)
    df["sazonalidade_cos"] = np.cos(2 * np.pi * df["semana_do_ano"] / 52)

    # AMPLITUDES TÉRMICAS E DE UMIDADE
    df["amplitude_termica"] = df["tempmax"] - df["tempmin"]
    df["amplitude_umidade"] = df["umidmax"] - df["umidmin"]

    # TENDÊNCIA (número sequencial da semana)
    df["tendencia"] = range(len(df))

    # INTERAÇÕES (features polinomiais)
    df["temp_umid_interacao"] = df["tempmed"] * df["umidmed"]

    # ────────────────────────────────────────────────────────────────────────
    # 2.4 Remoção de primeiras linhas (lag warmup)
    # ────────────────────────────────────────────────────────────────────────
    # Primeiras 4 semanas têm lags incompletos
    df = df.iloc[4:].reset_index(drop=True)

    print(f"✅ Features criadas: {len(df.columns)} colunas")
    print(f"📊 Dataset final: {len(df)} semanas")

    # Verifica NaN antes de remover
    nan_counts = df.isna().sum()
    print(f"🔍 Debug - Colunas com NaN:")
    for col, count in nan_counts[nan_counts > 0].items():
        print(f"  {col}: {count} valores ausentes")

    # Remove linhas com NaN remanescentes (só nas features importantes)
    critical_cols = ["casos", "tempmed", "umidmed", "data_iniSE"]
    df = df.dropna(subset=critical_cols)
    
    print(f"📊 Após remover NaN: {len(df)} semanas")

    return df


# ════════════════════════════════════════════════════════════════════════════
# ETAPA 3: PREPARAÇÃO DOS DADOS PARA ML
# ════════════════════════════════════════════════════════════════════════════


def prepare_train_test_split(
    df: pd.DataFrame, test_year: int = 2024
) -> Tuple[pd.DataFrame, pd.DataFrame, pd.Series, pd.Series]:
    """
    Separa dados em treino e teste (temporal split).

    Estratégia:
        - Treino: Todos os anos ANTES do test_year
        - Teste: Apenas o test_year
        - Validação temporal (não shuffled)

    Args:
        df: DataFrame com features
        test_year: Ano para conjunto de teste

    Returns:
        Tupla (X_train, X_test, y_train, y_test)
    """
    print("\n" + "=" * 80)
    print("ETAPA 3: PREPARAÇÃO TREINO/TESTE")
    print("=" * 80)

    # Adiciona coluna de ano
    df["ano"] = df["data_iniSE"].dt.year

    # Separa treino e teste
    train_df = df[df["ano"] < test_year].copy()
    test_df = df[df["ano"] == test_year].copy()

    print(f"📅 Treino: {train_df['ano'].min()}-{train_df['ano'].max()} ({len(train_df)} semanas)")
    print(f"📅 Teste: {test_df['ano'].min()}-{test_df['ano'].max()} ({len(test_df)} semanas)")

    # Features para o modelo (remove colunas não numéricas)
    feature_cols = [
        "tempmin",
        "tempmed",
        "tempmax",
        "umidmin",
        "umidmed",
        "umidmax",
        "casos_semana_anterior",
        "casos_2sem_anterior",
        "casos_3sem_anterior",
        "casos_4sem_anterior",
        "casos_media_4sem",
        "temp_media_movel_4sem",
        "umid_media_movel_4sem",
        "sazonalidade_sen",
        "sazonalidade_cos",
        "amplitude_termica",
        "amplitude_umidade",
        "tendencia",
        "temp_umid_interacao",
        "semana_do_ano",
    ]

    # Garante que todas as features existem
    feature_cols = [col for col in feature_cols if col in df.columns]

    X_train = train_df[feature_cols]
    y_train = train_df["casos"]

    X_test = test_df[feature_cols]
    y_test = test_df["casos"]

    print(f"✅ Features selecionadas: {len(feature_cols)}")
    print(f"📊 Shape treino: {X_train.shape}")
    print(f"📊 Shape teste: {X_test.shape}")

    return X_train, X_test, y_train, y_test


# ════════════════════════════════════════════════════════════════════════════
# ETAPA 4: TREINAMENTO DO MODELO
# ════════════════════════════════════════════════════════════════════════════


def train_model(
    X_train: pd.DataFrame, y_train: pd.Series
) -> Tuple[XGBRegressor, StandardScaler, list]:
    """
    Treina modelo XGBoost com validação cruzada.

    Hiperparâmetros otimizados para:
        - Previsão de séries temporais
        - Dados de saúde pública (volatilidade)
        - Evitar overfitting

    Args:
        X_train: Features de treino
        y_train: Target de treino

    Returns:
        Tupla (modelo treinado, scaler, feature_names)
    """
    print("\n" + "=" * 80)
    print("ETAPA 4: TREINAMENTO DO MODELO")
    print("=" * 80)

    # ────────────────────────────────────────────────────────────────────────
    # 4.1 Normalização
    # ────────────────────────────────────────────────────────────────────────
    print("⚖️  Normalizando features (StandardScaler)...")

    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)

    # ────────────────────────────────────────────────────────────────────────
    # 4.2 Treinamento com XGBoost
    # ────────────────────────────────────────────────────────────────────────
    print("🤖 Treinando XGBoost Regressor...")

    model = XGBRegressor(
        n_estimators=200,  # Número de árvores
        max_depth=6,  # Profundidade máxima
        learning_rate=0.1,  # Taxa de aprendizado
        subsample=0.8,  # Fração de amostras por árvore
        colsample_bytree=0.8,  # Fração de features por árvore
        random_state=RANDOM_STATE,
        n_jobs=-1,  # Usa todos os cores
        verbosity=0,  # Silencioso
    )

    model.fit(X_train_scaled, y_train)

    # ────────────────────────────────────────────────────────────────────────
    # 4.3 Validação Cruzada (Time Series Split)
    # ────────────────────────────────────────────────────────────────────────
    print("📊 Validação cruzada (Time Series Split)...")

    tscv = TimeSeriesSplit(n_splits=5)
    cv_scores = cross_val_score(
        model, X_train_scaled, y_train, cv=tscv, scoring="neg_mean_absolute_error", n_jobs=-1
    )

    cv_mae = -cv_scores.mean()
    cv_std = cv_scores.std()

    print(f"   MAE médio (CV): {cv_mae:.2f} ± {cv_std:.2f} casos")

    # ────────────────────────────────────────────────────────────────────────
    # 4.4 Feature Importance
    # ────────────────────────────────────────────────────────────────────────
    feature_importance = list(
        zip(X_train.columns, model.feature_importances_)
    )
    feature_importance.sort(key=lambda x: x[1], reverse=True)

    print("\n📈 Top 5 Features Mais Importantes:")
    for feat, imp in feature_importance[:5]:
        print(f"   {feat:30s} → {imp:.4f}")

    return model, scaler, list(X_train.columns)


# ════════════════════════════════════════════════════════════════════════════
# ETAPA 5: VALIDAÇÃO E MÉTRICAS
# ════════════════════════════════════════════════════════════════════════════


def evaluate_model(
    model: XGBRegressor,
    scaler: StandardScaler,
    X_test: pd.DataFrame,
    y_test: pd.Series,
) -> Dict[str, float]:
    """
    Avalia performance do modelo no conjunto de teste.

    Métricas calculadas:
        - MAE (Mean Absolute Error): Erro médio em casos
        - RMSE (Root Mean Squared Error): Penaliza erros grandes
        - R² (Coefficient of Determination): Qualidade do ajuste

    Args:
        model: Modelo treinado
        scaler: Scaler ajustado
        X_test: Features de teste
        y_test: Target de teste

    Returns:
        Dict com métricas de performance
    """
    print("\n" + "=" * 80)
    print("ETAPA 5: VALIDAÇÃO DO MODELO")
    print("=" * 80)

    X_test_scaled = scaler.transform(X_test)
    y_pred = model.predict(X_test_scaled)

    # Calcula métricas
    mae = mean_absolute_error(y_test, y_pred)
    rmse = np.sqrt(mean_squared_error(y_test, y_pred))
    r2 = r2_score(y_test, y_pred)

    print("📊 MÉTRICAS DE PERFORMANCE:")
    print(f"   MAE (Erro Médio Absoluto):  {mae:.2f} casos")
    print(f"   RMSE (Raiz do Erro Quad.):  {rmse:.2f} casos")
    print(f"   R² (Coef. Determinação):    {r2:.4f}")

    # Análise de resíduos
    residuals = y_test - y_pred
    print(f"\n📉 ANÁLISE DE RESÍDUOS:")
    print(f"   Média dos resíduos:         {residuals.mean():.2f}")
    print(f"   Desvio padrão:              {residuals.std():.2f}")
    print(f"   Min erro:                   {residuals.min():.2f}")
    print(f"   Max erro:                   {residuals.max():.2f}")

    return {"mae": mae, "rmse": rmse, "r2": r2}


# ════════════════════════════════════════════════════════════════════════════
# ETAPA 6: EXPORTAÇÃO
# ════════════════════════════════════════════════════════════════════════════


def save_model_and_metadata(
    model: XGBRegressor,
    scaler: StandardScaler,
    feature_names: list,
    metrics: Dict[str, float],
) -> None:
    """
    Salva modelo treinado e metadados.

    Arquivos gerados:
        - dengo_model.joblib: Modelo completo (XGBoost + Scaler + Features)
        - model_metadata.json: Informações de treino e performance

    Args:
        model: Modelo treinado
        scaler: Scaler ajustado
        feature_names: Lista de nomes das features
        metrics: Métricas de performance
    """
    print("\n" + "=" * 80)
    print("ETAPA 6: EXPORTAÇÃO DO MODELO")
    print("=" * 80)

    # Cria diretório de saída
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # ────────────────────────────────────────────────────────────────────────
    # 6.1 Salvar modelo (joblib)
    # ────────────────────────────────────────────────────────────────────────
    print(f"💾 Salvando modelo em: {MODEL_PATH}")

    model_artifact = {
        "model": model,
        "scaler": scaler,
        "feature_names": feature_names,
        "version": "2.0.0",
        "trained_at": datetime.now().isoformat(),
        "metrics": metrics,
    }

    joblib.dump(model_artifact, MODEL_PATH, compress=3)

    file_size_mb = MODEL_PATH.stat().st_size / (1024 * 1024)
    print(f"   ✓ Tamanho: {file_size_mb:.2f} MB")

    # ────────────────────────────────────────────────────────────────────────
    # 6.2 Salvar metadata (JSON)
    # ────────────────────────────────────────────────────────────────────────
    print(f"📄 Salvando metadata em: {METADATA_PATH}")

    metadata = {
        "model_version": "2.0.0",
        "trained_at": datetime.now().strftime("%d/%m/%Y %H:%M:%S"),
        "trained_at_iso": datetime.now().isoformat(),
        "geocode": GEOCODE,
        "city": "Curitiba",
        "data_period": {"start": START_DATE, "end": END_DATE},
        "metrics": {
            "mae": round(metrics["mae"], 2),
            "rmse": round(metrics["rmse"], 2),
            "r2": round(metrics["r2"], 4),
        },
        "features_count": len(feature_names),
        "model_type": "XGBoost Regressor",
        "purpose": "Predição de casos de dengue baseado em clima e histórico",
    }

    with open(METADATA_PATH, "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2, ensure_ascii=False)

    print(f"   ✓ Metadata salvo")


# ════════════════════════════════════════════════════════════════════════════
# PIPELINE PRINCIPAL
# ════════════════════════════════════════════════════════════════════════════


def main():
    """
    Executa pipeline completo de ETL e treinamento.

    Passos:
        1. Coleta dados históricos (InfoDengue API)
        2. Limpa e engenharia features
        3. Separa treino/teste
        4. Treina modelo XGBoost
        5. Valida performance
        6. Exporta modelo e metadata
    """
    print("\n")
    print("╔" + "═" * 78 + "╗")
    print("║" + " " * 20 + "DENGO - ML TRAINING PIPELINE" + " " * 30 + "║")
    print("║" + " " * 15 + "ETL + Feature Engineering + XGBoost" + " " * 28 + "║")
    print("╚" + "═" * 78 + "╝")
    print()

    try:
        # ETAPA 1: Coleta de dados
        df_raw = fetch_historical_data(GEOCODE, 2015, 2024)

        # ETAPA 2: Limpeza e feature engineering
        df_clean = clean_and_engineer_features(df_raw)

        # ETAPA 3: Preparação treino/teste
        X_train, X_test, y_train, y_test = prepare_train_test_split(df_clean, TEST_YEAR)

        # Validação de tamanho mínimo
        if len(X_train) < MIN_SAMPLES_TRAIN:
            raise ValueError(
                f"❌ Dados insuficientes para treino: {len(X_train)} < {MIN_SAMPLES_TRAIN}"
            )

        # ETAPA 4: Treinamento
        model, scaler, feature_names = train_model(X_train, y_train)

        # ETAPA 5: Validação
        metrics = evaluate_model(model, scaler, X_test, y_test)

        # ETAPA 6: Exportação
        save_model_and_metadata(model, scaler, feature_names, metrics)

        # ════════════════════════════════════════════════════════════════════
        # RESUMO FINAL
        # ════════════════════════════════════════════════════════════════════
        print("\n" + "=" * 80)
        print("✅ PIPELINE CONCLUÍDO COM SUCESSO!")
        print("=" * 80)
        print(f"🎯 MAE Final: {metrics['mae']:.2f} casos")
        print(f"📁 Modelo salvo em: {MODEL_PATH}")
        print(f"📄 Metadata em: {METADATA_PATH}")
        print(f"🚀 Pronto para produção!")
        print("=" * 80)

    except Exception as e:
        print(f"\n❌ ERRO NO PIPELINE: {e}")
        import traceback

        traceback.print_exc()
        raise


if __name__ == "__main__":
    main()
