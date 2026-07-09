class CategoryModel {
  final int categoryId; // Matches Supabase category ID
  final int businessId;
  final String name;
  final String type; // 'income' or 'expense'
  final DateTime? lastSyncedAt;
  final DateTime? createdAt;

  CategoryModel({
    required this.categoryId,
    required this.businessId,
    required this.name,
    required this.type,
    this.lastSyncedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'categoryId': categoryId,
        'businessId': businessId,
        'name': name,
        'type': type,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
      };

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
        categoryId: map['categoryId'] as int,
        businessId: map['businessId'] as int,
        name: map['name'] as String,
        type: map['type'] as String,
        lastSyncedAt: map['lastSyncedAt'] != null
            ? DateTime.parse(map['lastSyncedAt'] as String)
            : null,
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : null,
      );
}
