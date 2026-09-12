// items_list_screen.dart
import 'package:flutter/material.dart';
import 'package:invoiceandbilling/core/api/items_service.dart';
import 'package:invoiceandbilling/models/item.dart';
import 'package:intl/intl.dart';

final currency = NumberFormat.currency(symbol: r'$'); // or 'BZD' if you prefer

class ItemsListScreen extends StatefulWidget {
  const ItemsListScreen({super.key});

  @override
  State<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends State<ItemsListScreen> {
  final ItemsService _service = ItemsService();

  final List<Item> _items = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  final int _perPage = 20;

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetch(reset: true);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _fetch({bool reset = false}) async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final nextPage = reset ? 1 : _page;
      final result = await _service.fetchItems(
        page: nextPage,
        perPage: _perPage,
      );

      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(result.items);
          _page = result.page + 1; // backend echoed page
        } else {
          _items.addAll(result.items);
          _page++;
        }

        // Prefer `total` if present; fall back to "returned == perPage".
        if (result.total != null) {
          _hasMore = _items.length < result.total!;
        } else {
          _hasMore = result.returned >= _perPage;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load items: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onScroll() {
    if (!_hasMore || _loading) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _fetch();
    }
  }

  Future<void> _refresh() async => _fetch(reset: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Items')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.separated(
          controller: _scroll,
          itemCount: _items.length + (_hasMore ? 1 : 0),
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index >= _items.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final it = _items[index];
            return ListTile(
              leading: (it.pictureUrl != null && it.pictureUrl!.isNotEmpty)
                  ? CircleAvatar(backgroundImage: NetworkImage(it.pictureUrl!))
                  : const CircleAvatar(child: Icon(Icons.inventory_2)),
              title: Text('${it.code} — ${it.name}', maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                'UOM: ${it.uom ?? "-"}   '
                    'AllStock: ${it.allStock ?? 0}   '
                    'Retail: ${it.retail != null ? currency.format(it.retail) : "-"}',
              ),
              onTap: () {},
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _fetch(reset: true),
        icon: const Icon(Icons.refresh),
        label: const Text('Reload'),
      ),
    );
  }
}
