import 'package:equatable/equatable.dart';
import 'heatmap_city.dart';

/// Dados completos do heatmap.
class HeatmapData extends Equatable {
  /// Sigla do estado.
  final String state;

  /// Total de cidades no mapa.
  final int totalCities;

  /// Período dos dados ("week" ou "month").
  final String period;

  /// Lista de cidades com dados geográficos.
  final List<HeatmapCity> cities;

  /// Construtor padrão com todos os dados do heatmap.
  const HeatmapData({
    required this.state,
    required this.totalCities,
    required this.period,
    required this.cities,
  });

  @override
  List<Object?> get props => [state, totalCities, period, cities];
}