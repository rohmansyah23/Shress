class DebtPaymentModel {
  final int id;
  final int debtId;
  final double amount;
  final String paymentDate;
  final String userId;
  final String? notes;
  final DateTime? createdAt;

  DebtPaymentModel({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.paymentDate,
    required this.userId,
    this.notes,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'debt_id': debtId,
        'amount': amount,
        'payment_date': paymentDate,
        'user_id': userId,
        'notes': notes,
        'created_at': createdAt?.toIso8601String(),
      };

  factory DebtPaymentModel.fromMap(Map<String, dynamic> map) =>
      DebtPaymentModel(
        id: map['id'] as int,
        debtId: map['debt_id'] as int,
        amount: (map['amount'] as num).toDouble(),
        paymentDate: map['payment_date'] as String,
        userId: map['user_id'] as String,
        notes: map['notes'] as String?,
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : null,
      );
}
