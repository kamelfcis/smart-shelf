import '../datasources/supabase_client.dart';
import '../models/item_model.dart';
import '../models/item_log_model.dart';

class ItemRepository {
  Future<List<ItemModel>> getItems(String shelfId) async {
    final data = await supabase
        .from('items')
        .select()
        .eq('shelf_id', shelfId)
        .eq('is_active', true)
        .order('created_at', ascending: true);

    return (data as List).map((e) => ItemModel.fromJson(e)).toList();
  }

  Future<ItemModel?> getItem(String itemId) async {
    final data = await supabase
        .from('items')
        .select()
        .eq('id', itemId)
        .maybeSingle();

    return data != null ? ItemModel.fromJson(data) : null;
  }

  Future<ItemModel> createItem(ItemModel item) async {
    final data = await supabase
        .from('items')
        .insert(item.toInsertJson())
        .select()
        .single();

    return ItemModel.fromJson(data);
  }

  Future<ItemModel> updateItem(ItemModel item) async {
    final data = await supabase
        .from('items')
        .update(item.toUpdateJson())
        .eq('id', item.id)
        .select()
        .single();

    return ItemModel.fromJson(data);
  }

  Future<void> deleteItem(String itemId) async {
    await supabase
        .from('items')
        .update({'is_active': false}).eq('id', itemId);
  }

  Future<void> updateWeight(String itemId, double weightG) async {
    await supabase
        .from('items')
        .update({'current_weight': weightG}).eq('id', itemId);
  }

  Future<List<ItemLogModel>> getItemLogs(
    String itemId, {
    int limit = 50,
  }) async {
    final data = await supabase
        .from('item_logs')
        .select()
        .eq('item_id', itemId)
        .order('recorded_at', ascending: false)
        .limit(limit);

    return (data as List).map((e) => ItemLogModel.fromJson(e)).toList();
  }

  /// Realtime stream for items on a shelf
  Stream<List<Map<String, dynamic>>> watchItems(String shelfId) =>
      supabase
          .from('items')
          .stream(primaryKey: ['id'])
          .eq('shelf_id', shelfId)
          .order('created_at', ascending: true);
}
