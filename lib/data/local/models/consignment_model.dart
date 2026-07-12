import 'consignor_model.dart';

class ConsignmentItemModel {
  final int id;
  final int consignmentId;
  final String productName;
  final String? description;
  final int quantity;
  final double agreedPrice;
  final double? sellingPrice;
  final int quantitySold;
  final int quantityReturned;
  final DateTime? createdAt;

  ConsignmentItemModel({
    required this.id,
    required this.consignmentId,
    required this.productName,
    this.description,
    required this.quantity,
    required this.agreedPrice,
    this.sellingPrice,
    this.quantitySold = 0,
    this.quantityReturned = 0,
    this.createdAt,
  });

  double get totalAgreedPrice => agreedPrice * quantity;
  double get totalAgreedPriceSold => agreedPrice * quantitySold;
  double get totalSellingPriceSold =>
      (sellingPrice ?? agreedPrice) * quantitySold;
  double get totalSellingPriceAll => (sellingPrice ?? agreedPrice) * quantity;

  factory ConsignmentItemModel.fromMap(Map<String, dynamic> map) =>
      ConsignmentItemModel(
        id: map['id'] as int,
        consignmentId: map['consignment_id'] as int,
        productName: map['product_name'] as String,
        description: map['description'] as String?,
        quantity: map['quantity'] as int,
        agreedPrice: (map['agreed_price'] as num).toDouble(),
        sellingPrice: (map['selling_price'] as num?)?.toDouble(),
        quantitySold: (map['quantity_sold'] as num?)?.toInt() ?? 0,
        quantityReturned: (map['quantity_returned'] as num?)?.toInt() ?? 0,
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : null,
      );
}

class ConsignmentSettlementModel {
  final int id;
  final int consignmentId;
  final double amount;
  final String settlementDate;
  final String userId;
  final String? notes;
  final DateTime? createdAt;

  ConsignmentSettlementModel({
    required this.id,
    required this.consignmentId,
    required this.amount,
    required this.settlementDate,
    required this.userId,
    this.notes,
    this.createdAt,
  });

  factory ConsignmentSettlementModel.fromMap(Map<String, dynamic> map) =>
      ConsignmentSettlementModel(
        id: map['id'] as int,
        consignmentId: map['consignment_id'] as int,
        amount: (map['amount'] as num).toDouble(),
        settlementDate: map['settlement_date'] as String,
        userId: map['user_id'] as String,
        notes: map['notes'] as String?,
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : null,
      );
}

class ConsignmentModel {
  final int id;
  final int consignorId;
  final int businessId;
  final String userId;
  final double totalAmount;
  final double settledAmount;
  final double paymentOwing;
  final String? description;
  final String status;
  final String type;
  final String reportStatus;
  final int? incomeTransactionId;
  final int? expenseTransactionId;
  final String consignmentDate;
  final String? dueDate;
  final DateTime? createdAt;

  ConsignmentModel({
    required this.id,
    required this.consignorId,
    required this.businessId,
    required this.userId,
    required this.totalAmount,
    this.settledAmount = 0,
    this.paymentOwing = 0,
    this.description,
    this.status = 'active',
    this.type = 'reseller',
    this.reportStatus = 'pending',
    this.incomeTransactionId,
    this.expenseTransactionId,
    required this.consignmentDate,
    this.dueDate,
    this.createdAt,
  });

  double get remainingAmount => totalAmount - settledAmount;
  double get displayOwing =>
      (isDaily || isReseller) ? (paymentOwing - settledAmount) : remainingAmount;

  double get displayTotal {
    if ((isDaily || isReseller) && reportStatus == 'pending') return totalAmount;
    return displayOwing;
  }

  String get displayStatus {
    if (isSettled) return 'Selesai';
    if ((isDaily || isReseller) && reportStatus == 'pending') return 'Menunggu Laporan';
    if ((isDaily || isReseller) && reportStatus == 'reported') return 'Dilaporkan';
    if (status == 'active') return 'Aktif';
    return status;
  }

  bool get isDisplayActive {
    if (isSettled) return false;
    return true;
  }

  bool get isSettled => status == 'settled';
  bool get isDaily => type == 'daily';
  bool get isReseller => type == 'reseller';

  ConsignmentModel copyWith({
    double? paymentOwing,
  }) {
    return ConsignmentModel(
      id: id,
      consignorId: consignorId,
      businessId: businessId,
      userId: userId,
      totalAmount: totalAmount,
      settledAmount: settledAmount,
      paymentOwing: paymentOwing ?? this.paymentOwing,
      description: description,
      status: status,
      type: type,
      reportStatus: reportStatus,
      incomeTransactionId: incomeTransactionId,
      expenseTransactionId: expenseTransactionId,
      consignmentDate: consignmentDate,
      dueDate: dueDate,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'consignor_id': consignorId,
        'business_id': businessId,
        'user_id': userId,
        'total_amount': totalAmount,
        'settled_amount': settledAmount,
        'description': description,
        'status': status,
        'type': type,
        'report_status': reportStatus,
        'income_transaction_id': incomeTransactionId,
        'expense_transaction_id': expenseTransactionId,
        'consignment_date': consignmentDate,
        'due_date': dueDate,
        'created_at': createdAt?.toIso8601String(),
      };

  factory ConsignmentModel.fromMap(Map<String, dynamic> map) =>
      ConsignmentModel(
        id: map['id'] as int,
        consignorId: map['consignor_id'] as int,
        businessId: map['business_id'] as int,
        userId: map['user_id'] as String,
        totalAmount: (map['total_amount'] as num).toDouble(),
        settledAmount: (map['settled_amount'] as num?)?.toDouble() ?? 0,
        description: map['description'] as String?,
        status: map['status'] as String? ?? 'active',
        type: map['type'] as String? ?? 'reseller',
        reportStatus: map['report_status'] as String? ?? 'pending',
        incomeTransactionId: (map['income_transaction_id'] as num?)?.toInt(),
        expenseTransactionId:
            (map['expense_transaction_id'] as num?)?.toInt(),
        consignmentDate: map['consignment_date'] as String,
        dueDate: map['due_date'] as String?,
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : null,
      );
}

class ConsignmentWithConsignor {
  final ConsignmentModel consignment;
  final ConsignorModel consignor;

  ConsignmentWithConsignor({required this.consignment, required this.consignor});

  double get remainingAmount => consignment.displayTotal;
}
