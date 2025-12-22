import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/city.dart';

/// Contrato (interface) do repositório de cidades.
///
/// Define as operações disponíveis para gerenciar cidades,
/// sem implementação concreta. A implementação fica na camada Data.
///
/// Usa Either<Failure, Success> para tratamento de erros funcional,
/// evitando exceções não tratadas.
abstract class CityRepository {
  /// Busca cidades por nome ou parte do nome.
  ///
  /// [query]: Texto de busca (ex: "São Paulo")
  ///
  /// Retorna:
  /// - Left(Failure): Em caso de erro (rede, parse, etc)
  /// - Right(List<City>): Lista de cidades encontradas
  Future<Either<Failure, List<City>>> searchCities(String query);

  /// Busca cidade por código IBGE.
  ///
  /// [ibgeCode]: Código IBGE da cidade
  ///
  /// Retorna:
  /// - Left(Failure): Se não encontrar ou houver erro
  /// - Right(City): Cidade encontrada
  Future<Either<Failure, City>> getCityByIbgeCode(String ibgeCode);

  /// Obtém a cidade selecionada salva localmente.
  ///
  /// Retorna:
  /// - Left(Failure): Se nenhuma cidade estiver salva
  /// - Right(City): Cidade salva anteriormente
  Future<Either<Failure, City>> getSavedCity();

  /// Salva a cidade selecionada pelo usuário localmente.
  ///
  /// [city]: Cidade a ser salva
  ///
  /// Retorna:
  /// - Left(Failure): Em caso de erro ao salvar
  /// - Right(void): Sucesso
  Future<Either<Failure, void>> saveCity(City city);
}
