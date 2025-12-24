import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/city.dart';
import '../../domain/repositories/city_repository.dart';
import '../datasources/city_local_datasource.dart';
import '../datasources/city_remote_datasource.dart';
import '../models/city_model.dart';

/// Implementação concreta do CityRepository.
///
/// Orquestra os DataSources (remoto e local) para:
/// - Buscar dados da API quando online
/// - Usar cache local quando offline
/// - Converter Models (Data) em Entities (Domain)
/// - Tratar exceções e retornar Failures tipadas
///
/// Esta classe é o "tradutor" entre camada Data e Domain.
class CityRepositoryImpl implements CityRepository {
  /// Remote data source for fetching cities from API.
  final CityRemoteDataSource remoteDataSource;
  /// Local data source for caching cities.
  final CityLocalDataSource localDataSource;
  /// Network info to check connectivity.
  final NetworkInfo networkInfo;

  /// Creates a [CityRepositoryImpl] with required data sources.
  CityRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<City>>> searchCities(String query) async {
    try {
      // Verifica conectividade
      if (!await networkInfo.isConnected) {
        return const Left(
          NetworkFailure(
            message:
                'Sem conexão com internet. Conecte-se para buscar cidades.',
          ),
        );
      }

      // Busca na API
      final cityModels = await remoteDataSource.searchCities(query);

      // Converte Models para Entities
      final cities = cityModels.map((model) => model.toEntity()).toList();

      return Right(cities);
    } on Exception catch (e, stackTrace) {
      // Trata exceções e retorna Failure apropriada
      return Left(
        ServerFailure(
          message: 'Erro ao buscar cidades: ${e.toString()}',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, City>> getCityByIbgeCode(String ibgeCode) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure());
      }

      final cityModel = await remoteDataSource.getCityByIbgeCode(ibgeCode);
      return Right(cityModel.toEntity());
    } on Exception catch (e, stackTrace) {
      return Left(
        ServerFailure(
          message: 'Erro ao buscar cidade: ${e.toString()}',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, City>> getSavedCity() async {
    try {
      final cityModel = await localDataSource.getLastCity();
      
      if (cityModel == null) {
        return const Left(
          CacheFailure(
            message: 'Nenhuma cidade selecionada ainda.',
          ),
        );
      }
      
      return Right(cityModel.toEntity());
    } on Exception catch (e, stackTrace) {
      return Left(
        CacheFailure(
          message: 'Erro ao recuperar cidade: ${e.toString()}',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> saveCity(City city) async {
    try {
      // Converte Entity para Model
      final cityModel = CityModel.fromEntity(city);
      await localDataSource.cacheCity(cityModel);
      return const Right(null);
    } on Exception catch (e, stackTrace) {
      return Left(
        CacheFailure(
          message: 'Erro ao salvar cidade: ${e.toString()}',
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
