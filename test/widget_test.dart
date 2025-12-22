/// Testes de widget para Dengo.
///
/// Verifica que os principais componentes da aplicação
/// renderizam corretamente.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dengue_predict/core/theme/app_theme.dart';
import 'package:dengue_predict/core/utils/widgets/common_widgets.dart';

void main() {
  group('Common Widgets Tests', () {
    testWidgets('AppLoadingIndicator renderiza corretamente',
        (WidgetTester tester) async {
      // Build widget
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppLoadingIndicator(),
          ),
        ),
      );

      // Verifica que CircularProgressIndicator está presente
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AppErrorWidget exibe mensagem de erro',
        (WidgetTester tester) async {
      const errorMessage = 'Erro de teste';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppErrorWidget(message: errorMessage),
          ),
        ),
      );

      // Verifica que a mensagem de erro aparece
      expect(find.text(errorMessage), findsOneWidget);
      // Verifica ícone de erro
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('AppEmptyState exibe mensagem vazia',
        (WidgetTester tester) async {
      const emptyMessage = 'Nenhum item encontrado';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppEmptyState(message: emptyMessage),
          ),
        ),
      );

      // Verifica mensagem vazia
      expect(find.text(emptyMessage), findsOneWidget);
      // Verifica ícone
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });
  });

  group('Theme Tests', () {
    test('AppTheme tem configuração light theme', () {
      final theme = AppTheme.lightTheme;

      // Verifica que tema foi criado
      expect(theme, isA<ThemeData>());
      // Verifica cor primária
      expect(theme.primaryColor, isNotNull);
    });
  });
}
