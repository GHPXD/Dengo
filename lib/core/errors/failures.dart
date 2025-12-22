import 'package:equatable/equatable.dart';

/// Classe abstrata base para todos os tipos de falhas na aplicação.
///
/// Utilizada em conjunto com o tipo `Either<Failure, Success>` do pacote Dartz
/// para implementar programação funcional e tratamento de erros robusto.
///
/// No contexto do TCC, esta abordagem demonstra maturidade técnica ao evitar
/// exceções não tratadas e fornecer feedback estruturado ao usuário.
abstract class Failure extends Equatable {
  final String message;
  final StackTrace? stackTrace;

  const Failure({required this.message, this.stackTrace});

  @override
  List<Object?> get props => [message, stackTrace];
}

// ══════════════════════════════════════════════════════════════════════════
// FALHAS DE SERVIDOR/API
// ══════════════════════════════════════════════════════════════════════════

/// Falha ao comunicar com o servidor (timeout, erro de conexão, etc).
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.stackTrace});
}

/// Falha de autenticação (401, token inválido, etc).
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({required super.message, super.stackTrace});
}

/// Falha de validação nos dados enviados (400, campos inválidos).
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.stackTrace});
}

// ══════════════════════════════════════════════════════════════════════════
// FALHAS DE REDE E CONECTIVIDADE
// ══════════════════════════════════════════════════════════════════════════

/// Falha de conexão com a internet (dispositivo offline).
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Sem conexão com a internet. Verifique sua rede.',
    super.stackTrace,
  });
}

/// Timeout de requisição (servidor demorou demais para responder).
class TimeoutFailure extends Failure {
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
  const CacheFailure({required super.message, super.stackTrace});
}

// ══════════════════════════════════════════════════════════════════════════
// FALHAS DE PARSE E SERIALIZAÇÃO
// ══════════════════════════════════════════════════════════════════════════

/// Falha ao fazer parse de JSON ou deserializar modelo.
class ParseFailure extends Failure {
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
  const UnknownFailure({
    super.message = 'Ocorreu um erro inesperado. Tente novamente.',
    super.stackTrace,
  });
}
