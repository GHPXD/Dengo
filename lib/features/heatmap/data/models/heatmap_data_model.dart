import '../../domain/entities/heatmap_data.dart';
import 'heatmap_city_model.dart';

/// Model para resposta completa do heatmap (API response).
class HeatmapDataModel {
  /// Nome ou sigla do estado (ex: "PR").
  final String estado;

  /// Número total de cidades contidas na resposta.
  final int totalCidades;

  /// Período de análise dos dados (ex: "week", "month").
  final String periodo;

  /// Lista de cidades com dados de risco e coordenadas.
  final List<HeatmapCityModel> cidades;

  /// Construtor padrão.
  const HeatmapDataModel({
    required this.estado,
    required this.totalCidades,
    required this.periodo,
    required this.cidades,
  });

  /// Cria model a partir do JSON da API com tratamento de segurança contra nulos.
  factory HeatmapDataModel.fromJson(Map<String, dynamic> json) {
    return HeatmapDataModel(
      estado: json['estado']?.toString() ?? '',
      totalCidades: (json['total_cidades'] as num?)?.toInt() ?? 0,
      periodo: json['periodo']?.toString() ?? '',
      // Tratamento seguro para lista: se for null, retorna lista vazia []
      cidades: (json['cidades'] as List<dynamic>?)
              ?.map((city) =>
                  HeatmapCityModel.fromJson(city as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Converte model para entidade de domínio.
  HeatmapData toEntity() {
    return HeatmapData(
      state: estado,
      totalCities: totalCidades,
      period: periodo,
      cities: cidades.map((city) => city.toEntity()).toList(),
    );
  }

  /// Converte model para JSON.
  Map<String, dynamic> toJson() {
    return {
      'estado': estado,
      'total_cidades': totalCidades,
      'periodo': periodo,
      'cidades': cidades.map((city) => city.toJson()).toList(),
    };
  }
}