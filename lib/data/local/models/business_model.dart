class BusinessModel {
  final int businessId; // Matches Supabase business ID
  final String name;
  final String? description;
  final String? qrisImageUrl; // QRIS image URL for offline caching
  final DateTime? lastSyncedAt;
  final DateTime? createdAt;

  BusinessModel({
    required this.businessId,
    required this.name,
    this.description,
    this.qrisImageUrl,
    this.lastSyncedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'businessId': businessId,
        'name': name,
        'description': description,
        'qrisImageUrl': qrisImageUrl,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
      };

  factory BusinessModel.fromMap(Map<String, dynamic> map) => BusinessModel(
        businessId: map['businessId'] as int,
        name: map['name'] as String,
        description: map['description'] as String?,
        qrisImageUrl: map['qrisImageUrl'] as String?,
        lastSyncedAt: map['lastSyncedAt'] != null
            ? DateTime.parse(map['lastSyncedAt'] as String)
            : null,
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : null,
      );
}
