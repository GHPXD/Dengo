import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_bottom_nav.dart';

import '../../domain/entities/week_prediction.dart';
import '../providers/predictions_provider.dart';
import '../widgets/predictions_chart.dart';
import '../widgets/trend_indicator.dart';

/// Tela de predições de casos de dengue.
///
/// Exibe gráfico dual-line com:
/// - Linha verde: Últimas 12 semanas (casos reais)
/// - Linha azul: Próximas 1-4 semanas (predições IA)
class PredictionsScreen extends ConsumerStatefulWidget {
  final String geocode;
  final String cityName;

  const PredictionsScreen({
    super.key,
    required this.geocode,
    required this.cityName,
  });

  @override
  ConsumerState<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends ConsumerState<PredictionsScreen> {
  int _selectedWeeks = 2;

  @override
  void initState() {
    super.initState();
    // Busca predições ao carregar a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPredictions();
    });
  }

  void _fetchPredictions() {
    ref.read(predictionsNotifierProvider.notifier).fetchPredictions(
          geocode: widget.geocode,
          weeksAhead: _selectedWeeks,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(predictionsNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E5C6E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Previsões - Curitiba',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E5C6E),
              ),
            ),
            const Text(
              'Powered by Machine Learning',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2E8B8B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Color(0xFF2E8B8B),
                ),
                const SizedBox(width: 4),
                Text(
                  'IA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E8B8B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null
              ? _buildErrorWidget(state.errorMessage!)
              : state.data != null
                  ? _buildContent(state.data!)
                  : const Center(
                      child: Text('Selecione o número de semanas'),
                    ),
      bottomNavigationBar: AppBottomNav(currentIndex: 1),
    );
  }

  Widget _buildContent(data) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Seletor de semanas
          _buildWeekSelector(),

          const SizedBox(height: 16),

          // Indicador de tendência
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TrendIndicator(
              trend: data.trend,
              percentage: data.trendPercentage,
            ),
          ),

          const SizedBox(height: 16),

          // Gráfico
          PredictionsChart(data: data),

          const SizedBox(height: 16),

          // Legenda
          _buildLegend(),

          const SizedBox(height: 16),

          // Informações do modelo
          _buildModelInfo(data),

          const SizedBox(height: 16),

          // Lista de predições
          _buildPredictionsList(data),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildWeekSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _buildPeriodButton('7 Dias', 1),
          const SizedBox(width: 12),
          _buildPeriodButton('30 Dias', 4),
          const SizedBox(width: 12),
          _buildPeriodButton('90 Dias', 12),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, int weeks) {
    final isSelected = _selectedWeeks == weeks;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedWeeks = weeks;
          });
          _fetchPredictions();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF2E8B8B), Color(0xFF1E7B7B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.grey[100],
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
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(Colors.green, 'Casos Reais', false),
          const SizedBox(width: 24),
          _buildLegendItem(Colors.blue, 'Predições IA', true),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, bool isDashed) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
          child: isDashed
              ? CustomPaint(
                  painter: _DashedLinePainter(color: color),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildModelInfo(data) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Modelo de IA',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Nome', data.modelName),
            _buildInfoRow(
              'Acurácia',
              '${(data.modelAccuracy * 100).toStringAsFixed(0)}%',
            ),
            _buildInfoRow('MAE', '~${data.modelMae.toInt()} casos'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionsList(data) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Predições Detalhadas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.predictions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final pred = data.predictions[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.2),
                  child: Text(
                    'S${pred.weekNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                title: Text(
                  '${pred.predictedCases.toStringAsFixed(1)} casos',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Confiança: ${pred.confidence.displayName} | '
                  'Intervalo: ${pred.lowerBound.toInt()}-${pred.upperBound.toInt()}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Chip(
                  label: Text(pred.confidence.displayName),
                  backgroundColor: _getConfidenceColor(pred.confidence),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(ConfidenceLevel confidence) {
    switch (confidence) {
      case ConfidenceLevel.high:
        return Colors.green.withOpacity(0.2);
      case ConfidenceLevel.medium:
        return Colors.orange.withOpacity(0.2);
      case ConfidenceLevel.low:
        return Colors.red.withOpacity(0.2);
    }
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar predições',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchPredictions,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter para linha tracejada na legenda
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const dashWidth = 3.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
