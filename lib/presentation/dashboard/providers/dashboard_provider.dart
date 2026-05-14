import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/shelf_model.dart';
import '../../../data/repositories/shelf_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notification_provider.dart';

final shelfRepositoryProvider = Provider<ShelfRepository>(
  (_) => ShelfRepository(),
);

/// Streams the live list of shelves from Supabase Realtime
final shelvesStreamProvider = StreamProvider<List<ShelfModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  final repo = ref.read(shelfRepositoryProvider);
  return repo.watchShelves(user.id).map(
        (list) => list.map(ShelfModel.fromJson).toList(),
      );
});

// ── Create / Edit shelf ───────────────────────────────────
class ShelfFormState {
  const ShelfFormState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });
  final bool isLoading;
  final String? error;
  final bool success;
}

class ShelfFormNotifier extends StateNotifier<ShelfFormState> {
  ShelfFormNotifier(this._repo, this._userId)
      : super(const ShelfFormState());

  final ShelfRepository _repo;
  final String _userId;

  Future<bool> createShelf({
    required String name,
    String? location,
    String? sensorId,
  }) async {
    state = const ShelfFormState(isLoading: true);
    try {
      final shelf = ShelfModel(
        id: '',
        userId: _userId,
        name: name,
        location: location,
        sensorId: sensorId?.isEmpty == true ? null : sensorId,
        isOnline: false,
        createdAt: DateTime.now(),
      );
      await _repo.createShelf(shelf);
      state = const ShelfFormState(success: true);
      return true;
    } catch (e) {
      state = ShelfFormState(error: e.toString());
      return false;
    }
  }

  Future<bool> updateShelf(ShelfModel shelf) async {
    state = const ShelfFormState(isLoading: true);
    try {
      await _repo.updateShelf(shelf);
      state = const ShelfFormState(success: true);
      return true;
    } catch (e) {
      state = ShelfFormState(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteShelf(String shelfId) async {
    state = const ShelfFormState(isLoading: true);
    try {
      await _repo.deleteShelf(shelfId);
      state = const ShelfFormState(success: true);
      return true;
    } catch (e) {
      state = ShelfFormState(error: e.toString());
      return false;
    }
  }
}

final shelfFormProvider =
    StateNotifierProvider<ShelfFormNotifier, ShelfFormState>((ref) {
  final user = ref.watch(currentUserProvider);
  return ShelfFormNotifier(
    ref.read(shelfRepositoryProvider),
    user?.id ?? '',
  );
});

/// Maps shelfId → item count (active items only)
final shelfItemCountsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  // Re-run whenever shelves change
  ref.watch(shelvesStreamProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return {};

  final data = await ref
      .read(shelfRepositoryProvider)
      .getShelvesItemCounts(userId);
  return data;
});

/// Summary stats derived from shelves list
class DashboardStats {
  const DashboardStats({
    required this.totalShelves,
    required this.onlineShelves,
    required this.totalAlerts,
  });
  final int totalShelves;
  final int onlineShelves;
  final int totalAlerts;
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final shelves = ref.watch(shelvesStreamProvider).valueOrNull ?? [];
  final unread = ref.watch(unreadCountProvider);
  return DashboardStats(
    totalShelves: shelves.length,
    onlineShelves: shelves.where((s) => s.isOnline).length,
    totalAlerts: unread,
  );
});
