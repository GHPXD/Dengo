import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Configurações globais do aplicativo DenguePredict.
///
/// Centraliza informações estáticas como nome, versão, URLs de API,
/// timeouts e outras constantes de configuração.
/// Facilita manutenção e documentação do projeto para o TCC.
class AppConfig {
  AppConfig._(); // Construtor privado para prevenir instanciação

  // ══════════════════════════════════════════════════════════════════════════
  // INFORMAÇÕES DO APLICATIVO
  // ══════════════════════════════════════════════════════════════════════════

  static const String appName = 'Dengo';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Previsão de casos de dengue usando Inteligência Artificial';

  // ══════════════════════════════════════════════════════════════════════════
  // CONFIGURAÇÕES DE API
  // ══════════════════════════════════════════════════════════════════════════

  /// URL base da API Python do Dengo (dinâmica por plataforma).
  ///
  /// A API Python orquestra:
  /// - Busca de dados climáticos no OpenWeather
  /// - Processamento de predição com IA (scikit-learn)
  ///
  /// LÓGICA DE URL:
  /// - Web/iOS: http://127.0.0.1:8000/api/v1 (localhost)
  /// - Android: http://10.0.2.2:8000/api/v1 (IP especial do emulador Android)
  /// - Produção: https://api.dengo.app/api/v1 (quando fazer deploy)
  static String get apiBaseUrl {
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
  static const int apiTimeoutMs = 30000; // 30 segundos

  /// Timeout para requisições de conexão
  static const int connectTimeoutMs = 15000; // 15 segundos

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

  // ══════════════════════════════════════════════════════════════════════════
  // NÍVEIS DE RISCO (Thresholds)
  // ══════════════════════════════════════════════════════════════════════════

  /// Threshold de risco baixo (verde) - casos por 100k habitantes
  static const double lowRiskThreshold = 100.0;

  /// Threshold de risco médio (amarelo) - casos por 100k habitantes
  static const double mediumRiskThreshold = 300.0;

  /// Acima deste valor é considerado risco alto (vermelho)
  static const double highRiskThreshold = 300.0;
}
