import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/city_search_bar.dart';
import '../widgets/city_search_results.dart';

/// Tela de Onboarding - Seleção de Cidade.
///
/// Primeira tela que o usuário vê ao abrir o app pela primeira vez.
/// Permite buscar e selecionar a cidade para receber previsões de dengue.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header com ilustração e título
            SliverToBoxAdapter(
              child: _buildHeader(context),
            ),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultHorizontalPadding,
                ),
                child: CitySearchBar(),
              ),
            ),

            const SliverToBoxAdapter(
                child: SizedBox(height: AppConstants.spacingMd)),

            // Resultados da busca
            const CitySearchResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingXl),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppConstants.radiusXl),
          bottomRight: Radius.circular(AppConstants.radiusXl),
        ),
      ),
      child: Column(
        children: [
          // Logo/Ícone
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_city_rounded,
              size: 64,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // Título
          Text(
            'Bem-vindo ao\nDengo',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                ),
          ),

          const SizedBox(height: AppConstants.spacingMd),

          // Subtítulo
          Text(
            'Selecione sua cidade para receber\nprevisões de casos de dengue',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }
}
