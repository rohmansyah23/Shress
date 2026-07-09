import 'package:hive_flutter/hive_flutter.dart';
import 'models/business_model.dart';
import 'models/category_model.dart';
import 'models/financial_report_model.dart';
import 'models/transaction_model.dart';
import 'models/user_business_model.dart';
import 'models/user_model.dart';

/// Box names
class BoxNames {
  static const String users = 'users';
  static const String businesses = 'businesses';
  static const String userBusinesses = 'userBusinesses';
  static const String categories = 'categories';
  static const String transactions = 'transactions';
  static const String financialReports = 'financialReports';
}

class LocalDatabase {
  static LocalDatabase? _instance;
  bool _initialized = false;

  LocalDatabase._();

  static LocalDatabase get instance => _instance ??= LocalDatabase._();

  Future<void> initialize() async {
    if (_initialized) return;

    await Hive.initFlutter();

    // Open all boxes
    await Hive.openBox(BoxNames.users);
    await Hive.openBox(BoxNames.businesses);
    await Hive.openBox(BoxNames.userBusinesses);
    await Hive.openBox(BoxNames.categories);
    await Hive.openBox(BoxNames.transactions);
    await Hive.openBox(BoxNames.financialReports);

    _initialized = true;
  }

  // ==================== Box Getters ====================

  Box get _usersBox => Hive.box(BoxNames.users);
  Box get _businessesBox => Hive.box(BoxNames.businesses);
  Box get _userBusinessesBox => Hive.box(BoxNames.userBusinesses);
  Box get _categoriesBox => Hive.box(BoxNames.categories);
  Box get _transactionsBox => Hive.box(BoxNames.transactions);
  Box get _reportsBox => Hive.box(BoxNames.financialReports);

  // ==================== User Operations ====================

  Future<void> saveUser(UserModel user) async {
    await _usersBox.put(user.userId, user.toMap());
  }

  UserModel? getUserByAuthId(String userId) {
    final data = _usersBox.get(userId);
    if (data == null) return null;
    return UserModel.fromMap(Map<String, dynamic>.from(data as Map));
  }

  List<UserModel> getAllUsers() {
    return _usersBox.values
        .map((e) => UserModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ==================== Business Operations ====================

  Future<void> saveBusiness(BusinessModel business) async {
    await _businessesBox.put(
      business.businessId.toString(),
      business.toMap(),
    );
  }

  Future<void> saveAllBusinesses(List<BusinessModel> businesses) async {
    for (final b in businesses) {
      await _businessesBox.put(b.businessId.toString(), b.toMap());
    }
  }

  BusinessModel? getBusinessById(int businessId) {
    final data = _businessesBox.get(businessId.toString());
    if (data == null) return null;
    return BusinessModel.fromMap(Map<String, dynamic>.from(data as Map));
  }

  List<BusinessModel> getAllBusinesses() {
    return _businessesBox.values
        .map((e) => BusinessModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ==================== User-Business Operations ====================

  Future<void> saveUserBusiness(UserBusinessModel ub) async {
    final key = '${ub.userId}_${ub.businessId}';
    await _userBusinessesBox.put(key, ub.toMap());
  }

  List<UserBusinessModel> getBusinessesForUser(String userId) {
    return _userBusinessesBox.values
        .where((e) =>
            (Map<String, dynamic>.from(e as Map))['userId'] == userId)
        .map((e) => UserBusinessModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> deleteUserBusiness(String userId, int businessId) async {
    final key = '${userId}_${businessId}';
    await _userBusinessesBox.delete(key);
  }

  // ==================== Category Operations ====================

  Future<void> saveAllCategories(List<CategoryModel> categories) async {
    for (final c in categories) {
      await _categoriesBox.put(c.categoryId.toString(), c.toMap());
    }
  }

  Future<void> saveCategory(CategoryModel category) async {
    await _categoriesBox.put(category.categoryId.toString(), category.toMap());
  }

  Future<void> deleteCategory(int categoryId) async {
    await _categoriesBox.delete(categoryId.toString());
  }

  List<CategoryModel> getCategoriesByBusiness(int businessId) {
    return _categoriesBox.values
        .where((e) =>
            (Map<String, dynamic>.from(e as Map))['businessId'] == businessId)
        .map((e) =>
            CategoryModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  List<CategoryModel> getCategoriesByType(int businessId, String type) {
    return _categoriesBox.values
        .where((e) {
          final map = Map<String, dynamic>.from(e as Map);
          return map['businessId'] == businessId && map['type'] == type;
        })
        .map((e) =>
            CategoryModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ==================== Transaction Operations ====================

  Future<int> saveTransaction(TransactionModel transaction) async {
    final hiveKey = await _transactionsBox.add(transaction.toMap());
    transaction.hiveKey = hiveKey;
    return hiveKey;
  }

  /// Helper to decode a single transaction entry (value + hive key)
  TransactionModel _decodeTransaction(dynamic key, dynamic value) {
    final tx = TransactionModel.fromMap(Map<String, dynamic>.from(value as Map));
    tx.hiveKey = key as int;
    return tx;
  }

  List<TransactionModel> getTransactionsByBusiness(int businessId) {
    return _transactionsBox.toMap().entries
        .where((e) =>
            (Map<String, dynamic>.from(e.value as Map))['businessId'] ==
            businessId)
        .map((e) => _decodeTransaction(e.key, e.value))
        .toList();
  }

  List<TransactionModel> getTransactionsByDateRange(
    int businessId,
    String startDate,
    String endDate,
  ) {
    return _transactionsBox.toMap().entries
        .where((e) {
          final map = Map<String, dynamic>.from(e.value as Map);
          return map['businessId'] == businessId &&
              (map['transactionDate'] as String).compareTo(startDate) >= 0 &&
              (map['transactionDate'] as String).compareTo(endDate) <= 0;
        })
        .map((e) => _decodeTransaction(e.key, e.value))
        .toList();
  }

  List<TransactionModel> getUnsyncedTransactions() {
    return _transactionsBox.toMap().entries
        .where((e) =>
            (Map<String, dynamic>.from(e.value as Map))['statusSync'] == false)
        .map((e) => _decodeTransaction(e.key, e.value))
        .toList();
  }

  Future<void> markTransactionSynced(int hiveKey, int serverTransactionId) async {
    final data = _transactionsBox.get(hiveKey);
    if (data != null) {
      final map = Map<String, dynamic>.from(data as Map);
      map['statusSync'] = true;
      map['transactionId'] = serverTransactionId;
      await _transactionsBox.put(hiveKey, map);
    }
  }

  Future<void> markAllTransactionsSynced() async {
    final entries = _transactionsBox.toMap().entries;
    for (final entry in entries) {
      final map = Map<String, dynamic>.from(entry.value as Map);
      if (map['statusSync'] == false) {
        map['statusSync'] = true;
        await _transactionsBox.put(entry.key, map);
      }
    }
  }

  // ==================== Financial Report Operations ====================

  Future<void> saveFinancialReport(FinancialReportModel report) async {
    final key = '${report.businessId}_${report.period}';
    await _reportsBox.put(key, report.toMap());
  }

  FinancialReportModel? getReport(int businessId, String period) {
    final key = '${businessId}_$period';
    final data = _reportsBox.get(key);
    if (data == null) return null;
    return FinancialReportModel.fromMap(
      Map<String, dynamic>.from(data as Map),
    );
  }

  List<FinancialReportModel> getReportsByBusiness(int businessId) {
    return _reportsBox.values
        .where((e) =>
            (Map<String, dynamic>.from(e as Map))['businessId'] == businessId)
        .map((e) =>
            FinancialReportModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ==================== Clear & Reset ====================

  Future<void> clearAll() async {
    await _usersBox.clear();
    await _businessesBox.clear();
    await _userBusinessesBox.clear();
    await _categoriesBox.clear();
    await _transactionsBox.clear();
    await _reportsBox.clear();
  }
}
