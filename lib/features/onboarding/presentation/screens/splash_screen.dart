import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/city_search_provider.dart';

/// Tela de Splash inicial.
///
/// Verifica se o usuário já selecionou uma cidade:
/// - Se SIM: Navega direto para Dashboard
/// - Se NÃO: Navega para Onboarding
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    // Aguarda tempo configurado (animação de splash)
    await Future.delayed(
      const Duration(seconds: AppConstants.splashDelaySeconds),
    );

    // Tenta carregar cidade salva
    await ref.read(selectedCityProvider.notifier).loadSavedCity();

    if (!mounted) return;

    final hasCity = ref.read(selectedCityProvider) != null;

    // Navega baseado se tem cidade salva
    if (hasCity) {
      context.go(AppRoutes.dashboard);
    } else {
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  size: 80,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              // App Name
              Text(
                'Dengo',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 16),

              // Tagline
              Text(
                'Previsão Inteligente • Saúde Pública',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
              ),

              const SizedBox(height: 48),

              // Loading indicator
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
