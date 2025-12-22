import 'package:shared_preferences/shared_preferences.dart';

import '../models/city_model.dart';
import 'dart:convert';

/// Data Source local para armazenar cidade selecionada.
///
/// Usa SharedPreferences para persistir a cidade escolhida pelo usuário.
/// Permite que o app "lembre" da cidade mesmo após fechar.
abstract class CityLocalDataSource {
  /// Salva cidade localmente.
  Future<void> saveCity(CityModel city);

  /// Recupera cidade salva.
  ///
  /// Throws: Exception se nenhuma cidade estiver salva.
  Future<CityModel> getSavedCity();

  /// Verifica se há cidade salva.
  Future<bool> hasSavedCity();

  /// Remove cidade salva (logout/reset).
  Future<void> clearSavedCity();
}

class CityLocalDataSourceImpl implements CityLocalDataSource {
  final SharedPreferences sharedPreferences;

  /// Chave usada para salvar no SharedPreferences.
  static const String _savedCityKey = 'saved_city';

  CityLocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<void> saveCity(CityModel city) async {
    final cityJson = jsonEncode(city.toJson());
    await sharedPreferences.setString(_savedCityKey, cityJson);
  }

  @override
  Future<CityModel> getSavedCity() async {
    final cityJson = sharedPreferences.getString(_savedCityKey);

    if (cityJson == null) {
      throw Exception('Nenhuma cidade salva');
    }

    final cityMap = jsonDecode(cityJson) as Map<String, dynamic>;
    return CityModel.fromJson(cityMap);
  }

  @override
  Future<bool> hasSavedCity() async {
    return sharedPreferences.containsKey(_savedCityKey);
  }

  @override
  Future<void> clearSavedCity() async {
    await sharedPreferences.remove(_savedCityKey);
  }
}
