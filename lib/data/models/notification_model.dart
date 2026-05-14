enum NotifType { lowStock, itemRemoved, sensorOffline, system }

extension NotifTypeX on NotifType {
  String get dbValue {
    switch (this) {
      case NotifType.lowStock:
        return 'low_stock';
      case NotifType.itemRemoved:
        return 'item_removed';
      case NotifType.sensorOffline:
        return 'sensor_offline';
      case NotifType.system:
        return 'system';
    }
  }

  static NotifType fromDb(String value) {
    switch (value) {
      case 'low_stock':
        return NotifType.lowStock;
      case 'item_removed':
        return NotifType.itemRemoved;
      case 'sensor_offline':
        return NotifType.sensorOffline;
      default:
        return NotifType.system;
    }
  }
}

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    this.shelfId,
    this.itemId,
    required this.type,
    required this.title,
    this.body,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? shelfId;
  final String? itemId;
  final NotifType type;
  final String title;
  final String? body;
  final bool isRead;
  final DateTime createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        shelfId: json['shelf_id'] as String?,
        itemId: json['item_id'] as String?,
        type: NotifTypeX.fromDb(json['type'] as String),
        title: json['title'] as String,
        body: json['body'] as String?,
        isRead: json['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        userId: userId,
        shelfId: shelfId,
        itemId: itemId,
        type: type,
        title: title,
        body: body,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}
