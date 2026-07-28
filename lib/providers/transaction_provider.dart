import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/constants.dart';
import '../data/remote/supabase_service.dart';

// ==================== Transaction Save ====================

class TransactionSaveResult {
  final bool success;
  final String? message;

  const TransactionSaveResult({required this.success, this.message});
}

/// Create a new transaction directly on Supabase (cloud-only)
Future<TransactionSaveResult> saveTransaction({
  required int businessId,
  required int categoryId,
  required String userId,
  required String type,
  required double amount,
  double cogs = 0.0,
  String? description,
  required String transactionDate,
  String paymentMethod = AppConstants.paymentCash,
}) async {
  try {
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

    await SupabaseService.instance.createTransaction(
      businessId: businessId,
      categoryId: categoryId,
      userId: userId,
      type: type,
      amount: amount,
      cogs: type == AppConstants.typeIncome ? cogs : 0.0,
      paymentMethod: paymentMethod,
      description: description,
      transactionDate: transactionDate,
    );

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

/// Update an existing transaction on Supabase (cloud-only)
Future<TransactionSaveResult> updateTransaction({
  required int transactionId,
  int? businessId,
  int? categoryId,
  String? type,
  double? amount,
  double? cogs,
  String? paymentMethod,
  String? description,
  String? transactionDate,
}) async {
  try {
    await SupabaseService.instance.updateTransaction(
      transactionId: transactionId,
      businessId: businessId,
      categoryId: categoryId,
      type: type,
      amount: amount,
      cogs: cogs,
      paymentMethod: paymentMethod,
      description: description,
      transactionDate: transactionDate,
    );

    return const TransactionSaveResult(
      success: true,
      message: 'Transaksi berhasil diperbarui',
    );
  } catch (e) {
    return TransactionSaveResult(
      success: false,
      message: 'Gagal memperbarui: $e',
    );
  }
}

/// Delete a transaction from Supabase (cloud-only)
Future<TransactionSaveResult> deleteTransaction({
  required int transactionId,
}) async {
  try {
    await SupabaseService.instance.deleteTransaction(transactionId);
    return const TransactionSaveResult(
      success: true,
      message: 'Transaksi berhasil dihapus',
    );
  } catch (e) {
    return TransactionSaveResult(
      success: false,
      message: 'Gagal menghapus: $e',
    );
  }
}

// ==================== Refresh Provider ====================

final transactionRefreshProvider = StateProvider<int>((ref) => 0);

void triggerTransactionRefresh(WidgetRef ref) {
  ref.read(transactionRefreshProvider.notifier).state++;
}
