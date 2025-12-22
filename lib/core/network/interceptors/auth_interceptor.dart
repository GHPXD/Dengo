import 'package:dio/dio.dart';

/// Interceptor de autenticação para adicionar tokens automaticamente.
///
/// Em um cenário real, este interceptor:
/// - Recuperaria o token de autenticação do cache (SharedPreferences/Hive)
/// - Adicionaria no header Authorization de cada requisição
/// - Trataria refresh de tokens expirados
///
/// Para o TCC, pode ser implementado conforme a API backend exigir.
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // TODO: Implementar lógica de autenticação quando necessário
    // Exemplo:
    // final token = await _getTokenFromStorage();
    // if (token != null) {
    //   options.headers['Authorization'] = 'Bearer $token';
    // }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Tratamento de erro 401 (não autorizado)
    if (err.response?.statusCode == 401) {
      // TODO: Implementar refresh token ou redirecionar para login
    }

    handler.next(err);
  }
}
