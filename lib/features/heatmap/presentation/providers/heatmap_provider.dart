import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_providers.dart';
import '../../data/datasources/heatmap_remote_datasource.dart';
import '../../data/repositories/heatmap_repository_impl.dart';
import '../../domain/entities/heatmap_data.dart';
import '../../domain/repositories/heatmap_repository.dart';

/// Provider para o DataSource.
final heatmapRemoteDataSourceProvider =
    Provider<HeatmapRemoteDataSource>((ref) {
  return HeatmapRemoteDataSource(
    apiClient: ref.watch(apiClientProvider),
  );
});

/// Provider para o Repository.
final heatmapRepositoryProvider = Provider<HeatmapRepository>((ref) {
  return HeatmapRepositoryImpl(
    remoteDataSource: ref.watch(heatmapRemoteDataSourceProvider),
  );
});

/// Estado do heatmap.
class HeatmapState {
  /// Dados do heatmap (cidades, risco, etc.).
  final HeatmapData? data;

  /// Indica se os dados estão sendo carregados.
  final bool isLoading;

  /// Mensagem de erro, se houver.
  final String? error;

  /// Período selecionado ("week" ou "month").
  final String selectedPeriod;

  /// Construtor padrão do estado.
  const HeatmapState({
    this.data,
    this.isLoading = false,
    this.error,
    this.selectedPeriod = 'week',
  });

  /// Cria uma cópia do estado com os campos atualizados.
  HeatmapState copyWith({
    HeatmapData? data,
    bool? isLoading,
    String? error,
    String? selectedPeriod,
  }) {
    return HeatmapState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
    );
  }
}

/// Notifier para gerenciar estado do heatmap.
class HeatmapNotifier extends StateNotifier<HeatmapState> {
  final HeatmapRepository _repository;

  /// Inicializa o notifier com o repositório.
  HeatmapNotifier(this._repository) : super(const HeatmapState());

  /// Carrega dados do heatmap.
  Future<void> loadHeatmap({String stateCode = 'PR'}) async {
    state = const HeatmapState(isLoading: true);

    try {
      final data = await _repository.getHeatmapData(
        state: stateCode,
        period: state.selectedPeriod,
      );

      state = state.copyWith(
        data: data,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Muda o período (week/month).
  Future<void> changePeriod(String period, {String stateCode = 'PR'}) async {
    if (period == state.selectedPeriod) return;

    state = state.copyWith(
      selectedPeriod: period,
      isLoading: true,
    );

    try {
      final data = await _repository.getHeatmapData(
        state: stateCode,
        period: period,
      );

      state = state.copyWith(
        data: data,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

/// Provider para o Notifier.
final heatmapProvider =
    StateNotifierProvider<HeatmapNotifier, HeatmapState>((ref) {
  return HeatmapNotifier(
    ref.watch(heatmapRepositoryProvider),
  );
});