import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/widgets/common_widgets.dart';
import '../../domain/entities/city.dart';
import '../providers/city_search_provider.dart';

/// Widget que exibe resultados da busca de cidades.
///
/// Gerencia os diferentes estados:
/// - Initial: Mensagem de instrução
/// - Loading: Skeleton loading
/// - Loaded: Lista de cidades
/// - Error: Mensagem de erro
class CitySearchResults extends ConsumerWidget {
  const CitySearchResults({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(citySearchProvider);

    return searchState.when(
      initial: () => _buildInitialState(context),
      loading: () => const SliverToBoxAdapter(
        child: AppLoadingIndicator(message: 'Buscando cidades...'),
      ),
      loaded: (cities) => _buildCityList(context, ref, cities),
      error: (message) => SliverToBoxAdapter(
        child: AppErrorWidget(
          message: message,
          onRetry: () {
            // Retry com última query
          },
        ),
      ),
    );
  }

  Widget _buildInitialState(BuildContext context) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_rounded,
                size: 80,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppConstants.spacingLg),
              Text(
                'Digite o nome da sua cidade',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                'Use a barra de busca acima para encontrar\nsua cidade e começar a usar o app',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityList(
      BuildContext context, WidgetRef ref, List<City> cities) {
    if (cities.isEmpty) {
      return const SliverFillRemaining(
        child: AppEmptyState(
          message: 'Nenhuma cidade encontrada.\nTente outro termo de busca.',
          icon: Icons.location_off_rounded,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultHorizontalPadding,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final city = cities[index];
            return CityListTile(
              city: city,
              onTap: () => _onCitySelected(context, ref, city),
            );
          },
          childCount: cities.length,
        ),
      ),
    );
  }

  Future<void> _onCitySelected(
    BuildContext context,
    WidgetRef ref,
    City city,
  ) async {
    // Seleciona a cidade
    ref.read(selectedCityProvider.notifier).selectCity(city);

    // Debug
    print('🏙️ Cidade selecionada: ${city.name} (ID: ${city.id})');

    // Salva localmente
    final saved = await ref.read(selectedCityProvider.notifier).saveCity();

    // Debug
    print('💾 Cidade salva: $saved');

    if (!context.mounted) return;

    if (saved) {
      // Debug
      print('🚀 Navegando para dashboard...');
      // Navega para Dashboard
      context.go(AppRoutes.dashboard);
    } else {
      // Mostra erro
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao salvar cidade. Tente novamente.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

/// Widget individual de cidade na lista.
class CityListTile extends StatelessWidget {
  final City city;
  final VoidCallback onTap;

  const CityListTile({
    super.key,
    required this.city,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Row(
            children: [
              // Ícone
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),

              const SizedBox(width: AppConstants.spacingMd),

              // Informações da cidade
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      city.fullName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pop: ${_formatPopulation(city.population)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),

              // Seta
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPopulation(int population) {
    if (population >= 1000000) {
      return '${(population / 1000000).toStringAsFixed(1)}M';
    } else if (population >= 1000) {
      return '${(population / 1000).toStringAsFixed(0)}k';
    }
    return population.toString();
  }
}
