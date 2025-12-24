import 'package:hive/hive.dart';

import '../models/city_model.dart';

/// Data Source local para armazenar cidade selecionada.
///
/// Usa Hive (NoSQL local database) para persistir a cidade escolhida.
/// Permite que o app "lembre" da cidade mesmo após fechar.
/// Mais rápido e eficiente que SharedPreferences para objetos complexos.
abstract class CityLocalDataSource {
  /// Salva cidade localmente no cache Hive.
  Future<void> cacheCity(CityModel city);

  /// Recupera última cidade salva do cache.
  ///
  /// Retorna null se nenhuma cidade estiver salva.
  Future<CityModel?> getLastCity();

  /// Verifica se há cidade salva.
  Future<bool> hasSavedCity();

  /// Remove cidade salva (logout/reset).
  Future<void> clearSavedCity();
}

/// Implementation of [CityLocalDataSource] using Hive.
class CityLocalDataSourceImpl implements CityLocalDataSource {
  /// Nome da box Hive usada para armazenar cidades.
  static const String boxName = 'cities';
  
  /// Chave para armazenar a última cidade selecionada.
  static const String _lastCityKey = 'last_selected_city';

  /// Box do Hive que armazena objetos CityModel.
  Box<CityModel> get _box => Hive.box<CityModel>(boxName);

  @override
  Future<void> cacheCity(CityModel city) async {
    // Salva a cidade com uma chave fixa (última selecionada)
    await _box.put(_lastCityKey, city);
  }

  @override
  Future<CityModel?> getLastCity() async {
    final city = _box.get(_lastCityKey);
    
    if (city == null) {
      return null;
    }
    
    // Debug: Cidade recuperada do cache Hive
    return city;
  }

  @override
  Future<bool> hasSavedCity() async {
    return _box.containsKey(_lastCityKey);
  }

  @override
  Future<void> clearSavedCity() async {
    await _box.delete(_lastCityKey);
  }
}
