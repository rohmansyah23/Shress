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

  @override
  void initState() {
    super.initState();
    _loadData();
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
    final consignmentsAsync = ref.read(
      consignmentsByConsignorProvider(consignorId),
    );
    return consignmentsAsync.when(
      data: (data) {
        double total = 0;
        for (final c in data) {
          if (c.status != AppConstants.consignmentSettled &&
              c.status != AppConstants.consignmentCancelled) {
            total += c.totalAmount - c.settledAmount;
          }
        }
        return total;
      },
      loading: () => 0,
      error: (_, _) => 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konsinyasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat ulang',
            onPressed: _loadData,
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
                  FadeInEntrance(
                    child: _buildSummaryCard(),
                  ),
                  const SizedBox(height: 16),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory_2_outlined,
                      size: 20, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                Text('Ringkasan Konsinyasi', style: AppTheme.heading3),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _summaryItem(
                    'Total Tagihan Aktif',
                    FormatHelpers.rupiah(totalOwed),
                    AppTheme.warningColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryItem(
                    'Sudah Dibayar',
                    FormatHelpers.rupiah(totalSettled),
                    AppTheme.profitColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _summaryItem(
              'Jumlah Penitip',
              '$consignorCount penitip',
              AppTheme.infoColor,
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
        const SizedBox(height: 4),
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
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.people_outline_rounded,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Belum ada penitip',
              style: AppTheme.caption.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Tekan tombol + untuk menambah titipan baru',
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

  Widget _buildConsignorCard(ConsignorModel consignor) {
    final totalActive = _getConsignorTotal(consignor.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openConsignorDetail(consignor),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    AppTheme.primaryColor.withValues(alpha: 0.12),
                child: Text(
                  consignor.name.length >= 2
                      ? consignor.name.substring(0, 2).toUpperCase()
                      : consignor.name.toUpperCase(),
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: totalActive > 0
                          ? AppTheme.warningColor
                          : AppTheme.profitColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    totalActive > 0 ? 'Aktif' : 'Lunas',
                    style: AppTheme.caption.copyWith(
                      fontSize: 11,
                      color: totalActive > 0
                          ? AppTheme.warningColor
                          : AppTheme.profitColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
