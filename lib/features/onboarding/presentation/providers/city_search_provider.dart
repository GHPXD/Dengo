import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/city.dart';
import 'onboarding_providers.dart';

part 'city_search_provider.freezed.dart';
part 'city_search_provider.g.dart';

/// Estado da busca de cidades.
@freezed
class CitySearchState with _$CitySearchState {
  const factory CitySearchState.initial() = _Initial;
  const factory CitySearchState.loading() = _Loading;
  const factory CitySearchState.loaded(List<City> cities) = _Loaded;
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

    final searchUseCase = await ref.read(searchCitiesUseCaseProvider.future);
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

    final saveUseCase = await ref.read(saveSelectedCityUseCaseProvider.future);
    final result = await saveUseCase(state!);

    return result.fold(
      (failure) => false,
      (_) => true,
    );
  }

  /// Carrega cidade salva (se existir).
  Future<void> loadSavedCity() async {
    print('🔍 Tentando carregar cidade salva...');

    final getSavedUseCase = await ref.read(getSavedCityUseCaseProvider.future);
    final result = await getSavedUseCase();

    result.fold(
      (failure) {
        print('⚠️ Nenhuma cidade salva: ${failure.message}');
        state = null;
      },
      (city) {
        print(
            '✅ Cidade carregada do cache: ${city.name} (IBGE: ${city.ibgeCode})');
        state = city;
      },
    );
  }
}
