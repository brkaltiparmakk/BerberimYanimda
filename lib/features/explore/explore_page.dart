import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/debouncer.dart';
import '../../state/providers.dart';
import '../../widgets/atoms/primary_button.dart';
import '../../widgets/molecules/empty_state.dart';
import 'barber_card.dart';
import 'filters_sheet.dart';

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  late final TextEditingController _searchController;
  late final Debouncer _debouncer;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(exploreFiltersProvider);
    _searchController = TextEditingController(text: filters.query);
    _debouncer = Debouncer();
    ref.listen<ExploreFilters>(exploreFiltersProvider, (previous, next) {
      if (next.query != _searchController.text) {
        _searchController.value = TextEditingValue(
          text: next.query,
          selection: TextSelection.collapsed(offset: next.query.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.refresh(exploreProvider.future);
  }

  void _onSearchChanged(String value) {
    _debouncer.run(() {
      ref.read(exploreFiltersProvider.notifier).updateQuery(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final businessesAsync = ref.watch(exploreProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Berber Keşfet'),
        actions: [
          IconButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (_) => const FiltersSheet(),
            ),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, _) {
                return TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Ara...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: value.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              ref.read(exploreFiltersProvider.notifier).updateQuery('');
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                );
              },
            ),
          ),
          Expanded(
            child: businessesAsync.when(
              data: (businesses) {
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: businesses.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 80),
                            EmptyState(
                              icon: Icons.search_off,
                              message: 'Yakınınızda işletme bulunamadı.',
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: businesses.length,
                          itemBuilder: (context, index) {
                            final business = businesses[index];
                            return BarberCard(
                              business: business,
                              onTap: () => context.go('/business/${business.id}'),
                              onBookTap: () => context.go('/booking/services/${business.id}'),
                            );
                          },
                        ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) {
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 80, left: 24, right: 24),
                        child: EmptyState(
                          icon: Icons.error_outline,
                          message: 'İşletmeler yüklenemedi. Lütfen tekrar deneyin.',
                          action: PrimaryButton(
                            onPressed: () {
                              _refresh();
                            },
                            label: 'Tekrar Dene',
                            icon: Icons.refresh,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/explore/map'),
        label: const Text('Haritada Gör'),
        icon: const Icon(Icons.map_outlined),
      ),
    );
  }
}
