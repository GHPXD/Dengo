import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/city_search_provider.dart';

/// Widget de busca de cidades com debounce.
///
/// Implementa debounce de 500ms para evitar requisições excessivas
/// enquanto o usuário digita.
class CitySearchBar extends ConsumerStatefulWidget {
  const CitySearchBar({super.key});

  @override
  ConsumerState<CitySearchBar> createState() => _CitySearchBarState();
}

class _CitySearchBarState extends ConsumerState<CitySearchBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Cancela timer anterior se existir
    _debounce?.cancel();

    // Cria novo timer de 500ms
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(citySearchProvider.notifier).searchCities(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Digite o nome da sua cidade...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  ref.read(citySearchProvider.notifier).clear();
                },
              )
            : null,
      ),
    );
  }
}
