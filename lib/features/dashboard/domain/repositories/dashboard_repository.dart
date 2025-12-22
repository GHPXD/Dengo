import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/dashboard_data.dart';

/// Contrato do repositório de Dashboard.
///
/// Define operações para buscar dados consolidados da API Python,
/// que já combina InfoDengue + OpenWeather + Predição da IA.
abstract class DashboardRepository {
  /// Busca dados completos do dashboard para uma cidade específica.
  ///
  /// Endpoint esperado: GET /api/dashboard?city_id={cityId}
  ///
  /// Retorna:
  /// - Right(DashboardData): Dados históricos + predição
  /// - Left(NetworkFailure): Erro de rede
  /// - Left(ServerFailure): Erro no servidor (500, 400, etc)
  /// - Left(CacheFailure): Erro ao acessar cache local
  Future<Either<Failure, DashboardData>> getDashboardData(String cityId);

  /// Atualiza os dados do dashboard (força nova chamada à API).
  ///
  /// Útil para pull-to-refresh.
  Future<Either<Failure, DashboardData>> refreshDashboardData(String cityId);
}
