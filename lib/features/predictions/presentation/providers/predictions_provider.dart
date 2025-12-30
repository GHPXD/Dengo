import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/predictions_remote_datasource.dart';
import '../../data/repositories/predictions_repository_impl.dart';
import '../../domain/entities/prediction_response.dart';
import '../../domain/repositories/predictions_repository.dart';

// --- INJEÇÃO DE DEPENDÊNCIA (DI) ---

/// Provider do ApiClient.
/// NOTA: Idealmente, este provider deveria vir de 'core/config/app_providers.dart'
/// para ser um Singleton global. Mantido aqui para compatibilidade local.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// Provider do Data Source
final predictionsRemoteDataSourceProvider = Provider<PredictionsRemoteDataSource>((ref) {
  return PredictionsRemoteDataSource(
    apiClient: ref.watch(apiClientProvider),
  );
});

/// Provider do Repositório
final predictionsRepositoryProvider = Provider<PredictionsRepository>((ref) {
  return PredictionsRepositoryImpl(
    remoteDataSource: ref.watch(predictionsRemoteDataSourceProvider),
  );
});

// --- ESTADO (STATE) ---

/// Estado da tela de predições.
class PredictionsState {
  /// Dados retornados pela API (predições, histórico, tendências).
  final PredictionResponse? data;

  /// Indica se uma requisição está em andamento.
  final bool isLoading;

  /// Mensagem de erro, se houver falha na requisição.
  final String? errorMessage;

  /// Construtor padrão do estado.
  const PredictionsState({
    this.data,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Cria uma cópia do estado atual com os campos alterados.
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

// --- GERENCIADOR DE ESTADO (NOTIFIER) ---

/// Gerenciador de estado para a tela de predições.
class PredictionsNotifier extends StateNotifier<PredictionsState> {
  /// Repositório de dados.
  final PredictionsRepository repository;

  /// Inicializa o notifier com o repositório injetado.
  PredictionsNotifier({required this.repository})
      : super(const PredictionsState());

  /// Busca predições para um município.
  Future<void> fetchPredictions({
    required String geocode,
    int weeksAhead = 2,
  }) async {
    // Reseta erros e inicia loading, mantendo os dados anteriores se existirem
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await repository.getPredictions(
      geocode: geocode,
      weeksAhead: weeksAhead,
    );

    if (!mounted) return; // Segurança contra atualizações após dispose

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
          errorMessage: null, // Limpa erro em caso de sucesso
        );
      },
    );
  }

  /// Limpa dados e erro manualmente (se necessário).
  void reset() {
    state = const PredictionsState();
  }
}

// --- PROVIDER FINAL ---

/// Provider do notifier com autoDispose.
/// O autoDispose garante que, ao sair da tela, o estado seja limpo.
final predictionsNotifierProvider =
    StateNotifierProvider.autoDispose<PredictionsNotifier, PredictionsState>((ref) {
  return PredictionsNotifier(
    repository: ref.watch(predictionsRepositoryProvider),
  );
});