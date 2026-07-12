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
        SupabaseService.instance
            .getConsignmentItems(_consignment.id),
        SupabaseService.instance
            .getConsignmentSettlements(_consignment.id),
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

  Future<void> _recordSettlement() async {
    final remaining = _consignment.totalAmount - _consignment.settledAmount;
    if (remaining <= 0) {
      ErrorSnackbar.showMessage(context, 'Konsinyasi sudah lunas');
      return;
    }

    final amountCtrl = TextEditingController(text: remaining.toStringAsFixed(0));
    final notesCtrl = TextEditingController();
    String settlementDate = DateTime.now().toIso8601String().substring(0, 10);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Bayar',
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: 12),
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
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Bayar',
                    prefixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                  child: Text(FormatHelpers.displayDate(settlementDate)),
                ),
              ),
              const SizedBox(height: 12),
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
          notes: notesCtrl.text.trim().isEmpty
              ? null
              : notesCtrl.text.trim(),
          settlementDate: settlementDate,
        );

        if (!mounted) return;
        triggerDebtRefresh(ref);
        ErrorSnackbar.showSuccess(context, 'Pembayaran berhasil dicatat');
        _loadData();
      } catch (e) {
        if (!mounted) return;
        ErrorSnackbar.show(context, ErrorHandler.classify(e));
      }
    }
  }

  Future<void> _deleteConsignment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Konsinyasi'),
        content: Text(
          'Yakin ingin menghapus konsinyasi tanggal ${FormatHelpers.displayDate(_consignment.consignmentDate)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                FilledButton.styleFrom(backgroundColor: AppTheme.lossColor),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.instance
            .deleteConsignment(_consignment.id);
        if (!mounted) return;
        triggerDebtRefresh(ref);
        Navigator.of(context).pop(true);
        ErrorSnackbar.showSuccess(
            context, 'Konsinyasi berhasil dihapus');
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
        return Colors.grey;
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

  @override
  Widget build(BuildContext context) {
    final remaining = _consignment.totalAmount - _consignment.settledAmount;
    final color = _statusColor(_consignment.status, context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Konsinyasi'),
        actions: [
          if (_consignment.status == AppConstants.consignmentActive)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  color: AppTheme.lossColorTheme(context)),
              tooltip: 'Hapus',
              onPressed: _deleteConsignment,
            ),
        ],
      ),
      floatingActionButton: _consignment.status == AppConstants.consignmentActive
          ? FloatingActionButton.extended(
              onPressed: _recordSettlement,
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Catat Pembayaran'),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatusBadge(color),
                  const SizedBox(height: 12),
                  _buildConsignorCard(),
                  const SizedBox(height: 12),
                  _buildSummaryCard(remaining),
                  const SizedBox(height: 16),
                  FadeInEntrance(
                    child: _buildItemsSection(),
                  ),
                  const SizedBox(height: 16),
                  FadeInEntrance(
                    delay: const Duration(milliseconds: 100),
                    child: _buildSettlementSection(),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusBadge(Color color) {
    return FadeInEntrance(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _statusLabel(_consignment.status),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            Text(
              FormatHelpers.displayDate(_consignment.consignmentDate),
              style: AppTheme.caption.copyWith(
                color: color,
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor:
                  AppTheme.primaryColor.withValues(alpha: 0.12),
              child: Text(
                widget.consignor.name.length >= 2
                    ? widget.consignor.name
                        .substring(0, 2)
                        .toUpperCase()
                    : widget.consignor.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ringkasan', style: AppTheme.labelSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _summaryColumn(
                    'Total',
                    FormatHelpers.rupiah(_consignment.totalAmount),
                    AppTheme.primaryColor,
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
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                _consignment.description!,
                style: AppTheme.caption.copyWith(fontSize: 13),
              ),
            ],
            if (_consignment.dueDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.event_outlined,
                      size: 14, color: AppTheme.infoColorTheme(context)),
                  const SizedBox(width: 4),
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

  Widget _summaryColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.labelSmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text('Item Titipan', style: AppTheme.heading3),
                const Spacer(),
                Text(
                  '${_items.length} item',
                  style: AppTheme.caption.copyWith(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Tidak ada item',
                    style: AppTheme.caption.copyWith(
                        color: Colors.grey.shade500),
                  ),
                ),
              )
            else
              ..._items.map((item) => _buildItemRow(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(ConsignmentItemModel item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.infoColorTheme(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined,
                    size: 18, color: AppTheme.profitColor),
                const SizedBox(width: 8),
                Text('Riwayat Pembayaran', style: AppTheme.heading3),
                const Spacer(),
                Text(
                  '${_settlements.length} transaksi',
                  style: AppTheme.caption.copyWith(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_settlements.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Belum ada pembayaran',
                    style: AppTheme.caption.copyWith(
                        color: Colors.grey.shade500),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color:
                  AppTheme.profitColorTheme(context).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.check_circle_rounded,
                size: 18, color: AppTheme.profitColorTheme(context)),
          ),
          const SizedBox(width: 12),
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
                      color: Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            FormatHelpers.rupiah(settlement.amount),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.profitColorTheme(context),
            ),
          ),
        ],
      ),
    );
  }
}
