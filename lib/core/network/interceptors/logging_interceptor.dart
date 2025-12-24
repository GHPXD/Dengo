import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Interceptor para logging detalhado de requisições HTTP.
///
/// Facilita debug durante desenvolvimento ao mostrar:
/// - URL e método de cada request
/// - Headers enviados
/// - Body da requisição/resposta
/// - Status code e tempo de resposta
///
/// IMPORTANTE: Em produção (release mode), este interceptor
/// pode ser desabilitado para performance.
class LoggingInterceptor extends Interceptor {
  /// Instância do logger para registrar eventos HTTP
  final Logger logger;

  /// Cria interceptor de logging
  LoggingInterceptor(this.logger);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.d('''
    ╔══════════════════════════════════════════════════════════════
    ║ REQUEST
    ╠══════════════════════════════════════════════════════════════
    ║ URL: ${options.uri}
    ║ METHOD: ${options.method}
    ║ HEADERS: ${options.headers}
    ║ BODY: ${options.data}
    ╚══════════════════════════════════════════════════════════════
    ''');

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.i('''
    ╔══════════════════════════════════════════════════════════════
    ║ RESPONSE
    ╠══════════════════════════════════════════════════════════════
    ║ URL: ${response.requestOptions.uri}
    ║ STATUS CODE: ${response.statusCode}
    ║ DATA: ${response.data}
    ╚══════════════════════════════════════════════════════════════
    ''');

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.e('''
    ╔══════════════════════════════════════════════════════════════
    ║ ERROR
    ╠══════════════════════════════════════════════════════════════
    ║ URL: ${err.requestOptions.uri}
    ║ METHOD: ${err.requestOptions.method}
    ║ STATUS CODE: ${err.response?.statusCode}
    ║ MESSAGE: ${err.message}
    ║ RESPONSE: ${err.response?.data}
    ╚══════════════════════════════════════════════════════════════
    ''');

    handler.next(err);
  }
}
