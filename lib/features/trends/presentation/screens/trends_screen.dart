import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      bottomNavigationBar: _buildBottomNav(context),
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

          // Placeholder do gráfico
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Stack(
              children: [
                // Linha do gráfico simulada
                CustomPaint(
                  size: const Size(double.infinity, 200),
                  painter: TrendLinePainter(),
                ),

                // Labels
                Positioned(
                  left: 16,
                  top: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2E8B8B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Casos Reais',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF4A5568),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF8A80),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Previsão IA',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF4A5568),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Insights da IA
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    size: 18, color: Color(0xFFFF8A80)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'A IA prevê aumento de 23% nos casos na próxima semana',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4A5568),
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

  Widget _buildAlerts(dashboardData) {
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
                'Alertas de Surto Iminente',
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
          city: 'Londrina',
          riskIncrease: '+85%',
          predictedCases: 450,
          daysAhead: 7,
          severity: 'high',
        ),
        _buildAlertCard(
          city: 'Maringá',
          riskIncrease: '+45%',
          predictedCases: 180,
          daysAhead: 10,
          severity: 'medium',
        ),
        _buildAlertCard(
          city: 'Cascavel',
          riskIncrease: '+32%',
          predictedCases: 120,
          daysAhead: 14,
          severity: 'medium',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Previsões - Outras Cidades do ${selectedCity.state}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E5C6E),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildCityPredictionCard('Curitiba', 28, 'estável', const Color(0xFF10B981)),
        _buildCityPredictionCard(
            'Ponta Grossa', 45, 'crescente', const Color(0xFFFF8A80)),
        _buildCityPredictionCard(
            'Foz do Iguaçu', 12, 'decrescente', const Color(0xFF2E8B8B)),
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

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_rounded, false, const Color(0xFF9CA3AF), () {
            Navigator.pop(context);
          }),
          _buildNavItem(Icons.local_fire_department_rounded, false,
              const Color(0xFF9CA3AF), () {}),
          _buildNavItem(
              Icons.bar_chart_rounded, true, const Color(0xFFFF8A80), () {}),
          _buildNavItem(
            Icons.location_city,
            false,
            const Color(0xFF9CA3AF),
            () {
              context.push(AppRoutes.cityDetail);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, bool isActive, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Icon(
          icon,
          size: 28,
          color: color,
        ),
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
