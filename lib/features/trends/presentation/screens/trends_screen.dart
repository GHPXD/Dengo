import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:dengue_predict/core/widgets/app_bottom_nav.dart';

import '../../../../core/config/app_router.dart';
import '../../../dashboard/presentation/providers/dashboard_data_provider.dart';
import '../../../onboarding/presentation/providers/city_search_provider.dart';

/// Hub de Previsões - Trends & Forecast
///
/// Mostra a mágica do Machine Learning:
/// - Gráficos de linha com tendências futuras
/// - Alertas de surto iminente
/// - Previsões por cidade
class TrendsScreen extends ConsumerStatefulWidget {
  const TrendsScreen({super.key});

  @override
  ConsumerState<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends ConsumerState<TrendsScreen> {
  String selectedPeriod = '30days'; // '7days', '30days', '90days'

  /// Builds the trends screen UI
  @override
  Widget build(BuildContext context) {
    final selectedCity = ref.watch(selectedCityProvider);
    final dashboardDataAsync = ref.watch(dashboardDataStateProvider);

    if (selectedCity == null) {
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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(selectedCity),
            Expanded(
              child: dashboardDataAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2E8B8B),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Erro ao carregar dados',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                data: (dashboardData) => ListView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  children: [
                    // Seletor de Período
                    _buildPeriodSelector(),

                    const SizedBox(height: 24),

                    // Gráfico Principal de Tendências
                    _buildMainChart(selectedCity, dashboardData),

                    const SizedBox(height: 24),

                    // Alertas de Surto Iminente
                    _buildAlerts(dashboardData),

                    const SizedBox(height: 24),

                    // Previsões por Cidade
                    _buildCityPredictions(selectedCity, dashboardData),

                    const SizedBox(height: 24),
                  ],
                ),
              ), // Fecha when()
            ), // Fecha Expanded
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: 3),
    );
  }

  Widget _buildHeader(selectedCity) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E8B8B), Color(0xFF1E7B7B)],
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
              /// @nodoc
              Text(
                'Previsões - ${selectedCity.name}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E8B8B),
                ),
              ),
              const Text(
                'Powered by Machine Learning',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildPeriodChip('7 Dias', '7days'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildPeriodChip('30 Dias', '30days'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildPeriodChip('90 Dias', '90days'),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = selectedPeriod == value;
    return GestureDetector(
      onTap: () => setState(() => selectedPeriod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF2E8B8B), Color(0xFF1E7B7B)],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E8B8B) : Colors.grey[300]!,
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

  Widget _buildMainChart(selectedCity, dashboardData) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// @nodoc
                  Text(
                    'Tendência de Casos - ${selectedCity.name}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E5C6E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Previsão dos próximos ${selectedPeriod == '7days' ? '7' : selectedPeriod == '30days' ? '30' : '90'} dias',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1F4F4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.memory, size: 14, color: Color(0xFF2E8B8B)),
                    SizedBox(width: 6),
                    Text(
                      'IA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E8B8B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Gráfico com dados reais
          _buildRealChart(dashboardData),

          const SizedBox(height: 12),

          // Insights da IA (dados reais)
          _buildAIInsight(dashboardData),
        ],
      ),
    );
  }

  Widget _buildRealChart(dashboardData) {
    // Dados históricos reais
    final historicalData = dashboardData.historicalData;
    
    if (historicalData.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('Sem dados históricos disponíveis'),
        ),
      );
    }
    
    // Cria spots para o gráfico (tipado explicitamente)
    final List<FlSpot> spots = historicalData.asMap().entries.map<FlSpot>((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.cases.toDouble());
    }).toList();
    
    // Adiciona predição como último ponto
    final predictionSpot = FlSpot(
      historicalData.length.toDouble(),
      dashboardData.prediction.estimatedCases.toDouble(),
    );
    
    final maxY = <FlSpot>[...spots, predictionSpot]
        .map((s) => s.y)
        .reduce((a, b) => a > b ? a : b);
    
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: (maxY * 1.2).ceilToDouble(),
            lineBarsData: [
              // Linha histórica (verde)
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: const Color(0xFF2E8B8B),
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFF2E8B8B).withOpacity(0.1),
                ),
              ),
              // Linha de predição (vermelho)
              LineChartBarData(
                spots: [spots.last, predictionSpot],
                isCurved: false,
                color: const Color(0xFFFF8A80),
                barWidth: 3,
                dashArray: [5, 5],
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFFFF8A80).withOpacity(0.1),
                ),
              ),
            ],
            titlesData: const FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 40),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey[300]!,
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }

  Widget _buildAIInsight(dashboardData) {
    final currentCases = dashboardData.currentWeek.cases;
    final predictedCases = dashboardData.prediction.estimatedCases;
    final percentageChange = currentCases > 0
        ? ((predictedCases - currentCases) / currentCases * 100).toStringAsFixed(0)
        : '0';
    
    final isIncrease = predictedCases > currentCases;
    final insightText = isIncrease
        ? 'A IA prevê aumento de $percentageChange% nos casos na próxima semana'
        : 'A IA prevê redução de ${percentageChange.replaceAll('-', '')}% nos casos na próxima semana';
    
    final insightColor = isIncrease ? const Color(0xFFFFF4EC) : const Color(0xFFE8F5E9);
    final iconColor = isIncrease ? const Color(0xFFFF8A80) : const Color(0xFF10B981);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: insightColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, size: 18, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insightText,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4A5568),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlerts(dashboardData) {
    // Calcula alerta baseado nos dados reais da cidade selecionada
    final currentCases = dashboardData.currentWeek.cases;
    final predictedCases = dashboardData.prediction.estimatedCases;
    final riskIncrease = currentCases > 0
        ? ((predictedCases - currentCases) / currentCases * 100)
        : 0.0;
    
    // Só mostra alerta se houver aumento significativo (>20%)
    if (riskIncrease <= 20) {
      return const SizedBox.shrink();
    }
    
    final severity = riskIncrease > 50 ? 'high' : riskIncrease > 30 ? 'medium' : 'low';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFFF6B6B), size: 20),
              SizedBox(width: 8),
              Text(
                'Alerta de Surto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E5C6E),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildAlertCard(
          city: dashboardData.cityName,
          riskIncrease: '+${riskIncrease.toStringAsFixed(0)}%',
          predictedCases: predictedCases,
          daysAhead: 7,
          severity: severity,
        ),
      ],
    );
  }

  Widget _buildAlertCard({
    required String city,
    required String riskIncrease,
    required int predictedCases,
    required int daysAhead,
    required String severity,
  }) {
    final color = severity == 'high'
        ? const Color(0xFFFF6B6B)
        : severity == 'medium'
            ? const Color(0xFFFF8A80)
            : const Color(0xFFFBBF24);

    return Container(
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
                      city,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E5C6E),
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
                        riskIncrease,
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
                  'Previsão: $predictedCases casos em $daysAhead dias',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildCityPredictions(selectedCity, dashboardData) {
    // Mostra apenas dados da cidade selecionada (sem hardcoded de outras cidades)
    final trend = dashboardData.prediction.trend;
    final trendText = trend == 'crescente' 
        ? 'crescente' 
        : trend == 'estavel' || trend == 'estável'
            ? 'estável'
            : 'decrescente';
    final trendColor = trend == 'crescente'
        ? const Color(0xFFFF8A80)
        : trend == 'estavel' || trend == 'estável'
            ? const Color(0xFF10B981)
            : const Color(0xFF2E8B8B);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Previsão - ${selectedCity.name}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E5C6E),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildCityPredictionCard(
          selectedCity.name,
          dashboardData.prediction.estimatedCases,
          trendText,
          trendColor,
        ),
      ],
    );
  }

  Widget _buildCityPredictionCard(
      String city, int cases, String trend, Color color) {
    final icon = trend == 'crescente'
        ? Icons.trending_up
        : trend == 'decrescente'
            ? Icons.trending_down
            : Icons.trending_flat;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E5C6E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$cases casos previstos',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  trend.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
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

// Custom Painter para o gráfico de linha
class TrendLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Linha de casos reais (teal)
    paint.color = const Color(0xFF2E8B8B);
    final realPath = Path();
    realPath.moveTo(20, size.height * 0.7);
    realPath.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.5,
      size.width * 0.5,
      size.height * 0.6,
    );
    canvas.drawPath(realPath, paint);

    // Linha de previsão (coral)
    paint.color = const Color(0xFFFF8A80);
    paint.strokeWidth = 3;
    paint.style = PaintingStyle.stroke;

    final predictionPath = Path();
    predictionPath.moveTo(size.width * 0.5, size.height * 0.6);
    predictionPath.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.4,
      size.width - 20,
      size.height * 0.3,
    );

    // Linha pontilhada
    final dashPath = _createDashedPath(predictionPath);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source) {
    final path = Path();
    final metrics = source.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      bool draw = true;

      while (distance < metric.length) {
        final length = draw ? 10 : 5;
        final end = distance + length;

        if (draw) {
          path.addPath(
            metric.extractPath(distance, end),
            Offset.zero,
          );
        }

        distance = end;
        draw = !draw;
      }
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
