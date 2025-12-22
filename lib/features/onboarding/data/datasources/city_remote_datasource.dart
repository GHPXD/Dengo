import 'package:dio/dio.dart';

import '../models/city_model.dart';

/// Data Source remoto para buscar cidades da API.
///
/// Responsável apenas por fazer requisições HTTP e retornar dados brutos.
/// Não trata erros de negócio, apenas exceções técnicas (IOException, etc).
abstract class CityRemoteDataSource {
  /// Busca cidades na API por query.
  Future<List<CityModel>> searchCities(String query);

  /// Busca cidade específica por código IBGE.
  Future<CityModel> getCityByIbgeCode(String ibgeCode);
}

class CityRemoteDataSourceImpl implements CityRemoteDataSource {
  final Dio dio;

  CityRemoteDataSourceImpl(this.dio);

  @override
  Future<List<CityModel>> searchCities(String query) async {
    // TODO: Substituir por endpoint real da API
    // Exemplo: final response = await dio.get('/cities/search', queryParameters: {'q': query});

    // Mock temporário para desenvolvimento (será substituído)
    await Future.delayed(const Duration(milliseconds: 500));

    // Retorna dados mockados para teste
    return _getMockCities()
        .where((city) =>
            city.name.toLowerCase().contains(query.toLowerCase()) ||
            city.state.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<CityModel> getCityByIbgeCode(String ibgeCode) async {
    // TODO: Implementar quando API estiver disponível
    await Future.delayed(const Duration(milliseconds: 300));

    final cities = _getMockCities();
    return cities.firstWhere(
      (city) => city.ibgeCode == ibgeCode,
      orElse: () => throw Exception('Cidade não encontrada'),
    );
  }

  /// Dados mockados de cidades brasileiras para desenvolvimento.
  /// ID agora usa código IBGE (formato real esperado pelo backend).
  /// Será removido quando integração com API real estiver pronta.
  List<CityModel> _getMockCities() {
    return [
      const CityModel(
        id: '3550308', // São Paulo (IBGE)
        name: 'São Paulo',
        state: 'SP',
        ibgeCode: '3550308',
        latitude: -23.5505,
        longitude: -46.6333,
        population: 12325232,
      ),
      const CityModel(
        id: '3304557', // Rio de Janeiro (IBGE)
        name: 'Rio de Janeiro',
        state: 'RJ',
        ibgeCode: '3304557',
        latitude: -22.9068,
        longitude: -43.1729,
        population: 6747815,
      ),
      const CityModel(
        id: '4106902', // Curitiba (IBGE)
        name: 'Curitiba',
        state: 'PR',
        ibgeCode: '4106902',
        latitude: -25.4284,
        longitude: -49.2733,
        population: 1963726,
      ),
      const CityModel(
        id: '4105805', // Colombo (IBGE)
        name: 'Colombo',
        state: 'PR',
        ibgeCode: '4105805',
        latitude: -25.2919,
        longitude: -49.2243,
        population: 242950,
      ),
      const CityModel(
        id: '5300108', // Brasília (IBGE)
        name: 'Brasília',
        state: 'DF',
        ibgeCode: '5300108',
        latitude: -15.7939,
        longitude: -47.8828,
        population: 3055149,
      ),
      const CityModel(
        id: '2927408', // Salvador (IBGE)
        name: 'Salvador',
        state: 'BA',
        ibgeCode: '2927408',
        latitude: -12.9714,
        longitude: -38.5014,
        population: 2886698,
      ),
      const CityModel(
        id: '2304400', // Fortaleza (IBGE)
        name: 'Fortaleza',
        state: 'CE',
        ibgeCode: '2304400',
        latitude: -3.7172,
        longitude: -38.5433,
        population: 2686612,
      ),
      const CityModel(
        id: '3106200', // Belo Horizonte (IBGE)
        name: 'Belo Horizonte',
        state: 'MG',
        ibgeCode: '3106200',
        latitude: -19.9167,
        longitude: -43.9345,
        population: 2521564,
      ),
      const CityModel(
        id: '1302603', // Manaus (IBGE)
        name: 'Manaus',
        state: 'AM',
        ibgeCode: '1302603',
        latitude: -3.1190,
        longitude: -60.0217,
        population: 2219580,
      ),
      const CityModel(
        id: '2611606', // Recife (IBGE)
        name: 'Recife',
        state: 'PE',
        ibgeCode: '2611606',
        latitude: -8.0476,
        longitude: -34.8770,
        population: 1653461,
      ),
      const CityModel(
        id: '4314902', // Porto Alegre (IBGE)
        name: 'Porto Alegre',
        state: 'RS',
        ibgeCode: '4314902',
        latitude: -30.0346,
        longitude: -51.2177,
        population: 1488252,
      ),
    ];
  }
}
