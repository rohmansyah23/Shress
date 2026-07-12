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
      if (mounted) {
        setState(() {
          _consignments = data;
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

  Future<void> _editConsignor() async {
    final nameCtrl = TextEditingController(text: widget.consignor.name);
    final phoneCtrl = TextEditingController(text: widget.consignor.phone ?? '');
    final notesCtrl = TextEditingController(text: widget.consignor.notes ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Penitip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Telepon'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: 'Catatan'),
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
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              try {
                await SupabaseService.instance.updateConsignor(
                  consignorId: widget.consignor.id,
                  name: name,
                  phone: phoneCtrl.text.trim().isEmpty
                      ? null
                      : phoneCtrl.text.trim(),
                  notes: notesCtrl.text.trim().isEmpty
                      ? null
                      : notesCtrl.text.trim(),
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

    if (result == true) {
      if (!mounted) return;
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _deleteConsignor() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Penitip'),
        content: Text(
          'Yakin ingin menghapus "${widget.consignor.name}"? Semua data konsinyasi terkait juga akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.lossColor),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.instance
            .deleteConsignor(widget.consignor.id);
        if (!mounted) return;
        triggerDebtRefresh(ref);
        Navigator.of(context).pop(true);
        ErrorSnackbar.showSuccess(context, 'Penitip berhasil dihapus');
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.consignor.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: _editConsignor,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                color: AppTheme.lossColorTheme(context)),
            tooltip: 'Hapus',
            onPressed: _deleteConsignor,
          ),
        ],
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
                padding: const EdgeInsets.all(16),
                children: [
                  _buildConsignorInfoCard(),
                  const SizedBox(height: 16),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      AppTheme.primaryColor.withValues(alpha: 0.12),
                  child: Text(
                    widget.consignor.name.length >= 2
                        ? widget.consignor.name
                            .substring(0, 2)
                            .toUpperCase()
                        : widget.consignor.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.consignor.name, style: AppTheme.heading2),
                      if (widget.consignor.phone != null &&
                          widget.consignor.phone!.isNotEmpty)
                        Text(
                          widget.consignor.phone!,
                          style: AppTheme.caption.copyWith(fontSize: 13),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.consignor.notes != null &&
                widget.consignor.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                widget.consignor.notes!,
                style: AppTheme.caption.copyWith(fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Jumlah Konsinyasi: ${_consignments.length}',
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
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Belum ada konsinyasi',
              style: AppTheme.caption.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Tekan tombol + untuk menambah titipan',
              style: AppTheme.caption.copyWith(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsignmentCard(ConsignmentModel consignment) {
    final remaining = consignment.totalAmount - consignment.settledAmount;
    final color = _statusColor(consignment.status, context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openConsignmentDetail(consignment),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.inventory_2_outlined,
                        size: 22, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          FormatHelpers.displayDate(
                              consignment.consignmentDate),
                          style: AppTheme.caption.copyWith(fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          FormatHelpers.rupiah(consignment.totalAmount),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _statusLabel(consignment.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dibayar', style: AppTheme.labelSmall),
                        const SizedBox(height: 2),
                        Text(
                          FormatHelpers.rupiah(consignment.settledAmount),
                          style: AppTheme.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.profitColorTheme(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sisa', style: AppTheme.labelSmall),
                        const SizedBox(height: 2),
                        Text(
                          FormatHelpers.rupiah(remaining),
                          style: AppTheme.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: remaining > 0
                                ? AppTheme.warningColorTheme(context)
                                : AppTheme.profitColorTheme(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
