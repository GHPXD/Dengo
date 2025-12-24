import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

import '../../domain/entities/city.dart';

part 'city_model.freezed.dart';
part 'city_model.g.dart';

/// Model de City para camada de dados.
///
/// Usa Freezed para:
/// - Imutabilidade automática
/// - Serialização JSON automática
/// - copyWith, toString, equality
///
/// Usa Hive para:
/// - Persistência local offline
/// - Cache rápido em disco
///
/// Estende a Entity pura do Domain, adicionando capacidades de serialização.
@freezed
@HiveType(typeId: 0)
class CityModel with _$CityModel {
  const CityModel._();

  const factory CityModel({
    @HiveField(0) required String id,
    @HiveField(1) @JsonKey(name: 'nome') required String name,
    @HiveField(2) @JsonKey(name: 'uf') required String state,
    @HiveField(3) @JsonKey(name: 'ibge_codigo') required String ibgeCode,
    @HiveField(4) @JsonKey(name: 'latitude') required double latitude,
    @HiveField(5) @JsonKey(name: 'longitude') required double longitude,
    @HiveField(6) @JsonKey(name: 'populacao') required int population,
  }) = _CityModel;

  /// Cria [CityModel] a partir do JSON recebido da API
  factory CityModel.fromJson(Map<String, dynamic> json) {
    // Usa ibge_codigo tanto para id quanto para ibgeCode
    final ibgeCodigo = json['ibge_codigo'] as String;
    
    return CityModel(
      id: ibgeCodigo,
      name: json['nome'] as String,
      state: json['uf'] as String,
      ibgeCode: ibgeCodigo,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      population: json['populacao'] as int,
    );
  }

  /// Converte para JSON para serialização
  Map<String, dynamic> toJson() {
    return {
      'ibge_codigo': ibgeCode,
      'nome': name,
      'uf': state,
      'latitude': latitude,
      'longitude': longitude,
      'populacao': population,
    };
  }

  /// Converte Model (Data) para Entity (Domain).
  ///
  /// Esta conversão mantém a separação de camadas limpa.
  City toEntity() {
    return City(
      id: id,
      name: name,
      state: state,
      ibgeCode: ibgeCode,
      latitude: latitude,
      longitude: longitude,
      population: population,
    );
  }

  /// Cria Model a partir de Entity (Domain).
  factory CityModel.fromEntity(City city) {
    return CityModel(
      id: city.id,
      name: city.name,
      state: city.state,
      ibgeCode: city.ibgeCode,
      latitude: city.latitude,
      longitude: city.longitude,
      population: city.population,
    );
  }
}
