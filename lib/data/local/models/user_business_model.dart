class UserBusinessModel {
  final String userId;
  final int businessId;
  final DateTime? lastSyncedAt;
  final DateTime? createdAt;

  UserBusinessModel({
    required this.userId,
    required this.businessId,
    this.lastSyncedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'businessId': businessId,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
      };

  factory UserBusinessModel.fromMap(Map<String, dynamic> map) =>
      UserBusinessModel(
        userId: map['userId'] as String,
        businessId: map['businessId'] as int,
        lastSyncedAt: map['lastSyncedAt'] != null
            ? DateTime.parse(map['lastSyncedAt'] as String)
            : null,
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : null,
      );
}
