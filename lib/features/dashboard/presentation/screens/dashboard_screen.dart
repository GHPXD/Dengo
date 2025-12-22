import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/helpers/time_helpers.dart';
import '../../../../core/utils/widgets/app_bottom_nav.dart';
import '../../../../core/utils/widgets/common_widgets.dart';
import '../../../onboarding/presentation/providers/city_search_provider.dart';
import '../providers/dashboard_data_provider.dart';
import '../widgets/dashboard_stats_card.dart';
import '../widgets/quick_actions_section.dart';
import '../widgets/risk_indicator_card.dart';

/// Dashboard principal do aplicativo.
///
/// Exibe:
/// - Indicador de risco atual da cidade
/// - Estatísticas resumidas
/// - Ações rápidas (navegação para outras features)
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCity = ref.watch(selectedCityProvider);
    final dashboardDataAsync = ref.watch(dashboardDataStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedCity?.name ?? 'Dengo'),
        actions: [
          // Botão para trocar cidade
          IconButton(
            icon: const Icon(Icons.location_on_outlined),
            tooltip: 'Trocar cidade',
            onPressed: () {
              context.push(AppRoutes.onboarding);
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notificações',
            onPressed: () {
              // TODO: Implementar notificações
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardDataStateProvider.notifier).refresh();
        },
        child: dashboardDataAsync.when(
          loading: () => const Center(child: AppLoadingIndicator()),
          error: (error, stack) => Center(
            child: AppErrorWidget(
              message: 'Erro ao carregar dados:\n$error',
              onRetry: () => ref.invalidate(dashboardDataStateProvider),
            ),
          ),
          data: (dashboardData) {
            if (dashboardData.historicalData.isEmpty) {
              return const Center(
                child: AppEmptyState(
                  message: 'Nenhum dado disponível para esta cidade',
                ),
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(
                AppConstants.defaultHorizontalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Saudação
                  _buildGreeting(context),

                  const SizedBox(height: AppConstants.spacingLg),

                  // Card principal - Indicador de Risco (DADOS REAIS DA API)
                  RiskIndicatorCard(
                    riskLevel: dashboardData.prediction.riskLevel,
                    cityName: selectedCity?.fullName ?? 'Carregando...',
                    casesCount: dashboardData.currentWeek.cases,
                  ),

                  const SizedBox(height: AppConstants.spacingLg),

                  // Estatísticas (DADOS REAIS DA API)
                  DashboardStatsCard(
                    newCasesThisWeek: dashboardData.newCasesThisWeek,
                    totalCases: dashboardData.totalConfirmedCases,
                    predictionNextWeek: dashboardData.prediction.estimatedCases,
                  ),

                  const SizedBox(height: AppConstants.spacingLg),

                  // Ações Rápidas
                  const QuickActionsSection(),

                  const SizedBox(height: AppConstants.spacingXl),

                  // Informações adicionais
                  _buildInfoSection(context),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final greeting = TimeHelpers.getGreeting();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Veja as previsões para sua cidade',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: AppConstants.spacingSm),
                Text(
                  'Como funciona?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'Utilizamos Inteligência Artificial para prever casos de dengue com base em dados históricos do InfoDengue (FIOCRUZ), clima (OpenWeather) e outros fatores epidemiológicos.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
