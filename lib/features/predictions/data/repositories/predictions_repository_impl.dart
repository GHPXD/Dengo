import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/prediction_response.dart';
import '../../domain/repositories/predictions_repository.dart';
import '../datasources/predictions_remote_datasource.dart';

/// Implementação do repositório de predições.
///
/// Faz a ponte entre a camada de domínio e a camada de dados.
/// Transforma exceções em Failures (pattern Either).
class PredictionsRepositoryImpl implements PredictionsRepository {
  /// Fonte de dados remota para buscar predições da API.
  final PredictionsRemoteDataSource remoteDataSource;

  /// Construtor que recebe o data source remoto via injeção de dependência.
  PredictionsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, PredictionResponse>> getPredictions({
    required String geocode,
    int weeksAhead = 2,
  }) async {
    try {
      final model = await remoteDataSource.getPredictions(
        geocode: geocode,
        weeksAhead: weeksAhead,
      );

      return Right(model.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: 'Erro inesperado: $e'));
    }
  }

  /// Converte DioException para Failure apropriado
  Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure(message: 'Timeout na conexão');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;

        if (statusCode == 404) {
          return const NotFoundFailure(
            message: 'Município não encontrado',
          );
        }

        if (statusCode == 422) {
          // Erro de validação (geocode inválido)
          final detail = responseData is Map ? responseData['detail'] : null;
          String message = 'Dados inválidos';

          if (detail is List && detail.isNotEmpty) {
            final firstError = detail[0];
            if (firstError is Map && firstError.containsKey('msg')) {
              message = firstError['msg'] as String;
            }
          }

          return ValidationFailure(message: message);
        }

        return ServerFailure(
          message: 'Erro no servidor (código $statusCode)',
        );

      case DioExceptionType.cancel:
        return const NetworkFailure(message: 'Requisição cancelada');

      default:
        return NetworkFailure(
          message: 'Erro de conexão: ${error.message}',
        );
    }
  }
}