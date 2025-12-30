import 'package:flutter/material.dart';

import '../../domain/entities/prediction_response.dart';

/// Widget que exibe indicador de tendência com ícone e percentual.
class TrendIndicator extends StatelessWidget {
  final TrendType trend;
  final double percentage;

  const TrendIndicator({
    super.key,
    required this.trend,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getTrendColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getTrendColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            trend.icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tendência: ${trend.displayName}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getTrendColor(),
                ),
              ),
              Text(
                '${percentage >= 0 ? '+' : ''}${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getTrendColor(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTrendColor() {
    switch (trend) {
      case TrendType.ascending:
        return Colors.red;
      case TrendType.stable:
        return Colors.orange;
      case TrendType.descending:
        return Colors.green;
    }
  }
}
