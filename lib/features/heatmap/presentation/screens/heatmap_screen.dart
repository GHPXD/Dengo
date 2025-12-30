import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/widgets/app_bottom_nav.dart';
import '../providers/heatmap_provider.dart';

// --- IMPORTS DAS ENTIDADES (Essenciais para Tipagem Forte) ---
import '../../domain/entities/heatmap_data.dart';
import '../../domain/entities/heatmap_city.dart';

// --- Constantes de Design ---
class _AppStyles {
  static const primary = Color(0xFF2E8B8B);
  static const primaryDark = Color(0xFF1E7B7B);
  static const textDark = Color(0xFF2E5C6E);
  static const textGrey = Color(0xFF6B7280);

  static const fireColor = Color(0xFFFF6B6B);

  // Gradiente da legenda
  static const gradientColors = [
    Color(0xFF10B981), // Verde
    Color(0xFFFBBF24), // Amarelo
    Color(0xFFFF8A80), // Laranja
    Color(0xFFFF6B6B), // Vermelho
  ];
}

/// Tela de Mapa de Calor Interativo
class HeatmapScreen extends ConsumerStatefulWidget {
  /// Construtor padrão da tela de mapa de calor.
  const HeatmapScreen({super.key});

  @override
  ConsumerState<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends ConsumerState<HeatmapScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Carrega dados do heatmap ao iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(heatmapProvider.notifier).loadHeatmap();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heatmapState = ref.watch(heatmapProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const _HeatmapHeader(),
            _HeatmapFilters(
              selectedPeriod: heatmapState.selectedPeriod,
              onPeriodChanged: (period) {
                ref.read(heatmapProvider.notifier).changePeriod(period);
              },
            ),
            Expanded(
              child: _buildContent(heatmapState),
            ),
            const _HeatmapLegend(),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  Widget _buildContent(HeatmapState state) {
    if (state.isLoading) {
      return const _LoadingMapState();
    }

    if (state.error != null) {
      return _ErrorMapState(
        error: state.error!,
        onRetry: () => ref.read(heatmapProvider.notifier).loadHeatmap(),
      );
    }

    if (state.data != null) {
      return _HeatmapMap(
        mapController: _mapController,
        data: state.data!,
      );
    }

    return const SizedBox.shrink();
  }
}

// ==========================================
// WIDGETS EXTRAÍDOS
// ==========================================

class _HeatmapHeader extends StatelessWidget {
  const _HeatmapHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: const Row(
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: _AppStyles.fireColor,
            size: 28,
          ),
          SizedBox(width: 12),
          Text(
            'Mapa de Calor',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _AppStyles.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapFilters extends StatelessWidget {
  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;

  const _HeatmapFilters({
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: _FilterChip(
              label: 'Última Semana',
              isSelected: selectedPeriod == 'week',
              onTap: () => onPeriodChanged('week'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _FilterChip(
              label: 'Último Mês',
              isSelected: selectedPeriod == 'month',
              onTap: () => onPeriodChanged('month'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [_AppStyles.primary, _AppStyles.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _AppStyles.primary : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeatmapMap extends StatelessWidget {
  final MapController mapController;
  final HeatmapData data;

  const _HeatmapMap({
    required this.mapController,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final markers = data.cities.map((city) {
      return Marker(
        point: city.location,
        width: 32,
        height: 32,
        child: GestureDetector(
          onTap: () => _showCityInfo(context, city),
          child: Container(
            decoration: BoxDecoration(
              color: Color(city.riskLevel.color).withValues(alpha: 0.8),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
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
        mapController: mapController,
        options: const MapOptions(
          initialCenter: LatLng(-25.4284, -49.2733), // Centro do Paraná
          initialZoom: 7.0,
          minZoom: 6.0,
          maxZoom: 12.0,
          interactionOptions: InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.dengo.app',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }

  void _showCityInfo(BuildContext context, HeatmapCity city) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CityDetailsModal(city: city),
    );
  }
}

class _CityDetailsModal extends StatelessWidget {
  final HeatmapCity city;

  const _CityDetailsModal({required this.city});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    color: _AppStyles.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Casos', value: '${city.cases}'),
          _InfoRow(label: 'População', value: '${city.population}'),
          _InfoRow(
            label: 'Incidência',
            value: '${city.incidence.toStringAsFixed(1)}/100k',
          ),
          _InfoRow(label: 'Nível de Risco', value: city.riskLevel.label),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: _AppStyles.textGrey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _AppStyles.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapLegend extends StatelessWidget {
  const _HeatmapLegend();

  @override
  Widget build(BuildContext context) {
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
              Icon(Icons.palette, size: 18, color: _AppStyles.primary),
              SizedBox(width: 8),
              Text(
                'Legenda de Intensidade',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _AppStyles.textDark,
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
                      colors: _AppStyles.gradientColors,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LegendLabel('Baixo'),
              _LegendLabel('Médio'),
              _LegendLabel('Alto'),
              _LegendLabel('Crítico'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendLabel extends StatelessWidget {
  final String text;

  const _LegendLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 11, color: _AppStyles.textGrey),
    );
  }
}

// --- ESTADOS DE LOADING E ERRO ---

class _LoadingMapState extends StatelessWidget {
  const _LoadingMapState();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_AppStyles.primary),
        ),
      ),
    );
  }
}

class _ErrorMapState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorMapState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
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
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: _AppStyles.primary,
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
}