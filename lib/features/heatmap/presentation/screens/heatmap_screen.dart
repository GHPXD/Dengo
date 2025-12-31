import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/info_row.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/heatmap_provider.dart';
import '../../../onboarding/presentation/providers/city_search_provider.dart';
import '../../../onboarding/domain/entities/city.dart';

// --- IMPORTS DAS ENTIDADES (Essenciais para Tipagem Forte) ---
import '../../domain/entities/heatmap_data.dart';
import '../../domain/entities/heatmap_city.dart';

/// Tela de Mapa de Calor Interativo
class HeatmapScreen extends ConsumerStatefulWidget {
  /// Construtor padrão da tela de mapa de calor.
  const HeatmapScreen({super.key});

  @override
  ConsumerState<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends ConsumerState<HeatmapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  
  // Controller para animação de zoom
  AnimationController? _animationController;

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
    _animationController?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Anima o mapa para a cidade selecionada (estilo Google Earth)
  void _animateToCity(City city) {
    final destLocation = LatLng(city.latitude, city.longitude);
    const destZoom = 11.0;

    // Cancela animação anterior se existir
    _animationController?.dispose();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Captura posição atual
    final startLocation = _mapController.camera.center;
    final startZoom = _mapController.camera.zoom;

    // Animação com curva suave (easeInOutCubic para efeito Google Earth)
    final animation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOutCubic,
    );

    // Listener para atualizar o mapa durante a animação
    animation.addListener(() {
      final lat = startLocation.latitude +
          (destLocation.latitude - startLocation.latitude) * animation.value;
      final lng = startLocation.longitude +
          (destLocation.longitude - startLocation.longitude) * animation.value;
      final zoom = startZoom + (destZoom - startZoom) * animation.value;

      _mapController.move(LatLng(lat, lng), zoom);
    });

    _animationController!.forward();
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
            // Nova barra de pesquisa
            _CitySearchBar(onCitySelected: _animateToCity),
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
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _buildContent(HeatmapState state) {
    if (state.isLoading) {
      return const AppLoadingIndicator(message: 'Carregando mapa...');
    }

    if (state.error != null) {
      return AppErrorWidget(
        message: 'Erro ao carregar mapa',
        details: state.error!,
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
// BARRA DE PESQUISA DE CIDADES
// ==========================================

/// Barra de pesquisa de cidades com autocomplete.
/// 
/// Permite buscar cidades e, ao selecionar, faz zoom animado no mapa.
class _CitySearchBar extends ConsumerStatefulWidget {
  final ValueChanged<City> onCitySelected;

  const _CitySearchBar({required this.onCitySelected});

  @override
  ConsumerState<_CitySearchBar> createState() => _CitySearchBarState();
}

class _CitySearchBarState extends ConsumerState<_CitySearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  
  OverlayEntry? _overlayEntry;
  bool _isOverlayVisible = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // Força rebuild para atualizar o suffixIcon
    setState(() {});
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Delay para permitir que o tap no item seja processado
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _showOverlay() {
    if (_isOverlayVisible) return;
    
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _isOverlayVisible = true;
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOverlayVisible = false;
  }

  void _onSearchChanged(String query) {
    if (query.length >= 2) {
      ref.read(citySearchProvider.notifier).searchCities(query);
      _showOverlay();
      // Atualiza o overlay quando a busca muda
      Future.delayed(const Duration(milliseconds: 50), _updateOverlay);
    } else {
      ref.read(citySearchProvider.notifier).clear();
      _removeOverlay();
    }
  }

  void _onCitySelected(City city) {
    _controller.text = city.fullName;
    _removeOverlay();
    _focusNode.unfocus();
    ref.read(citySearchProvider.notifier).clear();
    
    // Chama o callback para fazer zoom
    widget.onCitySelected(city);
  }

  void _clearSearch() {
    _controller.clear();
    ref.read(citySearchProvider.notifier).clear();
    _removeOverlay();
    setState(() {});
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            shadowColor: Colors.black26,
            child: Consumer(
              // Consumer garante que o widget seja reconstruído quando o provider muda
              builder: (context, ref, _) {
                final searchState = ref.watch(citySearchProvider);
                return _SearchResultsContent(
                  searchState: searchState,
                  onCitySelected: _onCitySelected,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen para mudanças no provider e atualizar overlay
    ref.listen(citySearchProvider, (_, __) {
      _updateOverlay();
    });

    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Buscar cidade no mapa...',
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.grey[500],
              size: 22,
            ),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[500], size: 20),
                    onPressed: _clearSearch,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }
}

/// Conteúdo da lista de resultados (separado para rebuild eficiente).
class _SearchResultsContent extends StatelessWidget {
  final CitySearchState searchState;
  final ValueChanged<City> onCitySelected;

  const _SearchResultsContent({
    required this.searchState,
    required this.onCitySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: searchState.when(
        initial: () => const SizedBox.shrink(),
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        loaded: (cities) {
          if (cities.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Nenhuma cidade encontrada',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: cities.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: Colors.grey[200],
            ),
            itemBuilder: (context, index) {
              final city = cities[index];
              return _CityResultTile(
                city: city,
                onTap: () => onCitySelected(city),
              );
            },
          );
        },
        error: (message) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            message,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

/// Tile individual de resultado de busca.
class _CityResultTile extends StatelessWidget {
  final City city;
  final VoidCallback onTap;

  const _CityResultTile({
    required this.city,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    city.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${city.state} • ${formatPopulation(city.population)} hab.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
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
            color: AppColors.fireColor,
            size: 28,
          ),
          SizedBox(width: 12),
          Text(
            'Mapa de Calor',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
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
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
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
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InfoRow(label: 'Casos', value: '${city.cases}'),
          InfoRow(label: 'População', value: formatPopulation(city.population)),
          InfoRow(
            label: 'Incidência',
            value: '${city.incidence.toStringAsFixed(1)}/100k',
          ),
          InfoRow(label: 'Nível de Risco', value: city.riskLevel.label),
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
              Icon(Icons.palette, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Legenda de Intensidade',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
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
                      colors: AppColors.heatmapGradient,
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
      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
    );
  }
}
