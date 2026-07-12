import 'debtor_model.dart';

class DebtModel {
  final int id;
  final int debtorId;
  final int businessId;
  final String userId;
  final double amount;
  final double paidAmount;
  final String? description;
  final String status;
  final String debtDate;
  final String? dueDate;
  final int? expenseTransactionId;
  final DateTime? createdAt;

  DebtModel({
    required this.id,
    required this.debtorId,
    required this.businessId,
    required this.userId,
    required this.amount,
    this.paidAmount = 0,
    this.description,
    this.status = 'unpaid',
    required this.debtDate,
    this.dueDate,
    this.expenseTransactionId,
    this.createdAt,
  });

  double get remainingAmount => amount - paidAmount;
  bool get isPaid => status == 'paid';
  bool get isPartial => status == 'partial';

  Map<String, dynamic> toMap() => {
        'id': id,
        'debtor_id': debtorId,
        'business_id': businessId,
        'user_id': userId,
        'amount': amount,
        'paid_amount': paidAmount,
        'description': description,
        'status': status,
        'debt_date': debtDate,
        'due_date': dueDate,
        'expense_transaction_id': expenseTransactionId,
        'created_at': createdAt?.toIso8601String(),
      };

  factory DebtModel.fromMap(Map<String, dynamic> map) => DebtModel(
        id: map['id'] as int,
        debtorId: map['debtor_id'] as int,
        businessId: map['business_id'] as int,
        userId: map['user_id'] as String,
        amount: (map['amount'] as num).toDouble(),
        paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0,
        description: map['description'] as String?,
        status: map['status'] as String? ?? 'unpaid',
        debtDate: map['debt_date'] as String,
        dueDate: map['due_date'] as String?,
        expenseTransactionId: map['expense_transaction_id'] as int?,
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : null,
      );
}

class DebtWithDebtor {
  final DebtModel debt;
  final DebtorModel debtor;

  DebtWithDebtor({required this.debt, required this.debtor});

  double get remainingAmount => debt.amount - debt.paidAmount;
}
