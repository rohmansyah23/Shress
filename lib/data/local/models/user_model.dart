class UserModel {
  final String userId;
  final String username;
  final String role; // 'owner', 'manager', 'staff'
  final String? displayName;
  final DateTime? lastSyncedAt;
  final DateTime? createdAt;

  UserModel({
    required this.userId,
    required this.username,
    required this.role,
    this.displayName,
    this.lastSyncedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'username': username,
        'role': role,
        'displayName': displayName,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        userId: map['userId'] as String,
        username: map['username'] as String,
        role: map['role'] as String,
        displayName: map['displayName'] as String?,
        lastSyncedAt: map['lastSyncedAt'] != null
            ? DateTime.parse(map['lastSyncedAt'] as String)
            : null,
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : null,
      );
}
