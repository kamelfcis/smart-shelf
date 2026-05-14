class ItemLogModel {
  const ItemLogModel({
    required this.id,
    required this.itemId,
    required this.weightG,
    this.qty,
    required this.recordedAt,
  });

  final String id;
  final String itemId;
  final double weightG;
  final int? qty;
  final DateTime recordedAt;

  factory ItemLogModel.fromJson(Map<String, dynamic> json) => ItemLogModel(
        id: json['id'] as String,
        itemId: json['item_id'] as String,
        weightG: (json['weight_g'] as num).toDouble(),
        qty: json['qty'] as int?,
        recordedAt: DateTime.parse(json['recorded_at'] as String),
      );
}
