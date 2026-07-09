class TransactionModel {
  int? hiveKey; // Hive auto-generated key
  final int? transactionId; // Supabase bigint ID (null for offline-created records)
  final int businessId;
  final int categoryId;
  final String userId;
  final String type; // 'income' or 'expense'
  final double amount;
  final double cogs; // Default 0.0 for expenses
  final String paymentMethod; // 'cash', 'transfer', 'qris', 'other'
  final String? description;
  final String transactionDate; // Format: YYYY-MM-DD
  bool statusSync; // false = pending upload to server
  final DateTime? createdAt;

  TransactionModel({
    this.hiveKey,
    this.transactionId,
    required this.businessId,
    required this.categoryId,
    required this.userId,
    required this.type,
    required this.amount,
    this.cogs = 0.0,
    this.paymentMethod = 'cash',
    this.description,
    required this.transactionDate,
    this.statusSync = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'transactionId': transactionId,
        'businessId': businessId,
        'categoryId': categoryId,
        'userId': userId,
        'type': type,
        'amount': amount,
        'cogs': cogs,
        'paymentMethod': paymentMethod,
        'description': description,
        'transactionDate': transactionDate,
        'statusSync': statusSync,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory TransactionModel.fromMap(Map<String, dynamic> map) =>
      TransactionModel(
        transactionId: map['transactionId'] as int?,
        businessId: map['businessId'] as int,
        categoryId: map['categoryId'] as int,
        userId: map['userId'] as String,
        type: map['type'] as String,
        amount: (map['amount'] as num).toDouble(),
        cogs: (map['cogs'] as num?)?.toDouble() ?? 0.0,
        paymentMethod: map['paymentMethod'] as String? ?? 'cash',
        description: map['description'] as String?,
        transactionDate: map['transactionDate'] as String,
        statusSync: map['statusSync'] as bool? ?? false,
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : null,
      );
}
