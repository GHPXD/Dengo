import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/heatmap_remote_datasource.dart';
import '../../data/repositories/heatmap_repository_impl.dart';
import '../../domain/entities/heatmap_data.dart';
import '../../domain/repositories/heatmap_repository.dart';

/// Provider para o ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Provider para o DataSource
final heatmapRemoteDataSourceProvider = Provider<HeatmapRemoteDataSource>((ref) {
  return HeatmapRemoteDataSource(
    apiClient: ref.watch(apiClientProvider),
  );
});

/// Provider para o Repository
final heatmapRepositoryProvider = Provider<HeatmapRepository>((ref) {
  return HeatmapRepositoryImpl(
    remoteDataSource: ref.watch(heatmapRemoteDataSourceProvider),
  );
});

/// Estado do heatmap
class HeatmapState {
  final HeatmapData? data;
  final bool isLoading;
  final String? error;
  final String selectedPeriod; // "week" ou "month"

  const HeatmapState({
    this.data,
    this.isLoading = false,
    this.error,
    this.selectedPeriod = 'week',
  });

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

/// Notifier para gerenciar estado do heatmap
class HeatmapNotifier extends StateNotifier<HeatmapState> {
  final HeatmapRepository _repository;

  HeatmapNotifier(this._repository) : super(const HeatmapState());

  /// Carrega dados do heatmap
  Future<void> loadHeatmap({String stateCode = 'PR'}) async {
    state = const HeatmapState(isLoading: true);

    try {
      final data = await _repository.getHeatmapData(
        state: stateCode,
        period: state.selectedPeriod,
      );

      state = this.state.copyWith(
        data: data,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = this.state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Muda o período (week/month)
  Future<void> changePeriod(String period, {String stateCode = 'PR'}) async {
    if (period == state.selectedPeriod) return;

    state = this.state.copyWith(
      selectedPeriod: period,
      isLoading: true,
    );

    try {
      final data = await _repository.getHeatmapData(
        state: stateCode,
        period: period,
      );

      state = this.state.copyWith(
        data: data,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = this.state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

/// Provider para o Notifier
final heatmapProvider = StateNotifierProvider<HeatmapNotifier, HeatmapState>((ref) {
  return HeatmapNotifier(
    ref.watch(heatmapRepositoryProvider),
  );
});
