import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/format_helpers.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/local/models/business_model.dart';
import '../../data/local/models/debtor_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/debt_consignment_provider.dart';
import '../../providers/transaction_provider.dart';
import 'add_debt_screen.dart';
import 'debtor_detail_screen.dart';

String _getInitials(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.isEmpty) return '?';
  if (words.length == 1) return words[0][0].toUpperCase();
  return '${words[0][0]}${words[1][0]}'.toUpperCase();
}

class DebtorsScreen extends ConsumerStatefulWidget {
  final BusinessModel business;

  const DebtorsScreen({super.key, required this.business});

  @override
  ConsumerState<DebtorsScreen> createState() => _DebtorsScreenState();
}

class _DebtorsScreenState extends ConsumerState<DebtorsScreen> {
  bool _isLoading = true;
  List<DebtorModel> _debtors = [];
  Map<String, dynamic> _summary = {};
  Map<int, double> _debtorTotals = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final debtors = await SupabaseService.instance
          .getDebtorsByBusiness(widget.business.businessId);
      final summary = await SupabaseService.instance
          .getDebtSummary(widget.business.businessId);
      final debts = await SupabaseService.instance
          .getDebtsByBusiness(widget.business.businessId);

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

      if (mounted) {
        setState(() {
          _debtors = debtors;
          _summary = summary;
          _debtorTotals = totals;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorSnackbar.show(context, ErrorHandler.classify(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(transactionRefreshProvider, (prev, next) {
      if (prev != null && prev != next) _loadData();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Piutang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat ulang',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _buildSummaryCard(),
                    ),
                  ),
                  if (_debtors.isEmpty)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline_rounded,
                                size: 64,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: AppTheme.s12),
                              Text(
                                'Belum ada penghutang',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: AppTheme.s4),
                              Text(
                                'Tekan + untuk menambah hutang baru',
                                style: AppTheme.caption.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final debtor = _debtors[index];
                            final total = _debtorTotals[debtor.id] ?? 0;
                            return FadeInEntrance(
                              delay: Duration(milliseconds: index * 50),
                              child: _DebtorCard(
                                debtor: debtor,
                                remainingAmount: total,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => DebtorDetailScreen(
                                        debtor: debtor,
                                        business: widget.business,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          childCount: _debtors.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => AddDebtScreen(business: widget.business),
                ),
              );
              if (result == true) {
                _loadData();
                triggerDebtRefresh(ref);
              }
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Tambah Hutang',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalOwed = (_summary['totalOwed'] as num?)?.toDouble() ?? 0;
    final debtorCount = (_summary['debtorCount'] as num?)?.toInt() ?? 0;
    final totalPaid = (_summary['totalPaid'] as num?)?.toDouble() ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 18, color: AppTheme.infoColorTheme(context)),
                const SizedBox(width: 6),
                Text('Ringkasan Piutang', style: AppTheme.labelSmall),
              ],
            ),
            const SizedBox(height: AppTheme.s16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Piutang Aktif', style: AppTheme.caption),
                      const SizedBox(height: AppTheme.s4),
                      Text(
                        FormatHelpers.rupiah(totalOwed),
                        style: AppTheme.amountMedium.copyWith(
                          color: AppTheme.lossColorTheme(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.s16),
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: 'Penghutang',
                    value: '$debtorCount',
                    icon: Icons.people_outline_rounded,
                    color: AppTheme.infoColorTheme(context),
                  ),
                ),
                const SizedBox(width: AppTheme.s12),
                Expanded(
                  child: _SummaryItem(
                    label: 'Sudah Dibayar',
                    value: FormatHelpers.rupiah(totalPaid),
                    icon: Icons.check_circle_outline_rounded,
                    color: AppTheme.profitColorTheme(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.caption.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

class _DebtorCard extends StatelessWidget {
  final DebtorModel debtor;
  final double remainingAmount;
  final VoidCallback onTap;

  const _DebtorCard({
    required this.debtor,
    required this.remainingAmount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.warningColorTheme(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                alignment: Alignment.center,
                child: Text(
                  _getInitials(debtor.name),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.warningColorTheme(context),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debtor.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (debtor.phone != null && debtor.phone!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          debtor.phone!,
                          style: AppTheme.caption.copyWith(fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Sisa Hutang',
                    style: AppTheme.caption.copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    FormatHelpers.rupiah(remainingAmount),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: remainingAmount > 0
                          ? AppTheme.lossColorTheme(context)
                          : AppTheme.profitColorTheme(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
