import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/config/app_config.dart';
import 'core/config/app_router.dart';
import 'core/theme/app_theme.dart';

/// Entry point do aplicativo Dengo.
///
/// Inicializa os serviços essenciais (Hive para cache local) e
/// configura o ProviderScope do Riverpod para gerenciamento de estado global.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialização do Hive para armazenamento local (cache offline)
  await Hive.initFlutter();

  // TODO: Registrar TypeAdapters do Hive aqui quando os models estiverem prontos
  // Exemplo: Hive.registerAdapter(CityAdapter());

  runApp(const ProviderScope(child: DengoApp()));
}

/// Widget raiz do aplicativo.
///
/// Aplica o tema customizado e integra GoRouter para navegação declarativa.
class DengoApp extends ConsumerWidget {
  const DengoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
