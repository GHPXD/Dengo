import '../../config/app_config.dart';

/// Enum para níveis de risco de dengue.
///
/// Baseado em thresholds epidemiológicos (casos por 100k habitantes).
/// Cada nível possui cor semântica associada para visualização.
enum RiskLevel {
  /// Risco baixo (< 100 casos/100k hab) - situação controlada
  low,

  /// Risco médio (100-300 casos/100k hab) - requer atenção
  medium,

  /// Risco alto (> 300 casos/100k hab) - situação crítica/surto
  high,
}

/// Extensões para facilitar uso do enum RiskLevel.
extension RiskLevelExtensions on RiskLevel {
  /// Retorna label descritivo em português.
  String get label {
    switch (this) {
      case RiskLevel.low:
        return 'Risco Baixo';
      case RiskLevel.medium:
        return 'Risco Médio';
      case RiskLevel.high:
        return 'Risco Alto';
    }
  }

  /// Retorna cor semântica do nível de risco.
  /// Verde (seguro) | Amarelo (atenção) | Vermelho (perigo)
  AppColorsClass get color {
    switch (this) {
      case RiskLevel.low:
        return const AppColorsClass.success();
      case RiskLevel.medium:
        return const AppColorsClass.warning();
      case RiskLevel.high:
        return const AppColorsClass.danger();
    }
  }

  /// Retorna descrição detalhada do nível.
  String get description {
    switch (this) {
      case RiskLevel.low:
        return 'Situação controlada. Mantenha os cuidados de prevenção.';
      case RiskLevel.medium:
        return 'Atenção necessária. Reforce medidas de combate ao mosquito.';
      case RiskLevel.high:
        return 'Situação crítica! Procure orientação médica ao menor sintoma.';
    }
  }

  /// Calcula nível de risco baseado em taxa de incidência.
  ///
  /// [incidenceRate]: Casos por 100.000 habitantes
  static RiskLevel fromIncidenceRate(double incidenceRate) {
    if (incidenceRate < AppConfig.lowRiskThreshold) {
      return RiskLevel.low;
    } else if (incidenceRate < AppConfig.mediumRiskThreshold) {
      return RiskLevel.medium;
    } else {
      return RiskLevel.high;
    }
  }
}

/// Helper class para acessar cores (workaround para constantes)
class AppColorsClass {
  final String name;
  final int value;

  const AppColorsClass.success()
      : name = 'success',
        value = 0xFF10B981;

  const AppColorsClass.warning()
      : name = 'warning',
        value = 0xFFF59E0B;

  const AppColorsClass.danger()
      : name = 'danger',
        value = 0xFFEF4444;
}
