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
/// - Trata erros e retorna Either<Failure, Success>
class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  // TODO: Adicionar LocalDataSource quando implementar cache Hive

  DashboardRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, DashboardData>> getDashboardData(String cityId) async {
    if (!await networkInfo.isConnected) {
      // TODO: Tentar buscar do cache local (Hive)
      return const Left(NetworkFailure());
    }

    try {
      final model = await remoteDataSource.getDashboardData(cityId);
      final entity = model.toEntity();

      // TODO: Salvar no cache local (Hive) para acesso offline
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

      // TODO: Atualizar cache local (Hive)
      return Right(entity);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
