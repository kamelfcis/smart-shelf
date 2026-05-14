import '../datasources/supabase_client.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  Future<List<NotificationModel>> getNotifications({int limit = 50}) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List)
        .map((e) => NotificationModel.fromJson(e))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    final data = await supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .eq('is_read', false);

    return (data as List).length;
  }

  Future<void> markAsRead(String notifId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true}).eq('id', notifId);
  }

  Future<void> markAllAsRead() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  Future<void> deleteNotification(String notifId) async {
    await supabase.from('notifications').delete().eq('id', notifId);
  }

  /// Inserts a fake notification — used for testing / demo only.
  Future<void> insertTestNotification({
    required String type,   // low_stock | item_removed | sensor_offline | system
    required String title,
    required String body,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    await supabase.from('notifications').insert({
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
    });
  }

  /// Realtime stream for user notifications
  Stream<List<Map<String, dynamic>>> watchNotifications(String userId) =>
      supabase
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
}
