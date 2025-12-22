import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/city.dart';
import '../repositories/city_repository.dart';

/// Use Case para buscar cidades.
///
/// Encapsula a regra de negócio de busca de cidades.
/// Cada Use Case tem uma única responsabilidade (Single Responsibility Principle).
///
/// No contexto do TCC, demonstra separação clara entre:
/// - Regras de negócio (Use Cases)
/// - Acesso a dados (Repositories)
/// - Apresentação (Providers/UI)
class SearchCities {
  final CityRepository repository;

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
      return Left(
        const ValidationFailure(
          message: 'Digite o nome da cidade para buscar.',
        ),
      );
    }

    if (query.trim().length < 3) {
      return Left(
        const ValidationFailure(
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
  final CityRepository repository;

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
  final CityRepository repository;

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
