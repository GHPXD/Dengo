/// Nível de risco de dengue para uma cidade.
///
/// Baseado nos critérios da OMS:
/// - Baixo: < 100 casos/100mil hab
/// - Médio: 100-300 casos/100mil hab
/// - Alto: > 300 casos/100mil hab
enum RiskLevel {
  /// Baixo risco (< 100 casos/100mil)
  low,

  /// Médio risco (100-300 casos/100mil)
  medium,

  /// Alto risco (> 300 casos/100mil)
  high;

  /// Retorna a cor correspondente ao nível de risco
  int get color {
    switch (this) {
      case RiskLevel.low:
        return 0xFF4CAF50; // Verde
      case RiskLevel.medium:
        return 0xFFFFA726; // Laranja
      case RiskLevel.high:
        return 0xFFE53935; // Vermelho
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

  /// Cria RiskLevel a partir de uma string ("baixo", "medio", "alto")
  static RiskLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'baixo':
        return RiskLevel.low;
      case 'medio':
        return RiskLevel.medium;
      case 'alto':
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
}
