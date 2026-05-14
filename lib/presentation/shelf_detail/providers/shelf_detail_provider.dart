import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/item_model.dart';
import '../../../data/models/item_log_model.dart';
import '../../../data/repositories/item_repository.dart';
import '../../../data/repositories/storage_repository.dart';
import '../../../data/models/shelf_model.dart';
import '../../auth/providers/auth_provider.dart' show storageRepositoryProvider;
import '../../dashboard/providers/dashboard_provider.dart'
    show shelfRepositoryProvider;

final itemRepositoryProvider = Provider<ItemRepository>(
  (_) => ItemRepository(),
);

/// Stream of items for a given shelf (realtime)
final itemsStreamProvider =
    StreamProvider.family<List<ItemModel>, String>((ref, shelfId) {
  final repo = ref.read(itemRepositoryProvider);
  return repo.watchItems(shelfId).map(
        (list) => list
            .where((e) => e['is_active'] == true)
            .map(ItemModel.fromJson)
            .toList(),
      );
});

/// Single shelf data
final shelfProvider =
    FutureProvider.family<ShelfModel?, String>((ref, shelfId) async {
  final repo = ref.read(shelfRepositoryProvider);
  return repo.getShelf(shelfId);
});

/// Single item by ID (used when pre-filling the edit form)
final singleItemProvider =
    FutureProvider.family<ItemModel?, String>((ref, itemId) async {
  final repo = ref.read(itemRepositoryProvider);
  return repo.getItem(itemId);
});

/// Item logs for history chart
final itemLogsProvider =
    FutureProvider.family<List<ItemLogModel>, String>((ref, itemId) async {
  final repo = ref.read(itemRepositoryProvider);
  return repo.getItemLogs(itemId);
});

// ── Item form ─────────────────────────────────────────────
class ItemFormState {
  const ItemFormState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });
  final bool isLoading;
  final String? error;
  final bool success;
}

class ItemFormNotifier extends StateNotifier<ItemFormState> {
  ItemFormNotifier(this._repo, this._storage) : super(const ItemFormState());

  final ItemRepository _repo;
  final StorageRepository _storage;

  Future<bool> createItem({
    required String shelfId,
    required String name,
    required double unitWeightG,
    required double tareWeightG,
    required int minThreshold,
    int? slotNumber,
    XFile? imageFile,
  }) async {
    state = const ItemFormState(isLoading: true);
    try {
      // 1. Create the item row first to get its ID
      final item = ItemModel(
        id: '',
        shelfId: shelfId,
        name: name,
        unitWeightG: unitWeightG,
        tareWeightG: tareWeightG,
        minThreshold: minThreshold,
        currentWeight: 0,
        currentQty: 0,
        isActive: true,
        createdAt: DateTime.now(),
        slotNumber: slotNumber,
      );
      final created = await _repo.createItem(item);

      // 2. Upload image if provided and patch image_url
      if (imageFile != null) {
        final url = await _storage.uploadItemImage(created.id, imageFile);
        await _repo.updateItem(created.copyWith(imageUrl: url));
      }

      state = const ItemFormState(success: true);
      return true;
    } catch (e) {
      state = ItemFormState(error: e.toString());
      return false;
    }
  }

  Future<bool> updateItem(ItemModel item, {XFile? imageFile}) async {
    state = const ItemFormState(isLoading: true);
    try {
      String? imageUrl = item.imageUrl;
      if (imageFile != null) {
        imageUrl = await _storage.uploadItemImage(item.id, imageFile);
      }
      await _repo.updateItem(item.copyWith(imageUrl: imageUrl));
      state = const ItemFormState(success: true);
      return true;
    } catch (e) {
      state = ItemFormState(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteItem(String itemId) async {
    state = const ItemFormState(isLoading: true);
    try {
      await _repo.deleteItem(itemId);
      state = const ItemFormState(success: true);
      return true;
    } catch (e) {
      state = ItemFormState(error: e.toString());
      return false;
    }
  }
}

final itemFormProvider =
    StateNotifierProvider<ItemFormNotifier, ItemFormState>((ref) {
  return ItemFormNotifier(
    ref.read(itemRepositoryProvider),
    ref.read(storageRepositoryProvider),
  );
});
