import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/city.dart';
import 'onboarding_providers.dart';

part 'city_search_provider.freezed.dart';
part 'city_search_provider.g.dart';

/// Estado da busca de cidades.
@freezed
class CitySearchState with _$CitySearchState {
  /// Initial state before any search.
  const factory CitySearchState.initial() = _Initial;
  /// Loading state while searching.
  const factory CitySearchState.loading() = _Loading;
  /// Loaded state with search results.
  const factory CitySearchState.loaded(List<City> cities) = _Loaded;
  /// Error state with error message.
  const factory CitySearchState.error(String message) = _Error;
}

/// Provider para buscar cidades.
///
/// Gerencia o estado da busca (loading, sucesso, erro).
@riverpod
class CitySearch extends _$CitySearch {
  @override
  CitySearchState build() {
    return const CitySearchState.initial();
  }

  /// Executa busca de cidades.
  Future<void> searchCities(String query) async {
    // Limpa resultados se query vazia
    if (query.trim().isEmpty) {
      state = const CitySearchState.initial();
      return;
    }

    state = const CitySearchState.loading();

    final searchUseCase = ref.read(searchCitiesUseCaseProvider);
    final result = await searchUseCase(query);

    result.fold(
      (failure) => state = CitySearchState.error(failure.message),
      (cities) => state = CitySearchState.loaded(cities),
    );
  }

  /// Limpa os resultados da busca.
  void clear() {
    state = const CitySearchState.initial();
  }
}

/// Provider para cidade selecionada.
///
/// Armazena a cidade escolhida pelo usuário durante o onboarding.
@riverpod
class SelectedCity extends _$SelectedCity {
  @override
  City? build() {
    return null;
  }

  /// Seleciona uma cidade.
  void selectCity(City city) {
    state = city;
  }

  /// Salva a cidade selecionada localmente.
  Future<bool> saveCity() async {
    if (state == null) return false;

    final saveUseCase = ref.read(saveSelectedCityUseCaseProvider);
    final result = await saveUseCase(state!);

    return result.fold(
      (failure) => false,
      (_) => true,
    );
  }

  /// Carrega cidade salva (se existir).
  Future<void> loadSavedCity() async {
    final getSavedUseCase = ref.read(getSavedCityUseCaseProvider);
    final result = await getSavedUseCase();

    result.fold(
      (failure) {
        state = null;
      },
      (city) {
        state = city;
      },
    );
  }
}
