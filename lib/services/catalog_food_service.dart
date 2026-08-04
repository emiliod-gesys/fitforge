import '../models/catalog_food.dart';
import 'supabase_service.dart';

/// Búsqueda en el catálogo regional de alimentos (Supabase).
class CatalogFoodService {
  final _client = SupabaseService.client;

  Future<List<CatalogFood>> search(String query, {int limit = 30}) async {
    final q = query.trim();
    if (q.length < 2) return const [];

    try {
      final data = await _client.rpc(
        'search_catalog_foods',
        params: {'p_query': q, 'p_limit': limit},
      );
      return (data as List)
          .map((row) => CatalogFood.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (_) {
      // Catálogo no disponible (offline o migración pendiente): degradar sin romper búsqueda.
      return const [];
    }
  }
}
