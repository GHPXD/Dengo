import 'package:freezed_annotation/freezed_annotation.dart';

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
/// Estende a Entity pura do Domain, adicionando capacidades de serialização.
@freezed
class CityModel with _$CityModel {
  const CityModel._();

  const factory CityModel({
    required String id,
    required String name,
    required String state,
    @JsonKey(name: 'ibge_code') required String ibgeCode,
    required double latitude,
    required double longitude,
    required int population,
  }) = _CityModel;

  /// Cria CityModel a partir de JSON.
  factory CityModel.fromJson(Map<String, dynamic> json) =>
      _$CityModelFromJson(json);

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
