import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/config/app_router.dart';
import '../providers/heatmap_provider.dart';

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
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Carrega dados do heatmap ao iniciar
    Future.microtask(() => ref.read(heatmapProvider.notifier).loadHeatmap());
  }

  @override
  Widget build(BuildContext context) {
    final heatmapState = ref.watch(heatmapProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Filtros
            _buildFilters(heatmapState),

            // Mapa
            Expanded(
              child: heatmapState.isLoading
                  ? _buildLoading()
                  : heatmapState.error != null
                      ? _buildError(heatmapState.error!)
                      : _buildMap(heatmapState),
            ),

            // Legenda
            _buildLegend(),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: 2),
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

  Widget _buildFilters(HeatmapState heatmapState) {
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
                  isSelected: heatmapState.selectedPeriod == 'week',
                  onTap: () => ref
                      .read(heatmapProvider.notifier)
                      .changePeriod('week'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterChip(
                  label: 'Último Mês',
                  isSelected: heatmapState.selectedPeriod == 'month',
                  onTap: () => ref
                      .read(heatmapProvider.notifier)
                      .changePeriod('month'),
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

  Widget _buildMap(HeatmapState heatmapState) {
    if (heatmapState.data == null) {
      return _buildLoading();
    }

    final cities = heatmapState.data!.cities;

    // Cria marcadores para cada cidade
    final markers = cities.map((city) {
      return Marker(
        point: city.location,
        width: 32,
        height: 32,
        child: GestureDetector(
          onTap: () {
            _showCityInfo(context, city);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Color(city.riskLevel.color).withOpacity(0.8),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${city.cases}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          // Centro do Paraná (Curitiba)
          initialCenter: const LatLng(-25.4284, -49.2733),
          initialZoom: 7.0,
          minZoom: 6.0,
          maxZoom: 12.0,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          // Camada de tiles (OpenStreetMap)
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.dengo.app',
          ),

          // Camada de marcadores
          MarkerLayer(
            markers: markers,
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E8B8B)),
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar mapa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(heatmapProvider.notifier).loadHeatmap(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B8B),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCityInfo(BuildContext context, city) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(city.riskLevel.color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    city.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E5C6E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Casos', '${city.cases}'),
            _buildInfoRow('População', '${city.population}'),
            _buildInfoRow(
                'Incidência', '${city.incidence.toStringAsFixed(1)}/100k'),
            _buildInfoRow('Nível de Risco', city.riskLevel.label),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E5C6E),
            ),
          ),
        ],
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
}
