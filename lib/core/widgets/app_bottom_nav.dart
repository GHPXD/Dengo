import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/app_router.dart';
import '../theme/app_colors.dart';
import '../../features/onboarding/presentation/providers/city_search_provider.dart';

/// Bottom Navigation Bar compartilhado entre todas as telas principais.
///
/// Usa [context.go()] para navegação lateral eficiente.
class AppBottomNav extends ConsumerWidget {
  /// Indica o índice do item atualmente ativo na navegação.
  final int currentIndex;

  /// Construtor constante.
  const AppBottomNav({
    required this.currentIndex,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. Dashboard (Home)
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            isActive: currentIndex == 0,
            onTap: () => context.go(AppRoutes.dashboard),
          ),

          // 2. Predições IA
          _NavItem(
            icon: Icons.analytics_rounded,
            label: 'Predições',
            isActive: currentIndex == 1,
            onTap: () {
              // Tenta pegar a cidade selecionada do estado global
              final selectedCity = ref.read(selectedCityProvider);
              
              context.go(
                AppRoutes.predictions,
                extra: {
                  // CORREÇÃO: Usar 'ibgeCode' conforme definido na entidade City
                  'geocode': selectedCity?.ibgeCode ?? '4106902', // Fallback Curitiba
                  'cityName': selectedCity?.name ?? 'Curitiba',
                },
              );
            },
          ),

          // 3. Mapa de Calor
          _NavItem(
            icon: Icons.map_rounded,
            label: 'Mapa',
            isActive: currentIndex == 2,
            onTap: () => context.go(AppRoutes.heatmap),
          ),

          // 4. Tendências
          _NavItem(
            icon: Icons.bar_chart_rounded,
            label: 'Trends',
            isActive: currentIndex == 3,
            onTap: () => context.go(AppRoutes.trends),
          ),

          // 5. Detalhes
          _NavItem(
            icon: Icons.location_city,
            label: 'Cidade',
            isActive: currentIndex == 4,
            onTap: () => context.go(AppRoutes.cityDetail),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // CORREÇÃO: Usar 'const' pois AppColors são constantes estáticas
    const activeColor = AppColors.primary; 
    const inactiveColor = AppColors.textTertiary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, // Melhora a área de toque
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 26,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 4),
            if (isActive)
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: activeColor,
                ),
              )
            else
              const SizedBox(height: 12), // Mantém o alinhamento
          ],
        ),
      ),
    );
  }
}