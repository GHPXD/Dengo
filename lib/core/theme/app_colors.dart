import 'package:flutter/material.dart';

/// Paleta de cores semânticas do Dengo.
///
/// Segue o conceito "Modern HealthTech" com:
/// - Base neutra (branco/cinza) para clareza e minimalismo
/// - Cores semânticas para níveis de risco de dengue
/// - Alto contraste para acessibilidade
///
/// As cores foram escolhidas para comunicar visualmente os níveis
/// de alerta epidemiológico de forma intuitiva ao usuário.
class AppColors {
  AppColors._(); // Construtor privado

  // ══════════════════════════════════════════════════════════════════════════
  // CORES PRINCIPAIS (Brand Identity)
  // ══════════════════════════════════════════════════════════════════════════

  /// Cor primária - Azul médico/saúde (confiança e tecnologia).
  static const Color primary = Color(0xFF2E8B8B);

  /// Cor primária escura - para gradientes e hover states.
  static const Color primaryDark = Color(0xFF1E7B7B);

  /// Cor secundária - Azul escuro para contraste.
  static const Color secondary = Color(0xFF1A4D5E);

  // ══════════════════════════════════════════════════════════════════════════
  // CORES SEMÂNTICAS (Níveis de Risco de Dengue)
  // ══════════════════════════════════════════════════════════════════════════

  /// Verde - Risco BAIXO (situação segura, poucos casos).
  static const Color success = Color(0xFF10B981);

  /// Tom claro de verde para fundos e chips de sucesso.
  static const Color successLight = Color(0xFFD1FAE5);

  /// Tom escuro de verde para textos e ícones.
  static const Color successDark = Color(0xFF059669);

  /// Amarelo/Laranja - Risco MÉDIO (atenção, monitoramento necessário).
  static const Color warning = Color(0xFFF59E0B);

  /// Tom claro de amarelo para fundos e chips de alerta.
  static const Color warningLight = Color(0xFFFEF3C7);

  /// Tom escuro de amarelo para textos e ícones.
  static const Color warningDark = Color(0xFFD97706);

  /// Vermelho - Risco ALTO (perigo, surto epidêmico).
  static const Color danger = Color(0xFFEF4444);

  /// Tom claro de vermelho para fundos e chips de perigo.
  static const Color dangerLight = Color(0xFFFEE2E2);

  /// Tom escuro de vermelho para textos e ícones.
  static const Color dangerDark = Color(0xFFDC2626);

  /// Azul - Informação (dicas, avisos informativos).
  static const Color info = Color(0xFF3B82F6);

  /// Tom claro de azul para fundos informativos.
  static const Color infoLight = Color(0xFFDBEAFE);

  /// Tom escuro de azul para textos informativos.
  static const Color infoDark = Color(0xFF2563EB);

  // ══════════════════════════════════════════════════════════════════════════
  // CORES NEUTRAS (Background, Surface, Text)
  // ══════════════════════════════════════════════════════════════════════════

  /// Background principal (branco puro).
  static const Color background = Color(0xFFFFFFFF);

  /// Surface secundária (cinza muito claro para cards).
  static const Color surface = Color(0xFFF9FAFB);

  /// Surface alternativa (cinza suave).
  static const Color surfaceAlt = Color(0xFFF3F4F6);

  // ──────────────────────────────────────────────────────────────────────────
  // HIERARQUIA DE TEXTO
  // ──────────────────────────────────────────────────────────────────────────

  /// Texto primário (preto suave, não puro para reduzir fadiga visual).
  static const Color textPrimary = Color(0xFF1F2937);

  /// Texto secundário (cinza médio).
  static const Color textSecondary = Color(0xFF6B7280);

  /// Texto terciário (cinza claro, hints e placeholders).
  static const Color textTertiary = Color(0xFF9CA3AF);

  /// Texto em superfícies escuras (branco).
  static const Color textOnDark = Color(0xFFFFFFFF);

  /// Texto escuro para títulos (azul escuro)
  static const Color textDark = Color(0xFF2E5C6E);

  /// Texto cinza para subtítulos
  static const Color textGrey = Color(0xFF4A5568);

  // ══════════════════════════════════════════════════════════════════════════
  // CORES DE ALERTA (Para cards e indicadores)
  // ══════════════════════════════════════════════════════════════════════════

  /// Alerta alto (vermelho coral)
  static const Color alertHigh = Color(0xFFFF6B6B);

  /// Alerta médio (coral claro)
  static const Color alertMedium = Color(0xFFFF8A80);

  /// Cor de fogo para ícones de calor
  static const Color fireColor = Color(0xFFFF6B6B);

  /// Background de informação (bege claro)
  static const Color infoBg = Color(0xFFFFF4EC);

  /// Background cinza claro
  static const Color bgGrey = Color(0xFFFAFAFA);

  /// Background de sucesso (verde claro)
  static const Color successBg = Color(0xFFE8F5E9);

  /// Background cinza neutro desativado
  static const Color disabledGrey = Color(0xFFBDBDBD);

  /// Background de chip/tag turquesa claro
  static const Color chipTurquoise = Color(0xFFD1F4F4);

  /// Background do chip turquesa escuro
  static const Color chipTurquoiseLight = Color(0xFFEFFAFA);

  /// Background de alerta warning suave
  static const Color alertWarningBg = Color(0xFFFFDAD6);

  /// Background de alerta warning mais claro
  static const Color alertWarningBgLight = Color(0xFFFFF5F3);

  /// Background vermelho muito claro para indicadores negativos
  static const Color dangerBgLight = Color(0xFFFFEBEE);

  // ══════════════════════════════════════════════════════════════════════════
  // ELEMENTOS DE UI (Bordas, Dividers, Shadows)
  // ══════════════════════════════════════════════════════════════════════════

  /// Bordas e dividers sutis.
  static const Color divider = Color(0xFFE5E7EB);

  /// Sombra para cards (usada com opacity).
  static const Color shadow = Color(0xFF000000);

  /// Sombra padrão para cards
  static const BoxShadow cardShadow = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.05),
    blurRadius: 10,
    offset: Offset(0, 4),
  );

  /// Gradiente de cores para legenda de heatmap
  static const List<Color> heatmapGradient = [
    Color(0xFF10B981), // Verde
    Color(0xFFFBBF24), // Amarelo
    Color(0xFFFF8A80), // Laranja
    Color(0xFFFF6B6B), // Vermelho
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS - Gradientes para Hero Sections
  // ══════════════════════════════════════════════════════════════════════════

  /// Gradiente de risco baixo (verde suave).
  static const LinearGradient lowRiskGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente de risco médio (amarelo/laranja).
  static const LinearGradient mediumRiskGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente de risco alto (vermelho intenso).
  static const LinearGradient highRiskGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente neutro (azul primário).
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2E7D99), Color(0xFF1A4D5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}