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
CityRemoteDataSource cityRemoteDataSource(CityRemoteDataSourceRef ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CityRemoteDataSourceImpl(apiClient.dio);
}

/// Provider para Local DataSource de cidades.
@riverpod
Future<CityLocalDataSource> cityLocalDataSource(
  CityLocalDataSourceRef ref,
) async {
  final sharedPrefs = await ref.watch(sharedPreferencesProvider.future);
  return CityLocalDataSourceImpl(sharedPrefs);
}

/// Provider para CityRepository (implementação concreta).
@riverpod
Future<CityRepository> cityRepository(CityRepositoryRef ref) async {
  final remoteDataSource = ref.watch(cityRemoteDataSourceProvider);
  final localDataSource = await ref.watch(cityLocalDataSourceProvider.future);
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
Future<SearchCities> searchCitiesUseCase(SearchCitiesUseCaseRef ref) async {
  final repository = await ref.watch(cityRepositoryProvider.future);
  return SearchCities(repository);
}

/// Provider para SaveSelectedCity UseCase.
@riverpod
Future<SaveSelectedCity> saveSelectedCityUseCase(
  SaveSelectedCityUseCaseRef ref,
) async {
  final repository = await ref.watch(cityRepositoryProvider.future);
  return SaveSelectedCity(repository);
}

/// Provider para GetSavedCity UseCase.
@riverpod
Future<GetSavedCity> getSavedCityUseCase(GetSavedCityUseCaseRef ref) async {
  final repository = await ref.watch(cityRepositoryProvider.future);
  return GetSavedCity(repository);
}
