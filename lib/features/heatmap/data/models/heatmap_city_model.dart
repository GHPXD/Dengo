import 'package:latlong2/latlong.dart';
import '../../domain/entities/heatmap_city.dart';
import '../../domain/entities/risk_level.dart';

/// Model para dados de cidade no heatmap (API response).
class HeatmapCityModel {
  final String geocode;
  final String nome;
  final double latitude;
  final double longitude;
  final int casos;
  final int populacao;
  final double incidencia;
  final String nivelRisco;

  HeatmapCityModel({
    required this.geocode,
    required this.nome,
    required this.latitude,
    required this.longitude,
    required this.casos,
    required this.populacao,
    required this.incidencia,
    required this.nivelRisco,
  });

  /// Cria model a partir do JSON da API
  factory HeatmapCityModel.fromJson(Map<String, dynamic> json) {
    return HeatmapCityModel(
      geocode: json['geocode'] as String,
      nome: json['nome'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      casos: json['casos'] as int,
      populacao: json['populacao'] as int,
      incidencia: (json['incidencia'] as num).toDouble(),
      nivelRisco: json['nivel_risco'] as String,
    );
  }

  /// Converte model para entidade de domínio
  HeatmapCity toEntity() {
    return HeatmapCity(
      geocode: geocode,
      name: nome,
      location: LatLng(latitude, longitude),
      cases: casos,
      population: populacao,
      incidence: incidencia,
      riskLevel: RiskLevel.fromString(nivelRisco),
    );
  }

  /// Converte model para JSON
  Map<String, dynamic> toJson() {
    return {
      'geocode': geocode,
      'nome': nome,
      'latitude': latitude,
      'longitude': longitude,
      'casos': casos,
      'populacao': populacao,
      'incidencia': incidencia,
      'nivel_risco': nivelRisco,
    };
  }
}
