import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/format_helpers.dart';
import '../local/models/business_model.dart';
import '../local/models/category_model.dart';
import '../local/models/consignor_model.dart';
import '../local/models/consignment_model.dart';
import '../local/models/debt_model.dart';
import '../local/models/debt_payment_model.dart';
import '../local/models/debtor_model.dart';
import '../local/models/transaction_model.dart';
import '../local/models/user_model.dart';

/// Central service for all cloud (Supabase) data operations.
/// All methods use ErrorHandler.guard() to throw typed AppError on failure.
class SupabaseService {
  static SupabaseService? _instance;

  late final SupabaseClient _supabase;

  SupabaseService._();

  static SupabaseService get instance => _instance ??= SupabaseService._();

  void init(SupabaseClient client) {
    _supabase = client;
  }

  SupabaseClient get client => _supabase;

  /// Check if the service has a live connection
  bool get isConnected => true;

  // ==================== User Operations ====================

  Future<UserModel?> getUserById(String userId) async {
    return ErrorHandler.guard(() async {
      final data = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return UserModel(
        userId: data['id'] as String,
        username: data['username'] as String,
        role: data['role'] as String,
        displayName: data['display_name'] as String?,
      );
    });
  }

  Future<List<UserModel>> getAllUsers() async {
    return ErrorHandler.guard(() async {
      final data = await _supabase.from('users').select();
      return (data as List).map((json) => UserModel(
            userId: json['id'] as String,
            username: json['username'] as String,
            role: json['role'] as String,
            displayName: json['display_name'] as String?,
          )).toList();
    });
  }

  // ==================== Business Operations ====================

  Future<List<BusinessModel>> getAllBusinesses() async {
    return ErrorHandler.guard(() async {
      final data = await _supabase.from('businesses').select();
      return (data as List).map((b) => BusinessModel(
            businessId: b['id'] as int,
            name: b['name'] as String,
            description: b['description'] as String?,
            qrisImageUrl: b['qris_image_url'] as String?,
          )).toList();
    });
  }

  Future<BusinessModel?> getBusinessById(int businessId) async {
    return ErrorHandler.guard(() async {
      final data = await _supabase
          .from('businesses')
          .select()
          .eq('id', businessId)
          .single();
      return BusinessModel(
        businessId: data['id'] as int,
        name: data['name'] as String,
        description: data['description'] as String?,
        qrisImageUrl: data['qris_image_url'] as String?,
      );
    });
  }

  // ==================== User-Business Operations ====================

  Future<List<int>> getBusinessIdsForUser(String userId) async {
    return ErrorHandler.guard(() async {
      final data = await _supabase
          .from('user_businesses')
          .select('business_id')
          .eq('user_id', userId);
      return (data as List).map((e) => e['business_id'] as int).toList();
    });
  }

  Future<List<BusinessModel>> getBusinessesForUser(String userId) async {
    final ids = await getBusinessIdsForUser(userId);
    if (ids.isEmpty) return [];
    final allBusinesses = await getAllBusinesses();
    return allBusinesses.where((b) => ids.contains(b.businessId)).toList();
  }

  Future<List<BusinessModel>> getAccessibleBusinesses(
      String userId, String role) async {
    if (role == AppConstants.roleOwner) {
      return getAllBusinesses();
    }
    return getBusinessesForUser(userId);
  }

  // ==================== Business Write Operations ====================

  /// Create a new business and return the created [BusinessModel].
  Future<BusinessModel> createBusiness({
    required String name,
    String? description,
  }) async {
    return ErrorHandler.guard(() async {
      final response = await _supabase.from('businesses').insert({
        'name': name,
        'description': description ?? '',
      }).select().single();

      return BusinessModel(
        businessId: response['id'] as int,
        name: response['name'] as String,
        description: response['description'] as String?,
        qrisImageUrl: response['qris_image_url'] as String?,
      );
    });
  }

  /// Update an existing business name and description.
  Future<BusinessModel> updateBusiness({
    required int businessId,
    required String name,
    String? description,
  }) async {
    return ErrorHandler.guard(() async {
      final response = await _supabase.from('businesses').update({
        'name': name,
        'description': description ?? '',
      }).eq('id', businessId).select().single();

      return BusinessModel(
        businessId: response['id'] as int,
        name: response['name'] as String,
        description: response['description'] as String?,
        qrisImageUrl: response['qris_image_url'] as String?,
      );
    });
  }

  /// Delete a business.
  Future<void> deleteBusiness(int businessId) async {
    return ErrorHandler.guard(() async {
      await _supabase.from('businesses').delete().eq('id', businessId);
    });
  }

  // ==================== Category Operations ====================

  Future<List<CategoryModel>> getCategoriesByBusiness(int businessId) async {
    return ErrorHandler.guard(() async {
      final data = await _supabase
          .from('categories')
          .select()
          .eq('business_id', businessId);
      return (data as List).map((c) => CategoryModel(
            categoryId: c['id'] as int,
            businessId: c['business_id'] as int,
            name: c['name'] as String,
            type: c['type'] as String,
          )).toList();
    });
  }

  /// Create a new category.
  Future<CategoryModel> createCategory({
    required int businessId,
    required String name,
    required String type,
  }) async {
    return ErrorHandler.guard(() async {
      final response = await _supabase.from('categories').insert({
        'business_id': businessId,
        'name': name,
        'type': type,
      }).select().single();

      return CategoryModel(
        categoryId: response['id'] as int,
        businessId: response['business_id'] as int,
        name: response['name'] as String,
        type: response['type'] as String,
      );
    });
  }

  /// Update an existing category.
  Future<CategoryModel> updateCategory({
    required int categoryId,
    required String name,
    required String type,
  }) async {
    return ErrorHandler.guard(() async {
      final response = await _supabase.from('categories').update({
        'name': name,
        'type': type,
      }).eq('id', categoryId).select().single();

      return CategoryModel(
        categoryId: response['id'] as int,
        businessId: response['business_id'] as int,
        name: response['name'] as String,
        type: response['type'] as String,
      );
    });
  }

  /// Delete a category.
  Future<void> deleteCategory(int categoryId) async {
    return ErrorHandler.guard(() async {
      await _supabase.from('categories').delete().eq('id', categoryId);
    });
  }

  Future<List<CategoryModel>> getCategoriesByType(
      int businessId, String type) async {
    return ErrorHandler.guard(() async {
      final data = await _supabase
          .from('categories')
          .select()
          .eq('business_id', businessId)
          .eq('type', type);
      return (data as List).map((c) => CategoryModel(
            categoryId: c['id'] as int,
            businessId: c['business_id'] as int,
            name: c['name'] as String,
            type: c['type'] as String,
          )).toList();
    });
  }

  // ==================== Transaction Operations ====================

  Future<List<TransactionModel>> getTransactionsByBusiness(
      int businessId) async {
    return ErrorHandler.guard(() async {
      final data = await _supabase
          .from('transactions')
          .select()
          .eq('business_id', businessId)
          .order('transaction_date', ascending: false);
      return _parseTransactions(data as List);
    });
  }

  Future<List<TransactionModel>> getTransactionsByDateRange(
    int businessId,
    String startDate,
    String endDate,
  ) async {
    return ErrorHandler.guard(() async {
      final data = await _supabase
          .from('transactions')
          .select()
          .eq('business_id', businessId)
          .gte('transaction_date', startDate)
          .lte('transaction_date', endDate)
          .order('transaction_date', ascending: false);
      return _parseTransactions(data as List);
    });
  }

  Future<List<TransactionModel>> getAllTransactionsByDateRange(
    List<int> businessIds,
    String startDate,
    String endDate,
  ) async {
    if (businessIds.isEmpty) return [];
    return ErrorHandler.guard(() async {
      final data = await _supabase
          .from('transactions')
          .select()
          .inFilter('business_id', businessIds)
          .gte('transaction_date', startDate)
          .lte('transaction_date', endDate)
          .order('transaction_date', ascending: false);
      return _parseTransactions(data as List);
    });
  }

  Future<List<TransactionModel>> getAllTransactions(
      List<int> businessIds) async {
    if (businessIds.isEmpty) return [];
    return ErrorHandler.guard(() async {
      final data = await _supabase
          .from('transactions')
          .select()
          .inFilter('business_id', businessIds)
          .order('transaction_date', ascending: false);
      return _parseTransactions(data as List);
    });
  }

  Future<Map<String, double>> getBusinessSummary(int businessId) async {
    final transactions = await getTransactionsByBusiness(businessId);
    double totalIncome = 0;
    double totalCogs = 0;
    double totalExpense = 0;

    for (final tx in transactions) {
      if (tx.type == AppConstants.typeIncome) {
        totalIncome += tx.amount;
        totalCogs += tx.cogs;
      } else if (tx.type == AppConstants.typeExpense) {
        totalExpense += tx.amount;
      }
    }

    return {
      'totalIncome': totalIncome,
      'totalCogs': totalCogs,
      'grossProfit': totalIncome - totalCogs,
      'totalExpense': totalExpense,
      'netProfit': (totalIncome - totalCogs) - totalExpense,
    };
  }

  Future<Map<String, double>> getAllBusinessesSummary(
      List<int> businessIds) async {
    return ErrorHandler.guard(() async {
      if (businessIds.isEmpty) {
        return {
          'totalIncome': 0.0,
          'totalCogs': 0.0,
          'grossProfit': 0.0,
          'totalExpense': 0.0,
          'netProfit': 0.0,
        };
      }
      final transactions = await getAllTransactions(businessIds);
      double totalIncome = 0;
      double totalCogs = 0;
      double totalExpense = 0;

      for (final tx in transactions) {
        if (tx.type == 'income') {
          totalIncome += tx.amount;
          totalCogs += tx.cogs;
        } else if (tx.type == 'expense') {
          totalExpense += tx.amount;
        }
      }

      return {
        'totalIncome': totalIncome,
        'totalCogs': totalCogs,
        'grossProfit': totalIncome - totalCogs,
        'totalExpense': totalExpense,
        'netProfit': (totalIncome - totalCogs) - totalExpense,
      };
    });
  }

  Future<int> createTransaction({
    required int businessId,
    required int categoryId,
    required String userId,
    required String type,
    required double amount,
    double cogs = 0.0,
    String paymentMethod = AppConstants.paymentCash,
    String? description,
    required String transactionDate,
  }) async {
    return ErrorHandler.guard(() async {
      final response = await _supabase.from('transactions').insert({
        'business_id': businessId,
        'category_id': categoryId,
        'user_id': userId,
        'type': type,
        'amount': amount,
        'cogs': type == AppConstants.typeIncome ? cogs : 0.0,
        'payment_method': paymentMethod,
        'description': description ?? '',
        'transaction_date': transactionDate,
        'status_sync': true,
      }).select('id').single();

      return response['id'] as int;
    });
  }

  Future<void> updateTransaction({
    required int transactionId,
    int? categoryId,
    String? type,
    double? amount,
    double? cogs,
    String? paymentMethod,
    String? description,
    String? transactionDate,
  }) async {
    return ErrorHandler.guard(() async {
      final Map<String, dynamic> updates = {};
      if (categoryId != null) updates['category_id'] = categoryId;
      if (type != null) updates['type'] = type;
      if (amount != null) updates['amount'] = amount;
      if (cogs != null) updates['cogs'] = cogs;
      if (paymentMethod != null) updates['payment_method'] = paymentMethod;
      if (description != null) updates['description'] = description;
      if (transactionDate != null) updates['transaction_date'] = transactionDate;

      if (updates.isNotEmpty) {
        await _supabase
            .from('transactions')
            .update(updates)
            .eq('id', transactionId);
      }
    });
  }

  Future<void> deleteTransaction(int transactionId) async {
    return ErrorHandler.guard(() async {
      await _supabase
          .from('transactions')
          .delete()
          .eq('id', transactionId);
    });
  }

  List<TransactionModel> _parseTransactions(List<dynamic> data) {
    return data.map((tx) => TransactionModel(
          transactionId: tx['id'] as int,
          businessId: tx['business_id'] as int,
          categoryId: tx['category_id'] as int,
          userId: tx['user_id'] as String,
          type: tx['type'] as String,
          amount: (tx['amount'] as num).toDouble(),
          cogs: (tx['cogs'] as num?)?.toDouble() ?? 0.0,
          paymentMethod: tx['payment_method'] as String? ?? AppConstants.paymentCash,
          description: tx['description'] as String?,
          transactionDate: tx['transaction_date'] as String,
          statusSync: tx['status_sync'] as bool? ?? true,
          createdAt: tx['created_at'] != null
              ? DateTime.parse(tx['created_at'] as String)
              : null,
        )).toList();
  }

  // ==================== Monthly Trend ====================


  // ==================== Debtor Operations ====================

  Future<List<DebtorModel>> getDebtorsByBusiness(int businessId) async {
    return ErrorHandler.guard(() async {
      final data = await _supabase
          .from('debtors')
          .select()
          .eq('business_id', businessId)
          .order('name', ascending: true);
      return (data as List)
          .map((d) => DebtorModel.fromMap(d as Map<String, dynamic>))
          .toList();
    });
  }

  Future<DebtorModel> createDebtor({
    required int businessId,
    required String name,
    String? phone,
    String? notes,
  }) async {
    return ErrorHandler.guard(() async {
      final response = await _supabase.from('debtors').insert({
        'business_id': businessId,
        'name': name,
        'phone': phone,
        'notes': notes,
      }).select().single();
      return DebtorModel.fromMap(response);
    });
  }

  Future<void> updateDebtor({
    required int debtorId,
    String? name,
    String? phone,
    String? notes,
  }) async {
    return ErrorHandler.guard(() async {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (notes != null) updates['notes'] = notes;
      if (updates.isNotEmpty) {
        await _supabase.from('debtors').update(updates).eq('id', debtorId);
      }
    });
  }

  Future<void> deleteDebtor(int debtorId) async {
    return ErrorHandler.guard(() async {
      await _supabase.from('debtors').delete().eq('id', debtorId);
    });
  }

  // ==================== Debt Operations ====================

  Future<List<DebtModel>> getDebtsByBusiness(int businessId) async {
    return ErrorHandler.guard(() async {
      final data = await _supabase
          .from('debts')
          .select()
          .eq('business_id', businessId)
          .order('debt_date', ascending: false);
      return (data as List)
          .map((d) => DebtModel.fromMap(d as Map<String, dynamic>))
          .toList();
    });
  }

  Future<List<DebtModel>> getDebtsByDebtor(int debtorId) async {
    return ErrorHandler.guard(() async {
      final data = await _supabase
          .from('debts')
          .select()
          .eq('debtor_id', debtorId)
          .order('debt_date', ascending: false);
      return (data as List)
          .map((d) => DebtModel.fromMap(d as Map<String, dynamic>))
          .toList();
    });
  }

  Future<int> createDebt({
    required int debtorId,
    required int businessId,
    required String userId,
    required double amount,
    String? description,
    String? dueDate,
    String? debtDate,
  }) async {
    return ErrorHandler.guard(() async {
      final response = await _supabase.from('debts').insert({
        'debtor_id': debtorId,
        'business_id': businessId,
        'user_id': userId,
        'amount': amount,
        'description': description,
        'status': AppConstants.debtUnpaid,
        'debt_date': debtDate,
        'due_date': dueDate,
      }).select('id').single();
      return response['id'] as int;
    });
  }

  Future<void> updateDebtStatus(int debtId, String status) async {
    return ErrorHandler.guard(() async {
      await _supabase.from('debts').update({'status': status}).eq('id', debtId);
    });
  }

  Future<void> deleteDebt(int debtId) async {
    return ErrorHandler.guard(() async {
      await _supabase.from('debts').delete().eq('id', debtId);
    });
  }

  Future<DebtModel> getDebtById(int debtId) async {
    return ErrorHandler.guard(() async {
      final data =
          await _supabase.from('debts').select().eq('id', debtId).single();
      return DebtModel.fromMap(data);
    });
  }

  // ==================== Debt Payment Operations ====================

  Future<List<DebtPaymentModel>> getDebtPayments(int debtId) async {
    return ErrorHandler.guard(() async {
      final data = await _supabase
          .from('debt_payments')
          .select()
          .eq('debt_id', debtId)
          .order('payment_date', ascending: false);
      return (data as List)
          .map((p) => DebtPaymentModel.fromMap(p as Map<String, dynamic>))
          .toList();
    });
  }

  Future<int> createDebtPayment({
    required int debtId,
    required double amount,
    required String userId,
    String? notes,
    String? paymentDate,
  }) async {
    return ErrorHandler.guard(() async {
      final response = await _supabase.from('debt_payments').insert({
        'debt_id': debtId,
        'amount': amount,
        'user_id': userId,
        'notes': notes,
        'payment_date': paymentDate,
      }).select('id').single();

      // Update paid_amount and status on the debt
      final debtData = await _supabase
          .from('debts')
          .select('amount, paid_amount')
          .eq('id', debtId)
          .single();

      final totalPaid = (debtData['paid_amount'] as num).toDouble() + amount;
      final totalAmount = (debtData['amount'] as num).toDouble();

      String newStatus;
      if (totalPaid >= totalAmount) {
        newStatus = AppConstants.debtPaid;
      } else if (totalPaid > 0) {
        newStatus = AppConstants.debtPartial;
      } else {
        newStatus = AppConstants.debtUnpaid;
      }

      await _supabase.from('debts').update({
        'paid_amount': totalPaid,
        'status': newStatus,
      }).eq('id', debtId);

      return response['id'] as int;
    });
  }

  Future<Map<String, dynamic>> getDebtSummary(int businessId) async {
    return ErrorHandler.guard(() async {
      final debts = await getDebtsByBusiness(businessId);
      double totalOwed = 0;
      double totalPaid = 0;
      int activeCount = 0;
      int debtorCount = 0;
      final debtorIds = <int>{};

      for (final debt in debts) {
        if (debt.status != AppConstants.debtPaid) {
          totalOwed += debt.remainingAmount;
          activeCount++;
        }
        totalPaid += debt.paidAmount;
        debtorIds.add(debt.debtorId);
      }

      debtorCount = debtorIds.length;

      return {
        'totalOwed': totalOwed,
        'totalPaid': totalPaid,
        'activeCount': activeCount,
        'debtorCount': debtorCount,
      };
    });
  }

  Future<void> updateDebt({
    required int debtId,
    double? amount,
    String? description,
    String? dueDate,
    String? debtDate,
  }) async {
    return ErrorHandler.guard(() async {
      final Map<String, dynamic> updates = {};
      if (amount != null) updates['amount'] = amount;
      if (description != null) updates['description'] = description;
      if (dueDate != null) updates['due_date'] = dueDate;
      if (debtDate != null) updates['debt_date'] = debtDate;
      if (updates.isNotEmpty) {
        await _supabase.from('debts').update(updates).eq('id', debtId);
      }
    });
  }

  Future<void> updateDebtPayment({
    required int paymentId,
    double? amount,
    String? notes,
    String? paymentDate,
  }) async {
    return ErrorHandler.guard(() async {
      final Map<String, dynamic> updates = {};
      if (amount != null) updates['amount'] = amount;
      if (notes != null) updates['notes'] = notes;
      if (paymentDate != null) updates['payment_date'] = paymentDate;
      if (updates.isNotEmpty) {
        await _supabase.from('debt_payments').update(updates).eq('id', paymentId);
      }
    });
  }

  Future<void> deleteDebtPayment(int paymentId) async {
    return ErrorHandler.guard(() async {
      await _supabase.from('debt_payments').delete().eq('id', paymentId);
    });
  }

  Future<bool> areAllDebtsPaid(int debtorId) async {
    return ErrorHandler.guard(() async {
      final data = await _supabase
          .from('debts')
          .select('status')
          .eq('debtor_id', debtorId);
      final debts = data as List;
      if (debts.isEmpty) return false;
      return debts.every((d) => d['status'] == AppConstants.debtPaid);
    });
  }

  Future<double> getTotalPaidByDebtor(int debtorId) async {
    return ErrorHandler.guard(() async {
      final data = await _supabase
          .from('debts')
          .select('paid_amount')
          .eq('debtor_id', debtorId);
      final debts = data as List;
      double total = 0;
      for (final d in debts) {
        total += (d['paid_amount'] as num?)?.toDouble() ?? 0;
      }
      return total;
    });
  }

  Future<void> resetDebtorData(int debtorId) async {
    return ErrorHandler.guard(() async {
      final paymentIds = await _supabase
          .from('debt_payments')
          .select('id')
          .inFilter('debt_id',
              (await _supabase.from('debts').select('id').eq('debtor_id', debtorId) as List).map((d) => d['id']).toList());
      for (final p in paymentIds as List) {
        await _supabase.from('debt_payments').delete().eq('id', p['id']);
      }
      await _supabase.from('debts').delete().eq('debtor_id', debtorId);
      await _supabase.from('debtors').delete().eq('id', debtorId);
    });
  }

  // ==================== Consignor Operations ====================

  Future<List<ConsignorModel>> getConsignorsByBusiness(int businessId) async {
    return ErrorHandler.guard(() async {
      final data = await _supabase
          .from('consignors')
          .select()
          .eq('business_id', businessId)
          .order('name', ascending: true);
      return (data as List)
          .map((c) => ConsignorModel.fromMap(c as Map<String, dynamic>))
          .toList();
    });
  }

  Future<ConsignorModel> createConsignor({
    required int businessId,
    required String name,
    String? phone,
    String? notes,
  }) async {
    return ErrorHandler.guard(() async {
      final response = await _supabase.from('consignors').insert({
        'business_id': businessId,
        'name': name,
        'phone': phone,
        'notes': notes,
      }).select().single();
      return ConsignorModel.fromMap(response);
    });
  }

  Future<void> updateConsignor({
    required int consignorId,
    String? name,
    String? phone,
    String? notes,
  }) async {
    return ErrorHandler.guard(() async {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (notes != null) updates['notes'] = notes;
      if (updates.isNotEmpty) {
        await _supabase.from('consignors').update(updates).eq('id', consignorId);
      }
    });
  }

  Future<void> deleteConsignor(int consignorId) async {
    return ErrorHandler.guard(() async {
      await _supabase.from('consignors').delete().eq('id', consignorId);
    });
  }

  // ==================== Consignment Operations ====================

  Future<List<ConsignmentModel>> getConsignmentsByBusiness(
      int businessId) async {
    return ErrorHandler.guard(() async {
      final data = await _supabase
          .from('consignments')
          .select()
          .eq('business_id', businessId)
          .order('consignment_date', ascending: false);
      return (data as List)
          .map((c) => ConsignmentModel.fromMap(c as Map<String, dynamic>))
          .toList();
    });
  }

  Future<List<ConsignmentModel>> getConsignmentsByConsignor(
      int consignorId) async {
    return ErrorHandler.guard(() async {
      final data = await _supabase
          .from('consignments')
          .select()
          .eq('consignor_id', consignorId)
          .order('consignment_date', ascending: false);
      final consignments = (data as List)
          .map((c) => ConsignmentModel.fromMap(c as Map<String, dynamic>))
          .toList();

      final enriched = <ConsignmentModel>[];
      for (final c in consignments) {
        if ((c.isDaily || c.isReseller) && (c.reportStatus == AppConstants.reportReported || c.reportStatus == AppConstants.reportSettled)) {
          final owing = await getDailyPaymentOwing(c.id);
          enriched.add(c.copyWith(paymentOwing: owing));
        } else {
          enriched.add(c);
        }
      }
      return enriched;
    });
  }

  Future<int> createConsignment({
    required int consignorId,
    required int businessId,
    required String userId,
    required double totalAmount,
    String type = AppConstants.consignmentTypeReseller,
    String? description,
    String? dueDate,
    String? consignmentDate,
  }) async {
    return ErrorHandler.guard(() async {
      final response = await _supabase.from('consignments').insert({
        'consignor_id': consignorId,
        'business_id': businessId,
        'user_id': userId,
        'total_amount': totalAmount,
        'description': description,
        'status': AppConstants.consignmentActive,
        'type': type,
        'consignment_date': consignmentDate,
        'due_date': dueDate,
      }).select('id').single();
      return response['id'] as int;
    });
  }

  Future<void> addConsignmentItem({
    required int consignmentId,
    required String productName,
    required int quantity,
    required double agreedPrice,
    double? sellingPrice,
    String? description,
  }) async {
    return ErrorHandler.guard(() async {
      final itemData = <String, dynamic>{
        'consignment_id': consignmentId,
        'product_name': productName,
        'quantity': quantity,
        'quantity_sold': 0,
        'quantity_returned': 0,
        'agreed_price': agreedPrice,
      };
      if (sellingPrice != null) itemData['selling_price'] = sellingPrice;
      if (description != null) itemData['description'] = description;
      await _supabase.from('consignment_items').insert(itemData);
    });
  }

  Future<List<ConsignmentItemModel>> getConsignmentItems(
      int consignmentId) async {
    return ErrorHandler.guard(() async {
      final data = await _supabase
          .from('consignment_items')
          .select()
          .eq('consignment_id', consignmentId);
      return (data as List)
          .map((i) => ConsignmentItemModel.fromMap(i as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> deleteConsignment(int consignmentId) async {
    return ErrorHandler.guard(() async {
      final consData = await _supabase
          .from('consignments')
          .select('income_transaction_id, expense_transaction_id')
          .eq('id', consignmentId)
          .maybeSingle();

      if (consData != null) {
        final incomeTxId = consData['income_transaction_id'] as int?;
        final expenseTxId = consData['expense_transaction_id'] as int?;
        if (incomeTxId != null) {
          await _supabase.from('transactions').delete().eq('id', incomeTxId);
        }
        if (expenseTxId != null) {
          await _supabase.from('transactions').delete().eq('id', expenseTxId);
        }
      }

      await _supabase.from('consignments').delete().eq('id', consignmentId);
    });
  }

  // ==================== Consignment Settlement Operations ====================

  Future<List<ConsignmentSettlementModel>> getConsignmentSettlements(
      int consignmentId) async {
    return ErrorHandler.guard(() async {
      final data = await _supabase
          .from('consignment_settlements')
          .select()
          .eq('consignment_id', consignmentId)
          .order('settlement_date', ascending: false);
      return (data as List)
          .map((s) =>
              ConsignmentSettlementModel.fromMap(s as Map<String, dynamic>))
          .toList();
    });
  }

  Future<int> createConsignmentSettlement({
    required int consignmentId,
    required double amount,
    required String userId,
    String? notes,
    String? settlementDate,
    String? paymentMethod,
  }) async {
    return ErrorHandler.guard(() async {
      final response = await _supabase.from('consignment_settlements').insert({
        'consignment_id': consignmentId,
        'amount': amount,
        'user_id': userId,
        'notes': notes,
        'settlement_date': settlementDate,
      }).select('id').single();

      // Update settled_amount and status on the consignment
      final consData = await _supabase
          .from('consignments')
          .select('total_amount, settled_amount, type, business_id, consignor_id, report_status')
          .eq('id', consignmentId)
          .single();

      final totalSettled =
          (consData['settled_amount'] as num).toDouble() + amount;
      final totalAmount = (consData['total_amount'] as num).toDouble();
      final type = consData['type'] as String? ?? 'reseller';
      final isReseller = type == 'reseller';
      final reportStatus = consData['report_status'] as String? ?? 'pending';

      // For reseller: settledAmount is compared against totalPayment (agreedPrice * qtySold)
      // For daily: same as reseller
      // For old debt: compare against totalAmount
      double settlementTarget = totalAmount;
      if (isReseller && reportStatus == AppConstants.reportReported) {
        final itemsData = await _supabase
            .from('consignment_items')
            .select('agreed_price, quantity_sold')
            .eq('consignment_id', consignmentId);
        double totalPayment = 0;
        for (final item in itemsData) {
          final agreedPrice = (item['agreed_price'] as num).toDouble();
          final qtySold = item['quantity_sold'] as int;
          totalPayment += agreedPrice * qtySold;
        }
        settlementTarget = totalPayment;
      }

      String newStatus;
      if (totalSettled >= settlementTarget) {
        newStatus = AppConstants.consignmentSettled;
      } else {
        newStatus = AppConstants.consignmentActive;
      }

      // For reseller: auto-finalize with commission when fully settled after report
      int? incomeTxId;
      if (isReseller &&
          newStatus == AppConstants.consignmentSettled &&
          reportStatus == AppConstants.reportReported) {
        final businessId = consData['business_id'] as int;
        final consignorId = consData['consignor_id'] as int;

        final consignorData = await _supabase
            .from('consignors')
            .select('name')
            .eq('id', consignorId)
            .single();
        final consignorName = consignorData['name'] as String;

        final itemsData = await _supabase
            .from('consignment_items')
            .select('product_name, agreed_price, selling_price, quantity_sold')
            .eq('consignment_id', consignmentId);

        double totalFromSales = 0;
        double totalPayment = 0;
        final itemSummary = <String>[];
        for (final item in itemsData) {
          final agreedPrice = (item['agreed_price'] as num).toDouble();
          final sellingPrice =
              (item['selling_price'] as num?)?.toDouble() ?? agreedPrice;
          final qtySold = item['quantity_sold'] as int;
          final productName = item['product_name'] as String;
          totalFromSales += sellingPrice * qtySold;
          totalPayment += agreedPrice * qtySold;
          itemSummary.add('$productName ($qtySold)');
        }

        final commission = totalFromSales - totalPayment;
        if (commission > 0) {
          final incomeCategoryId = await getOrCreateCategoryForBusiness(
            businessId,
            AppConstants.categoryKomisiTitipan,
            AppConstants.typeIncome,
          );

          final itemDesc = itemSummary.join(', ');
          incomeTxId = await createTransaction(
            businessId: businessId,
            categoryId: incomeCategoryId,
            userId: userId,
            type: AppConstants.typeIncome,
            amount: commission,
            paymentMethod: paymentMethod ?? AppConstants.paymentCash,
            description: 'Komisi titipan $consignorName - $itemDesc',
            transactionDate: settlementDate ??
                DateTime.now().toIso8601String().substring(0, 10),
          );
        }
      }

      await _supabase.from('consignments').update({
        'settled_amount': totalSettled,
        'status': newStatus,
        if (newStatus == AppConstants.consignmentSettled)
          'report_status': AppConstants.reportSettled,
        if (incomeTxId != null) 'income_transaction_id': incomeTxId,
      }).eq('id', consignmentId);

      return response['id'] as int;
    });
  }

  Future<Map<String, dynamic>> getConsignmentSummary(int businessId) async {
    return ErrorHandler.guard(() async {
      final consignments = await getConsignmentsByBusiness(businessId);
      double totalOwed = 0;
      double totalSettled = 0;
      int activeCount = 0;
      int consignorCount = 0;
      final consignorIds = <int>{};

      for (final c in consignments) {
        if (c.status != AppConstants.consignmentSettled &&
            c.status != AppConstants.consignmentCancelled) {
          if (c.isDaily || c.isReseller) {
            if (c.reportStatus == AppConstants.reportReported) {
              totalOwed += await getDailyPaymentOwing(c.id);
            } else {
              totalOwed += c.totalAmount;
            }
          } else {
            totalOwed += c.remainingAmount;
          }
          activeCount++;
        }
        totalSettled += c.settledAmount;
        consignorIds.add(c.consignorId);
      }

      consignorCount = consignorIds.length;

      return {
        'totalOwed': totalOwed,
        'totalSettled': totalSettled,
        'activeCount': activeCount,
        'consignorCount': consignorCount,
      };
    });
  }

  // ==================== Daily Consignment Operations ====================

  Future<double> getDailyPaymentOwing(int consignmentId) async {
    return ErrorHandler.guard(() async {
      final items = await _supabase
          .from('consignment_items')
          .select('agreed_price, quantity_sold')
          .eq('consignment_id', consignmentId);
      double total = 0;
      for (final item in items) {
        total += (item['agreed_price'] as num).toDouble() *
            (item['quantity_sold'] as int);
      }
      return total;
    });
  }

  Future<void> reportConsignmentItem({
    required int consignmentId,
    required int itemId,
    required int quantitySold,
  }) async {
    return ErrorHandler.guard(() async {
      final itemData = await _supabase
          .from('consignment_items')
          .select('quantity')
          .eq('id', itemId)
          .single();

      final totalQty = itemData['quantity'] as int;
      if (quantitySold < 0 || quantitySold > totalQty) {
        throw Exception('Jumlah terjual harus antara 0 dan $totalQty');
      }

      await _supabase.from('consignment_items').update({
        'quantity_sold': quantitySold,
        'quantity_returned': totalQty - quantitySold,
      }).eq('id', itemId);
    });
  }

  Future<void> finalizeConsignmentReport(int consignmentId) async {
    return ErrorHandler.guard(() async {
      await _supabase.from('consignments').update({
        'report_status': AppConstants.reportReported,
      }).eq('id', consignmentId);
    });
  }

  Future<int> getOrCreateCategoryForBusiness(
    int businessId,
    String categoryName,
    String categoryType,
  ) async {
    return ErrorHandler.guard(() async {
      final existing = await _supabase
          .from('categories')
          .select('id')
          .eq('business_id', businessId)
          .eq('name', categoryName)
          .eq('type', categoryType);

      if (existing.isNotEmpty) {
        return existing.first['id'] as int;
      }

      final response = await _supabase.from('categories').insert({
        'business_id': businessId,
        'name': categoryName,
        'type': categoryType,
      }).select('id');

      return (response as List).first['id'] as int;
    });
  }

  Future<void> settleConsignment({
    required int consignmentId,
    required int businessId,
    required String userId,
    required String paymentMethod,
    required String paymentDate,
  }) async {
    return ErrorHandler.guard(() async {
      final consData = await _supabase
          .from('consignments')
          .select('settled_amount, consignor_id, status, report_status')
          .eq('id', consignmentId)
          .single();

      if (consData['status'] != AppConstants.consignmentActive) {
        throw Exception('Konsinyasi sudah tidak aktif');
      }
      if (consData['report_status'] != AppConstants.reportReported) {
        throw Exception('Laporan penjualan belum diselesaikan');
      }
      final existingSettled =
          (consData['settled_amount'] as num?)?.toDouble() ?? 0;
      if (existingSettled > 0) {
        throw Exception('Konsinyasi sudah pernah dibayar');
      }

      final consignorId = consData['consignor_id'] as int;

      final consignorData = await _supabase
          .from('consignors')
          .select('name')
          .eq('id', consignorId)
          .single();
      final consignorName = consignorData['name'] as String;

      final itemsData = await _supabase
          .from('consignment_items')
          .select('product_name, agreed_price, selling_price, quantity_sold')
          .eq('consignment_id', consignmentId);

      double totalFromSales = 0;
      double totalPayment = 0;
      final itemSummary = <String>[];
      for (final item in itemsData) {
        final agreedPrice = (item['agreed_price'] as num).toDouble();
        final sellingPrice =
            (item['selling_price'] as num?)?.toDouble() ?? agreedPrice;
        final qtySold = item['quantity_sold'] as int;
        final productName = item['product_name'] as String;
        totalFromSales += sellingPrice * qtySold;
        totalPayment += agreedPrice * qtySold;
        itemSummary.add('$productName ($qtySold)');
      }

      final commission = totalFromSales - totalPayment;

      int? incomeTxId;
      if (commission > 0) {
        final incomeCategoryId = await getOrCreateCategoryForBusiness(
          businessId,
          AppConstants.categoryKomisiTitipan,
          AppConstants.typeIncome,
        );

        final itemDesc = itemSummary.join(', ');
        incomeTxId = await createTransaction(
          businessId: businessId,
          categoryId: incomeCategoryId,
          userId: userId,
          type: AppConstants.typeIncome,
          amount: commission,
          paymentMethod: paymentMethod,
          description: 'Komisi titipan $consignorName - $itemDesc',
          transactionDate: paymentDate,
        );
      }

      await _supabase.from('consignment_settlements').insert({
        'consignment_id': consignmentId,
        'amount': totalPayment,
        'user_id': userId,
        'settlement_date': paymentDate,
        'notes': 'Settlement harian via laporan penjualan',
      });

      await _supabase.from('consignments').update({
        'status': AppConstants.consignmentSettled,
        'report_status': AppConstants.reportSettled,
        'settled_amount': totalPayment,
        if (incomeTxId != null) 'income_transaction_id': incomeTxId,
      }).eq('id', consignmentId);
    });
  }

  // ==================== Category Name Lookup ====================

  Future<String> getCategoryName(int businessId, int categoryId) async {
    return ErrorHandler.guard(() async {
      final cats = await getCategoriesByBusiness(businessId);
      final cat = cats.where((c) => c.categoryId == categoryId).firstOrNull;
      return cat?.name ?? 'Kategori #$categoryId';
    });
  }

  /// Get net profit trend based on the TrendFilter (weekly, monthly, yearly).
  /// Works for single or multiple businesses.
  Future<List<({String period, double netProfit})>> getNetProfitsTrend({
    required List<int> businessIds,
    required TrendFilter filter,
  }) async {
    if (businessIds.isEmpty) return [];
    return ErrorHandler.guard(() async {
      final now = DateTime.now();
      String startStr;
      String endStr;

      if (filter == TrendFilter.daily) {
        final startDay = now.subtract(const Duration(days: 6));
        startStr = '${startDay.year}-${startDay.month.toString().padLeft(2, '0')}-${startDay.day.toString().padLeft(2, '0')}';
        endStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      } else if (filter == TrendFilter.weekly) {
        final currentMonday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        final startWeek = currentMonday.subtract(const Duration(days: 28)); // Monday of 4 weeks ago
        startStr = '${startWeek.year}-${startWeek.month.toString().padLeft(2, '0')}-${startWeek.day.toString().padLeft(2, '0')}';
        endStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      } else if (filter == TrendFilter.monthly) {
        const months = 6;
        final startMonth = DateTime(now.year, now.month - months + 1, 1);
        startStr = '${startMonth.year}-${startMonth.month.toString().padLeft(2, '0')}-01';
        endStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${FormatHelpers.daysInMonth(now.year, now.month)}';
      } else {
        // yearly
        final startYear = now.year - 4;
        startStr = '$startYear-01-01';
        endStr = '${now.year}-12-31';
      }

      final data = await _supabase
          .from('transactions')
          .select()
          .inFilter('business_id', businessIds)
          .gte('transaction_date', startStr)
          .lte('transaction_date', endStr)
          .order('transaction_date', ascending: true);

      final transactions = _parseTransactions(data as List);

      final Map<String, double> incomeMap = {};
      final Map<String, double> expenseMap = {};

      for (final tx in transactions) {
        String key;
        final txDate = DateTime.parse(tx.transactionDate);

        if (filter == TrendFilter.daily) {
          key = '${txDate.year}-${txDate.month.toString().padLeft(2, '0')}-${txDate.day.toString().padLeft(2, '0')}';
        } else if (filter == TrendFilter.weekly) {
          final txMonday = DateTime(txDate.year, txDate.month, txDate.day).subtract(Duration(days: txDate.weekday - 1));
          key = '${txMonday.year}-${txMonday.month.toString().padLeft(2, '0')}-${txMonday.day.toString().padLeft(2, '0')}';
        } else if (filter == TrendFilter.monthly) {
          key = tx.transactionDate.length >= 7
              ? tx.transactionDate.substring(0, 7)
              : tx.transactionDate;
        } else {
          key = '${txDate.year}';
        }

        if (tx.type == 'income') {
          incomeMap.update(key, (v) => v + tx.amount, ifAbsent: () => tx.amount);
        } else {
          expenseMap.update(key, (v) => v + tx.amount, ifAbsent: () => tx.amount);
        }
      }

      final result = <({String period, double netProfit})>[];

      if (filter == TrendFilter.daily) {
        final startDay = now.subtract(const Duration(days: 6));
        for (int i = 0; i < 7; i++) {
          final d = startDay.add(Duration(days: i));
          final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          final income = incomeMap[key] ?? 0;
          final expense = expenseMap[key] ?? 0;
          result.add((period: key, netProfit: income - expense));
        }
      } else if (filter == TrendFilter.weekly) {
        final currentMonday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        final startWeek = currentMonday.subtract(const Duration(days: 28));
        for (int i = 0; i < 5; i++) {
          final d = startWeek.add(Duration(days: i * 7));
          final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          final income = incomeMap[key] ?? 0;
          final expense = expenseMap[key] ?? 0;
          result.add((period: key, netProfit: income - expense));
        }
      } else if (filter == TrendFilter.monthly) {
        const months = 6;
        for (int i = 0; i < months; i++) {
          final d = DateTime(now.year, now.month - months + 1 + i, 1);
          final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
          final income = incomeMap[key] ?? 0;
          final expense = expenseMap[key] ?? 0;
          result.add((period: key, netProfit: income - expense));
        }
      } else {
        // yearly
        for (int i = 0; i < 5; i++) {
          final year = now.year - 4 + i;
          final key = '$year';
          final income = incomeMap[key] ?? 0;
          final expense = expenseMap[key] ?? 0;
          result.add((period: key, netProfit: income - expense));
        }
      }

      return result;
    });
  }
}

enum TrendFilter { daily, weekly, monthly, yearly }
