import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Widget de estado de erro padronizado.
///
/// Exibe uma mensagem de erro com ícone e opcionalmente um botão
/// para tentar novamente.
class AppErrorWidget extends StatelessWidget {
  /// Mensagem de erro principal.
  final String message;

  /// Mensagem secundária com mais detalhes (opcional).
  final String? details;

  /// Callback para o botão "Tentar novamente" (opcional).
  /// Se não fornecido, o botão não é exibido.
  final VoidCallback? onRetry;

  /// Texto do botão de retry (padrão: "Tentar Novamente").
  final String retryText;

  /// Ícone a ser exibido (padrão: error_outline).
  final IconData icon;

  /// Cor do ícone (padrão: vermelho).
  final Color? iconColor;

  /// Cria um widget de erro.
  const AppErrorWidget({
    super.key,
    this.message = 'Erro ao carregar dados',
    this.details,
    this.onRetry,
    this.retryText = 'Tentar Novamente',
    this.icon = Icons.error_outline,
    this.iconColor,
  });

  /// Cria um widget de erro de conexão.
  factory AppErrorWidget.connection({
    VoidCallback? onRetry,
  }) {
    return AppErrorWidget(
      message: 'Erro de Conexão',
      details: 'Verifique sua conexão com a internet e tente novamente.',
      icon: Icons.wifi_off,
      onRetry: onRetry,
    );
  }

  /// Cria um widget de erro de timeout.
  factory AppErrorWidget.timeout({
    VoidCallback? onRetry,
  }) {
    return AppErrorWidget(
      message: 'Tempo Esgotado',
      details: 'A requisição demorou muito. Tente novamente.',
      icon: Icons.timer_off,
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: iconColor ?? Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            if (details != null) ...[
              const SizedBox(height: 8),
              Text(
                details!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
