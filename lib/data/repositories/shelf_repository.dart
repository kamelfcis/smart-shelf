import '../datasources/supabase_client.dart';
import '../models/shelf_model.dart';

class ShelfRepository {
  Future<List<ShelfModel>> getShelves() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await supabase
        .from('shelves')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return (data as List).map((e) => ShelfModel.fromJson(e)).toList();
  }

  Future<ShelfModel?> getShelf(String shelfId) async {
    final data = await supabase
        .from('shelves')
        .select()
        .eq('id', shelfId)
        .maybeSingle();

    return data != null ? ShelfModel.fromJson(data) : null;
  }

  Future<ShelfModel> createShelf(ShelfModel shelf) async {
    final data = await supabase
        .from('shelves')
        .insert(shelf.toInsertJson())
        .select()
        .single();

    return ShelfModel.fromJson(data);
  }

  Future<ShelfModel> updateShelf(ShelfModel shelf) async {
    final data = await supabase
        .from('shelves')
        .update(shelf.toUpdateJson())
        .eq('id', shelf.id)
        .select()
        .single();

    return ShelfModel.fromJson(data);
  }

  Future<void> deleteShelf(String shelfId) async {
    await supabase.from('shelves').delete().eq('id', shelfId);
  }

  /// Returns a map of shelfId → active item count for all user shelves.
  Future<Map<String, int>> getShelvesItemCounts(String userId) async {
    // Fetch IDs of all shelves for this user
    final shelves = await supabase
        .from('shelves')
        .select('id')
        .eq('user_id', userId);

    if ((shelves as List).isEmpty) return {};

    final ids = shelves.map((s) => s['id'] as String).toList();

    final items = await supabase
        .from('items')
        .select('shelf_id')
        .inFilter('shelf_id', ids)
        .eq('is_active', true);

    final counts = <String, int>{};
    for (final row in (items as List)) {
      final sid = row['shelf_id'] as String;
      counts[sid] = (counts[sid] ?? 0) + 1;
    }
    return counts;
  }

  /// Realtime stream for the user's shelves
  Stream<List<Map<String, dynamic>>> watchShelves(String userId) =>
      supabase
          .from('shelves')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: true);
}
