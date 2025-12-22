/// Constantes globais do aplicativo Dengo.
///
/// Agrupa valores fixos utilizados em múltiplas partes do código,
/// facilitando manutenção e evitando números mágicos (magic numbers).
class AppConstants {
  AppConstants._(); // Construtor privado

  // ══════════════════════════════════════════════════════════════════════════
  // SPACING E LAYOUT (Design System)
  // ══════════════════════════════════════════════════════════════════════════

  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // ══════════════════════════════════════════════════════════════════════════
  // BORDER RADIUS
  // ══════════════════════════════════════════════════════════════════════════

  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 9999.0; // Círculo perfeito

  // ══════════════════════════════════════════════════════════════════════════
  // ELEVATIONS (Material Design)
  // ══════════════════════════════════════════════════════════════════════════

  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;

  // ══════════════════════════════════════════════════════════════════════════
  // DURAÇÃO DE ANIMAÇÕES
  // ══════════════════════════════════════════════════════════════════════════

  static const int animationDurationFast = 200; // ms
  static const int animationDurationNormal = 300; // ms
  static const int animationDurationSlow = 500; // ms

  // ══════════════════════════════════════════════════════════════════════════
  // TEMPORIZADORES
  // ══════════════════════════════════════════════════════════════════════════

  /// Duração do splash screen em segundos
  static const int splashDelaySeconds = 2;

  /// Debounce para busca em milissegundos
  static const int searchDebounceMs = 500;

  // ══════════════════════════════════════════════════════════════════════════
  // ASPECTOS DO APLICATIVO
  // ══════════════════════════════════════════════════════════════════════════

  /// Largura máxima para conteúdo em telas grandes (web/tablet)
  static const double maxContentWidth = 1200.0;

  /// Padding horizontal padrão das telas
  static const double defaultHorizontalPadding = 16.0;

  /// Padding vertical padrão das telas
  static const double defaultVerticalPadding = 16.0;

  // ══════════════════════════════════════════════════════════════════════════
  // MENSAGENS PADRÃO
  // ══════════════════════════════════════════════════════════════════════════

  static const String errorGeneric =
      'Algo deu errado. Por favor, tente novamente.';

  static const String errorNetwork =
      'Sem conexão com a internet. Verifique sua rede e tente novamente.';

  static const String errorTimeout =
      'A requisição demorou muito. Tente novamente.';

  static const String loadingMessage = 'Carregando...';

  static const String noDataMessage = 'Nenhum dado disponível no momento.';
}
