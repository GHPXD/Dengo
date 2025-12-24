import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_router.dart';

/// Tela de Mapa de Calor Interativo
///
/// Mostra zonas de risco de dengue em um mapa com:
/// - Visualização por intensidade (paleta coral/laranja)
/// - Filtros temporais (semana, mês)
/// - Alternância entre casos reais e previsões
class HeatmapScreen extends ConsumerStatefulWidget {
  const HeatmapScreen({super.key});

  /// Creates the mutable state for this widget.
  @override
  ConsumerState<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends ConsumerState<HeatmapScreen> {
  String selectedTimeFilter = 'week'; // 'week' ou 'month'
  String selectedDataType = 'real'; // 'real' ou 'prediction'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Filtros
            _buildFilters(),

            // Mapa (placeholder por enquanto)
            Expanded(
              child: _buildMap(),
            ),

            // Legenda
            _buildLegend(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: const Row(
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: Color(0xFFFF6B6B),
            size: 28,
          ),
          SizedBox(width: 12),
          Text(
            'Mapa de Calor',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E8B8B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtro de Tempo
          Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  label: 'Última Semana',
                  isSelected: selectedTimeFilter == 'week',
                  onTap: () => setState(() => selectedTimeFilter = 'week'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterChip(
                  label: 'Último Mês',
                  isSelected: selectedTimeFilter == 'month',
                  onTap: () => setState(() => selectedTimeFilter = 'month'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Filtro de Tipo de Dado
          Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  label: 'Casos Reais',
                  isSelected: selectedDataType == 'real',
                  onTap: () => setState(() => selectedDataType = 'real'),
                  icon: Icons.analytics_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterChip(
                  label: 'Previsão IA',
                  isSelected: selectedDataType == 'prediction',
                  onTap: () => setState(() => selectedDataType = 'prediction'),
                  icon: Icons.memory,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF2E8B8B), Color(0xFF1E7B7B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E8B8B) : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          // Placeholder do mapa
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_rounded,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Mapa Interativo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedDataType == 'real'
                      ? 'Casos Reais - ${selectedTimeFilter == 'week' ? 'Última Semana' : 'Último Mês'}'
                      : 'Previsão IA - ${selectedTimeFilter == 'week' ? 'Última Semana' : 'Último Mês'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Color(0xFF2E8B8B)),
                      SizedBox(width: 8),
                      Text(
                        'Integração com Google Maps em breve',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Controles do mapa (zoom, etc)
          Positioned(
            right: 16,
            top: 16,
            child: Column(
              children: [
                _buildMapControl(Icons.add, () {}),
                const SizedBox(height: 8),
                _buildMapControl(Icons.remove, () {}),
                const SizedBox(height: 8),
                _buildMapControl(Icons.my_location, () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControl(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF2E8B8B)),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.palette, size: 18, color: Color(0xFF2E8B8B)),
              SizedBox(width: 8),
              Text(
                'Legenda de Intensidade',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E5C6E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF10B981), // Verde (baixo)
                        Color(0xFFFBBF24), // Amarelo (médio)
                        Color(0xFFFF8A80), // Laranja
                        Color(0xFFFF6B6B), // Vermelho (alto)
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Baixo',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              Text('Médio',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              Text('Alto',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              Text('Crítico',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
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
          _buildNavItem(Icons.home_rounded, false, const Color(0xFF9CA3AF), () {
            Navigator.pop(context);
          }),
          _buildNavItem(Icons.local_fire_department_rounded, true,
              const Color(0xFFFF8A80), () {}),
          _buildNavItem(
              Icons.bar_chart_rounded, false, const Color(0xFF9CA3AF), () {}),
          _buildNavItem(
            Icons.location_city,
            false,
            const Color(0xFF9CA3AF),
            () => context.push(AppRoutes.cityDetail),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, bool isActive, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Icon(
          icon,
          size: 28,
          color: color,
        ),
      ),
    );
  }
}
