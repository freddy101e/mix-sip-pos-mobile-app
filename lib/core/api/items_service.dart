// items_service.dart
import 'package:dio/dio.dart';
import 'package:invoiceandbilling/core/api/api_client.dart';
import 'package:invoiceandbilling/models/item.dart';

class ItemsService {
  final Dio _dio = ApiClient.instance.client;

  Future<FetchItemsResult> fetchItems({
    String? itemCode,
    String? itemName,
    int priceList = 1,
    String warehouse = '01',
    String hideStock = 'no',
    String orderBy = 'ItemName',
    bool desc = false,
    int page = 1,
    int perPage = 20,
    String? manufacturer,
    String? vendor,
    List<String>? category,
  }) async {
    final q = <String, dynamic>{
      if (itemCode?.isNotEmpty == true) 'itemcode': itemCode,
      if (itemName?.isNotEmpty == true) 'itemname': itemName,
      'price_list': priceList,
      'warehouse': warehouse,
      'hidestock': hideStock,
      'orderby': orderBy,
      'desc': desc ? 1 : 0,
      'page': page,
      'perPage': perPage,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (vendor != null) 'vendor': vendor,
    };

    if (category != null && category.isNotEmpty) {
      for (int i = 0; i < category.length; i++) {
        q['category[$i]'] = category[i];
      }
    }

    // Using ?r=api/items to match your Yii route
    final res = await _dio.get('', queryParameters: {'r': 'api/items', ...q});

    final data = res.data;

    // Accept several payload shapes safely:
    // 1) { items: [...], meta: {...} }
    // 2) { data: [...], meta: {...} }
    // 3) [ ... ]
    late final List list;
    Map<String, dynamic>? meta;

    if (data is Map) {
      if (data['items'] is List) {
        list = data['items'] as List;
      } else if (data['data'] is List) {
        list = data['data'] as List;
      } else {
        list = const [];
      }
      if (data['meta'] is Map) {
        meta = Map<String, dynamic>.from(data['meta'] as Map);
      }
    } else if (data is List) {
      list = data;
    } else {
      list = const [];
    }

    final items =
        list
            .map((e) => Item.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

    // meta.returned or items.length help us decide pagination
    final returned =
        meta?['returned'] is int ? meta!['returned'] as int : items.length;
    final total = meta?['total'] as int?; // if your backend adds it later

    return FetchItemsResult(
      items: items,
      page: meta?['page'] as int? ?? page,
      perPage: meta?['perPage'] as int? ?? perPage,
      returned: returned,
      total: total,
    );
  }
}

class FetchItemsResult {
  final List<Item> items;
  final int page;
  final int perPage;
  final int returned;
  final int? total;

  FetchItemsResult({
    required this.items,
    required this.page,
    required this.perPage,
    required this.returned,
    this.total,
  });
}
