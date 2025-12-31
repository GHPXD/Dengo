import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Widget de indicador de carregamento padronizado.
///
/// Exibe um [CircularProgressIndicator] centralizado com a cor primária
/// do aplicativo. Pode opcionalmente exibir uma mensagem de texto.
class AppLoadingIndicator extends StatelessWidget {
  /// Mensagem opcional a ser exibida abaixo do indicador.
  final String? message;

  /// Tamanho do indicador de progresso.
  final double size;

  /// Cor do indicador (padrão: [AppColors.primary]).
  final Color? color;

  /// Cria um indicador de carregamento.
  const AppLoadingIndicator({
    super.key,
    this.message,
    this.size = 40.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              color: color ?? AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
