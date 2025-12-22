import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import '../network/network_info.dart';

part 'app_providers.g.dart';

/// Providers globais da aplicação.
///
/// Centraliza a criação de providers para serviços essenciais
/// que são compartilhados por toda a aplicação.

// ══════════════════════════════════════════════════════════════════════════
// NETWORK
// ══════════════════════════════════════════════════════════════════════════

/// Provider para o ApiClient (Dio configurado).
///
/// Singleton que fornece acesso à instância configurada do Dio
/// para todos os repositories.
@riverpod
ApiClient apiClient(ApiClientRef ref) {
  return ApiClient();
}

/// Provider para NetworkInfo (Conectividade).
///
/// Verifica status de conexão com internet.
@riverpod
NetworkInfo networkInfo(NetworkInfoRef ref) {
  return NetworkInfo(Connectivity());
}

// ══════════════════════════════════════════════════════════════════════════
// STORAGE
// ══════════════════════════════════════════════════════════════════════════

/// Provider para SharedPreferences (configurações simples).
@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(SharedPreferencesRef ref) async {
  return await SharedPreferences.getInstance();
}
