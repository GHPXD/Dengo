import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/app_providers.dart';
import '../../data/datasources/city_local_datasource.dart';
import '../../data/datasources/city_remote_datasource.dart';
import '../../data/repositories/city_repository_impl.dart';
import '../../domain/repositories/city_repository.dart';
import '../../domain/usecases/city_usecases.dart';

part 'onboarding_providers.g.dart';

// ══════════════════════════════════════════════════════════════════════════
// REPOSITORY E DATASOURCES
// ══════════════════════════════════════════════════════════════════════════

/// Provider para Remote DataSource de cidades.
@riverpod
CityRemoteDataSource cityRemoteDataSource(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CityRemoteDataSourceImpl(apiClient.dio);
}

/// Provider para Local DataSource de cidades.
/// 
/// Usa Hive para persistência local, sem dependência de SharedPreferences.
@riverpod
CityLocalDataSource cityLocalDataSource(Ref ref) {
  return CityLocalDataSourceImpl();
}

/// Provider para CityRepository (implementação concreta).
@riverpod
CityRepository cityRepository(Ref ref) {
  final remoteDataSource = ref.watch(cityRemoteDataSourceProvider);
  final localDataSource = ref.watch(cityLocalDataSourceProvider);
  final networkInfo = ref.watch(networkInfoProvider);

  return CityRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
    networkInfo: networkInfo,
  );
}

// ══════════════════════════════════════════════════════════════════════════
// USE CASES
// ══════════════════════════════════════════════════════════════════════════

/// Provider para SearchCities UseCase.
@riverpod
SearchCities searchCitiesUseCase(Ref ref) {
  final repository = ref.watch(cityRepositoryProvider);
  return SearchCities(repository);
}

/// Provider para SaveSelectedCity UseCase.
@riverpod
SaveSelectedCity saveSelectedCityUseCase(Ref ref) {
  final repository = ref.watch(cityRepositoryProvider);
  return SaveSelectedCity(repository);
}

/// Provider para GetSavedCity UseCase.
@riverpod
GetSavedCity getSavedCityUseCase(Ref ref) {
  final repository = ref.watch(cityRepositoryProvider);
  return GetSavedCity(repository);
}
