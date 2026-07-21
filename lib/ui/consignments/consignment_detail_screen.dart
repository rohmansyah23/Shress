import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/format_helpers.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/local/models/business_model.dart';
import '../../data/local/models/consignor_model.dart';
import '../../data/local/models/consignment_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/debt_consignment_provider.dart';
import 'report_sales_screen.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

import '../../core/theme/app_icon_size.dart';

class ConsignmentDetailScreen extends ConsumerStatefulWidget {
  final ConsignmentModel consignment;
  final ConsignorModel consignor;
  final BusinessModel business;

  const ConsignmentDetailScreen({
    super.key,
    required this.consignment,
    required this.consignor,
    required this.business,
  });

  @override
  ConsumerState<ConsignmentDetailScreen> createState() =>
      _ConsignmentDetailScreenState();
}

class _ConsignmentDetailScreenState
    extends ConsumerState<ConsignmentDetailScreen> {
  bool _isLoading = true;
  List<ConsignmentItemModel> _items = [];
  List<ConsignmentSettlementModel> _settlements = [];
  late ConsignmentModel _consignment;
  String _paymentMethod = AppConstants.paymentCash;

  @override
  void initState() {
    super.initState();
    _consignment = widget.consignment;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        SupabaseService.instance.getConsignmentItems(_consignment.id),
        SupabaseService.instance.getConsignmentSettlements(_consignment.id),
      ]);
      if (mounted) {
        setState(() {
          _items = results[0] as List<ConsignmentItemModel>;
          _settlements = results[1] as List<ConsignmentSettlementModel>;
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

  Future<void> _handleReportSales() async {
    if (!mounted) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReportSalesScreen(
          consignment: _consignment,
          items: _items,
        ),
      ),
    );

    if (result == true) {
      _refreshConsignment();
    }
  }

  Future<void> _refreshConsignment() async {
    try {
      final data = await SupabaseService.instance
          .getConsignmentItems(_consignment.id);
      final settlements = await SupabaseService.instance
          .getConsignmentSettlements(_consignment.id);

      final refreshed = await SupabaseService.instance
          .getConsignmentsByBusiness(_consignment.businessId);
      final found = refreshed.where((c) => c.id == _consignment.id).firstOrNull;

      if (mounted) {
        setState(() {
          _items = data;
          _settlements = settlements;
          if (found != null) {
            double paymentOwing = 0;
            for (final item in data) {
              paymentOwing += item.agreedPrice * item.quantitySold;
            }
            _consignment = found.copyWith(paymentOwing: paymentOwing);
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _handleSettleDaily() async {
    final totalPayment = _items.fold<double>(
      0,
      (sum, item) => sum + item.agreedPrice * item.quantitySold,
    );

    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.radiusMedium)),
          title: const Text('Bayar ke Pihak Penitip'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.consignor.name,
                style: AppTheme.heading3,
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Total dibayar: ${FormatHelpers.rupiah(totalPayment)}',
                style: AppTheme.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lossColorTheme(context),
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              Text('Metode bayar', style: AppTheme.labelSmall),
              const SizedBox(height: AppSpacing.s8),
              _buildPaymentOption(
                ctx,
                setDialogState,
                value: AppConstants.paymentCash,
                label: 'Cash',
                icon: Icons.money_rounded,
              ),
              const SizedBox(height: AppSpacing.s4),
              _buildPaymentOption(
                ctx,
                setDialogState,
                value: AppConstants.paymentTransfer,
                label: 'Transfer',
                icon: Icons.account_balance_rounded,
              ),
              const SizedBox(height: AppSpacing.s4),
              _buildPaymentOption(
                ctx,
                setDialogState,
                value: AppConstants.paymentQris,
                label: 'QRIS',
                icon: Icons.qr_code_rounded,
              ),
              const SizedBox(height: AppSpacing.s16),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s12),
                decoration: BoxDecoration(
                  color: AppTheme.infoColorTheme(context)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long_rounded,
                        size: AppIconSize.s16, color: AppTheme.infoColorTheme(context)),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: Text(
                        'transaksi akan dibuat otomatis',
                        style: AppTheme.caption.copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Bayar Sekarang'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        if (!mounted) return;
        final user = ref.read(currentUserProvider);
        if (user == null) {
          ErrorSnackbar.showMessage(context, 'Sesi tidak valid');
          return;
        }

        await SupabaseService.instance.settleConsignment(
          consignmentId: _consignment.id,
          businessId: _consignment.businessId,
          userId: user.userId,
          paymentMethod: _paymentMethod,
          paymentDate: DateTime.now().toIso8601String().substring(0, 10),
        );

        if (!mounted) return;
        triggerDebtRefresh(ref);
        await _refreshConsignment();
        if (!mounted) return;
        ErrorSnackbar.showSuccess(context, 'Pembayaran berhasil');
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (!mounted) return;
        final appError = ErrorHandler.classify(e);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(appError.isOffline
                    ? Icons.wifi_off_rounded
                    : Icons.error_outline_rounded,
                    color: AppTheme.onDangerColorTheme(context), size: AppIconSize.s18),
                const SizedBox(width: AppSpacing.s8),
                Expanded(child: Text(appError.userMessage)),
              ],
            ),                      backgroundColor: appError.isOffline
                ? AppTheme.warningColor
                : AppTheme.lossColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
            ),
            action: SnackBarAction(
              label: 'Tutup',
              textColor: AppTheme.onDangerColorTheme(context),
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  Widget _buildPaymentOption(
    BuildContext ctx,
    StateSetter setDialogState, {
    required String value,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _paymentMethod == value;
    final textColor = Theme.of(ctx).textTheme.bodyMedium?.color ?? AppTheme.secondaryText;
    final subtleColor = Theme.of(ctx).brightness == Brightness.dark
        ? AppTheme.darkSecondaryText.withValues(alpha: 0.7)
        : (Theme.of(ctx).textTheme.bodySmall?.color ?? AppTheme.secondaryText);
    return InkWell(
      onTap: () => setDialogState(() => _paymentMethod = value),            borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: AppSpacing.s12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColorTheme(ctx).withValues(alpha: 0.15)
              : AppTheme.surfaceContainerHighestColorTheme(ctx).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColorTheme(ctx)
                : subtleColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: AppIconSize.s18,
                color: isSelected ? AppTheme.primaryColorTheme(ctx) : subtleColor),
            const SizedBox(width: AppSpacing.s8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColorTheme(ctx) : textColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle_rounded,
                  size: AppIconSize.s18, color: AppTheme.primaryColorTheme(ctx)),
          ],
        ),
      ),
    );
  }

  Future<void> _recordSettlement() async {
    final remaining = _consignment.displayTotal;
    if (remaining <= 0) {
      ErrorSnackbar.showMessage(context, 'Titipan sudah lunas');
      return;
    }

    final amountCtrl =
        TextEditingController(text: remaining.toStringAsFixed(0));
    final notesCtrl = TextEditingController();
    String settlementDate =
        DateTime.now().toIso8601String().substring(0, 10);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.radiusMedium)),
          title: const Text('Catat Pembayaran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sisa tagihan: ${FormatHelpers.rupiah(remaining)}',
                style: AppTheme.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.warningColorTheme(context),
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Bayar',
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.parse(settlementDate),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      settlementDate =
                          picked.toIso8601String().substring(0, 10);
                    });
                  }
                },
                borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Bayar',
                    prefixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                  child: Text(FormatHelpers.displayDate(settlementDate)),
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                if (amount <= 0) {
                  ErrorSnackbar.showMessage(
                      ctx, 'Jumlah harus lebih dari 0');
                  return;
                }
                if (amount > remaining) {
                  ErrorSnackbar.showMessage(
                      ctx, 'Jumlah melebihi sisa tagihan');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        if (!mounted) return;
        final user = ref.read(currentUserProvider);
        if (user == null) {
          ErrorSnackbar.showMessage(context, 'Sesi tidak valid');
          return;
        }

        final amount = double.tryParse(amountCtrl.text) ?? 0;
        await SupabaseService.instance.createConsignmentSettlement(
          consignmentId: _consignment.id,
          amount: amount,
          userId: user.userId,
          notes:
              notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
          settlementDate: settlementDate,
          paymentMethod: _paymentMethod,
        );

        if (!mounted) return;
        triggerDebtRefresh(ref);
        ErrorSnackbar.showSuccess(context, 'Pembayaran berhasil dicatat');
        _refreshConsignment();
      } catch (e) {
        if (!mounted) return;
        ErrorSnackbar.show(context, ErrorHandler.classify(e));
      }
    }
  }



  Color _statusColor(String status, BuildContext context) {
    switch (status) {
      case AppConstants.consignmentActive:
        return AppTheme.warningColorTheme(context);
      case AppConstants.consignmentSettled:
        return AppTheme.profitColorTheme(context);
      case AppConstants.consignmentCancelled:
        return AppTheme.lossColorTheme(context);
      default:
        return AppTheme.secondaryText;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case AppConstants.consignmentActive:
        return 'Aktif';
      case AppConstants.consignmentSettled:
        return 'Selesai';
      case AppConstants.consignmentCancelled:
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  String _reportStatusLabel(String reportStatus) {
    switch (reportStatus) {
      case AppConstants.reportPending:
        return 'Menunggu';
      case AppConstants.reportReported:
        return 'Dilaporkan';
      case AppConstants.reportSettled:
        return 'Selesai';
      default:
        return reportStatus;
    }
  }

  Color _reportStatusColor(String reportStatus, BuildContext context) {
    switch (reportStatus) {
      case AppConstants.reportPending:
        return AppTheme.warningColorTheme(context);
      case AppConstants.reportReported:
        return AppTheme.infoColorTheme(context);
      case AppConstants.reportSettled:
        return AppTheme.profitColorTheme(context);
      default:
        return AppTheme.secondaryText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _consignment.displayTotal;
    final color = _statusColor(_consignment.status, context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Titipan'),
      ),
      floatingActionButton: _buildFab(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.s16),
                children: [
                  _buildStatusBadge(color),
                  const SizedBox(height: AppSpacing.s12),
                  _buildConsignorCard(),
                  const SizedBox(height: AppSpacing.s12),
                  _buildSummaryCard(remaining),
                  const SizedBox(height: AppSpacing.s16),
                  FadeInEntrance(
                    child: _buildItemsSection(),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  FadeInEntrance(
                    delay: const Duration(milliseconds: 100),
                    child: _buildSettlementSection(),
                  ),
                  if ((_consignment.isDaily || _consignment.isReseller) &&
                      _consignment.status ==
                          AppConstants.consignmentSettled) ...[
                    const SizedBox(height: AppSpacing.s16),
                    FadeInEntrance(
                      delay: const Duration(milliseconds: 200),
                      child: _buildTransactionLinks(),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s80),
                ],
              ),
            ),
    );
  }

  Widget? _buildFab() {
    if (_consignment.status != AppConstants.consignmentActive) return null;

    final fabShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
    );

    if (_consignment.isDaily || _consignment.isReseller) {
      if (_consignment.reportStatus == AppConstants.reportPending) {
        return FloatingActionButton.extended(
          onPressed: _handleReportSales,
          shape: fabShape,
          icon: const Icon(Icons.edit_note_rounded),
          label: const Text('Laporkan Penjualan'),
        );
      }
      if (_consignment.reportStatus == AppConstants.reportReported) {
        if (_consignment.isDaily || _consignment.isReseller) {
          return FloatingActionButton.extended(
            onPressed: _handleSettleDaily,
            shape: fabShape,
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Bayar ke Pihak Penitip'),
          );
        }
        return FloatingActionButton.extended(
          onPressed: _recordSettlement,
          shape: fabShape,
          icon: const Icon(Icons.payments_outlined),
          label: const Text('Catat Pembayaran'),
        );
      }
    }

    return FloatingActionButton.extended(
      onPressed: _recordSettlement,
      shape: fabShape,
      icon: const Icon(Icons.payments_outlined),
      label: const Text('Catat Pembayaran'),
    );
  }

  Widget _buildStatusBadge(Color color) {
    return FadeInEntrance(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(
              _consignment.status == AppConstants.consignmentSettled
                  ? Icons.check_circle_rounded
                  : _consignment.status == AppConstants.consignmentCancelled
                      ? Icons.cancel_rounded
                      : Icons.schedule_rounded,
              color: color,
              size: AppIconSize.s20,
            ),
            const SizedBox(width: AppSpacing.s8),
            Flexible(
              child: Text(
                _statusLabel(_consignment.status),
                style: AppTheme.subtitle.copyWith(fontSize: 14, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
              decoration: BoxDecoration(
                color: _consignment.isDaily
                    ? AppTheme.infoColorTheme(context).withValues(alpha: 0.2)
                    : AppTheme.primaryColorTheme(context).withValues(alpha: 0.2),                    borderRadius: BorderRadius.circular(AppRadius.s6),
              ),
              child: Text(
                _consignment.isDaily ? 'Harian' : 'Reseller',
                style: AppTheme.labelSmall.copyWith(
                  color: _consignment.isDaily
                      ? AppTheme.infoColorTheme(context)
                      : AppTheme.primaryColorTheme(context),
                ),
              ),
            ),
            if (_consignment.isDaily || _consignment.isReseller) ...[
              const SizedBox(width: AppSpacing.s8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
                decoration: BoxDecoration(
                  color: _reportStatusColor(
                          _consignment.reportStatus, context)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.s6),
                ),
                child: Text(
                  _reportStatusLabel(_consignment.reportStatus),
                style: AppTheme.labelSmall.copyWith(
                  color: _reportStatusColor(
                      _consignment.reportStatus, context),
                ),
                ),
              ),
            ],
            const SizedBox(width: AppSpacing.s8),
            Flexible(
              child: Text(
                FormatHelpers.displayDate(_consignment.consignmentDate),
                style: AppTheme.caption.copyWith(color: color, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsignorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor:
                  AppTheme.primaryColorTheme(context).withValues(alpha: 0.12),
              child: Text(
                widget.consignor.name.length >= 2
                    ? widget.consignor.name
                        .substring(0, 2)
                        .toUpperCase()
                    : widget.consignor.name.toUpperCase(),
                style: AppTheme.subtitle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColorTheme(context),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.consignor.name, style: AppTheme.heading3),
                  if (widget.consignor.phone != null &&
                      widget.consignor.phone!.isNotEmpty)
                    Text(
                      widget.consignor.phone!,
                      style: AppTheme.caption.copyWith(fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double remaining) {
    if (_consignment.isDaily || _consignment.isReseller) {
      if (_consignment.reportStatus == AppConstants.reportPending) {
        return _buildDailyPendingSummaryCard();
      }
      return _buildDailySummaryCard();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ringkasan', style: AppTheme.labelSmall),
            const SizedBox(height: AppSpacing.s12),
            Row(
              children: [
                Expanded(
                  child: _summaryColumn(
                    'Total',
                    FormatHelpers.rupiah(_consignment.totalAmount),
                    AppTheme.primaryColorTheme(context),
                  ),
                ),
                Expanded(
                  child: _summaryColumn(
                    'Dibayar',
                    FormatHelpers.rupiah(_consignment.settledAmount),
                    AppTheme.profitColorTheme(context),
                  ),
                ),
                Expanded(
                  child: _summaryColumn(
                    'Sisa',
                    FormatHelpers.rupiah(remaining),
                    remaining > 0
                        ? AppTheme.warningColorTheme(context)
                        : AppTheme.profitColorTheme(context),
                  ),
                ),
              ],
            ),
            if (_consignment.description != null &&
                _consignment.description!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s12),
              const Divider(),
              const SizedBox(height: AppSpacing.s8),
              Text(
                _consignment.description!,
                style: AppTheme.caption,
              ),
            ],
            if (_consignment.dueDate != null) ...[
              const SizedBox(height: AppSpacing.s8),
              Row(
                children: [
                  Icon(Icons.event_outlined,
                      size: AppIconSize.s14,
                      color: AppTheme.infoColorTheme(context)),
                  const SizedBox(width: AppSpacing.s4),
                  Text(
                    'Jatuh tempo: ${FormatHelpers.displayDate(_consignment.dueDate!)}',
                    style: AppTheme.caption.copyWith(
                      fontSize: 12,
                      color: AppTheme.infoColorTheme(context),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDailyPendingSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ringkasan Titipan', style: AppTheme.labelSmall),
            const SizedBox(height: AppSpacing.s12),
            _buildSummaryRow(
              'Total Nilai Titipan',
              FormatHelpers.rupiah(_consignment.totalAmount),
              AppTheme.primaryColorTheme(context),
            ),
            const SizedBox(height: AppSpacing.s8),
            _buildSummaryRow(
              'Sudah Dibayar',
              FormatHelpers.rupiah(_consignment.settledAmount),
              AppTheme.profitColorTheme(context),
            ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(AppSpacing.s12),
              decoration: BoxDecoration(
                color: AppTheme.warningColorTheme(context)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded,
                      size: AppIconSize.s16, color: AppTheme.warningColorTheme(context)),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: Text(
                      'Menunggu laporan penjualan',
                      style: AppTheme.caption.copyWith(
                        fontSize: 12,
                        color: AppTheme.warningColorTheme(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_consignment.description != null &&
                _consignment.description!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s12),
              const Divider(),
              const SizedBox(height: AppSpacing.s8),
              Text(
                _consignment.description!,
                style: AppTheme.caption,
              ),
            ],
            if (_consignment.dueDate != null) ...[
              const SizedBox(height: AppSpacing.s8),
              Row(
                children: [
                  Icon(Icons.event_outlined,
                      size: AppIconSize.s14,
                      color: AppTheme.infoColorTheme(context)),
                  const SizedBox(width: AppSpacing.s4),
                  Text(
                    'Jatuh tempo: ${FormatHelpers.displayDate(_consignment.dueDate!)}',
                    style: AppTheme.caption.copyWith(
                      fontSize: 12,
                      color: AppTheme.infoColorTheme(context),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummaryCard() {
    double totalFromSales = 0;
    double totalPayment = 0;
    for (final item in _items) {
      final effectivePrice = item.sellingPrice ?? item.agreedPrice;
      totalFromSales += effectivePrice * item.quantitySold;
      totalPayment += item.agreedPrice * item.quantitySold;
    }
    final commission = totalFromSales - totalPayment;

    return Card(
      color: AppTheme.primaryColorTheme(context).withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ringkasan Penjualan', style: AppTheme.labelSmall),
            const SizedBox(height: AppSpacing.s12),
            _buildSummaryRow(
              'Total Pendapatan',
              FormatHelpers.rupiah(totalFromSales),
              AppTheme.profitColorTheme(context),
            ),
            const SizedBox(height: AppSpacing.s8),
            _buildSummaryRow(
              'Total ke Pihak Penitip',
              FormatHelpers.rupiah(totalPayment),
              AppTheme.lossColorTheme(context),
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              'Komisi',
              FormatHelpers.rupiah(commission),
              AppTheme.primaryColorTheme(context),
            ),
            if (_consignment.description != null &&
                _consignment.description!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s12),
              const Divider(),
              const SizedBox(height: AppSpacing.s8),
              Text(
                _consignment.description!,
                style: AppTheme.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      children: [
        Flexible(
          child: Text(label, style: AppTheme.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: AppSpacing.s8),
        Flexible(
          child: Text(
            value,
            style: AppTheme.amountMedium.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _summaryColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.labelSmall),
        const SizedBox(height: AppSpacing.s4),
        Text(
          value,
          style: AppTheme.amountMedium.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildItemsSection() {
    final showSalesInfo = (_consignment.isDaily || _consignment.isReseller) &&
        _consignment.reportStatus != AppConstants.reportPending;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: AppIconSize.s18, color: AppTheme.primaryColorTheme(context)),
                const SizedBox(width: AppSpacing.s8),
                Text('Item Titipan', style: AppTheme.heading3),
                const Spacer(),
                Text(
                  '${_items.length} item',
                  style: AppTheme.caption.copyWith(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
                child: Center(
                  child: Text(
                    'Tidak ada item',
                    style: AppTheme.caption.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              )
            else
              ..._items.map(
                  (item) => _buildItemRow(item, showSalesInfo)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(ConsignmentItemModel item, bool showSalesInfo) {
    if (showSalesInfo) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.productName,
              style:
                  AppTheme.subtitle.copyWith(fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.s4),
            Wrap(
              spacing: AppSpacing.s4,
              runSpacing: AppSpacing.s4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildQtyChip(
                    'Dititipkan', item.quantity, AppTheme.primaryColorTheme(context)),
                Icon(Icons.arrow_forward_rounded,
                    size: AppIconSize.s14, color: AppTheme.secondaryText),
                _buildQtyChip(
                  'Terjual',
                  item.quantitySold,
                  AppTheme.profitColorTheme(context),
                ),
                Icon(Icons.arrow_forward_rounded,
                    size: AppIconSize.s14, color: AppTheme.secondaryText),
                _buildQtyChip(
                  'Kembali',
                  item.quantityReturned,
                  AppTheme.warningColorTheme(context),
                ),
              ],
            ),
            if (item.sellingPrice != null) ...[
              const SizedBox(height: AppSpacing.s8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.quantitySold} × ${FormatHelpers.rupiah(item.sellingPrice!)} pendapatan',
                    style:
                        AppTheme.caption.copyWith(fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    '${item.quantitySold} × ${FormatHelpers.rupiah(item.agreedPrice)} ke pihak penitip',
                    style: AppTheme.caption.copyWith(
                        fontSize: 11,
                        color: AppTheme.lossColorTheme(context)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    final isFullySold = (_consignment.isDaily || _consignment.isReseller) &&
        item.sellingPrice != null &&
        item.quantitySold >= item.quantity;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style:                  AppTheme.subtitle.copyWith(fontSize: 14),
                ),
                if (item.description != null &&
                    item.description!.isNotEmpty)
                  Text(
                    item.description!,
                    style: AppTheme.caption.copyWith(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  '${item.quantity} x ${FormatHelpers.rupiah(item.agreedPrice)}',
                  style: AppTheme.caption.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          if (item.sellingPrice != null)
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Harga Jual', style: AppTheme.labelSmall),
                  Text(
                    FormatHelpers.rupiah(item.sellingPrice!),
                    style: AppTheme.caption.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Subtotal', style: AppTheme.labelSmall),
                Text(
                  FormatHelpers.rupiah(item.totalAgreedPrice),
                  style: AppTheme.amountMedium.copyWith(color: AppTheme.infoColorTheme(context)),
                ),
                if (item.sellingPrice != null) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    isFullySold ? 'Estimasi Pemasukan' : 'Omzet',
                    style: AppTheme.labelSmall,
                  ),
                  Text(
                    FormatHelpers.rupiah(item.totalSellingPriceAll),
                    style: AppTheme.caption.copyWith(fontWeight: FontWeight.w600, color: AppTheme.profitColorTheme(context)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyChip(String label, int qty, Color color) {
    return Container(                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.s6),
      ),
      child: Text(
        '$label: $qty',
        style: AppTheme.labelSmall.copyWith(color: color),
      ),
    );
  }

  Widget _buildSettlementSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined,
                    size: AppIconSize.s18, color: AppTheme.profitColor),
                const SizedBox(width: AppSpacing.s8),
                Text('Riwayat Pembayaran', style: AppTheme.heading3),
                const Spacer(),
                Text(
                  '${_settlements.length} transaksi',
                  style: AppTheme.caption.copyWith(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            if (_settlements.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
                child: Center(
                  child: Text(
                    'Belum ada pembayaran',
                    style: AppTheme.caption.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              )
            else
              ..._settlements.map((s) => _buildSettlementRow(s)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementRow(ConsignmentSettlementModel settlement) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.profitColorTheme(context)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
            ),
            child: Icon(Icons.check_circle_rounded,
                size: AppIconSize.s18, color: AppTheme.profitColorTheme(context)),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  FormatHelpers.displayDate(settlement.settlementDate),
                  style: AppTheme.caption.copyWith(fontSize: 12),
                ),
                if (settlement.notes != null &&
                    settlement.notes!.isNotEmpty)
                  Text(
                    settlement.notes!,
                    style: AppTheme.caption.copyWith(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Flexible(
            child: Text(
              FormatHelpers.rupiah(settlement.amount),
              style: AppTheme.amountMedium.copyWith(color: AppTheme.profitColorTheme(context)),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionLinks() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.link_rounded,
                    size: AppIconSize.s18, color: AppTheme.primaryColor),
                const SizedBox(width: AppSpacing.s8),
                Text('Transaksi Terkait', style: AppTheme.heading3),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            if (_consignment.incomeTransactionId != null)
              _buildTransactionLink(
                label: 'Uang Masuk',
                transactionId: _consignment.incomeTransactionId!,
                color: AppTheme.profitColorTheme(context),
                icon: Icons.arrow_downward_rounded,
              ),
            if (_consignment.expenseTransactionId != null) ...[
              const SizedBox(height: AppSpacing.s8),
              _buildTransactionLink(
                label: 'Uang Keluar',
                transactionId: _consignment.expenseTransactionId!,
                color: AppTheme.lossColorTheme(context),
                icon: Icons.arrow_upward_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionLink({
    required String label,
    required int transactionId,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: AppIconSize.s16, color: color),
          const SizedBox(width: AppSpacing.s8),
          Flexible(
            child: Text(
              '$label #$transactionId',
              style: AppTheme.caption.copyWith(fontWeight: FontWeight.w500, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
