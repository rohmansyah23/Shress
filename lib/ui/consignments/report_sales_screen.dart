import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/format_helpers.dart';
import '../../core/widgets/error_widgets.dart';
import '../../data/local/models/consignment_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/debt_consignment_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

import '../../core/theme/app_icon_size.dart';

class ReportSalesScreen extends ConsumerStatefulWidget {
  final ConsignmentModel consignment;
  final List<ConsignmentItemModel> items;

  const ReportSalesScreen({
    super.key,
    required this.consignment,
    required this.items,
  });

  @override
  ConsumerState<ReportSalesScreen> createState() => _ReportSalesScreenState();
}

class _ReportSalesScreenState extends ConsumerState<ReportSalesScreen> {
  bool _isSaving = false;
  late List<int> _quantitiesSold;
  late List<TextEditingController> _qtyControllers;

  @override
  void initState() {
    super.initState();
    _quantitiesSold = widget.items.map((i) => i.quantitySold).toList();
    _qtyControllers = _quantitiesSold
        .map((q) => TextEditingController(text: q.toString()))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _qtyControllers) {
      c.dispose();
    }
    super.dispose();
  }

  double get _totalFromSales {
    double total = 0;
    for (var i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final effectivePrice = item.sellingPrice ?? item.agreedPrice;
      total += effectivePrice * _quantitiesSold[i];
    }
    return total;
  }

  double get _totalPayment {
    double total = 0;
    for (var i = 0; i < widget.items.length; i++) {
      total += widget.items[i].agreedPrice * _quantitiesSold[i];
    }
    return total;
  }

  double get _commission => _totalFromSales - _totalPayment;

  bool get _isValid {
    for (var i = 0; i < widget.items.length; i++) {
      if (_quantitiesSold[i] < 0 ||
          _quantitiesSold[i] > widget.items[i].quantity) {
        return false;
      }
    }
    return true;
  }

  Future<void> _handleSave() async {
    if (!_isValid) {
      ErrorSnackbar.showMessage(
          context, 'Jumlah terjual melebihi jumlah dititipkan');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        if (mounted) {
          setState(() => _isSaving = false);
          ErrorSnackbar.showMessage(context, 'Sesi tidak valid');
        }
        return;
      }

      for (var i = 0; i < widget.items.length; i++) {
        await SupabaseService.instance.reportConsignmentItem(
          consignmentId: widget.consignment.id,
          itemId: widget.items[i].id,
          quantitySold: _quantitiesSold[i],
        );
      }

      await SupabaseService.instance
          .finalizeConsignmentReport(widget.consignment.id);

      if (!mounted) return;
      triggerDebtRefresh(ref);
      ErrorSnackbar.showSuccess(context, 'Laporan penjualan berhasil disimpan');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ErrorSnackbar.show(context, ErrorHandler.classify(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporkan Penjualan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        children: [
          _buildConsignorInfo(),
          const SizedBox(height: AppSpacing.s16),
          ...List.generate(
              widget.items.length, (index) => _buildItemCard(index)),
          const SizedBox(height: AppSpacing.s16),
          _buildSummaryCard(),
          const SizedBox(height: AppSpacing.s32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _handleSave,
              icon: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.onPrimaryColorTheme(context)),
                    )
                  : const Icon(Icons.save_outlined),
              label:
                  Text(_isSaving ? 'Menyimpan...' : 'Simpan Laporan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsignorInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColorTheme(context).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
        border: Border.all(
            color: AppTheme.primaryColorTheme(context).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline_rounded,
              color: AppTheme.primaryColorTheme(context), size: AppIconSize.s20),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  FormatHelpers.displayDate(
                      widget.consignment.consignmentDate),
                  style: AppTheme.caption.copyWith(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  '${widget.items.length} item dititipkan',
                  style: AppTheme.caption.copyWith(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(int index) {
    final item = widget.items[index];
    final qtySold = _quantitiesSold[index];
    final qtyReturned = item.quantity - qtySold;
    final effectivePrice = item.sellingPrice ?? item.agreedPrice;
    final fromSales = effectivePrice * qtySold;
    final payment = item.agreedPrice * qtySold;
    final hasError = qtySold > item.quantity;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.productName,
                    style: AppTheme.title.copyWith(fontSize: 16),
                  ),
                ),
                Text(
                  'Dititipkan: ${item.quantity} pcs',
                  style: AppTheme.caption.copyWith(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Terjual', style: AppTheme.labelSmall),
                      const SizedBox(height: AppSpacing.s4),
                      TextFormField(
                        controller: _qtyControllers[index],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          suffixText: 'pcs',
                          isDense: true,
                          errorText: hasError
                              ? 'Maks ${item.quantity} pcs'
                              : null,
                        ),
                        onChanged: (value) {
                          final parsed = int.tryParse(value) ?? 0;
                          setState(() {
                            _quantitiesSold[index] = parsed;
                          });
                          if (value.startsWith('0') && value.length > 1) {
                            final cleaned = value.replaceFirst(RegExp(r'^0+'), '');
                            _qtyControllers[index].text = cleaned;
                            _qtyControllers[index].selection =
                                TextSelection.fromPosition(
                              TextPosition(offset: cleaned.length),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dikembalikan', style: AppTheme.labelSmall),
                      const SizedBox(height: AppSpacing.s4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s12, vertical: AppSpacing.s12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHighestColorTheme(context)
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                        ),
                        child: Text(
                          '$qtyReturned pcs',
                          style: AppTheme.subtitle.copyWith(
                            fontSize: 14,
                            color: qtyReturned > 0
                                ? AppTheme.warningColorTheme(context)
                                : AppTheme.profitColorTheme(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.s12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pendapatan', style: AppTheme.labelSmall),
                      Text(
                        FormatHelpers.rupiah(fromSales),
                        style: AppTheme.subtitle.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bayar pihak penitip', style: AppTheme.labelSmall),
                      Text(
                        FormatHelpers.rupiah(payment),
                        style: AppTheme.subtitle.copyWith(
                          fontSize: 14,
                          color: AppTheme.lossColorTheme(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      color: AppTheme.primaryColorTheme(context).withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ringkasan', style: AppTheme.labelSmall),
            const SizedBox(height: AppSpacing.s12),
            _buildSummaryRow(
              'Total Pendapatan',
              FormatHelpers.rupiah(_totalFromSales),
              AppTheme.profitColorTheme(context),
            ),
            const SizedBox(height: AppSpacing.s8),
            _buildSummaryRow(
              'Total ke Pihak Penitip',
              FormatHelpers.rupiah(_totalPayment),
              AppTheme.lossColorTheme(context),
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              'Komisi',
              FormatHelpers.rupiah(_commission),
              AppTheme.primaryColorTheme(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.caption),
        Text(
          value,
          style: AppTheme.amountMedium.copyWith(color: color),
        ),
      ],
    );
  }
}
