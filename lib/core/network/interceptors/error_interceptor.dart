import 'package:dio/dio.dart';

/// Interceptor para tratamento centralizado de erros HTTP.
///
/// Converte DioExceptions em mensagens amigáveis ao usuário,
/// evitando exposição de detalhes técnicos na UI.
///
/// Mapeia códigos HTTP para mensagens em português claro.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String userFriendlyMessage;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        userFriendlyMessage =
            'A conexão demorou muito. Verifique sua internet e tente novamente.';
        break;

      case DioExceptionType.badResponse:
        userFriendlyMessage = _handleStatusCode(err.response?.statusCode);
        break;

      case DioExceptionType.cancel:
        userFriendlyMessage = 'Requisição cancelada.';
        break;

      case DioExceptionType.connectionError:
        userFriendlyMessage = 'Sem conexão com a internet. Verifique sua rede.';
        break;

      default:
        userFriendlyMessage =
            'Ocorreu um erro inesperado. Tente novamente mais tarde.';
    }

    // Sobrescreve a mensagem de erro com versão amigável
    final modifiedError = err.copyWith(
      message: userFriendlyMessage,
    );

    handler.next(modifiedError);
  }

  /// Mapeia códigos de status HTTP para mensagens amigáveis.
  String _handleStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Dados inválidos. Verifique as informações e tente novamente.';
      case 401:
        return 'Não autorizado. Faça login novamente.';
      case 403:
        return 'Acesso negado. Você não tem permissão para esta ação.';
      case 404:
        return 'Recurso não encontrado. Verifique a URL.';
      case 500:
        return 'Erro no servidor. Tente novamente mais tarde.';
      case 503:
        return 'Serviço temporariamente indisponível. Tente em alguns minutos.';
      default:
        return 'Erro ao processar sua solicitação. Código: $statusCode';
    }
  }
}
