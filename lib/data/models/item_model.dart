class ItemModel {
  const ItemModel({
    required this.id,
    required this.shelfId,
    required this.name,
    this.imageUrl,
    required this.unitWeightG,
    required this.tareWeightG,
    required this.minThreshold,
    required this.currentWeight,
    required this.currentQty,
    required this.isActive,
    required this.createdAt,
    this.slotNumber,
  });

  final String id;
  final String shelfId;
  final String name;
  final String? imageUrl;
  final double unitWeightG;
  final double tareWeightG;
  final int minThreshold;
  final double currentWeight;
  final int currentQty;
  final bool isActive;
  final DateTime createdAt;
  final int? slotNumber;

  factory ItemModel.fromJson(Map<String, dynamic> json) => ItemModel(
        id: json['id'] as String,
        shelfId: json['shelf_id'] as String,
        name: json['name'] as String,
        imageUrl: json['image_url'] as String?,
        unitWeightG: (json['unit_weight_g'] as num).toDouble(),
        tareWeightG: (json['tare_weight_g'] as num).toDouble(),
        minThreshold: json['min_threshold'] as int,
        currentWeight: (json['current_weight'] as num? ?? 0).toDouble(),
        currentQty: json['current_qty'] as int? ?? 0,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        slotNumber: json['slot_number'] as int?,
      );

  Map<String, dynamic> toInsertJson() => {
        'shelf_id': shelfId,
        'name': name,
        'image_url': imageUrl,
        'unit_weight_g': unitWeightG,
        'tare_weight_g': tareWeightG,
        'min_threshold': minThreshold,
        'slot_number': slotNumber,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'image_url': imageUrl,
        'unit_weight_g': unitWeightG,
        'tare_weight_g': tareWeightG,
        'min_threshold': minThreshold,
        'slot_number': slotNumber,
      };

  double get fillRatio {
    final maxWeight = unitWeightG * minThreshold * 2;
    if (maxWeight <= 0) return 0;
    return ((currentWeight - tareWeightG) / maxWeight).clamp(0.0, 1.0);
  }

  bool get isLowStock => currentQty > 0 && currentQty <= minThreshold;
  bool get isEmpty => currentQty <= 0;

  ItemModel copyWith({
    String? name,
    String? imageUrl,
    double? unitWeightG,
    double? tareWeightG,
    int? minThreshold,
    double? currentWeight,
    int? currentQty,
    bool? isActive,
    int? slotNumber,
  }) =>
      ItemModel(
        id: id,
        shelfId: shelfId,
        name: name ?? this.name,
        imageUrl: imageUrl ?? this.imageUrl,
        unitWeightG: unitWeightG ?? this.unitWeightG,
        tareWeightG: tareWeightG ?? this.tareWeightG,
        minThreshold: minThreshold ?? this.minThreshold,
        currentWeight: currentWeight ?? this.currentWeight,
        currentQty: currentQty ?? this.currentQty,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
        slotNumber: slotNumber ?? this.slotNumber,
      );
}
