import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/constants.dart';
import '../data/local/database.dart';
import '../data/local/models/transaction_model.dart';

// ==================== Transaction Save ====================

/// Result of saving a transaction
class TransactionSaveResult {
  final bool success;
  final String? message;

  const TransactionSaveResult({required this.success, this.message});
}

/// Save a new transaction locally (offline-first)
Future<TransactionSaveResult> saveTransaction({
  required int businessId,
  required int categoryId,
  required String userId,
  required String type,
  required double amount,
  double cogs = 0.0,
  String? description,
  required String transactionDate,
  String paymentMethod = 'cash',
}) async {
  try {
    // Validate
    if (amount <= 0) {
      return const TransactionSaveResult(
        success: false,
        message: 'Jumlah harus lebih dari 0',
      );
    }
    if (type == AppConstants.typeIncome && cogs < 0) {
      return const TransactionSaveResult(
        success: false,
        message: 'HPP tidak boleh negatif',
      );
    }

    final transaction = TransactionModel(
      businessId: businessId,
      categoryId: categoryId,
      userId: userId,
      type: type,
      amount: amount,
      cogs: type == AppConstants.typeIncome ? cogs : 0.0,
      paymentMethod: paymentMethod,
      description: description,
      transactionDate: transactionDate,
      statusSync: false, // Offline-first: pending sync
    );

    await LocalDatabase.instance.saveTransaction(transaction);

    return const TransactionSaveResult(
      success: true,
      message: 'Transaksi berhasil disimpan',
    );
  } catch (e) {
    return TransactionSaveResult(
      success: false,
      message: 'Gagal menyimpan: $e',
    );
  }
}

// ==================== Refresh Provider ====================

/// Provider that invalidates when transaction is saved (for auto-refresh)
final transactionRefreshProvider = StateProvider<int>((ref) => 0);

/// Trigger a refresh of transaction data (call after saving a transaction)
void triggerTransactionRefresh(WidgetRef ref) {
  ref.read(transactionRefreshProvider.notifier).state++;
}
