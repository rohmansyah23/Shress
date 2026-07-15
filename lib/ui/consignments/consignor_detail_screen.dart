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
import '../../providers/debt_consignment_provider.dart';
import 'add_consignment_screen.dart';
import 'consignment_detail_screen.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

import '../../core/theme/app_icon_size.dart';

class ConsignorDetailScreen extends ConsumerStatefulWidget {
  final ConsignorModel consignor;
  final BusinessModel business;

  const ConsignorDetailScreen({
    super.key,
    required this.consignor,
    required this.business,
  });

  @override
  ConsumerState<ConsignorDetailScreen> createState() =>
      _ConsignorDetailScreenState();
}

class _ConsignorDetailScreenState
    extends ConsumerState<ConsignorDetailScreen> {
  bool _isLoading = true;
  List<ConsignmentModel> _consignments = [];
  Map<int, List<ConsignmentItemModel>> _itemsByConsignment = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance
          .getConsignmentsByConsignor(widget.consignor.id);
      final itemsMap = <int, List<ConsignmentItemModel>>{};
      await Future.wait(data.map((c) async {
        final items = await SupabaseService.instance
            .getConsignmentItems(c.id);
        itemsMap[c.id] = items;
      }));
      if (mounted) {
        setState(() {
          _consignments = data;
          _itemsByConsignment = itemsMap;
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

  Future<void> _addConsignment() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddConsignmentScreen(
          business: widget.business,
          existingConsignor: widget.consignor,
        ),
      ),
    );
    if (result == true) {
      _loadData();
      triggerDebtRefresh(ref);
    }
  }

  Future<void> _openConsignmentDetail(ConsignmentModel consignment) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ConsignmentDetailScreen(
          consignment: consignment,
          consignor: widget.consignor,
          business: widget.business,
        ),
      ),
    );
    if (result == true) {
      _loadData();
      triggerDebtRefresh(ref);
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
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.consignor.name),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addConsignment,
        tooltip: 'Tambah Titipan',
        child: const Icon(Icons.add_rounded),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.s16),
                children: [
                  _buildConsignorInfoCard(),
                  const SizedBox(height: AppSpacing.s16),
                  if (_consignments.isEmpty)
                    _buildEmptyState()
                  else
                    ...List.generate(_consignments.length, (index) {
                      return FadeInEntrance(
                        delay: Duration(milliseconds: 50 * index),
                        child: _buildConsignmentCard(_consignments[index]),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _buildConsignorInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      AppTheme.primaryColorTheme(context).withValues(alpha: 0.12),
                  child: Text(
                    widget.consignor.name.length >= 2
                        ? widget.consignor.name
                            .substring(0, 2)
                            .toUpperCase()
                        : widget.consignor.name.toUpperCase(),
                    style: AppTheme.heading3.copyWith(
                      color: AppTheme.primaryColorTheme(context),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.consignor.name, style: AppTheme.heading2),
                      if (widget.consignor.phone != null &&
                          widget.consignor.phone!.isNotEmpty)
                        Text(
                          widget.consignor.phone!,
                          style: AppTheme.caption,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.consignor.notes != null &&
                widget.consignor.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s12),
              const Divider(),
              const SizedBox(height: AppSpacing.s8),
              Text(
                widget.consignor.notes!,
                style: AppTheme.caption,
              ),
            ],
            const SizedBox(height: AppSpacing.s12),
            Text(
              'Jumlah Titipan: ${_consignments.length}',
              style: AppTheme.labelSmall.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s64),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined,
                size: AppIconSize.s64, color: Theme.of(context).textTheme.bodySmall?.color),
            const SizedBox(height: AppSpacing.s16),
            Text(
              'Belum ada titipan',
              style: AppTheme.caption.copyWith(fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Tekan tombol + untuk menambah titipan',
              style: AppTheme.caption.copyWith(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsignmentCard(ConsignmentModel consignment) {
    final color = _statusColor(consignment.status, context);
    final statusLabel = consignment.displayStatus;
    final items = _itemsByConsignment[consignment.id] ?? [];
    final itemNames = items.map((i) => i.productName).join(', ');
    final totalQty = items.fold<int>(0, (sum, i) => sum + i.quantity);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
        onTap: () => _openConsignmentDetail(consignment),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                    ),
                    child: Icon(Icons.inventory_2_outlined,
                        size: AppIconSize.s22, color: color),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          FormatHelpers.displayDate(
                              consignment.consignmentDate),
                          style: AppTheme.caption.copyWith(fontSize: 11),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          FormatHelpers.rupiah(
                            (consignment.isDaily || consignment.isReseller) &&
                                (consignment.reportStatus == AppConstants.reportReported ||
                                 consignment.reportStatus == AppConstants.reportSettled)
                                ? consignment.paymentOwing
                                : consignment.totalAmount,
                          ),
                          style: AppTheme.amountMedium.copyWith(color: color),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: AppIconSize.s20,
                      color: AppTheme.onSurfaceVariantColorTheme(context),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') _editConsignment(consignment);
                      if (value == 'delete') _deleteConsignment(consignment);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: AppIconSize.s18),
                            SizedBox(width: AppSpacing.s8),
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
                              size: AppIconSize.s18,
                              color: AppTheme.lossColorTheme(context),
                            ),
                            const SizedBox(width: AppSpacing.s8),
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
              if (items.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s12),
                Text(
                  '$totalQty pcs - $itemNames',
                  style: AppTheme.caption.copyWith(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: AppSpacing.s12),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.s6),
                    ),
                    child: Text(
                      statusLabel,
                      style: AppTheme.labelSmall.copyWith(color: color),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
                    decoration: BoxDecoration(
                      color: consignment.isDaily
                          ? AppTheme.infoColorTheme(context)
                              .withValues(alpha: 0.2)
                          : AppTheme.primaryColorTheme(context)
                              .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.s6),
                    ),
                    child: Text(
                      consignment.isDaily ? 'Harian' : 'Reseller',
                      style: AppTheme.labelSmall.copyWith(
                        fontSize: 10,
                        color: consignment.isDaily
                            ? AppTheme.infoColorTheme(context)
                            : AppTheme.primaryColorTheme(context),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text('Dibayar', style: AppTheme.labelSmall),
                  const SizedBox(width: AppSpacing.s4),
                  Text(
                    FormatHelpers.rupiah(consignment.settledAmount),
                    style: AppTheme.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.profitColorTheme(context),
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

  Future<void> _editConsignment(ConsignmentModel consignment) async {
    DateTime selectedDate = DateTime.tryParse(consignment.consignmentDate) ?? DateTime.now();
    final descCtrl = TextEditingController(text: consignment.description ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusMedium)),
          title: const Text('Edit Titipan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: dialogCtx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
                borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Titip',
                    prefixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                  child: Text(FormatHelpers.displayDate(
                      '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}')),
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Keterangan / Catatan'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  final dateStr =
                      '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                  await SupabaseService.instance.updateConsignment(
                    consignmentId: consignment.id,
                    consignmentDate: dateStr,
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
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
      ),
    );

    if (result == true) {
      _loadData();
      triggerDebtRefresh(ref);
      if (!mounted) return;
      ErrorSnackbar.showSuccess(context, 'Titipan berhasil diperbarui');
    }
  }

  Future<void> _deleteConsignment(ConsignmentModel consignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusMedium)),
        title: const Text('Hapus Titipan'),
        content: Text(
          'Yakin ingin menghapus titipan tanggal ${FormatHelpers.displayDate(consignment.consignmentDate)}? Semua data terkait juga akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.lossColorTheme(context),
              foregroundColor: AppTheme.onDangerColorTheme(context),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.instance.deleteConsignment(consignment.id);
        _loadData();
        triggerDebtRefresh(ref);
        if (!mounted) return;
        ErrorSnackbar.showSuccess(context, 'Titipan berhasil dihapus');
      } catch (e) {
        if (!mounted) return;
        ErrorSnackbar.show(context, ErrorHandler.classify(e));
      }
    }
  }
}
