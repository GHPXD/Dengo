import '../../domain/entities/heatmap_data.dart';
import 'heatmap_city_model.dart';

/// Model para resposta completa do heatmap (API response).
class HeatmapDataModel {
  final String estado;
  final int totalCidades;
  final String periodo;
  final List<HeatmapCityModel> cidades;

  HeatmapDataModel({
    required this.estado,
    required this.totalCidades,
    required this.periodo,
    required this.cidades,
  });

  /// Cria model a partir do JSON da API
  factory HeatmapDataModel.fromJson(Map<String, dynamic> json) {
    return HeatmapDataModel(
      estado: json['estado'] as String,
      totalCidades: json['total_cidades'] as int,
      periodo: json['periodo'] as String,
      cidades: (json['cidades'] as List<dynamic>)
          .map((city) => HeatmapCityModel.fromJson(city as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Converte model para entidade de domínio
  HeatmapData toEntity() {
    return HeatmapData(
      state: estado,
      totalCities: totalCidades,
      period: periodo,
      cities: cidades.map((city) => city.toEntity()).toList(),
    );
  }

  /// Converte model para JSON
  Map<String, dynamic> toJson() {
    return {
      'estado': estado,
      'total_cidades': totalCidades,
      'periodo': periodo,
      'cidades': cidades.map((city) => city.toJson()).toList(),
    };
  }
}
