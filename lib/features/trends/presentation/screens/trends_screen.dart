import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_empty_state_widget.dart';
import '../../../../core/widgets/period_selector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_router.dart';
import '../../../dashboard/presentation/providers/dashboard_data_provider.dart';
import '../../../onboarding/presentation/providers/city_search_provider.dart';

// --- IMPORTS DAS ENTIDADES (Necessários para remover o dynamic) ---
import '../../../dashboard/domain/entities/historical_data.dart';
import '../../../dashboard/domain/entities/prediction_data.dart';

/// Hub de Previsões - Trends & Forecast
/// 
/// Esta tela apresenta a análise temporal de casos de dengue.
/// O Modo Pro permite acesso à tela técnica de Predições de ML.
class TrendsScreen extends ConsumerStatefulWidget {
  /// Construtor padrão da tela de tendências.
  const TrendsScreen({super.key});

  @override
  ConsumerState<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends ConsumerState<TrendsScreen> {
  // Estado local para controle do filtro de período
  String _selectedPeriod = '30days';

  @override
  Widget build(BuildContext context) {
    final selectedCity = ref.watch(selectedCityProvider);
    final dashboardDataAsync = ref.watch(dashboardDataStateProvider);

    if (selectedCity == null) {
      return Scaffold(
        backgroundColor: AppColors.bgGrey,
        body: AppEmptyStateWidget.noCity(),
        bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgGrey,
      body: SafeArea(
        child: Column(
          children: [
            _HeaderSection(
              cityName: selectedCity.name,
              ibgeCode: selectedCity.ibgeCode,
            ),
            Expanded(
              child: dashboardDataAsync.when(
                loading: () => const AppLoadingIndicator(),
                error: (error, stack) => AppErrorWidget(
                  message: 'Erro ao carregar dados',
                  details: error.toString(),
                ),
                data: (dashboardData) {
                  // LÓGICA DE FILTRAGEM APLICADA AQUI
                  final filteredHistory = _filterData(
                      dashboardData.historicalData, _selectedPeriod);

                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    children: [
                      PeriodSelector.standard(
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
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  /// Filtra os dados históricos por número de SEMANAS.
  /// Nota: Dados do InfoDengue são semanais (1 ponto = 1 semana epidemiológica)
  List<HistoricalData> _filterData(
      List<HistoricalData> fullHistory, String period) {
    if (fullHistory.isEmpty) return [];

    // Mapeamento: periodo -> número de semanas
    int weeks;
    switch (period) {
      case '7days':   // 4 semanas (~1 mês)
        weeks = 4;
        break;
      case '90days':  // 12 semanas (~3 meses)
        weeks = 12;
        break;
      case '30days':  // 8 semanas (~2 meses) - padrão
      default:
        weeks = 8;
        break;
    }

    if (fullHistory.length <= weeks) return fullHistory;
    return fullHistory.sublist(fullHistory.length - weeks);
  }
}

// --- WIDGETS REFATORADOS ---

class _HeaderSection extends StatelessWidget {
  final String cityName;
  final String ibgeCode;

  const _HeaderSection({
    required this.cityName,
    required this.ibgeCode,
  });

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
                colors: [AppColors.primary, AppColors.primaryDark],
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Previsões - $cityName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Text(
                  'Powered by Machine Learning',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Botão discreto do Modo Pro - navega para Predições
          _ProModeButton(
            cityName: cityName,
            ibgeCode: ibgeCode,
          ),
        ],
      ),
    );
  }
}

/// Botão discreto para acessar a tela de Predições IA (Modo Desenvolvedor).
class _ProModeButton extends StatelessWidget {
  final String cityName;
  final String ibgeCode;

  const _ProModeButton({
    required this.cityName,
    required this.ibgeCode,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.go(
          AppRoutes.predictions,
          extra: {'geocode': ibgeCode, 'cityName': cityName},
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.code,
              size: 16,
              color: AppColors.textTertiary,
            ),
            SizedBox(width: 4),
            Text(
              'Pro',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textTertiary,
              ),
            ),
          ],
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
        boxShadow: const [AppColors.cardShadow],
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
    // Mapeamento correto: periodo -> semanas
    final weeksText =
        period == '7days' ? '4' : period == '30days' ? '8' : '12';
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
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Histórico ($weeksText sem.) + Previsão (1 sem.)',
              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.chipTurquoise,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.memory, size: 14, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'IA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
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
          color: AppColors.bgGrey,
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
        color: AppColors.bgGrey,
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
                color: AppColors.primary,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
              // Linha de previsão
              LineChartBarData(
                spots: [spots.last, predictionSpot],
                isCurved: false,
                color: AppColors.alertMedium,
                barWidth: 3,
                dashArray: [5, 5],
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.alertMedium.withValues(alpha: 0.1),
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
    // Calcula percentual com safeguard para valores extremos
    var percentageChange = currentWeekCases > 0
        ? ((predictedCases - currentWeekCases) / currentWeekCases * 100).round()
        : 0;
    // Limita a ±500% para evitar valores absurdos em semanas com poucos casos
    percentageChange = percentageChange.clamp(-500, 500);

    final isIncrease = predictedCases > currentWeekCases;

    // Texto mais claro: especifica semana atual vs próxima
    final insightText = isIncrease
        ? 'Previsão próx. semana: $predictedCases casos (+$percentageChange% vs atual: $currentWeekCases)'
        : 'Previsão próx. semana: $predictedCases casos ($percentageChange% vs atual: $currentWeekCases)';

    final bgColor =
        isIncrease ? AppColors.infoBg : AppColors.successBg;
    final iconColor =
        isIncrease ? AppColors.alertMedium : AppColors.success;

    return Column(
      children: [
        Container(
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
                  style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Indicador de confiança do modelo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Confiança: Moderada (50%) • Modelo em validação',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
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
                  color: AppColors.alertHigh, size: 20),
              SizedBox(width: 8),
              Text(
                'Alerta de Surto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
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
                            color: AppColors.textDark,
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
                      'Previsão: $predictedCases casos na próxima semana',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textTertiary),
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
        return AppColors.alertHigh;
      case 'medium':
        return AppColors.alertMedium;
      default:
        return AppColors.warning;
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
      trendColor = AppColors.alertMedium;
      icon = Icons.trending_up;
    } else if (trend.contains('estavel') || trend.contains('estável')) {
      trendText = 'estável';
      trendColor = AppColors.success;
      icon = Icons.trending_flat;
    } else {
      trendText = 'decrescente';
      trendColor = AppColors.primary;
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
              color: AppColors.textDark,
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
            boxShadow: const [AppColors.cardShadow],
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
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${prediction.estimatedCases} casos previstos',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textTertiary),
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