import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/app_router.dart';


/// Bottom Navigation Bar compartilhado entre todas as telas principais.
///
/// Usa [context.go()] em vez de [context.push()] para navegação lateral
/// (não empilha rotas, apenas substitui).
class AppBottomNav extends ConsumerWidget {
  /// Indica qual item está atualmente ativo
  final int currentIndex;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {


    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. Dashboard (Home)
          _buildNavItem(
            icon: Icons.home_rounded,
            isActive: currentIndex == 0,
            onTap: () => context.go(AppRoutes.dashboard),
          ),

          // 2. Predições IA
          _buildNavItem(
            icon: Icons.analytics_rounded,
            isActive: currentIndex == 1,
            onTap: () {
              context.go(
                AppRoutes.predictions,
                extra: {
                  'geocode': '4106902',
                  'cityName': 'Curitiba',
                },
              );
            },
          ),

          // 3. Mapa de Calor (NOVO)
          _buildNavItem(
            icon: Icons.map_rounded,
            isActive: currentIndex == 2,
            onTap: () => context.go(AppRoutes.heatmap),
          ),

          // 4. Tendências/Gráficos
          _buildNavItem(
            icon: Icons.bar_chart_rounded,
            isActive: currentIndex == 3,
            onTap: () => context.go(AppRoutes.trends),
          ),

          // 5. Detalhes da Cidade
          _buildNavItem(
            icon: Icons.location_city,
            isActive: currentIndex == 4,
            onTap: () => context.go(AppRoutes.cityDetail),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Icon(
          icon,
          size: 28,
          color: isActive ? const Color(0xFFFF8A80) : const Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}
