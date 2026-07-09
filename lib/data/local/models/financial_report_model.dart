class FinancialReportModel {
  final int? reportId;
  final int businessId;
  final String period; // YYYY-MM
  final double totalIncome;
  final double totalCogs;
  final double grossProfit;
  final double totalExpense;
  final double netProfit;
  final String status; // 'laba' or 'rugi'
  final DateTime? lastSyncedAt;
  final DateTime? createdAt;

  FinancialReportModel({
    this.reportId,
    required this.businessId,
    required this.period,
    this.totalIncome = 0.0,
    this.totalCogs = 0.0,
    this.grossProfit = 0.0,
    this.totalExpense = 0.0,
    this.netProfit = 0.0,
    this.status = 'laba',
    this.lastSyncedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'reportId': reportId,
        'businessId': businessId,
        'period': period,
        'totalIncome': totalIncome,
        'totalCogs': totalCogs,
        'grossProfit': grossProfit,
        'totalExpense': totalExpense,
        'netProfit': netProfit,
        'status': status,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
      };

  factory FinancialReportModel.fromMap(Map<String, dynamic> map) =>
      FinancialReportModel(
        reportId: map['reportId'] as int?,
        businessId: map['businessId'] as int,
        period: map['period'] as String,
        totalIncome: (map['totalIncome'] as num?)?.toDouble() ?? 0.0,
        totalCogs: (map['totalCogs'] as num?)?.toDouble() ?? 0.0,
        grossProfit: (map['grossProfit'] as num?)?.toDouble() ?? 0.0,
        totalExpense: (map['totalExpense'] as num?)?.toDouble() ?? 0.0,
        netProfit: (map['netProfit'] as num?)?.toDouble() ?? 0.0,
        status: map['status'] as String? ?? 'laba',
        lastSyncedAt: map['lastSyncedAt'] != null
            ? DateTime.parse(map['lastSyncedAt'] as String)
            : null,
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : null,
      );
}
