import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/heatmap/presentation/screens/heatmap_screen.dart';
import '../../features/education/presentation/screens/education_screen.dart';

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
GoRouter appRouter(AppRouterRef ref) {
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
        path: AppRoutes.education,
        name: AppRouteNames.education,
        builder: (context, state) => const EducationScreen(),
      ),

      // ════════════════════════════════════════════════════════════════════
      // PREDICTION DETAILS
      // ════════════════════════════════════════════════════════════════════
      GoRoute(
        path: '${AppRoutes.predictionDetails}/:cityId',
        name: AppRouteNames.predictionDetails,
        builder: (context, state) {
          final cityId = state.pathParameters['cityId']!;
          return PredictionDetailsScreen(cityId: cityId);
        },
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
/// Centralizadas para evitar typos e facilitar refatoração.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String dashboard = '/dashboard';
  static const String heatmap = '/heatmap';
  static const String education = '/education';
  static const String predictionDetails = '/prediction';
}

/// Nomes das rotas para navegação type-safe.
///
/// Usado com context.goNamed() para navegação declarativa.
class AppRouteNames {
  AppRouteNames._();

  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String dashboard = 'dashboard';
  static const String heatmap = 'heatmap';
  static const String education = 'education';
  static const String predictionDetails = 'prediction-details';
}

// ══════════════════════════════════════════════════════════════════════════
// PLACEHOLDER SCREENS (Prediction Details - temporário)
// ══════════════════════════════════════════════════════════════════════════

class PredictionDetailsScreen extends StatelessWidget {
  final String cityId;

  const PredictionDetailsScreen({
    super.key,
    required this.cityId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Prediction Details for city: $cityId')),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;

  const ErrorScreen({
    super.key,
    required this.error,
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
