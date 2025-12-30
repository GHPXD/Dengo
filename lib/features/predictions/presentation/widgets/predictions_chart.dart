import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/prediction_response.dart';

/// Widget que exibe gráfico dual-line com dados históricos e predições.
///
/// - Linha verde sólida: Casos históricos confirmados (últimas 12 semanas)
/// - Linha azul tracejada: Predições da IA (próximas 1-4 semanas)
class PredictionsChart extends StatelessWidget {
  /// Dados contendo histórico e predições.
  final PredictionResponse data;

  /// Construtor padrão.
  const PredictionsChart({
    required this.data,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          _buildChartData(),
          duration: const Duration(milliseconds: 250),
        ),
      ),
    );
  }

  LineChartData _buildChartData() {
    return LineChartData(
      minY: 0,
      maxY: (data.maxCases * 1.2).ceilToDouble(), // 20% margem superior
      lineBarsData: [
        _buildHistoricalLine(),
        _buildPredictionsLine(),
      ],
      titlesData: _buildTitles(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: data.maxCases / 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            // Correção: withValues em vez de withOpacity
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 1,
          );
        },
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
          left: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          // Correção: withValues em vez de withOpacity
          getTooltipColor: (touchedSpot) =>
              Colors.blueGrey.withValues(alpha: 0.8),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final isHistorical = spot.barIndex == 0;
              final label = isHistorical ? 'Real' : 'Predição';
              return LineTooltipItem(
                '$label\n${spot.y.toStringAsFixed(0)} casos',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  /// Linha verde - Dados históricos (sólida)
  LineChartBarData _buildHistoricalLine() {
    final spots = data.historicalData.asMap().entries.map((entry) {
      final index = entry.key;
      final week = entry.value;
      return FlSpot(index.toDouble(), week.cases.toDouble());
    }).toList();

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: Colors.green,
      barWidth: 3,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: Colors.green,
            strokeWidth: 2,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        // Correção: withValues em vez de withOpacity
        color: Colors.green.withValues(alpha: 0.1),
      ),
    );
  }

  /// Linha azul - Predições IA (tracejada)
  LineChartBarData _buildPredictionsLine() {
    final historicalLength = data.historicalData.length;

    final spots = data.predictions.asMap().entries.map((entry) {
      final index = entry.key;
      final prediction = entry.value;
      return FlSpot(
        (historicalLength + index).toDouble(),
        prediction.predictedCases,
      );
    }).toList();

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: Colors.blue,
      barWidth: 3,
      dashArray: [5, 5], // Linha tracejada
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: Colors.blue,
            strokeWidth: 2,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        // Correção: withValues em vez de withOpacity
        color: Colors.blue.withValues(alpha: 0.1),
      ),
    );
  }

  /// Títulos dos eixos
  FlTitlesData _buildTitles() {
    return FlTitlesData(
      leftTitles: AxisTitles(
        axisNameWidget: const Text(
          'Casos',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: data.maxCases / 5,
          getTitlesWidget: (value, meta) {
            return Text(
              value.toInt().toString(),
              style: const TextStyle(fontSize: 10),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        axisNameWidget: const Text(
          'Semanas',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 2,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < data.totalWeeks) {
              if (index < data.historicalData.length) {
                final week = data.historicalData[index];
                return Text(
                  'S${week.weekNumber}',
                  style: const TextStyle(fontSize: 9),
                );
              } else {
                final predIndex = index - data.historicalData.length;
                if (predIndex < data.predictions.length) {
                  final pred = data.predictions[predIndex];
                  return Text(
                    'S${pred.weekNumber}',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.blue,
                    ),
                  );
                }
              }
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    );
  }
}