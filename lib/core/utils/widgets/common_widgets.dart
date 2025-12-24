import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../theme/app_colors.dart';

/// Widget de loading customizado para o Dengo.
///
/// Exibe um CircularProgressIndicator com a cor primária do app
/// e uma mensagem opcional.
class AppLoadingIndicator extends StatelessWidget {
  /// Mensagem exibida abaixo do indicador de progresso
  final String? message;

  /// Cor customizada do indicador (padrão: AppColors.primary)
  final Color? color;

  /// Tamanho do indicador em pixels
  final double size;

  /// Cria um indicador de carregamento personalizado
  const AppLoadingIndicator({
    super.key,
    this.message,
    this.color,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              color: color ?? AppColors.primary,
              strokeWidth: 3.0,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              message!,
              // ignore: avoid_dynamic_calls
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget de erro customizado.
///
/// Exibe mensagem de erro com opção de retry.
class AppErrorWidget extends StatelessWidget {
  /// Mensagem de erro a ser exibida
  final String message;

  /// Callback chamado ao pressionar botão "Tentar Novamente"
  final VoidCallback? onRetry;

  /// Ícone exibido no topo do widget de erro
  final IconData icon;

  /// Cria um widget de erro
  const AppErrorWidget({
    required this.message, super.key,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.danger,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              message,
              // ignore: avoid_dynamic_calls
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppConstants.spacingLg),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget de estado vazio (sem dados).
///
/// Exibe quando não há dados para mostrar, mas não é um erro.
class AppEmptyState extends StatelessWidget {
  /// Mensagem explicativa sobre o estado vazio
  final String message;

  /// Ícone representando estado vazio
  final IconData icon;

  /// Widget de ação customizada (ex: botão)
  final Widget? action;

  /// Cria um widget de estado vazio
  const AppEmptyState({
    required this.message, super.key,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              message,
              // ignore: avoid_dynamic_calls
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppConstants.spacingLg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
