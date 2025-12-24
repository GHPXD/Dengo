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
        userFriendlyMessage =
            'Tempo de conexão esgotado. Verifique se o servidor está acessível.';
        break;

      case DioExceptionType.sendTimeout:
        userFriendlyMessage =
            'Tempo de envio esgotado. Sua conexão pode estar lenta.';
        break;

      case DioExceptionType.receiveTimeout:
        userFriendlyMessage =
            'O servidor demorou para responder. Tente novamente.';
        break;

      case DioExceptionType.badResponse:
        userFriendlyMessage = _handleStatusCode(
          err.response?.statusCode,
          err.response?.data,
        );
        break;

      case DioExceptionType.cancel:
        userFriendlyMessage = 'Requisição cancelada pelo usuário.';
        break;

      case DioExceptionType.connectionError:
        // Mensagem específica para CORS ou backend offline
        if (err.message?.contains('XMLHttpRequest') == true ||
            err.message?.contains('CORS') == true) {
          userFriendlyMessage =
              'Erro de conexão (CORS). Verifique se o backend está rodando.';
        } else {
          userFriendlyMessage =
              'Não foi possível conectar ao servidor. Verifique sua internet ou se o backend está ativo.';
        }
        break;

      case DioExceptionType.badCertificate:
        userFriendlyMessage =
            'Certificado SSL inválido. Conexão não segura.';
        break;

      case DioExceptionType.unknown:
        // Tenta identificar erro de rede
        if (err.message?.toLowerCase().contains('failed host lookup') ==
            true) {
          userFriendlyMessage =
              'Servidor não encontrado. Verifique a URL da API.';
        } else if (err.message?.toLowerCase().contains('network') == true) {
          userFriendlyMessage =
              'Erro de rede. Verifique sua conexão com a internet.';
        } else {
          userFriendlyMessage =
              'Erro desconhecido. Tente novamente mais tarde.';
        }
        break;
    }

    // Sobrescreve a mensagem de erro com versão amigável
    final modifiedError = err.copyWith(
      message: userFriendlyMessage,
    );

    handler.next(modifiedError);
  }

  /// Mapeia códigos de status HTTP para mensagens amigáveis.
  String _handleStatusCode(int? statusCode, dynamic responseData) {
    // Tenta extrair mensagem de erro do backend
    String? backendMessage;
    if (responseData is Map) {
      backendMessage = responseData['detail']?.toString() ??
          responseData['message']?.toString() ??
          responseData['error']?.toString();
    }

    switch (statusCode) {
      case 400:
        return backendMessage ??
            'Dados inválidos. Verifique as informações e tente novamente.';
      case 401:
        return backendMessage ?? 'Não autorizado. Faça login novamente.';
      case 403:
        return backendMessage ??
            'Acesso negado. Você não tem permissão para esta ação.';
      case 404:
        return backendMessage ??
            'Cidade não encontrada. Selecione outra cidade.';
      case 422:
        return backendMessage ??
            'Erro de validação. Verifique os dados enviados.';
      case 429:
        return 'Muitas requisições. Aguarde um momento e tente novamente.';
      case 500:
        return 'Erro interno do servidor. Tente novamente mais tarde.';
      case 502:
        return 'Gateway inválido. O servidor pode estar offline.';
      case 503:
        return 'Serviço temporariamente indisponível. Tente em alguns minutos.';
      case 504:
        return 'Timeout do servidor. O servidor demorou para responder.';
      default:
        return backendMessage ??
            'Erro ao processar sua solicitação. Código: $statusCode';
    }
  }
}
