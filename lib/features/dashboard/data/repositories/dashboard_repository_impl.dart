import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

/// Implementação do DashboardRepository seguindo Clean Architecture.
///
/// Esta camada:
/// - Converte Models (Data Layer) → Entities (Domain Layer)
/// - Gerencia cache local (Hive) para modo offline
/// - Trata erros e retorna `Either<Failure, Success>`
class DashboardRepositoryImpl implements DashboardRepository {
  /// Remote data source for fetching dashboard data from API
  final DashboardRemoteDataSource remoteDataSource;
  
  /// Network info service to check connectivity
  final NetworkInfo networkInfo;

  /// Creates a [DashboardRepositoryImpl] with required dependencies
  DashboardRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, DashboardData>> getDashboardData(String cityId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final model = await remoteDataSource.getDashboardData(cityId);
      final entity = model.toEntity();

      return Right(entity);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DashboardData>> refreshDashboardData(
    String cityId,
  ) async {
    // Força busca na API (ignora cache)
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final model = await remoteDataSource.getDashboardData(cityId);
      final entity = model.toEntity();

      return Right(entity);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
