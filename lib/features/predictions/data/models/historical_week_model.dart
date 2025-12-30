import '../../domain/entities/historical_week.dart';

/// Model representando dados históricos de uma semana (camada de dados).
///
/// Responsável por serialização/deserialização JSON da API.
class HistoricalWeekModel extends HistoricalWeek {
  const HistoricalWeekModel({
    required super.weekNumber,
    required super.date,
    required super.cases,
  });

  /// Cria model a partir de JSON da API
  factory HistoricalWeekModel.fromJson(Map<String, dynamic> json) {
    return HistoricalWeekModel(
      weekNumber: json['week_number'] as int,
      date: DateTime.parse(json['date'] as String),
      cases: json['cases'] as int,
    );
  }

  /// Converte model para JSON
  Map<String, dynamic> toJson() {
    return {
      'week_number': weekNumber,
      'date': date.toIso8601String().split('T')[0], // Apenas data (yyyy-mm-dd)
      'cases': cases,
    };
  }

  /// Converte para entidade de domínio
  HistoricalWeek toEntity() {
    return HistoricalWeek(
      weekNumber: weekNumber,
      date: date,
      cases: cases,
    );
  }
}
