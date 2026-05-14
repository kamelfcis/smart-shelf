import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../auth/providers/auth_provider.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (_) => NotificationRepository(),
);

/// Live stream of notifications
final notificationsStreamProvider =
    StreamProvider<List<NotificationModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  final repo = ref.read(notificationRepositoryProvider);
  return repo.watchNotifications(user.id).map(
        (list) =>
            list.map(NotificationModel.fromJson).toList(),
      );
});

/// Unread count derived from notifications
final unreadCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsStreamProvider).valueOrNull ?? [];
  return notifs.where((n) => !n.isRead).length;
});

// ── Notification actions ──────────────────────────────────
class NotificationActionsNotifier extends StateNotifier<bool> {
  NotificationActionsNotifier(this._repo) : super(false);

  final NotificationRepository _repo;

  Future<void> markAsRead(String id) async {
    await _repo.markAsRead(id);
  }

  Future<void> markAllAsRead() async {
    state = true;
    try {
      await _repo.markAllAsRead();
    } finally {
      state = false;
    }
  }

  Future<void> delete(String id) async {
    await _repo.deleteNotification(id);
  }

  Future<void> insertTest(String type) async {
    final labels = {
      'low_stock': ('⚠️ Low stock: Coffee Beans', 'Only 1 unit left on shelf "Kitchen Pantry". Min threshold is 2.'),
      'item_removed': ('📦 Out of stock: Antiseptic Spray', '"Antiseptic Spray" is now empty on shelf "Medical Cabinet". Time to restock!'),
      'sensor_offline': ('📡 Sensor offline: Office Supplies', 'The sensor on shelf "Office Supplies" stopped responding. Check the device.'),
      'system': ('✅ System check passed', 'All shelves are synced and up to date.'),
    };
    final (title, body) = labels[type] ?? ('Test notification', 'This is a test.');
    await _repo.insertTestNotification(type: type, title: title, body: body);
  }
}

final notificationActionsProvider =
    StateNotifierProvider<NotificationActionsNotifier, bool>((ref) {
  return NotificationActionsNotifier(
    ref.read(notificationRepositoryProvider),
  );
});
