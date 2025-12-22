import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/error_interceptor.dart';

/// Client HTTP configurado com Dio para comunicação com a API.
///
/// Utiliza interceptors para:
/// - Logging de requisições/respostas (debug)
/// - Autenticação automática (headers)
/// - Tratamento de erros centralizado
///
/// Este setup demonstra boas práticas de arquitetura para o TCC,
/// permitindo manutenção e testabilidade do código.
class ApiClient {
  late final Dio _dio;
  final Logger _logger = Logger();

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: Duration(milliseconds: AppConfig.connectTimeoutMs),
        receiveTimeout: Duration(milliseconds: AppConfig.apiTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  /// Configura os interceptors na ordem correta.
  /// A ordem importa: logging deve vir por último para capturar tudo.
  void _setupInterceptors() {
    _dio.interceptors.addAll([
      AuthInterceptor(),
      ErrorInterceptor(),
      LoggingInterceptor(_logger),
    ]);
  }

  /// Getter para acessar a instância do Dio configurado.
  /// Útil para injeção de dependência em repositories.
  Dio get dio => _dio;

  // ══════════════════════════════════════════════════════════════════════════
  // MÉTODOS HTTP CONVENIENTES (Wrappers)
  // ══════════════════════════════════════════════════════════════════════════

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
