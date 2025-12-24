import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/heatmap/presentation/screens/heatmap_screen.dart';
import '../../features/trends/presentation/screens/trends_screen.dart';
import '../../features/city_detail/presentation/screens/city_detail_screen.dart';

part 'app_router.g.dart';

/// Configuração de rotas da aplicação usando GoRouter.
///
/// GoRouter oferece:
/// - Navegação declarativa
/// - Deep linking automático
/// - Rotas tipadas e type-safe
/// - Suporte nativo para Web (URLs)
///
/// As rotas são gerenciadas via Riverpod para facilitar
/// navegação programática e guarda de rotas.
@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      // ════════════════════════════════════════════════════════════════════
      // SPLASH / ONBOARDING
      // ════════════════════════════════════════════════════════════════════
      GoRoute(
        path: AppRoutes.splash,
        name: AppRouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: AppRoutes.onboarding,
        name: AppRouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ════════════════════════════════════════════════════════════════════
      // MAIN NAVIGATION (Dashboard, Map, Education)
      // ════════════════════════════════════════════════════════════════════
      GoRoute(
        path: AppRoutes.dashboard,
        name: AppRouteNames.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),

      GoRoute(
        path: AppRoutes.heatmap,
        name: AppRouteNames.heatmap,
        builder: (context, state) => const HeatmapScreen(),
      ),

      GoRoute(
        path: AppRoutes.trends,
        name: AppRouteNames.trends,
        builder: (context, state) => const TrendsScreen(),
      ),

      GoRoute(
        path: AppRoutes.cityDetail,
        name: AppRouteNames.cityDetail,
        builder: (context, state) => const CityDetailScreen(),
      ),
    ],

    // Tratamento de erros de rota
    errorBuilder: (context, state) => ErrorScreen(
      error: state.error.toString(),
    ),
  );
}

/// Definição de caminhos (paths) das rotas.
///
/// Caminhos de rotas do aplicativo.
///
/// Centralizada para evitar typos e facilitar refatoração.
class AppRoutes {
  AppRoutes._();

  /// Rota da tela de splash (inicial)
  static const String splash = '/';

  /// Rota da tela de onboarding
  static const String onboarding = '/onboarding';

  /// Rota da tela de dashboard (principal)
  static const String dashboard = '/dashboard';

  /// Rota da tela de mapa de calor
  static const String heatmap = '/heatmap';

  /// Rota da tela de tendências/gráficos
  static const String trends = '/trends';

  /// Rota da tela de detalhes da cidade
  static const String cityDetail = '/city-detail';
}

/// Nomes das rotas para navegação type-safe.
///
/// Usado com context.goNamed() para navegação declarativa.
class AppRouteNames {
  AppRouteNames._();

  /// Nome da rota splash
  static const String splash = 'splash';

  /// Nome da rota onboarding
  static const String onboarding = 'onboarding';

  /// Nome da rota dashboard
  static const String dashboard = 'dashboard';

  /// Nome da rota heatmap
  static const String heatmap = 'heatmap';

  /// Nome da rota trends
  static const String trends = 'trends';

  /// Nome da rota city detail
  static const String cityDetail = 'city-detail';
}

/// Tela de erro genérica para erros de navegação
class ErrorScreen extends StatelessWidget {
  /// Mensagem de erro a ser exibida
  final String error;

  /// Cria tela de erro
  const ErrorScreen({
    required this.error, super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erro de navegação: $error'),
          ],
        ),
      ),
    );
  }
}
