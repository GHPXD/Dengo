import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/predictions_remote_datasource.dart';
import '../../data/repositories/predictions_repository_impl.dart';
import '../../domain/entities/prediction_response.dart';
import '../../domain/repositories/predictions_repository.dart';

/// Provider do ApiClient (compartilhado com outras features)
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// Provider do data source remoto
final predictionsRemoteDataSourceProvider =
    Provider<PredictionsRemoteDataSource>((ref) {
  return PredictionsRemoteDataSource(
    apiClient: ref.watch(apiClientProvider),
  );
});

/// Provider do repositório
final predictionsRepositoryProvider = Provider<PredictionsRepository>((ref) {
  return PredictionsRepositoryImpl(
    remoteDataSource: ref.watch(predictionsRemoteDataSourceProvider),
  );
});

/// Estado da tela de predições
class PredictionsState {
  final PredictionResponse? data;
  final bool isLoading;
  final String? errorMessage;

  const PredictionsState({
    this.data,
    this.isLoading = false,
    this.errorMessage,
  });

  PredictionsState copyWith({
    PredictionResponse? data,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PredictionsState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier para gerenciar estado das predições
class PredictionsNotifier extends StateNotifier<PredictionsState> {
  final PredictionsRepository repository;

  PredictionsNotifier({required this.repository})
      : super(const PredictionsState());

  /// Busca predições para um município
  Future<void> fetchPredictions({
    required String geocode,
    int weeksAhead = 2,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await repository.getPredictions(
      geocode: geocode,
      weeksAhead: weeksAhead,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (data) {
        state = state.copyWith(
          isLoading: false,
          data: data,
          errorMessage: null,
        );
      },
    );
  }

  /// Limpa dados e erro
  void reset() {
    state = const PredictionsState();
  }
}

/// Provider do notifier
final predictionsNotifierProvider =
    StateNotifierProvider<PredictionsNotifier, PredictionsState>((ref) {
  return PredictionsNotifier(
    repository: ref.watch(predictionsRepositoryProvider),
  );
});
