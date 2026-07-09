import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/error_handler.dart';
import '../local/models/business_model.dart';
import '../local/models/category_model.dart';
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
  bool get isConnected => _supabase.auth.currentSession != null;

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
    if (role == 'owner') {
      return getAllBusinesses();
    }
    return getBusinessesForUser(userId);
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
    String paymentMethod = 'cash',
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
        'cogs': type == 'income' ? cogs : 0.0,
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
          paymentMethod: tx['payment_method'] as String? ?? 'cash',
          description: tx['description'] as String?,
          transactionDate: tx['transaction_date'] as String,
          statusSync: tx['status_sync'] as bool? ?? true,
          createdAt: tx['created_at'] != null
              ? DateTime.parse(tx['created_at'] as String)
              : null,
        )).toList();
  }

  // ==================== Category Name Lookup ====================

  Future<String> getCategoryName(int businessId, int categoryId) async {
    return ErrorHandler.guard(() async {
      final cats = await getCategoriesByBusiness(businessId);
      final cat = cats.where((c) => c.categoryId == categoryId).firstOrNull;
      return cat?.name ?? 'Kategori #$categoryId';
    });
  }
}
