import 'package:latlong2/latlong.dart';
import '../../../../core/utils/enums/risk_level.dart';
import '../../domain/entities/heatmap_city.dart';

/// Model para dados de cidade no heatmap (API response).
class HeatmapCityModel {
  /// Código geográfico do IBGE (ex: "4106902").
  final String geocode;

  /// Nome da cidade.
  final String nome;

  /// Latitude geográfica.
  final double latitude;

  /// Longitude geográfica.
  final double longitude;

  /// Número total de casos confirmados.
  final int casos;

  /// População total da cidade.
  final int populacao;

  /// Taxa de incidência (casos por 100k habitantes).
  final double incidencia;

  /// Nível de risco textual (baixo, medio, alto).
  final String nivelRisco;

  /// Construtor padrão com todos os campos obrigatórios.
  const HeatmapCityModel({
    required this.geocode,
    required this.nome,
    required this.latitude,
    required this.longitude,
    required this.casos,
    required this.populacao,
    required this.incidencia,
    required this.nivelRisco,
  });

  /// Cria model a partir do JSON da API com tratamento robusto de tipos.
  factory HeatmapCityModel.fromJson(Map<String, dynamic> json) {
    return HeatmapCityModel(
      geocode: json['geocode']?.toString() ?? '',
      nome: json['nome']?.toString() ?? 'Desconhecido',
      // Cast seguro: aceita int ou double e converte, com fallback para 0.0 se nulo
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      casos: (json['casos'] as num?)?.toInt() ?? 0,
      populacao: (json['populacao'] as num?)?.toInt() ?? 0,
      incidencia: (json['incidencia'] as num?)?.toDouble() ?? 0.0,
      nivelRisco: json['nivel_risco']?.toString() ?? 'baixo',
    );
  }

  /// Converte model para entidade de domínio.
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

  /// Converte model para JSON.
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