import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:dengue_predict/core/widgets/app_bottom_nav.dart';
import '../../../dashboard/presentation/providers/dashboard_data_provider.dart';
import '../../../onboarding/presentation/providers/city_search_provider.dart';

// --- IMPORTS DAS ENTIDADES (Necessários para remover o dynamic) ---
import '../../../dashboard/domain/entities/historical_data.dart';
import '../../../dashboard/domain/entities/prediction_data.dart';

// --- Constantes de Design ---
class _AppStyles {
  static const primary = Color(0xFF2E8B8B);
  static const primaryDark = Color(0xFF1E7B7B);
  static const textDark = Color(0xFF2E5C6E);
  static const textGrey = Color(0xFF9CA3AF);
  static const bgGrey = Color(0xFFFAFAFA); // Colors.grey[50]

  static const alertHigh = Color(0xFFFF6B6B);
  static const alertMedium = Color(0xFFFF8A80);
  static const alertLow = Color(0xFFFBBF24);
  static const success = Color(0xFF10B981);

  static const cardShadow = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.05),
    blurRadius: 10,
    offset: Offset(0, 4),
  );
}

/// Hub de Previsões - Trends & Forecast
class TrendsScreen extends ConsumerStatefulWidget {
  /// Construtor padrão da tela de tendências.
  const TrendsScreen({super.key});

  @override
  ConsumerState<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends ConsumerState<TrendsScreen> {
  // Estado local para controle do filtro
  String _selectedPeriod = '30days';

  @override
  Widget build(BuildContext context) {
    final selectedCity = ref.watch(selectedCityProvider);
    final dashboardDataAsync = ref.watch(dashboardDataStateProvider);

    if (selectedCity == null) {
      return const _EmptyStateWidget();
    }

    return Scaffold(
      backgroundColor: _AppStyles.bgGrey,
      body: SafeArea(
        child: Column(
          children: [
            _HeaderSection(cityName: selectedCity.name),
            Expanded(
              child: dashboardDataAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _AppStyles.primary),
                ),
                error: (error, stack) => const _ErrorStateWidget(),
                data: (dashboardData) {
                  // LÓGICA DE FILTRAGEM APLICADA AQUI
                  final filteredHistory = _filterData(
                      dashboardData.historicalData, _selectedPeriod);

                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    children: [
                      _PeriodSelector(
                        selectedPeriod: _selectedPeriod,
                        onChanged: (value) =>
                            setState(() => _selectedPeriod = value),
                      ),
                      const SizedBox(height: 24),
                      _ChartSection(
                        cityName: selectedCity.name,
                        period: _selectedPeriod,
                        history: filteredHistory,
                        prediction: dashboardData.prediction,
                        currentWeekCases: dashboardData.currentWeek.cases,
                      ),
                      const SizedBox(height: 24),
                      _AlertSection(
                        cityName: dashboardData.cityName,
                        currentCases: dashboardData.currentWeek.cases,
                        predictedCases: dashboardData.prediction.estimatedCases,
                      ),
                      const SizedBox(height: 24),
                      _CityPredictionSection(
                        cityName: selectedCity.name,
                        prediction: dashboardData.prediction,
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  /// Filtra os dados históricos mantendo a tipagem forte
  List<HistoricalData> _filterData(
      List<HistoricalData> fullHistory, String period) {
    if (fullHistory.isEmpty) return [];

    int days;
    switch (period) {
      case '7days':
        days = 7;
        break;
      case '90days':
        days = 90;
        break;
      case '30days':
      default:
        days = 30;
        break;
    }

    if (fullHistory.length <= days) return fullHistory;
    return fullHistory.sublist(fullHistory.length - days);
  }
}

// --- WIDGETS REFATORADOS ---

class _HeaderSection extends StatelessWidget {
  final String cityName;

  const _HeaderSection({required this.cityName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_AppStyles.primary, _AppStyles.primaryDark],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Previsões - $cityName',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _AppStyles.primary,
                ),
              ),
              const Text(
                'Powered by Machine Learning',
                style: TextStyle(
                  fontSize: 12,
                  color: _AppStyles.textGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final ValueChanged<String> onChanged;

  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
              child: _PeriodChip(
                  label: '7 Dias',
                  value: '7days',
                  groupValue: selectedPeriod,
                  onTap: onChanged)),
          const SizedBox(width: 12),
          Expanded(
              child: _PeriodChip(
                  label: '30 Dias',
                  value: '30days',
                  groupValue: selectedPeriod,
                  onTap: onChanged)),
          const SizedBox(width: 12),
          Expanded(
              child: _PeriodChip(
                  label: '90 Dias',
                  value: '90days',
                  groupValue: selectedPeriod,
                  onTap: onChanged)),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onTap;

  const _PeriodChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = groupValue == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  // Correção: removido 'const' redundante dentro da lista
                  colors: [_AppStyles.primary, _AppStyles.primaryDark])
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _AppStyles.primary : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF4A5568),
          ),
        ),
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  final String cityName;
  final String period;
  // Tipagem Forte para evitar erros
  final List<HistoricalData> history;
  final PredictionData prediction;
  final int currentWeekCases;

  const _ChartSection({
    required this.cityName,
    required this.period,
    required this.history,
    required this.prediction,
    required this.currentWeekCases,
  });

  @override
  Widget build(BuildContext context) {
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
          _buildChartHeader(),
          const SizedBox(height: 24),
          _buildGraph(),
          const SizedBox(height: 12),
          _buildAIInsight(),
        ],
      ),
    );
  }

  Widget _buildChartHeader() {
    final daysText =
        period == '7days' ? '7' : period == '30days' ? '30' : '90';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tendência de Casos - $cityName',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _AppStyles.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Histórico + Previsão ($daysText dias)',
              style: const TextStyle(fontSize: 12, color: _AppStyles.textGrey),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFD1F4F4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.memory, size: 14, color: _AppStyles.primary),
              SizedBox(width: 6),
              Text(
                'IA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _AppStyles.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGraph() {
    if (history.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: _AppStyles.bgGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('Sem dados para este período')),
      );
    }

    // Mapeamento usando dados tipados
    final List<FlSpot> spots = history.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.cases.toDouble());
    }).toList();

    // Ponto de previsão
    final predictionSpot = FlSpot(
      history.length.toDouble(),
      prediction.estimatedCases.toDouble(),
    );

    final allY = [...spots, predictionSpot].map((s) => s.y);
    final maxY = allY.isEmpty ? 10.0 : allY.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: _AppStyles.bgGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 16, bottom: 16, left: 8),
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: (maxY * 1.2).ceilToDouble(),
            lineBarsData: [
              // Linha histórica
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: _AppStyles.primary,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: _AppStyles.primary.withValues(alpha: 0.1),
                ),
              ),
              // Linha de previsão
              LineChartBarData(
                spots: [spots.last, predictionSpot],
                isCurved: false,
                color: _AppStyles.alertMedium,
                barWidth: 3,
                dashArray: [5, 5],
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: _AppStyles.alertMedium.withValues(alpha: 0.1),
                ),
              ),
            ],
            titlesData: const FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true, reservedSize: 35, interval: null),
              ),
              bottomTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }

  Widget _buildAIInsight() {
    final predictedCases = prediction.estimatedCases;
    final percentageChange = currentWeekCases > 0
        ? ((predictedCases - currentWeekCases) / currentWeekCases * 100).round()
        : 0;

    final isIncrease = predictedCases > currentWeekCases;

    final insightText = isIncrease
        ? 'A IA prevê aumento de $percentageChange% nos casos na próxima semana'
        : 'A IA prevê redução de ${percentageChange.abs()}% nos casos na próxima semana';

    final bgColor =
        isIncrease ? const Color(0xFFFFF4EC) : const Color(0xFFE8F5E9);
    final iconColor =
        isIncrease ? _AppStyles.alertMedium : _AppStyles.success;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, size: 18, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insightText,
              style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertSection extends StatelessWidget {
  final String cityName;
  final int currentCases;
  final int predictedCases;

  const _AlertSection({
    required this.cityName,
    required this.currentCases,
    required this.predictedCases,
  });

  @override
  Widget build(BuildContext context) {
    final riskIncrease = currentCases > 0
        ? ((predictedCases - currentCases) / currentCases * 100)
        : 0.0;

    if (riskIncrease <= 20) return const SizedBox.shrink();

    final severity =
        riskIncrease > 50 ? 'high' : riskIncrease > 30 ? 'medium' : 'low';
    final color = _getSeverityColor(severity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: _AppStyles.alertHigh, size: 20),
              SizedBox(width: 8),
              Text(
                'Alerta de Surto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _AppStyles.textDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.trending_up, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          cityName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _AppStyles.textDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+${riskIncrease.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Previsão: $predictedCases casos em 7 dias',
                      style: const TextStyle(
                          fontSize: 13, color: _AppStyles.textGrey),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ],
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'high':
        return _AppStyles.alertHigh;
      case 'medium':
        return _AppStyles.alertMedium;
      default:
        return _AppStyles.alertLow;
    }
  }
}

class _CityPredictionSection extends StatelessWidget {
  final String cityName;
  // Tipagem forte para PredictionData
  final PredictionData prediction;

  const _CityPredictionSection({
    required this.cityName,
    required this.prediction,
  });

  @override
  Widget build(BuildContext context) {
    final String trend = (prediction.trend).toString().toLowerCase();

    String trendText;
    Color trendColor;
    IconData icon;

    if (trend == 'crescente') {
      trendText = 'crescente';
      trendColor = _AppStyles.alertMedium;
      icon = Icons.trending_up;
    } else if (trend.contains('estavel') || trend.contains('estável')) {
      trendText = 'estável';
      trendColor = _AppStyles.success;
      icon = Icons.trending_flat;
    } else {
      trendText = 'decrescente';
      trendColor = _AppStyles.primary;
      icon = Icons.trending_down;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Previsão - $cityName',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _AppStyles.textDark,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [_AppStyles.cardShadow],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cityName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _AppStyles.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${prediction.estimatedCases} casos previstos',
                      style: const TextStyle(
                          fontSize: 12, color: _AppStyles.textGrey),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: trendColor),
                    const SizedBox(width: 6),
                    Text(
                      trendText.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- WIDGETS AUXILIARES DE ESTADO ---

class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppStyles.bgGrey,
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
  const _ErrorStateWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar dados',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}