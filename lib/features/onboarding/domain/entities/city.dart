import 'package:equatable/equatable.dart';

/// Entidade de domínio representando uma Cidade.
///
/// Esta é uma classe pura de negócio (Domain Layer), sem dependências
/// de frameworks externos. Representa o conceito de "Cidade" no contexto
/// do DenguePredict.
///
/// Contém apenas dados essenciais, sem lógica de serialização (que fica na camada Data).
class City extends Equatable {
  /// Identificador único da cidade
  final String id;

  /// Nome da cidade (ex: "São Paulo")
  final String name;

  /// Estado/UF (ex: "SP")
  final String state;

  /// Código IBGE da cidade
  final String ibgeCode;

  /// Latitude geográfica
  final double latitude;

  /// Longitude geográfica
  final double longitude;

  /// População estimada
  final int population;

  /// Cria instância de [City] com todas propriedades obrigatórias
  const City({
    required this.id,
    required this.name,
    required this.state,
    required this.ibgeCode,
    required this.latitude,
    required this.longitude,
    required this.population,
  });

  /// Nome completo da cidade (Cidade - UF)
  /// Exemplo: "São Paulo - SP"
  String get fullName => '$name - $state';

  @override
  List<Object?> get props => [
        id,
        name,
        state,
        ibgeCode,
        latitude,
        longitude,
        population,
      ];

  @override
  String toString() => fullName;
}
