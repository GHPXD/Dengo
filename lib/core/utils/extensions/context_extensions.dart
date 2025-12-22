import 'package:flutter/material.dart';

/// Extensões úteis para BuildContext.
///
/// Facilitam acesso a recursos do tema, navegação e dimensões
/// de tela sem precisar repetir código boilerplate.
extension BuildContextExtensions on BuildContext {
  // ══════════════════════════════════════════════════════════════════════════
  // TEMA
  // ══════════════════════════════════════════════════════════════════════════

  /// Acesso rápido ao ThemeData atual.
  ThemeData get theme => Theme.of(this);

  /// Acesso rápido ao ColorScheme.
  ColorScheme get colorScheme => theme.colorScheme;

  /// Acesso rápido ao TextTheme.
  TextTheme get textTheme => theme.textTheme;

  // ══════════════════════════════════════════════════════════════════════════
  // DIMENSÕES DA TELA
  // ══════════════════════════════════════════════════════════════════════════

  /// Largura da tela.
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Altura da tela.
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Verifica se é uma tela pequena (mobile portrait).
  bool get isSmallScreen => screenWidth < 600;

  /// Verifica se é uma tela média (tablet).
  bool get isMediumScreen => screenWidth >= 600 && screenWidth < 1200;

  /// Verifica se é uma tela grande (desktop/web).
  bool get isLargeScreen => screenWidth >= 1200;

  /// Padding das áreas seguras (notch, barra de navegação, etc).
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;

  /// Altura da barra de status.
  double get statusBarHeight => MediaQuery.of(this).padding.top;

  /// Altura da barra de navegação inferior.
  double get bottomBarHeight => MediaQuery.of(this).padding.bottom;

  // ══════════════════════════════════════════════════════════════════════════
  // NAVEGAÇÃO
  // ══════════════════════════════════════════════════════════════════════════

  /// Volta para a tela anterior.
  void pop<T>([T? result]) => Navigator.of(this).pop(result);

  /// Verifica se pode voltar (há rota anterior).
  bool get canPop => Navigator.of(this).canPop();

  // ══════════════════════════════════════════════════════════════════════════
  // SNACKBARS E DIÁLOGOS
  // ══════════════════════════════════════════════════════════════════════════

  /// Mostra SnackBar com mensagem.
  void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
      ),
    );
  }

  /// Mostra SnackBar de erro (vermelho).
  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Mostra SnackBar de sucesso (verde).
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TECLADO
  // ══════════════════════════════════════════════════════════════════════════

  /// Fecha o teclado.
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }

  /// Verifica se o teclado está visível.
  bool get isKeyboardVisible => MediaQuery.of(this).viewInsets.bottom > 0;
}
