/// Enum para níveis de risco de dengue.
///
/// Centraliza thresholds epidemiológicos (casos por 100k habitantes).
/// Cada nível possui cor semântica associada para visualização.
/// 
/// Baseado nos critérios da OMS:
/// - Baixo: < 100 casos/100mil hab
/// - Médio: 100-300 casos/100mil hab
/// - Alto: > 300 casos/100mil hab
enum RiskLevel {
  /// Risco baixo (< 100 casos/100k hab) - situação controlada
  low,

  /// Risco médio (100-300 casos/100k hab) - requer atenção
  medium,

  /// Risco alto (> 300 casos/100k hab) - situação crítica/surto
  high;

  // ══════════════════════════════════════════════════════════════════════════
  // THRESHOLDS EPIDEMIOLÓGICOS (Fonte Única de Verdade)
  // ══════════════════════════════════════════════════════════════════════════

  /// Threshold de risco baixo (verde) - casos por 100k habitantes
  static const double lowThreshold = 100.0;

  /// Threshold de risco médio (amarelo) - casos por 100k habitantes
  static const double mediumThreshold = 300.0;

  /// Threshold de risco alto (vermelho) - casos por 100k habitantes
  /// Valores acima deste são considerados situação crítica/surto
  static const double highThreshold = 300.0;

  /// Retorna a cor correspondente ao nível de risco (valor ARGB int)
  int get color {
    switch (this) {
      case RiskLevel.low:
        return 0xFF10B981; // Verde
      case RiskLevel.medium:
        return 0xFFFFA726; // Laranja
      case RiskLevel.high:
        return 0xFFEF4444; // Vermelho
    }
  }

  /// Retorna o rótulo do nível de risco
  String get label {
    switch (this) {
      case RiskLevel.low:
        return 'Baixo';
      case RiskLevel.medium:
        return 'Médio';
      case RiskLevel.high:
        return 'Alto';
    }
  }

  /// Retorna label descritivo completo em português.
  String get fullLabel {
    switch (this) {
      case RiskLevel.low:
        return 'Risco Baixo';
      case RiskLevel.medium:
        return 'Risco Médio';
      case RiskLevel.high:
        return 'Risco Alto';
    }
  }

  /// Retorna nome simples do enum (baixo, médio, alto).
  String get displayName {
    switch (this) {
      case RiskLevel.low:
        return 'baixo';
      case RiskLevel.medium:
        return 'médio';
      case RiskLevel.high:
        return 'alto';
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

  /// Cria RiskLevel a partir de uma string ("baixo", "medio", "alto")
  static RiskLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'baixo':
      case 'low':
        return RiskLevel.low;
      case 'medio':
      case 'médio':
      case 'medium':
        return RiskLevel.medium;
      case 'alto':
      case 'high':
      case 'muito_alto':
      case 'very_high':
        return RiskLevel.high;
      default:
        return RiskLevel.low;
    }
  }

  /// Converte para string ("baixo", "medio", "alto")
  String toApiString() {
    switch (this) {
      case RiskLevel.low:
        return 'baixo';
      case RiskLevel.medium:
        return 'medio';
      case RiskLevel.high:
        return 'alto';
    }
  }

  /// Calcula nível de risco baseado em taxa de incidência.
  ///
  /// [incidenceRate]: Casos por 100.000 habitantes
  static RiskLevel fromIncidenceRate(double incidenceRate) {
    if (incidenceRate < RiskLevel.lowThreshold) {
      return RiskLevel.low;
    } else if (incidenceRate < RiskLevel.mediumThreshold) {
      return RiskLevel.medium;
    } else {
      return RiskLevel.high;
    }
  }
}
