import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/config/app_config.dart';
import 'core/config/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/data/models/city_model.dart';

/// Entry point do aplicativo Dengo.
///
/// Inicializa os serviços essenciais (Hive para cache local) e
/// configura o ProviderScope do Riverpod para gerenciamento de estado global.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialização do Hive para armazenamento local (cache offline)
  await Hive.initFlutter();

  // IMPORTANTE: Execute 'dart run build_runner build' antes para gerar os adapters
  // Registra TypeAdapters do Hive (gerados automaticamente pelo build_runner)
  Hive.registerAdapter(CityModelAdapter());

  // Abre a box de cidades (será criada se não existir)
  await Hive.openBox<CityModel>('cities');

  runApp(const ProviderScope(child: DengoApp()));
}

/// Widget raiz do aplicativo.
///
/// Aplica o tema customizado e integra GoRouter para navegação declarativa.
class DengoApp extends ConsumerWidget {
  /// Construtor padrão do widget raiz.
  const DengoApp({super.key});

  /// Builds the root widget of the app
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,

      // ────────────────────────────────────────────────────────────────────────
      // TEMAS (Light e Dark)
      // ────────────────────────────────────────────────────────────────────────
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Respeita preferência do sistema

      routerConfig: router,
    );
  }
}