import 'package:equatable/equatable.dart';

/// Classe abstrata base para todos os tipos de falhas na aplicação.
///
/// Utilizada em conjunto com o tipo `Either<Failure, Success>` do pacote Dartz
/// para implementar programação funcional e tratamento de erros robusto.
///
/// Esta abordagem evita exceções não tratadas e fornece feedback estruturado ao usuário.
abstract class Failure extends Equatable {
  /// Mensagem descritiva do erro para exibição ao usuário ou log.
  final String message;
  /// Rastreamento da pilha de execução onde o erro ocorreu (opcional).
  final StackTrace? stackTrace;

  /// Construtor base para todas as falhas.
  const Failure({required this.message, this.stackTrace});

  @override
  List<Object?> get props => [message, stackTrace];
}

// ══════════════════════════════════════════════════════════════════════════
// FALHAS DE SERVIDOR/API
// ══════════════════════════════════════════════════════════════════════════

/// Falha ao comunicar com o servidor (timeout, erro de conexão, etc).
class ServerFailure extends Failure {
  /// Cria uma falha de servidor com mensagem customizada.
  const ServerFailure({required super.message, super.stackTrace});
}

/// Falha de autenticação (401, token inválido, etc).
class AuthenticationFailure extends Failure {
  /// Cria uma falha de autenticação com mensagem customizada.
  const AuthenticationFailure({required super.message, super.stackTrace});
}

/// Falha de validação nos dados enviados (400, campos inválidos).
class ValidationFailure extends Failure {
  /// Cria uma falha de validação com mensagem customizada.
  const ValidationFailure({required super.message, super.stackTrace});
}

/// Falha de recurso não encontrado (404).
class NotFoundFailure extends Failure {
  /// Cria uma falha de recurso não encontrado com mensagem customizada.
  const NotFoundFailure({required super.message, super.stackTrace});
}

// ══════════════════════════════════════════════════════════════════════════
// FALHAS DE REDE E CONECTIVIDADE
// ══════════════════════════════════════════════════════════════════════════

/// Falha de conexão com a internet (dispositivo offline).
class NetworkFailure extends Failure {
  /// Cria uma falha de rede com mensagem padrão ou customizada.
  const NetworkFailure({
    super.message = 'Sem conexão com a internet. Verifique sua rede.',
    super.stackTrace,
  });
}

/// Timeout de requisição (servidor demorou demais para responder).
class TimeoutFailure extends Failure {
  /// Cria uma falha de timeout com mensagem padrão ou customizada.
  const TimeoutFailure({
    super.message = 'A requisição demorou muito. Tente novamente.',
    super.stackTrace,
  });
}

// ══════════════════════════════════════════════════════════════════════════
// FALHAS DE CACHE E ARMAZENAMENTO LOCAL
// ══════════════════════════════════════════════════════════════════════════

/// Falha ao acessar ou salvar dados no cache local (Hive, SharedPreferences).
class CacheFailure extends Failure {
  /// Cria uma falha de cache com mensagem customizada.
  const CacheFailure({required super.message, super.stackTrace});
}

// ══════════════════════════════════════════════════════════════════════════
// FALHAS DE PARSE E SERIALIZAÇÃO
// ══════════════════════════════════════════════════════════════════════════

/// Falha ao fazer parse de JSON ou deserializar modelo.
class ParseFailure extends Failure {
  /// Cria uma falha de parse com mensagem padrão ou customizada.
  const ParseFailure({
    super.message = 'Erro ao processar os dados recebidos.',
    super.stackTrace,
  });
}

// ══════════════════════════════════════════════════════════════════════════
// FALHAS GENÉRICAS
// ══════════════════════════════════════════════════════════════════════════

/// Falha genérica quando nenhuma outra categoria se aplica.
class UnknownFailure extends Failure {
  /// Cria uma falha genérica com mensagem padrão ou customizada.
  const UnknownFailure({
    super.message = 'Ocorreu um erro inesperado. Tente novamente.',
    super.stackTrace,
  });
}
