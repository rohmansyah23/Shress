import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/format_helpers.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/local/models/business_model.dart';
import '../../data/local/models/debt_model.dart';
import '../../data/local/models/debt_payment_model.dart';
import '../../data/local/models/debtor_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/debt_consignment_provider.dart';
import '../../providers/transaction_provider.dart';
import 'add_debt_screen.dart';

String _getInitials(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.isEmpty) return '?';
  if (words.length == 1) return words[0][0].toUpperCase();
  return '${words[0][0]}${words[1][0]}'.toUpperCase();
}

class DebtorDetailScreen extends ConsumerStatefulWidget {
  final DebtorModel debtor;
  final BusinessModel business;

  const DebtorDetailScreen({
    super.key,
    required this.debtor,
    required this.business,
  });

  @override
  ConsumerState<DebtorDetailScreen> createState() =>
      _DebtorDetailScreenState();
}

class _DebtorDetailScreenState extends ConsumerState<DebtorDetailScreen> {
  bool _isLoading = true;
  List<DebtModel> _debts = [];
  DebtorModel? _debtor;

  @override
  void initState() {
    super.initState();
    _debtor = widget.debtor;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final debts = await SupabaseService.instance
          .getDebtsByDebtor(widget.debtor.id);
      if (mounted) {
        setState(() {
          _debts = debts;
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



  Future<void> _editDebt(DebtModel debt) async {
    final amountController =
        TextEditingController(text: debt.amount.toInt().toString());
    final descController =
        TextEditingController(text: debt.description ?? '');
    final dueDateController =
        TextEditingController(text: debt.dueDate ?? '');
    DateTime? dueDate =
        debt.dueDate != null ? DateTime.tryParse(debt.dueDate!) : null;
    bool isFormattingAmount = false;

    String formatRupiah(int value) {
      final s = value.toString();
      final result = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) result.write('.');
        result.write(s[i]);
      }
      return result.toString();
    }

    amountController.addListener(() {
      if (isFormattingAmount) return;
      isFormattingAmount = true;
      final text = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (text.isNotEmpty) {
        final value = int.tryParse(text) ?? 0;
        final formatted = formatRupiah(value);
        if (amountController.text != formatted) {
          amountController.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      }
      isFormattingAmount = false;
    });

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
        title: const Text('Edit Hutang'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah (Rp)',
                  prefixText: 'Rp ',
                  prefixIcon: Icon(Icons.monetization_on_outlined),
                ),
              ),
              const SizedBox(height: AppTheme.s16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
              ),
              const SizedBox(height: AppTheme.s16),
              TextField(
                controller: dueDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Jatuh Tempo',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: dueDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    dueDate = picked;
                    dueDateController.text =
                        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(
                      amountController.text.replaceAll('.', '')) ??
                  0;
              if (amount <= 0) return;
              try {
                await SupabaseService.instance.updateDebt(
                  debtId: debt.id,
                  amount: amount,
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                  dueDate: dueDateController.text.isEmpty
                      ? null
                      : dueDateController.text,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx, true);
              } catch (e) {
                if (!ctx.mounted) return;
                ErrorSnackbar.show(ctx, ErrorHandler.classify(e));
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      _loadData();
      triggerDebtRefresh(ref);
    }
  }

  Future<void> _deleteDebt(DebtModel debt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
        title: const Text('Hapus Hutang'),
        content: const Text('Yakin ingin menghapus data hutang ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.lossColorTheme(context),
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await SupabaseService.instance.deleteDebt(debt.id);
        _loadData();
        triggerDebtRefresh(ref);
        if (!mounted) return;
        ErrorSnackbar.showSuccess(context, 'Hutang berhasil dihapus');
      } catch (e) {
        if (!mounted) return;
        ErrorSnackbar.show(context, ErrorHandler.classify(e));
      }
    }
  }

  Future<void> _showDebtDetail(DebtModel debt) async {
    List<DebtPaymentModel> payments = [];
    try {
      payments = await SupabaseService.instance.getDebtPayments(debt.id);
    } catch (_) {}

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DebtPaymentSheet(
        debt: debt,
        payments: payments,
        business: widget.business,
        onPaymentAdded: () {
          _loadData();
          triggerDebtRefresh(ref);
        },
      ),
    );
  }



  String _statusLabel(String status) {
    switch (status) {
      case AppConstants.debtPaid:
        return 'Lunas';
      case AppConstants.debtPartial:
        return 'Sebagian';
      default:
        return 'Belum Bayar';
    }
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case AppConstants.debtPaid:
        return AppTheme.profitColorTheme(context);
      case AppConstants.debtPartial:
        return AppTheme.warningColorTheme(context);
      default:
        return AppTheme.lossColorTheme(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(transactionRefreshProvider, (prev, next) {
      if (prev != null && prev != next) _loadData();
    });



    return Scaffold(
      appBar: AppBar(
        title: Text(_debtor?.name ?? widget.debtor.name),
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
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.s16,
                        AppTheme.s16,
                        AppTheme.s16,
                        0,
                      ),
                      child: _buildInfoCard(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.s16,
                        AppTheme.s12,
                        AppTheme.s16,
                        AppTheme.s8,
                      ),
                      child: Text('Daftar Hutang', style: AppTheme.heading3),
                    ),
                  ),
                  if (_debts.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 48,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: AppTheme.s8),
                              Text(
                                'Belum ada hutang',
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
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.s16,
                        0,
                        AppTheme.s16,
                        AppTheme.s16,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final debt = _debts[index];
                            return FadeInEntrance(
                              delay: Duration(milliseconds: index * 50),
                              child: _DebtCard(
                                debt: debt,
                                statusLabel: _statusLabel(debt.status),
                                statusColor:
                                    _statusColor(context, debt.status),
                                onTap: () => _showDebtDetail(debt),
                                onEdit: () => _editDebt(debt),
                                onDelete: () => _deleteDebt(debt),
                              ),
                            );
                          },
                          childCount: _debts.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          AppTheme.s16,
          0,
          AppTheme.s16,
          MediaQuery.of(context).viewInsets.bottom + AppTheme.s16,
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => AddDebtScreen(
                    business: widget.business,
                    existingDebtor: _debtor,
                  ),
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

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.warningColorTheme(context)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(_debtor?.name ?? widget.debtor.name),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.warningColorTheme(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _debtor?.name ?? widget.debtor.name,
                        style: AppTheme.heading3,
                      ),
                      if ((_debtor?.phone ?? widget.debtor.phone) != null &&
                          (_debtor?.phone ?? widget.debtor.phone)!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _debtor?.phone ?? widget.debtor.phone!,
                            style: AppTheme.caption,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if ((_debtor?.notes ?? widget.debtor.notes) != null &&
                (_debtor?.notes ?? widget.debtor.notes)!.isNotEmpty) ...[
              const SizedBox(height: AppTheme.s12),
              const Divider(height: 1),
              const SizedBox(height: AppTheme.s12),
              Text('Catatan', style: AppTheme.labelSmall),
              const SizedBox(height: AppTheme.s4),
              Text(
                _debtor?.notes ?? widget.debtor.notes!,
                style: AppTheme.bodyText,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final DebtModel debt;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DebtCard({
    required this.debt,
    required this.statusLabel,
    required this.statusColor,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.s12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  debt.isPaid
                      ? Icons.check_circle_outline_rounded
                      : Icons.receipt_long_rounded,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: AppTheme.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FormatHelpers.rupiah(debt.amount),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      FormatHelpers.displayDate(debt.debtDate),
                      style: AppTheme.caption.copyWith(fontSize: 11),
                    ),
                    if (debt.description != null &&
                        debt.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          debt.description!,
                          style: AppTheme.caption.copyWith(fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  if (!debt.isPaid) ...[
                    const SizedBox(height: AppTheme.s4),
                    Text(
                      'Sisa: ${FormatHelpers.rupiah(debt.remainingAmount)}',
                      style: AppTheme.caption.copyWith(
                        fontSize: 10,
                        color: AppTheme.lossColorTheme(context),
                      ),
                    ),
                  ],
                ],
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: AppTheme.s8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppTheme.lossColorTheme(context),
                        ),
                        const SizedBox(width: AppTheme.s8),
                        Text(
                          'Hapus',
                          style: TextStyle(color: AppTheme.lossColorTheme(context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebtPaymentSheet extends ConsumerStatefulWidget {
  final DebtModel debt;
  final List<DebtPaymentModel> payments;
  final BusinessModel business;
  final VoidCallback onPaymentAdded;

  const _DebtPaymentSheet({
    required this.debt,
    required this.payments,
    required this.business,
    required this.onPaymentAdded,
  });

  @override
  ConsumerState<_DebtPaymentSheet> createState() => _DebtPaymentSheetState();
}

class _DebtPaymentSheetState extends ConsumerState<_DebtPaymentSheet> {
  late List<DebtPaymentModel> _payments;
  late DebtModel _currentDebt;
  final bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _payments = List.from(widget.payments);
    _currentDebt = widget.debt;
  }

  Future<void> _editPayment(DebtPaymentModel payment) async {
    final amountController =
        TextEditingController(text: payment.amount.toInt().toString());
    final notesController =
        TextEditingController(text: payment.notes ?? '');
    bool isFormattingAmount = false;

    String formatRupiah(int value) {
      final s = value.toString();
      final result = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) result.write('.');
        result.write(s[i]);
      }
      return result.toString();
    }

    amountController.addListener(() {
      if (isFormattingAmount) return;
      isFormattingAmount = true;
      final text = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (text.isNotEmpty) {
        final value = int.tryParse(text) ?? 0;
        final formatted = formatRupiah(value);
        if (amountController.text != formatted) {
          amountController.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      }
      isFormattingAmount = false;
    });

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
        title: const Text('Edit Pembayaran'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah (Rp)',
                  prefixText: 'Rp ',
                  prefixIcon: Icon(Icons.monetization_on_outlined),
                ),
              ),
              const SizedBox(height: AppTheme.s16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Catatan'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(
                      amountController.text.replaceAll('.', '')) ??
                  0;
              if (amount <= 0) return;
              try {
                await SupabaseService.instance.updateDebtPayment(
                  paymentId: payment.id,
                  amount: amount,
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx, true);
              } catch (e) {
                if (!ctx.mounted) return;
                ErrorSnackbar.show(ctx, ErrorHandler.classify(e));
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      _refreshPayments();
      _refreshDebt();
      widget.onPaymentAdded();
    }
  }

  Future<void> _deletePayment(DebtPaymentModel payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
        title: const Text('Hapus Pembayaran'),
        content: const Text('Yakin ingin menghapus data pembayaran ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.lossColorTheme(context),
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await SupabaseService.instance.deleteDebtPayment(payment.id);
        _refreshPayments();
        _refreshDebt();
        widget.onPaymentAdded();
        if (!mounted) return;
        ErrorSnackbar.showSuccess(context, 'Pembayaran berhasil dihapus');
      } catch (e) {
        if (!mounted) return;
        ErrorSnackbar.show(context, ErrorHandler.classify(e));
      }
    }
  }

  Future<void> _refreshPayments() async {
    try {
      final payments = await SupabaseService.instance
          .getDebtPayments(widget.debt.id);
      if (mounted) {
        setState(() => _payments = payments);
      }
    } catch (_) {}
  }

  Future<void> _refreshDebt() async {
    try {
      final debt =
          await SupabaseService.instance.getDebtById(widget.debt.id);
      if (mounted) {
        setState(() => _currentDebt = debt);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Detail Hutang', style: AppTheme.heading2),
                      const SizedBox(height: AppTheme.s4),
                      Text(
                        FormatHelpers.rupiah(widget.debt.amount),
                        style: AppTheme.amountMedium.copyWith(
                          color: AppTheme.infoColorTheme(context),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.s8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _InfoChip(
                  label: 'Dibayar',
                  value: FormatHelpers.rupiah(_currentDebt.paidAmount),
                ),
                const SizedBox(width: AppTheme.s8),
                _InfoChip(
                  label: 'Sisa',
                  value: FormatHelpers.rupiah(_currentDebt.remainingAmount),
                  color: AppTheme.lossColorTheme(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.s16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Riwayat Pembayaran', style: AppTheme.heading3),
          ),
          const SizedBox(height: AppTheme.s8),
          Expanded(
            child: _payments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.payment_outlined,
                          size: 48,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: AppTheme.s8),
                        Text(
                          'Belum ada pembayaran',
                          style: AppTheme.caption.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _payments.length,
                    itemBuilder: (context, index) {
                      final payment = _payments[index];
                      return Card(
                        child: ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.profitColorTheme(context)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.check_circle_outline_rounded,
                              size: 18,
                              color: AppTheme.profitColorTheme(context),
                            ),
                          ),
                          title: Text(
                            FormatHelpers.rupiah(payment.amount),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            FormatHelpers.displayDate(payment.paymentDate),
                            style: AppTheme.caption.copyWith(fontSize: 11),
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert_rounded,
                              size: 18,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            onSelected: (value) {
                              if (value == 'edit') _editPayment(payment);
                              if (value == 'delete') _deletePayment(payment);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 18),
                                    SizedBox(width: AppTheme.s8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: AppTheme.lossColorTheme(context),
                                    ),
                                    const SizedBox(width: AppTheme.s8),
                                    Text(
                                      'Hapus',
                                      style: TextStyle(
                                        color: AppTheme.lossColorTheme(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (!_currentDebt.isPaid)
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _showPaymentForm,
                  icon: const Icon(Icons.payment_rounded),
                  label: const Text(
                    'Catat Pembayaran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          if (_currentDebt.isPaid)
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text(
                    'Sudah Lunas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showPaymentForm() {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final dateController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = DateTime.now();
    bool isSaving = false;
    bool isFormattingAmount = false;

    String formatRupiah(int value) {
      final s = value.toString();
      final result = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) {
          result.write('.');
        }
        result.write(s[i]);
      }
      return result.toString();
    }

    String formatDate(DateTime date) {
      return FormatHelpers.displayDate(
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');
    }

    String formatDateIso(DateTime date) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

    dateController.text = formatDate(selectedDate);

    amountController.addListener(() {
      if (isFormattingAmount) return;
      isFormattingAmount = true;
      final text = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (text.isNotEmpty) {
        final value = int.tryParse(text) ?? 0;
        final formatted = formatRupiah(value);
        if (amountController.text != formatted) {
          amountController.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      }
      isFormattingAmount = false;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Text('Catat Pembayaran', style: AppTheme.heading2),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FormLabel('Jumlah Pembayaran (Rp)'),
                        const SizedBox(height: AppTheme.s8),
                        TextFormField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.monetization_on_outlined),
                            hintText: '0',
                            prefixText: 'Rp ',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Masukkan jumlah pembayaran';
                            }
                            final numeric = value.replaceAll('.', '');
                            final amount = double.tryParse(numeric);
                            if (amount == null || amount <= 0) {
                              return 'Jumlah harus lebih dari 0';
                            }
                            if (amount > _currentDebt.remainingAmount) {
                              return 'Melebihi sisa hutang (${FormatHelpers.rupiah(_currentDebt.remainingAmount)})';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.s20),
                        _FormLabel('Tanggal Pembayaran'),
                        const SizedBox(height: AppTheme.s8),
                        TextFormField(
                          controller: dateController,
                          readOnly: true,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setSheetState(() {
                                selectedDate = picked;
                                dateController.text = formatDate(picked);
                              });
                            }
                          },
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                        ),
                        const SizedBox(height: AppTheme.s20),
                        _FormLabel('Catatan (opsional)'),
                        const SizedBox(height: AppTheme.s8),
                        TextFormField(
                          controller: notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'Catatan pembayaran...',
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }
                                    setSheetState(() => isSaving = true);
                                    final user = ref.read(currentUserProvider);
                                    if (user == null) {
                                      setSheetState(() => isSaving = false);
                                      if (context.mounted) {
                                        ErrorSnackbar.showError(context,
                                            'Sesi tidak valid, silakan login ulang');
                                      }
                                      return;
                                    }
                                    final amountStr = amountController.text
                                        .replaceAll('.', '');
                                    final amount =
                                        double.tryParse(amountStr) ?? 0;
                                    try {
                                      final incomeCategoryId = await SupabaseService
                                          .instance
                                          .getOrCreateCategoryForBusiness(
                                        widget.business.businessId,
                                        AppConstants.categoryPiutang,
                                        AppConstants.typeIncome,
                                      );
                                      await SupabaseService.instance
                                          .createDebtPayment(
                                        debtId: widget.debt.id,
                                        amount: amount,
                                        userId: user.userId,
                                        notes:
                                            notesController.text.trim().isEmpty
                                                ? null
                                                : notesController.text.trim(),
                                        paymentDate:
                                            formatDateIso(selectedDate),
                                        incomeCategoryId: incomeCategoryId,
                                      );
                                      if (!context.mounted) return;
                                      Navigator.of(context).pop();
                                      _refreshPayments();
                                      _refreshDebt();
                                      widget.onPaymentAdded();
                                      triggerTransactionRefresh(ref);
                                      if (!context.mounted) return;
                                      ErrorSnackbar.showSuccess(
                                          context,
                                          'Pembayaran berhasil dicatat');
                                    } catch (e) {
                                      setSheetState(() => isSaving = false);
                                      if (mounted) {
                                        ErrorSnackbar.show(
                                            context, ErrorHandler.classify(e));
                                      }
                                    }
                                  },
                            icon: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.payment_rounded),
                            label: Text(
                              isSaving
                                  ? 'Menyimpan...'
                                  : 'Simpan Pembayaran',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _InfoChip({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (color ?? AppTheme.infoColorTheme(context))
              .withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTheme.caption.copyWith(fontSize: 10)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color ?? AppTheme.infoColorTheme(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String label;

  const _FormLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
