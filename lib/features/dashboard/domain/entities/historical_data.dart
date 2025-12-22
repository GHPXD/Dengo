import 'package:equatable/equatable.dart';

/// Entidade que representa um ponto de dados históricos de dengue.
///
/// Esses dados vêm do Backend Python e representam
/// informações diárias de casos e clima.
class HistoricalData extends Equatable {
  /// Data do registro
  final DateTime date;

  /// Número de casos confirmados naquele dia
  final int cases;

  /// Temperatura média do dia (°C)
  final double avgTemperature;

  /// Umidade média do dia (%)
  final double avgHumidity;

  const HistoricalData({
    required this.date,
    required this.cases,
    required this.avgTemperature,
    required this.avgHumidity,
  });

  @override
  List<Object?> get props => [
        date,
        cases,
        avgTemperature,
        avgHumidity,
      ];
}
