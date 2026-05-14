class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    required this.createdAt,
  });

  final String id;
  final String fullName;
  final String? avatarUrl;
  final DateTime createdAt;

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        id: json['id'] as String,
        fullName: json['full_name'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'created_at': createdAt.toIso8601String(),
      };

  ProfileModel copyWith({
    String? fullName,
    String? avatarUrl,
  }) =>
      ProfileModel(
        id: id,
        fullName: fullName ?? this.fullName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        createdAt: createdAt,
      );
}
