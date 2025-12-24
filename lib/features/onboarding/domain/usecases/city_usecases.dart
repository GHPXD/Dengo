import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/city.dart';
import '../repositories/city_repository.dart';

/// Use Case para buscar cidades.
///
/// Encapsula a regra de negócio de busca de cidades.
/// Cada Use Case tem uma única responsabilidade (Single Responsibility Principle).
///
/// Demonstra separação clara entre:
/// - Regras de negócio (Use Cases)
/// - Acesso a dados (Repositories)
/// - Apresentação (Providers/UI)
class SearchCities {
  /// Repositório para acesso aos dados de cidades
  final CityRepository repository;

  /// Cria use case de busca de cidades
  SearchCities(this.repository);

  /// Executa a busca de cidades.
  ///
  /// [query]: Texto de busca fornecido pelo usuário
  ///
  /// Validações:
  /// - Query não pode ser vazia
  /// - Query deve ter pelo menos 3 caracteres para otimizar busca
  Future<Either<Failure, List<City>>> call(String query) async {
    // Validação de entrada
    if (query.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Digite o nome da cidade para buscar.',
        ),
      );
    }

    if (query.trim().length < 3) {
      return const Left(
        ValidationFailure(
          message: 'Digite pelo menos 3 caracteres para buscar.',
        ),
      );
    }

    // Delega ao repository
    return await repository.searchCities(query.trim());
  }
}

/// Use Case para salvar a cidade selecionada.
class SaveSelectedCity {
  /// Repositório para persistir dados de cidades
  final CityRepository repository;

  /// Cria use case para salvar cidade
  SaveSelectedCity(this.repository);

  /// Salva a cidade escolhida pelo usuário.
  ///
  /// [city]: Cidade a ser salva
  Future<Either<Failure, void>> call(City city) async {
    return await repository.saveCity(city);
  }
}

/// Use Case para obter a cidade salva.
class GetSavedCity {
  /// Repositório para recuperar dados de cidades
  final CityRepository repository;

  /// Cria use case para obter cidade salva
  GetSavedCity(this.repository);

  /// Recupera a cidade previamente salva.
  ///
  /// Útil para:
  /// - Pular onboarding se cidade já foi selecionada
  /// - Carregar dados da cidade do usuário ao iniciar app
  Future<Either<Failure, City>> call() async {
    return await repository.getSavedCity();
  }
}
