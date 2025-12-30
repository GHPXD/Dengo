import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dengue_predict/core/widgets/app_bottom_nav.dart';
import '../../../dashboard/presentation/providers/dashboard_data_provider.dart';
import '../../../onboarding/presentation/providers/city_search_provider.dart';

// --- IMPORTS DAS ENTIDADES (Essenciais para Tipagem Forte) ---
import '../../../onboarding/domain/entities/city.dart';
import '../../../dashboard/domain/entities/dashboard_data.dart';
import '../../../dashboard/domain/entities/historical_data.dart';

// --- Constantes de Design ---
class _AppStyles {
  static const primary = Color(0xFF2E8B8B);
  static const primaryDark = Color(0xFF1E7B7B);
  static const textDark = Color(0xFF2E5C6E);
  static const textGrey = Color(0xFF4A5568);
  static const textLightGrey = Color(0xFF9CA3AF);
  static const bgGrey = Color(0xFFFAFAFA);

  static const alertHigh = Color(0xFFFF6B6B);
  static const alertMedium = Color(0xFFFF8A80);
  static const warning = Color(0xFFFBBF24);
  static const success = Color(0xFF10B981);
  static const infoBg = Color(0xFFFFF4EC);

  static const cardShadow = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.05),
    blurRadius: 10,
    offset: Offset(0, 4),
  );
}

/// Perfil da Cidade - City Detail
class CityDetailScreen extends ConsumerWidget {
  /// Construtor padrão da tela de detalhes da cidade.
  const CityDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tipagem explícita para evitar dynamic
    final City? selectedCity = ref.watch(selectedCityProvider);
    final AsyncValue<DashboardData> dashboardDataAsync =
        ref.watch(dashboardDataStateProvider);

    if (selectedCity == null) {
      return const _EmptyStateWidget();
    }

    return Scaffold(
      backgroundColor: _AppStyles.bgGrey,
      body: SafeArea(
        child: Column(
          children: [
            _CityHeader(city: selectedCity),
            Expanded(
              child: dashboardDataAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _AppStyles.primary),
                ),
                error: (error, stack) =>
                    _ErrorStateWidget(error: error.toString()),
                data: (dashboardData) => ListView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  children: [
                    // Estatísticas Principais
                    _MainStatsCard(data: dashboardData),

                    const SizedBox(height: 24),

                    // População vs Casos
                    _PopulationVsCasesCard(data: dashboardData),

                    const SizedBox(height: 24),

                    // Comparação com Estado
                    _StateComparisonCard(
                        city: selectedCity, data: dashboardData),

                    const SizedBox(height: 24),

                    // Previsão Específica
                    _CityForecastCard(data: dashboardData),

                    const SizedBox(height: 24),

                    // Histórico Recente
                    _RecentHistoryCard(history: dashboardData.historicalData),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
    );
  }
}

// ==========================================
// WIDGETS EXTRAÍDOS E TIPADOS
// ==========================================

class _CityHeader extends StatelessWidget {
  final City city;

  const _CityHeader({required this.city});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_AppStyles.primary, _AppStyles.primaryDark],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.location_city, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  city.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${city.state}, Brasil',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainStatsCard extends StatelessWidget {
  final DashboardData data;

  const _MainStatsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final cases = data.currentWeek.cases;
    final population = data.cityPopulation;

    // Evita divisão por zero
    final incidence = population > 0
        ? (cases / population * 100000).toStringAsFixed(1)
        : '0.0';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [_AppStyles.cardShadow],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Casos Ativos',
                  cases.toString(),
                  Icons.coronavirus_outlined,
                  _AppStyles.alertMedium,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.grey[200],
              ),
              Expanded(
                child: _buildStatItem(
                  'População',
                  _formatPopulation(population),
                  Icons.people_outline,
                  _AppStyles.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _AppStyles.infoBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_up,
                    color: _AppStyles.alertMedium, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Incidência: $incidence casos por 100 mil habitantes',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _AppStyles.textGrey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _AppStyles.textDark,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: _AppStyles.textLightGrey,
          ),
        ),
      ],
    );
  }
}

class _PopulationVsCasesCard extends StatelessWidget {
  final DashboardData data;

  const _PopulationVsCasesCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final population = data.cityPopulation;
    final cases = data.currentWeek.cases;

    final casesPercentage = population > 0
        ? (cases / population * 100).toStringAsFixed(2)
        : '0.00';

    final recovering = (cases * 0.77).round(); // Estimativa 77%
    final recoveringPercentage =
        cases > 0 ? ((recovering / cases) * 100).round() : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [_AppStyles.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'População vs Casos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _AppStyles.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              _ProgressBar(
                label: 'População Total',
                value: population,
                total: population,
                color: _AppStyles.primary,
                displayText: '${_formatNumber(population)} habitantes',
              ),
              const SizedBox(height: 16),
              _ProgressBar(
                label: 'Casos Confirmados',
                value: cases,
                total: population,
                color: _AppStyles.alertMedium,
                displayText: '$cases casos ($casesPercentage%)',
              ),
              const SizedBox(height: 16),
              _ProgressBar(
                label: 'Casos em Recuperação',
                value: recovering,
                total: population,
                color: _AppStyles.warning,
                displayText: '$recovering casos ($recoveringPercentage%)',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}

class _ProgressBar extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;
  final String displayText;

  const _ProgressBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
    required this.displayText,
  });

  @override
  Widget build(BuildContext context) {
    // Evita divisão por zero
    final percentage = total > 0
        ? (value / total * 100).clamp(0, 100).toDouble()
        : 0.0;

    final visualPercentage =
        label == 'População Total' ? 100.0 : percentage * 20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _AppStyles.textGrey,
              ),
            ),
            Text(
              displayText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor:
                (visualPercentage / 100).clamp(0.01, 1.0), // Garante mínimo visível
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StateComparisonCard extends StatelessWidget {
  final City city;
  final DashboardData data;

  const _StateComparisonCard({required this.city, required this.data});

  @override
  Widget build(BuildContext context) {
    final population = data.cityPopulation;
    final cityIncidence =
        population > 0 ? (data.currentWeek.cases / population * 100000) : 0.0;

    final cityGrowth = data.prediction.estimatedCases >
                data.currentWeek.cases &&
            data.currentWeek.cases > 0
        ? ((data.prediction.estimatedCases - data.currentWeek.cases) /
            data.currentWeek.cases *
            100)
        : 0.0;

    // Valores de referência (Mantendo a lógica original)
    const stateIncidence = 24155.0;
    const stateGrowth = 24.4;

    final incidenceDiff = stateIncidence > 0
        ? ((cityIncidence - stateIncidence) / stateIncidence * 100)
            .toStringAsFixed(0)
        : '0';

    final growthDiff = stateGrowth > 0
        ? ((cityGrowth - stateGrowth) / stateGrowth * 100).toStringAsFixed(0)
        : '0';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [_AppStyles.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows,
                  color: _AppStyles.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Comparação com ${city.state}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _AppStyles.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ComparisonItem(
            label: 'Incidência',
            cityValue: '${cityIncidence.toStringAsFixed(1)} / 100k',
            stateValue: '${stateIncidence.toStringAsFixed(1)} / 100k',
            difference: '$incidenceDiff%',
            isNegative: cityIncidence > stateIncidence,
            cityName: city.name,
          ),
          const SizedBox(height: 16),
          _ComparisonItem(
            label: 'Taxa de Crescimento',
            cityValue: '+${cityGrowth.toStringAsFixed(0)}% (7 dias)',
            stateValue: '+${stateGrowth.toStringAsFixed(0)}% (7 dias)',
            difference: '+$growthDiff%',
            isNegative: cityGrowth > stateGrowth,
            cityName: city.name,
          ),
          const SizedBox(height: 16),
          _ComparisonItem(
            label: 'Taxa de Recuperação',
            cityValue: '82%',
            stateValue: '82%',
            difference: '0%',
            isNegative: false,
            cityName: city.name,
          ),
        ],
      ),
    );
  }
}

class _ComparisonItem extends StatelessWidget {
  final String label;
  final String cityValue;
  final String stateValue;
  final String difference;
  final bool isNegative;
  final String cityName;

  const _ComparisonItem({
    required this.label,
    required this.cityValue,
    required this.stateValue,
    required this.difference,
    required this.isNegative,
    required this.cityName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _AppStyles.textGrey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cityName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _AppStyles.textLightGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cityValue,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _AppStyles.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isNegative
                      ? const Color(0xFFFFEBEE)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  difference,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color:
                        isNegative ? _AppStyles.alertHigh : _AppStyles.success,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Média PR',
                      style: TextStyle(
                        fontSize: 11,
                        color: _AppStyles.textLightGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stateValue,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _AppStyles.textLightGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CityForecastCard extends StatelessWidget {
  final DashboardData data;

  const _CityForecastCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final predictedCases = data.prediction.estimatedCases;
    final currentCases = data.currentWeek.cases;
    final casesIncrease = predictedCases - currentCases;

    final percentageIncrease = currentCases > 0
        ? ((casesIncrease / currentCases) * 100).toStringAsFixed(0)
        : '0';

    final riskLevel = data.prediction.riskLevel.toString().toLowerCase();
    final riskLevelText = riskLevel == 'alto'
        ? 'Alto'
        : (riskLevel == 'medio' || riskLevel == 'médio')
            ? 'Médio'
            : 'Baixo';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_AppStyles.alertMedium, _AppStyles.alertHigh],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _AppStyles.alertMedium.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.auto_graph, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Previsão - Próximos 7 Dias',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Atualizado há 2 horas',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.memory, size: 14, color: _AppStyles.alertMedium),
                    SizedBox(width: 4),
                    Text(
                      'IA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _AppStyles.alertMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ForecastStat(
                        label: 'Casos Previstos',
                        value: '+$casesIncrease',
                        icon: Icons.trending_up),
                    Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.3)),
                    _ForecastStat(
                        label: 'Aumento',
                        value: '+$percentageIncrease%',
                        icon: Icons.arrow_upward),
                    Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.3)),
                    _ForecastStat(
                        label: 'Risco',
                        value: riskLevelText,
                        icon: Icons.warning_amber),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Surto previsto para os próximos 5-7 dias com base em dados climáticos e mobilidade.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ForecastStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RecentHistoryCard extends StatelessWidget {
  // Tipagem forte aqui
  final List<HistoricalData> history;

  const _RecentHistoryCard({required this.history});

  @override
  Widget build(BuildContext context) {
    // Lógica para pegar as últimas 4 semanas de forma segura
    final recentWeeks =
        history.length >= 4 ? history.sublist(history.length - 4) : history;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [_AppStyles.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Histórico Recente (últimas semanas)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _AppStyles.textDark,
            ),
          ),
          const SizedBox(height: 16),
          // map tipado automaticamente pela lista de HistoricalData
          ...recentWeeks.asMap().entries.map((entry) {
            final index = entry.key;
            final week = entry.value;
            final daysAgo = recentWeeks.length - index - 1;

            final label = daysAgo == 0
                ? 'Última semana'
                : '$daysAgo ${daysAgo == 1 ? 'semana' : 'semanas'} atrás';

            final prevCases =
                index > 0 ? recentWeeks[index - 1].cases : week.cases;
            final newCases = week.cases - prevCases;

            final change = prevCases > 0
                ? ((newCases / prevCases) * 100).toStringAsFixed(1)
                : '0.0';

            return _HistoryItem(
              date: label,
              cases: week.cases,
              newCases: newCases.abs(),
              change: '${newCases >= 0 ? '+' : ''}$change%',
            );
          }),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String date;
  final int cases;
  final int newCases;
  final String change;

  const _HistoryItem({
    required this.date,
    required this.cases,
    required this.newCases,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    final isIncrease = change.startsWith('+');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              date,
              style: const TextStyle(
                fontSize: 13,
                color: _AppStyles.textGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$cases',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _AppStyles.textDark,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isIncrease
                    ? const Color(0xFFFFEBEE)
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '+$newCases',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isIncrease ? _AppStyles.alertHigh : _AppStyles.success,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              change,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _AppStyles.textLightGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- ESTADOS DE CARREGAMENTO E ERRO ---

class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhuma cidade selecionada',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorStateWidget extends StatelessWidget {
  final String error;

  const _ErrorStateWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar dados',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}