class ShelfModel {
  const ShelfModel({
    required this.id,
    required this.userId,
    required this.name,
    this.location,
    this.sensorId,
    required this.isOnline,
    this.lastPing,
    required this.createdAt,
    this.itemCount = 0,
    this.alertCount = 0,
  });

  final String id;
  final String userId;
  final String name;
  final String? location;
  final String? sensorId;
  final bool isOnline;
  final DateTime? lastPing;
  final DateTime createdAt;
  final int itemCount;
  final int alertCount;

  factory ShelfModel.fromJson(Map<String, dynamic> json) => ShelfModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        location: json['location'] as String?,
        sensorId: json['sensor_id'] as String?,
        isOnline: json['is_online'] as bool? ?? false,
        lastPing: json['last_ping'] != null
            ? DateTime.parse(json['last_ping'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'name': name,
        'location': location,
        'sensor_id': sensorId,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'location': location,
        'sensor_id': sensorId,
      };

  ShelfModel copyWith({
    String? name,
    String? location,
    String? sensorId,
    bool? isOnline,
    DateTime? lastPing,
    int? itemCount,
    int? alertCount,
  }) =>
      ShelfModel(
        id: id,
        userId: userId,
        name: name ?? this.name,
        location: location ?? this.location,
        sensorId: sensorId ?? this.sensorId,
        isOnline: isOnline ?? this.isOnline,
        lastPing: lastPing ?? this.lastPing,
        createdAt: createdAt,
        itemCount: itemCount ?? this.itemCount,
        alertCount: alertCount ?? this.alertCount,
      );
}
