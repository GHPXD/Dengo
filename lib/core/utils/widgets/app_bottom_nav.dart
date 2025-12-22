import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_router.dart';
import '../../theme/app_colors.dart';

/// Bottom Navigation Bar reutilizável para navegação principal.
///
/// Usado em: Dashboard, Heatmap e Education screens.
///
/// **Uso**:
/// ```dart
/// bottomNavigationBar: AppBottomNavBar(currentIndex: 0),
/// ```
class AppBottomNavBar extends StatelessWidget {
  /// Índice da aba atualmente selecionada (0 = Dashboard, 1 = Mapa, 2 = Educação)
  final int currentIndex;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textTertiary,
      onTap: (index) => _onTabTapped(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_rounded),
          label: 'Mapa',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school_rounded),
          label: 'Educação',
        ),
      ],
    );
  }

  void _onTabTapped(BuildContext context, int index) {
    // Não navega se já está na aba selecionada
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
        break;
      case 1:
        context.go(AppRoutes.heatmap);
        break;
      case 2:
        context.go(AppRoutes.education);
        break;
    }
  }
}
