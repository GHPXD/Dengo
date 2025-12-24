/// Constantes globais do aplicativo Dengo.
///
/// Agrupa valores fixos utilizados em múltiplas partes do código,
/// facilitando manutenção e evitando números mágicos (magic numbers).
class AppConstants {
  AppConstants._(); // Construtor privado

  // ══════════════════════════════════════════════════════════════════════════
  // SPACING E LAYOUT (Design System)
  // ══════════════════════════════════════════════════════════════════════════

  /// Espaçamento extra pequeno (4px)
  static const double spacingXs = 4.0;

  /// Espaçamento pequeno (8px)
  static const double spacingSm = 8.0;

  /// Espaçamento médio (16px)
  static const double spacingMd = 16.0;

  /// Espaçamento grande (24px)
  static const double spacingLg = 24.0;

  /// Espaçamento extra grande (32px)
  static const double spacingXl = 32.0;

  /// Espaçamento extra extra grande (48px)
  static const double spacingXxl = 48.0;

  // ══════════════════════════════════════════════════════════════════════════
  // BORDER RADIUS
  // ══════════════════════════════════════════════════════════════════════════

  /// Raio de borda pequeno (8px)
  static const double radiusSm = 8.0;

  /// Raio de borda médio (12px)
  static const double radiusMd = 12.0;

  /// Raio de borda grande (16px)
  static const double radiusLg = 16.0;

  /// Raio de borda extra grande (24px)
  static const double radiusXl = 24.0;

  /// Raio completo para círculos perfeitos
  static const double radiusFull = 9999.0; // Círculo perfeito

  // ══════════════════════════════════════════════════════════════════════════
  // ELEVATIONS (Material Design)
  // ══════════════════════════════════════════════════════════════════════════

  /// Elevação baixa (2dp) para elementos sutis
  static const double elevationLow = 2.0;

  /// Elevação média (4dp) para cards e botões
  static const double elevationMedium = 4.0;

  /// Elevação alta (8dp) para dialogs e modais
  static const double elevationHigh = 8.0;

  // ══════════════════════════════════════════════════════════════════════════
  // DURAÇÃO DE ANIMAÇÕES
  // ══════════════════════════════════════════════════════════════════════════

  /// Duração rápida para micointerações (200ms)
  static const int animationDurationFast = 200; // ms

  /// Duração normal para transições comuns (300ms)
  static const int animationDurationNormal = 300; // ms

  /// Duração lenta para animações complexas (500ms)
  static const int animationDurationSlow = 500; // ms

  // ══════════════════════════════════════════════════════════════════════════
  // TEMPORIZADORES
  // ══════════════════════════════════════════════════════════════════════════

  /// Duração do splash screen em segundos
  static const int splashDelaySeconds = 2;

  /// Tempo de debounce para campos de busca em milissegundos
  static const int searchDebounceMs = 500;

  // ══════════════════════════════════════════════════════════════════════════
  // ASPECTOS DO APLICATIVO
  // ══════════════════════════════════════════════════════════════════════════

  /// Largura máxima de conteúdo em telas grandes (web/tablet)
  static const double maxContentWidth = 1200.0;

  /// Padding horizontal padrão aplicado nas telas
  static const double defaultHorizontalPadding = 16.0;

  /// Padding vertical padrão aplicado nas telas
  static const double defaultVerticalPadding = 16.0;

  // ══════════════════════════════════════════════════════════════════════════
  // MENSAGENS PADRÃO
  // ══════════════════════════════════════════════════════════════════════════

  /// Mensagem genérica de erro
  static const String errorGeneric =
      'Algo deu errado. Por favor, tente novamente.';

  /// Mensagem de erro de conexão
  static const String errorNetwork =
      'Sem conexão com a internet. Verifique sua rede e tente novamente.';

  /// Mensagem de erro de timeout
  static const String errorTimeout =
      'A requisição demorou muito. Tente novamente.';

  /// Mensagem de carregamento padrão
  static const String loadingMessage = 'Carregando...';

  /// Mensagem quando não há dados disponíveis
  static const String noDataMessage = 'Nenhum dado disponível no momento.';
}
