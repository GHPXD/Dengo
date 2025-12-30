import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'risk_level.dart';

/// Dados de uma cidade para exibição no heatmap.
class HeatmapCity extends Equatable {
  /// Código IBGE da cidade
  final String geocode;

  /// Nome da cidade
  final String name;

  /// Coordenadas geográficas
  final LatLng location;

  /// Número de casos confirmados no período
  final int cases;

  /// População da cidade
  final int population;

  /// Incidência por 100mil habitantes
  final double incidence;

  /// Nível de risco (baixo/médio/alto)
  final RiskLevel riskLevel;

  const HeatmapCity({
    required this.geocode,
    required this.name,
    required this.location,
    required this.cases,
    required this.population,
    required this.incidence,
    required this.riskLevel,
  });

  @override
  List<Object?> get props => [
        geocode,
        name,
        location,
        cases,
        population,
        incidence,
        riskLevel,
      ];
}
