import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_bottom_nav.dart';
// Import essencial para tipagem forte
import '../../domain/entities/prediction_response.dart';
import '../../domain/entities/week_prediction.dart';
import '../providers/predictions_provider.dart';
import '../widgets/predictions_chart.dart';
import '../widgets/trend_indicator.dart';

// --- Constantes de Design ---
class _AppStyles {
  static const primary = Color(0xFF2E8B8B);
  static const primaryDark = Color(0xFF1E7B7B);
  static const textDark = Color(0xFF2E5C6E);
  static const textGrey = Color(0xFF6B7280);
}

/// Tela de predições de casos de dengue.
class PredictionsScreen extends ConsumerStatefulWidget {
  /// Código geográfico da cidade (IBGE).
  final String geocode;

  /// Nome da cidade para exibição.
  final String cityName;

  /// Construtor padrão.
  const PredictionsScreen({
    required this.geocode,
    required this.cityName,
    super.key,
  });

  @override
  ConsumerState<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends ConsumerState<PredictionsScreen> {
  int _selectedWeeks = 2;

  @override
  void initState() {
    super.initState();
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
          icon: const Icon(Icons.arrow_back, color: _AppStyles.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Previsões - ${widget.cityName}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _AppStyles.textDark,
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
        actions: const [_IAIndicator()],
      ),
      body: _buildBody(state),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _buildBody(PredictionsState state) {
    if (state.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: _AppStyles.primary));
    }

    if (state.errorMessage != null) {
      return _ErrorWidget(
        message: state.errorMessage!,
        onRetry: _fetchPredictions,
      );
    }

    if (state.data != null) {
      return _ContentWidget(
        data: state.data!,
        selectedWeeks: _selectedWeeks,
        onPeriodChanged: (weeks) {
          setState(() => _selectedWeeks = weeks);
          _fetchPredictions();
        },
      );
    }

    return const Center(child: Text('Selecione o número de semanas'));
  }
}

// ==========================================
// WIDGETS EXTRAÍDOS (Com Tipagem Forte)
// ==========================================

class _IAIndicator extends StatelessWidget {
  const _IAIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _AppStyles.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 16,
            color: _AppStyles.primary,
          ),
          SizedBox(width: 4),
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
    );
  }
}

class _ContentWidget extends StatelessWidget {
  final PredictionResponse data;
  final int selectedWeeks;
  final ValueChanged<int> onPeriodChanged;

  const _ContentWidget({
    required this.data,
    required this.selectedWeeks,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WeekSelector(
            selectedWeeks: selectedWeeks,
            onChanged: onPeriodChanged,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TrendIndicator(
              trend: data.trend,
              percentage: data.trendPercentage,
            ),
          ),
          const SizedBox(height: 16),
          PredictionsChart(data: data),
          const SizedBox(height: 16),
          const _ChartLegend(),
          const SizedBox(height: 16),
          _ModelInfoCard(data: data),
          const SizedBox(height: 16),
          _PredictionsList(predictions: data.predictions),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _WeekSelector extends StatelessWidget {
  final int selectedWeeks;
  final ValueChanged<int> onChanged;

  const _WeekSelector({
    required this.selectedWeeks,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _PeriodButton(
              label: '7 Dias',
              weeks: 1,
              groupValue: selectedWeeks,
              onTap: onChanged),
          const SizedBox(width: 12),
          _PeriodButton(
              label: '30 Dias',
              weeks: 4,
              groupValue: selectedWeeks,
              onTap: onChanged),
          const SizedBox(width: 12),
          _PeriodButton(
              label: '90 Dias',
              weeks: 12,
              groupValue: selectedWeeks,
              onTap: onChanged),
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final int weeks;
  final int groupValue;
  final ValueChanged<int> onTap;

  const _PeriodButton({
    required this.label,
    required this.weeks,
    required this.groupValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = groupValue == weeks;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(weeks),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [_AppStyles.primary, _AppStyles.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.grey[100],
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
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendItem(color: Colors.green, label: 'Casos Reais', isDashed: false),
          SizedBox(width: 24),
          _LegendItem(color: Colors.blue, label: 'Predições IA', isDashed: true),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDashed;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.isDashed,
  });

  @override
  Widget build(BuildContext context) {
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
              ? CustomPaint(painter: _DashedLinePainter(color: color))
              : null,
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _ModelInfoCard extends StatelessWidget {
  final PredictionResponse data;

  const _ModelInfoCard({required this.data});

  @override
  Widget build(BuildContext context) {
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
            _InfoRow(label: 'Nome', value: data.modelName),
            _InfoRow(
              label: 'Acurácia',
              value: '${(data.modelAccuracy * 100).toStringAsFixed(0)}%',
            ),
            _InfoRow(label: 'MAE', value: '~${data.modelMae.toInt()} casos'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
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
}

class _PredictionsList extends StatelessWidget {
  final List<WeekPrediction> predictions;

  const _PredictionsList({required this.predictions});

  @override
  Widget build(BuildContext context) {
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
            itemCount: predictions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final pred = predictions[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.2),
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
        return Colors.green.withValues(alpha: 0.2);
      case ConfidenceLevel.medium:
        return Colors.orange.withValues(alpha: 0.2);
      case ConfidenceLevel.low:
        return Colors.red.withValues(alpha: 0.2);
    }
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
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
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

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