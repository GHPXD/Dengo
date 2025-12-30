import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/enums/risk_level.dart';
import '../../../../core/utils/widgets/common_widgets.dart';
import '../../../onboarding/presentation/providers/city_search_provider.dart';
import '../providers/dashboard_data_provider.dart';
import 'package:dengue_predict/core/widgets/app_bottom_nav.dart';

/// Dashboard principal do aplicativo - Design UX/UI Refatorado.
///
/// Novo layout focado em:
/// - Cards visuais grandes (Risco da Cidade e Risco Estadual)
/// - Informações concisas e fáceis de entender
/// - Hierarquia visual clara
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  /// Builds the dashboard screen UI
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCity = ref.watch(selectedCityProvider);
    final dashboardDataAsync = ref.watch(dashboardDataStateProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(dashboardDataStateProvider.notifier).refresh();
          },
          child: Column(
            children: [
              // Header fixo
              _buildHeader(context, ref, selectedCity),

              // Conteúdo scrollável
              Expanded(
                child: dashboardDataAsync.when(
                  loading: () => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppLoadingIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Carregando dados...',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  error: (error, stack) =>
                      _buildErrorState(context, ref, error),
                  data: (dashboardData) => _buildDashboardContent(
                    context,
                    ref,
                    selectedCity,
                    dashboardData,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: 0),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BOTTOM NAVIGATION
  // ══════════════════════════════════════════════════════════════════════════



  // ══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(
      BuildContext context, WidgetRef ref, dynamic selectedCity) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      color: Colors.white,
      child: const Text(
        'Dengo',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E8B8B),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ERROR STATE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    final errorMessage = error.toString();
    final isNetworkError =
        errorMessage.contains('conexão') || errorMessage.contains('CORS');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNetworkError ? Icons.wifi_off : Icons.error_outline,
              size: 64,
              color: AppColors.danger,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro de Conexão',
              // ignore: avoid_dynamic_calls
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Cidade não encontrada no servidor',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(dashboardDataStateProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DASHBOARD CONTENT
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildDashboardContent(
    BuildContext context,
    WidgetRef ref,
    dynamic selectedCity,
    dynamic dashboardData,
  ) {
    /// @nodoc
    final cityName = selectedCity?.name ?? 'Carregando...';
    /// @nodoc
    final stateName = selectedCity?.state ?? 'PR';

    // Calcula nível de risco
    /// @nodoc
    final riskLevel = dashboardData.prediction.riskLevel;
    final riskColor = _getRiskColor(riskLevel);
    final riskText = _getRiskText(riskLevel);

    /// @nodoc
    final newCases = dashboardData.currentWeek.cases;
    /// @nodoc
    final trend = dashboardData.prediction.trend;

    final pageController = PageController(viewportFraction: 1.0);
    final currentPage = ValueNotifier<int>(0);

    pageController.addListener(() {
      currentPage.value = pageController.page?.round() ?? 0;
    });

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      children: [
        // Carrossel de Cards de Risco
        SizedBox(
          height: 240,
          child: PageView(
            controller: pageController,
            onPageChanged: (index) => currentPage.value = index,
            children: [
              // Card de Risco da Cidade
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildRiskCard(
                  context,
                  title: 'Risco da Cidade Hoje',
                  subtitle: cityName,
                  riskLevel: riskText,
                  riskColor: riskColor,
                  trend: _getTrendText(trend),
                ),
              ),

              // Card de Risco Estadual
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildRiskCard(
                  context,
                  title: 'Risco Estadual Hoje',
                  subtitle: stateName,
                  riskLevel: riskText,
                  riskColor: riskColor,
                  trend: 'Tendência de Estabilidade',
                ),
              ),
            ],
          ),
        ),

        // Indicadores de página (dots)
        const SizedBox(height: 12),
        ValueListenableBuilder<int>(
          valueListenable: currentPage,
          builder: (context, page, _) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              2,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: page == index ? const Color(0xFFFF8A80) : const Color(0xFFBDBDBD),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Cards pequenos (Novos Casos e Previsão IA)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: _buildSmallCardCases(
                  context,
                  newCases,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSmallCardPrediction(
                  context,
                  _getTrendText(trend),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Dica do Dia
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildTipCard(context),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CARD BUILDERS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildRiskCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String riskLevel,
    required Color riskColor,
    required String trend,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2E8B8B),
            Color(0xFF1E7B7B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Formas decorativas
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF8A80).withValues(alpha: 0.3),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF8A80).withValues(alpha: 0.2),
              ),
            ),
          ),
          // Conteúdo
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$title ($subtitle)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 200,
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.thermostat_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Risco',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            riskLevel.replaceAll('Risco ', ''),
                            style: TextStyle(
                              color: riskColor == AppColors.warning
                                  ? const Color(0xFFFF8A80)
                                  : Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            trend,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallCardCases(BuildContext context, int cases) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFDAD6),
            Color(0xFFFFF5F3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Forma decorativa
          Positioned(
            bottom: -20,
            left: -10,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF8A80).withValues(alpha: 0.2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      color: Color(0xFFFF6B6B),
                      size: 20,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Novos Casos (24h)',
                      style: TextStyle(
                        color: Color(0xFF2E5C6E),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+$cases',
                      style: const TextStyle(
                        color: Color(0xFFFF6B6B),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallCardPrediction(BuildContext context, String prediction) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFD1F4F4),
            Color(0xFFEFFAFA),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2E8B8B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.memory,
                color: Colors.white,
                size: 24,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Previsão de IA',
                  style: TextStyle(
                    color: Color(0xFF2E5C6E),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  prediction,
                  style: const TextStyle(
                    color: Color(0xFF2E8B8B),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EC),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2E8B8B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.volunteer_activism,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dica do Dia',
                  style: TextStyle(
                    color: Color(0xFF2E5C6E),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Verifique vasos de plantas após a chuva.',
                  style: TextStyle(
                    color: Color(0xFF4A5568),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ══════════════════════════════════════════════════════════════════════════

  /// Returns the color associated with the given risk level
  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return AppColors.success;
      case RiskLevel.medium:
        return AppColors.warning;
      case RiskLevel.high:
        return AppColors.danger;
    }
  }

  String _getRiskText(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return 'Risco Baixo';
      case RiskLevel.medium:
        return 'Risco Moderado';
      case RiskLevel.high:
        return 'Risco Alto';
    }
  }

  String _getTrendText(String trend) {
    switch (trend) {
      case 'crescente':
      case 'growing':
        return 'Tendência de Alta';
      case 'estavel':
      case 'stable':
        return 'Tendência de Estabilidade';
      case 'decrescente':
      case 'declining':
        return 'Queda Leve';
      default:
        return 'Sem Previsão';
    }
  }
}
