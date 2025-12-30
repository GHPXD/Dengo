import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:retry/retry.dart';

import '../config/app_config.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/error_interceptor.dart';

/// Client HTTP configurado com Dio para comunicação com a API.
///
/// Utiliza interceptors para:
/// - Logging de requisições/respostas (debug)
/// - Autenticação automática (headers)
/// - Tratamento de erros centralizado
/// - Retry automático em caso de falhas de rede
///
/// Arquitetura robusta que facilita manutenção e testabilidade do código.
class ApiClient {
  late final Dio _dio;
  final Logger _logger = Logger();
  late final RetryOptions _retryOptions;

  /// Construtor que inicializa o Dio com as configurações padrão do [AppConfig].
  ///
  /// Define timeouts, headers padrão (JSON) e a política de retry para
  /// falhas de rede.
  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(milliseconds: AppConfig.connectTimeoutMs),
        receiveTimeout: const Duration(milliseconds: AppConfig.apiTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Configura política de retry: 2 tentativas com delay exponencial
    _retryOptions = const RetryOptions(
      maxAttempts: AppConfig.maxRetryAttempts,
      delayFactor: Duration(milliseconds: AppConfig.retryDelayMs),
      maxDelay: Duration(seconds: 5),
    );

    _setupInterceptors();
  }

  /// Configura os interceptors na ordem correta.
  /// A ordem importa: logging deve vir por último para capturar tudo.
  void _setupInterceptors() {
    _dio.interceptors.addAll([
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

  /// GET request com retry automático
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _retryOptions.retry(
      () => _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      ),
      retryIf: (e) => e is DioException && _shouldRetry(e),
    );
  }

  /// POST request com retry automático
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _retryOptions.retry(
      () => _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      retryIf: (e) => e is DioException && _shouldRetry(e),
    );
  }

  /// PUT request com retry automático
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _retryOptions.retry(
      () => _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      retryIf: (e) => e is DioException && _shouldRetry(e),
    );
  }

  /// DELETE request com retry automático
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _retryOptions.retry(
      () => _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      retryIf: (e) => e is DioException && _shouldRetry(e),
    );
  }

  /// Determina se deve tentar novamente baseado no tipo de erro.
  /// Retries apenas para erros de rede/timeout, não para erros de servidor (4xx/5xx).
  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
  }
}