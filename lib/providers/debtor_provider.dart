import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/constants.dart';
import '../data/local/models/debtor_model.dart';
import '../data/remote/supabase_service.dart';
import 'transaction_provider.dart';

/// Provider untuk mengelola state data Piutang (Debtors) secara global.
final debtorProvider = FutureProvider.family<
    ({List<DebtorModel> debtors, Map<String, dynamic> summary, Map<int, double> debtorTotals}),
    int>((ref, businessId) async {
  ref.watch(transactionRefreshProvider);

  final debtors = await SupabaseService.instance.getDebtorsByBusiness(businessId);
  final summary = await SupabaseService.instance.getDebtSummary(businessId);
  final debts = await SupabaseService.instance.getDebtsByBusiness(businessId);

  final totals = <int, double>{};
  for (final debt in debts) {
    if (debt.status != AppConstants.debtPaid) {
      totals.update(
        debt.debtorId,
        (v) => v + debt.remainingAmount,
        ifAbsent: () => debt.remainingAmount,
      );
    }
  }

  return (debtors: debtors, summary: summary, debtorTotals: totals);
});