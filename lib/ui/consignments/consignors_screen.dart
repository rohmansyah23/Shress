import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/format_helpers.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/local/models/business_model.dart';
import '../../data/local/models/consignor_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/debt_consignment_provider.dart';
import 'add_consignment_screen.dart';
import 'consignor_detail_screen.dart';

class ConsignorsScreen extends ConsumerStatefulWidget {
  final BusinessModel business;

  const ConsignorsScreen({super.key, required this.business});

  @override
  ConsumerState<ConsignorsScreen> createState() => _ConsignorsScreenState();
}

class _ConsignorsScreenState extends ConsumerState<ConsignorsScreen> {
  bool _isLoading = true;
  List<ConsignorModel> _consignors = [];
  Map<String, dynamic> _summary = {};
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    _channel = SupabaseService.instance.client
        .channel('consignments-${widget.business.businessId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'consignments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'business_id',
            value: widget.business.businessId,
          ),
          callback: (_) => _loadData(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'consignments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'business_id',
            value: widget.business.businessId,
          ),
          callback: (_) => _loadData(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'consignment_items',
          callback: (_) => _loadData(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'consignment_items',
          callback: (_) => _loadData(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_channel != null) {
      SupabaseService.instance.client.removeChannel(_channel!);
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        SupabaseService.instance
            .getConsignorsByBusiness(widget.business.businessId),
        SupabaseService.instance
            .getConsignmentSummary(widget.business.businessId),
      ]);
      if (mounted) {
        setState(() {
          _consignors = results[0] as List<ConsignorModel>;
          _summary = results[1] as Map<String, dynamic>;
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
        builder: (_) => AddConsignmentScreen(business: widget.business),
      ),
    );
    if (result == true) {
      _loadData();
      triggerDebtRefresh(ref);
    }
  }

  Future<void> _openConsignorDetail(ConsignorModel consignor) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ConsignorDetailScreen(
          consignor: consignor,
          business: widget.business,
        ),
      ),
    );
    if (result == true) {
      _loadData();
      triggerDebtRefresh(ref);
    }
  }

  double _getConsignorTotal(int consignorId) {
    final consignmentsAsync = ref.watch(
      consignmentsByConsignorProvider(consignorId),
    );
    return consignmentsAsync.when(
      data: (data) {
        double total = 0;
        for (final c in data) {
          if (c.status != AppConstants.consignmentSettled &&
              c.status != AppConstants.consignmentCancelled) {
            total += c.displayTotal;
          }
        }
        return total;
      },
      loading: () => 0,
      error: (_, _) => 0,
    );
  }

  String _getConsignorStatusLabel(int consignorId) {
    final consignmentsAsync = ref.watch(
      consignmentsByConsignorProvider(consignorId),
    );
    return consignmentsAsync.when(
      data: (data) {
        final active = data.where(
          (c) => c.status != AppConstants.consignmentSettled &&
              c.status != AppConstants.consignmentCancelled,
        );
        if (active.isEmpty) return 'Selesai';
        return 'Aktif';
      },
      loading: () => '',
      error: (_, _) => '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Titipan'),
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
                padding: const EdgeInsets.all(AppTheme.s16),
                children: [
                  FadeInEntrance(
                    child: _buildSummaryCard(),
                  ),
                  const SizedBox(height: AppTheme.s16),
                  if (_consignors.isEmpty)
                    _buildEmptyState()
                  else
                    ...List.generate(_consignors.length, (index) {
                      return FadeInEntrance(
                        delay: Duration(milliseconds: 50 * index),
                        child: _buildConsignorCard(_consignors[index]),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final totalOwed = (_summary['totalOwed'] as double?) ?? 0;
    final consignorCount = (_summary['consignorCount'] as int?) ?? 0;
    final totalSettled = (_summary['totalSettled'] as double?) ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(Icons.inventory_2_outlined,
                      size: 20, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: AppTheme.s12),
                Text('Ringkasan Titipan', style: AppTheme.heading3),
              ],
            ),
            const SizedBox(height: AppTheme.s20),
            Row(
              children: [
                Expanded(
                  child: _summaryItem(
                    'Belum Dibayar',
                    FormatHelpers.rupiah(totalOwed),
                    AppTheme.warningColorTheme(context),
                  ),
                ),
                const SizedBox(width: AppTheme.s12),
                Expanded(
                  child: _summaryItem(
                    'Sudah Dibayar',
                    FormatHelpers.rupiah(totalSettled),
                    AppTheme.profitColorTheme(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.s12),
            _summaryItem(
              'Jumlah Pihak Penitip',
              '$consignorCount pihak penitip',
              AppTheme.infoColorTheme(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.labelSmall),
        const SizedBox(height: AppTheme.s4),
        Text(
          value,
          style: AppTheme.amountMedium.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.s64),
        child: Column(
          children: [
            Icon(Icons.people_outline_rounded,
                size: 64, color: Theme.of(context).textTheme.bodySmall?.color),
            const SizedBox(height: AppTheme.s16),
            Text(
              'Belum ada pihak penitip',
              style: AppTheme.caption.copyWith(fontSize: 14),
            ),
            const SizedBox(height: AppTheme.s8),
            Text(
              'Tekan tombol + untuk menambah pihak penitip baru',
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

  Widget _buildConsignorCard(ConsignorModel consignor) {
    final totalActive = _getConsignorTotal(consignor.id);
    final statusLabel = _getConsignorStatusLabel(consignor.id);

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.s12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        onTap: () => _openConsignorDetail(consignor),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.s16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                child: Text(
                  consignor.name.length >= 2
                      ? consignor.name.substring(0, 2).toUpperCase()
                      : consignor.name.toUpperCase(),
                  style: AppTheme.subtitle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(consignor.name, style: AppTheme.heading3),
                    if (consignor.phone != null &&
                        consignor.phone!.isNotEmpty)
                      Text(
                        consignor.phone!,
                        style: AppTheme.caption.copyWith(fontSize: 12),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    FormatHelpers.rupiah(totalActive),
                    style: AppTheme.amountMedium.copyWith(
                      color: statusLabel == 'Selesai'
                          ? AppTheme.profitColorTheme(context)
                          : AppTheme.warningColorTheme(context),
                    ),
                  ),
                  const SizedBox(height: AppTheme.s4),
                  Text(
                    statusLabel,
                    style: AppTheme.caption.copyWith(
                      fontSize: 11,
                      color: statusLabel == 'Selesai'
                          ? AppTheme.profitColorTheme(context)
                          : AppTheme.warningColorTheme(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppTheme.s4),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onSelected: (value) {
                  if (value == 'edit') _editConsignor(consignor);
                  if (value == 'delete') _deleteConsignor(consignor);
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

  Future<void> _editConsignor(ConsignorModel consignor) async {
    final nameCtrl = TextEditingController(text: consignor.name);
    final phoneCtrl = TextEditingController(text: consignor.phone ?? '');
    final notesCtrl = TextEditingController(text: consignor.notes ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
        title: const Text('Edit Pihak Penitip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            const SizedBox(height: AppTheme.s12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Telepon'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppTheme.s12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: 'Catatan'),
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
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              try {
                await SupabaseService.instance.updateConsignor(
                  consignorId: consignor.id,
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
      _loadData();
      triggerDebtRefresh(ref);
      if (!mounted) return;
      ErrorSnackbar.showSuccess(context, 'Pihak penitip berhasil diperbarui');
    }
  }

  Future<void> _deleteConsignor(ConsignorModel consignor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
        title: const Text('Hapus Pihak Penitip'),
        content: Text(
          'Yakin ingin menghapus "${consignor.name}"? Semua data titipan terkait juga akan dihapus.',
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
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.instance.deleteConsignor(consignor.id);
        _loadData();
        triggerDebtRefresh(ref);
        if (!mounted) return;
        ErrorSnackbar.showSuccess(context, 'Pihak penitip berhasil dihapus');
      } catch (e) {
        if (!mounted) return;
        ErrorSnackbar.show(context, ErrorHandler.classify(e));
      }
    }
  }
}
