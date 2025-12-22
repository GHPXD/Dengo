import 'package:connectivity_plus/connectivity_plus.dart';

/// Utilitário para verificar conectividade de rede.
///
/// Útil para exibir mensagens offline ou usar cache local
/// quando não há internet disponível.
///
/// No contexto do TCC, demonstra preocupação com UX offline-first.
class NetworkInfo {
  final Connectivity connectivity;

  NetworkInfo(this.connectivity);

  /// Verifica se o dispositivo está conectado à internet.
  ///
  /// Retorna `true` se há WiFi ou dados móveis ativos.
  /// Não garante que a internet esteja funcionando, apenas que
  /// há uma conexão de rede disponível.
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();

    return result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.ethernet);
  }

  /// Stream que emite eventos de mudança de conectividade.
  ///
  /// Útil para atualizar a UI em tempo real quando a conexão
  /// cai ou retorna.
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return connectivity.onConnectivityChanged;
  }
}
