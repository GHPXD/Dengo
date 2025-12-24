import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/app_providers.dart';
import '../../../onboarding/presentation/providers/city_search_provider.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/dashboard_data.dart' as entities;
import '../../domain/repositories/dashboard_repository.dart';

part 'dashboard_data_provider.g.dart';

// ══════════════════════════════════════════════════════════════════════════
// REPOSITORY PROVIDER
// ══════════════════════════════════════════════════════════════════════════

/// Provider do DashboardRepository.
///
/// Injeta dependências: ApiClient e NetworkInfo.
@riverpod
DashboardRepository dashboardRepository(Ref ref) {
  return DashboardRepositoryImpl(
    remoteDataSource: DashboardRemoteDataSourceImpl(
      apiClient: ref.watch(apiClientProvider),
    ),
    networkInfo: ref.watch(networkInfoProvider),
  );
}

// ══════════════════════════════════════════════════════════════════════════
// DASHBOARD DATA STATE PROVIDER
// ══════════════════════════════════════════════════════════════════════════

/// Provider que gerencia o estado dos dados do Dashboard.
///
/// Automaticamente busca dados da API Python quando:
/// - O provider é inicializado
/// - A cidade selecionada muda
///
/// ROBUSTEZ: Se cidade estiver null, tenta carregar do SharedPreferences
/// antes de lançar erro.
///
/// Retorna `AsyncValue<entities.DashboardData>`:
/// - AsyncLoading: Carregando dados
/// - AsyncData: Dados carregados com sucesso
/// - AsyncError: Erro ao carregar
@riverpod
class DashboardDataState extends _$DashboardDataState {
  @override
  Future<entities.DashboardData> build() async {
    // Escuta mudanças na cidade selecionada
    var city = ref.watch(selectedCityProvider);

    // 📊 DashboardDataState.build() - Cidade inicial: ${city?.name ?? "NULL"}

    // ROBUSTEZ: Se cidade for null, tenta carregar do SharedPreferences
    if (city == null) {
      // ⚠️ Cidade null, tentando carregar do SharedPreferences...

      // Tenta carregar cidade salva
      await ref.read(selectedCityProvider.notifier).loadSavedCity();

      // Re-lê após tentativa de carregamento
      city = ref.read(selectedCityProvider);

      // 🔄 Após loadSavedCity(): ${city?.name ?? "AINDA NULL"}

      // Se mesmo assim for null, lança erro
      if (city == null) {
        // ❌ Erro: Nenhuma cidade disponível
        throw Exception('Nenhuma cidade selecionada');
      }
    }

    // 🌐 Buscando dados para: ${city.name} (IBGE: ${city.ibgeCode})

    // Busca dados da API Python usando código IBGE (não ID interno)
    final repository = ref.watch(dashboardRepositoryProvider);
    final result = await repository.getDashboardData(city.ibgeCode);

    return result.fold(
      (failure) {
        // ❌ Erro ao buscar dados: ${failure.message}
        throw Exception(failure.message);
      },
      (data) {
        // ✅ Dados carregados com sucesso!
        return data;
      },
    );
  }

  /// Atualiza os dados (pull-to-refresh).
  Future<void> refresh() async {
    var city = ref.read(selectedCityProvider);

    // ROBUSTEZ: Se cidade for null, tenta carregar do SharedPreferences
    if (city == null) {
      await ref.read(selectedCityProvider.notifier).loadSavedCity();
      city = ref.read(selectedCityProvider);

      if (city == null) {
        state = AsyncError(
          Exception('Nenhuma cidade selecionada'),
          StackTrace.current,
        );
        return;
      }
    }

    state = const AsyncLoading();

    final repository = ref.read(dashboardRepositoryProvider);
    final result = await repository.refreshDashboardData(city.ibgeCode);

    state = await AsyncValue.guard(() async {
      return result.fold(
        (failure) => throw Exception(failure.message),
        (data) => data,
      );
    });
  }
}
