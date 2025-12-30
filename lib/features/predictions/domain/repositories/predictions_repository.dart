import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/prediction_response.dart';

/// Interface do repositório de predições.
///
/// Define o contrato que a camada de dados deve implementar.
/// Segue Clean Architecture: Domain não depende de Data.
abstract class PredictionsRepository {
  /// Obtém predições de casos de dengue para um município.
  ///
  /// [geocode] - Código IBGE do município (7 dígitos, deve começar com 41 - Paraná)
  /// [weeksAhead] - Número de semanas a prever (1-4)
  ///
  /// Retorna:
  /// - Right(PredictionResponse) em caso de sucesso
  /// - Left(Failure) em caso de erro
  Future<Either<Failure, PredictionResponse>> getPredictions({
    required String geocode,
    int weeksAhead = 2,
  });
}
