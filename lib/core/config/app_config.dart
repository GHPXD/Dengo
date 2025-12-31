import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Configurações globais do aplicativo Dengo.
///
/// Centraliza informações estáticas como nome, versão, URLs de API,
/// timeouts e outras constantes de configuração.
/// Sistema escalável de previsão de dengue, iniciando pelo Paraná com expansão futura para outros estados.
class AppConfig {
  AppConfig._(); // Construtor privado para prevenir instanciação

  // ══════════════════════════════════════════════════════════════════════════
  // INFORMAÇÕES DO APLICATIVO
  // ══════════════════════════════════════════════════════════════════════════

  /// Nome do aplicativo exibido ao usuário.
  static const String appName = 'Dengo';

  /// Versão atual do aplicativo (formato semver).
  static const String appVersion = '1.0.0';

  /// Descrição curta do propósito do aplicativo.
  static const String appDescription =
      'Previsão de casos de dengue usando Inteligência Artificial';

  // ══════════════════════════════════════════════════════════════════════════
  // CONFIGURAÇÕES DE API
  // ══════════════════════════════════════════════════════════════════════════

  /// Define se está em modo produção (conecta ao Render)
  /// Mude para `true` quando quiser usar o backend online
  static const bool isProduction = false;

  /// URL do backend em produção (Render)
  /// Será algo como: https://dengo-api.onrender.com/api/v1
  static const String productionApiUrl = 'https://dengo-api.onrender.com/api/v1';

  /// URL base da API Python do Dengo (dinâmica por plataforma/ambiente).
  ///
  /// A API Python orquestra:
  /// - Busca de dados climáticos no OpenWeather
  /// - Processamento de predição com IA
  ///
  /// LÓGICA DE URL:
  /// - Produção: https://dengo-api.onrender.com/api/v1 (Render)
  /// - Dev Web/iOS: http://127.0.0.1:8000/api/v1 (localhost)
  /// - Dev Android: http://10.0.2.2:8000/api/v1 (IP especial do emulador)
  static String get apiBaseUrl {
    // Se produção, sempre usar Render
    if (isProduction) {
      return productionApiUrl;
    }
    
    // Desenvolvimento local
    if (kIsWeb) {
      // Flutter Web
      return 'http://127.0.0.1:8000/api/v1';
    } else if (Platform.isAndroid) {
      // Android Emulator (10.0.2.2 = localhost da máquina host)
      return 'http://10.0.2.2:8000/api/v1';
    } else {
      // iOS Simulator ou dispositivo físico
      return 'http://127.0.0.1:8000/api/v1';
    }
  }

  /// Timeout padrão para requisições HTTP (em milissegundos)
  static const int apiTimeoutMs = 45000; // 45 segundos (ML pode demorar)

  /// Timeout para requisições de conexão
  static const int connectTimeoutMs = 10000; // 10 segundos

  /// Número de tentativas de retry em caso de erro
  static const int maxRetryAttempts = 2;

  /// Delay entre tentativas de retry (em milissegundos)
  static const int retryDelayMs = 1000; // 1 segundo

  // ══════════════════════════════════════════════════════════════════════════
  // CONFIGURAÇÕES DE CACHE
  // ══════════════════════════════════════════════════════════════════════════

  /// Duração em horas que os dados de previsão ficam em cache
  static const int cacheDurationHours = 6;

  /// Nome da box do Hive para armazenar dados de cidades
  static const String citiesBoxName = 'cities_cache';

  /// Nome da box do Hive para armazenar previsões
  static const String predictionsBoxName = 'predictions_cache';

  // ══════════════════════════════════════════════════════════════════════════
  // CONFIGURAÇÕES DE MAPAS
  // ══════════════════════════════════════════════════════════════════════════

  /// URL template para tiles do OpenStreetMap
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Zoom inicial padrão do mapa
  static const double defaultMapZoom = 13.0;

  /// Zoom mínimo permitido
  static const double minMapZoom = 5.0;

  /// Zoom máximo permitido
  static const double maxMapZoom = 18.0;
}
