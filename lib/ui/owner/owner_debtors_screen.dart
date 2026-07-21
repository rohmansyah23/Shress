import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/format_helpers.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/widgets/summary_card.dart' as summary_card;
import '../../core/widgets/app_text_field.dart';
import '../../data/local/models/business_model.dart';
import '../../data/local/models/debtor_model.dart';
import '../../providers/debtor_provider.dart';
import '../../providers/debt_consignment_provider.dart';
import '../../data/remote/supabase_service.dart';
import '../debtors/add_debt_screen.dart';
import '../debtors/debtor_detail_screen.dart';

String _getInitials(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.isEmpty) return '?';
  if (words.length == 1) return words[0][0].toUpperCase();
  return '${words[0][0]}${words[1][0]}'.toUpperCase();
}

class OwnerDebtorsScreen extends ConsumerStatefulWidget {
  final List<BusinessModel> businesses;

  const OwnerDebtorsScreen({super.key, required this.businesses});

  @override
  ConsumerState<OwnerDebtorsScreen> createState() => _OwnerDebtorsScreenState();
}

class _OwnerDebtorsScreenState extends ConsumerState<OwnerDebtorsScreen> {
  BusinessModel? _selectedBusinessFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<int, List<DebtorModel>> businessDebtors = {};
    final Map<int, Map<int, double>> businessDebtorTotals = {};
    final Map<int, Map<String, dynamic>> businessSummaries = {};
    bool isLoading = false;
    Object? error;

    for (final business in widget.businesses) {
      final asyncValue = ref.watch(debtorProvider(business.businessId));
      asyncValue.when(
        data: (data) {
          businessDebtors[business.businessId] = data.debtors;
          businessDebtorTotals[business.businessId] = data.debtorTotals;
          businessSummaries[business.businessId] = data.summary;
        },
        loading: () => isLoading = true,
        error: (err, _) {
          error = err;
        },
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Piutang')),
        body: ErrorRetryWidget(
          message: ErrorHandler.classify(error!).userMessage,
          onRetry: () {
            for (final business in widget.businesses) {
              ref.invalidate(debtorProvider(business.businessId));
            }
          },
        ),
      );
    }

    if (isLoading && businessDebtors.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Combine data based on current filter & search query
    final combinedDebtors = <({DebtorModel debtor, BusinessModel business, double total})>[];
    double totalOwed = 0;
    double totalPaid = 0;
    int debtorCount = 0;

    for (final business in widget.businesses) {
      final isFiltered = _selectedBusinessFilter != null &&
          _selectedBusinessFilter!.businessId != business.businessId;

      final summary = businessSummaries[business.businessId];
      if (summary != null && !isFiltered) {
        totalOwed += (summary['totalOwed'] as num?)?.toDouble() ?? 0;
        totalPaid += (summary['totalPaid'] as num?)?.toDouble() ?? 0;
        debtorCount += (summary['debtorCount'] as num?)?.toInt() ?? 0;
      }

      if (isFiltered) continue;

      final debtors = businessDebtors[business.businessId] ?? [];
      final totals = businessDebtorTotals[business.businessId] ?? {};

      for (final debtor in debtors) {
        if (_searchQuery.isNotEmpty &&
            !debtor.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
          continue;
        }
        final total = totals[debtor.id] ?? 0.0;
        combinedDebtors.add((debtor: debtor, business: business, total: total));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Piutang'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          for (final business in widget.businesses) {
            ref.invalidate(debtorProvider(business.businessId));
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterChips(),
                  _buildSearchBar(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s12,
                      AppSpacing.s8,
                      AppSpacing.s12,
                      0,
                    ),
                    child: summary_card.SummaryCard(
                      title: _selectedBusinessFilter != null
                          ? 'Ringkasan ${_selectedBusinessFilter!.name}'
                          : 'Ringkasan Semua Bisnis',
                      titleIcon: Icons.account_balance_wallet_outlined,
                      titleIconColor: AppTheme.warningColorTheme(context),
                      unpaidAmount: totalOwed,
                      unpaidLabel: 'Belum Lunas',
                      paidAmount: totalPaid,
                      paidLabel: 'Sudah Dibayar',
                      countValue: debtorCount,
                      countLabel: 'Jumlah Penghutang',
                      countSuffix: 'orang',
                    ),
                  ),
                ],
              ),
            ),
            if (combinedDebtors.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.s48),
                  child: PfEmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'Belum ada penghutang',
                    subtitle: 'Tekan tombol di bawah untuk menambah hutang baru',
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = combinedDebtors[index];
                    return FadeInEntrance(
                      delay: Duration(milliseconds: index * 40),
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: AppSpacing.s12,
                          right: AppSpacing.s12,
                          bottom: AppSpacing.s8,
                          top: index == 0 ? AppSpacing.s8 : 0,
                        ),
                        child: _DebtorCard(
                          debtor: item.debtor,
                          business: item.business,
                          remainingAmount: item.total,
                          onTap: () async {
                            final needRefresh = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => DebtorDetailScreen(
                                  debtor: item.debtor,
                                  business: item.business,
                                ),
                              ),
                            );
                            if (needRefresh == true) {
                              ref.invalidate(debtorProvider(item.business.businessId));
                            }
                          },
                          onEdit: () => _editDebtor(context, item.debtor, item.business),
                          onDelete: () => _deleteDebtor(context, item.debtor, item.business),
                        ),
                      ),
                    );
                  },
                  childCount: combinedDebtors.length,
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.s16,
          0,
          AppSpacing.s16,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.s16,
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: () => _addNewDebt(context),
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

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
      child: Row(
        children: [
          _buildChip(
            label: 'Semua Bisnis',
            isSelected: _selectedBusinessFilter == null,
            onTap: () => setState(() => _selectedBusinessFilter = null),
          ),
          ...widget.businesses.map((business) {
            final isSelected = _selectedBusinessFilter?.businessId == business.businessId;
            return Padding(
              padding: const EdgeInsets.only(left: AppSpacing.s8),
              child: _buildChip(
                label: business.name,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedBusinessFilter = business),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final primaryColor = AppTheme.primaryColorTheme(context);
    final surfaceContainer = AppTheme.surfaceContainerColorTheme(context);
    final onSurface = AppTheme.onSurfaceColorTheme(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.radiusPill),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : AppTheme.outlineColorTheme(context).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s16, 0, AppSpacing.s16, AppSpacing.s8),
      child: AppTextField(
        controller: _searchController,
        hintText: 'Cari nama penghutang...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              )
            : null,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
      ),
    );
  }

  void _addNewDebt(BuildContext context) async {
    BusinessModel? targetBusiness;
    if (_selectedBusinessFilter != null) {
      targetBusiness = _selectedBusinessFilter;
    } else {
      targetBusiness = await showDialog<BusinessModel>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
          ),
          title: const Text('Pilih Bisnis'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.businesses.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final b = widget.businesses[index];
                return ListTile(
                  leading: const Icon(Icons.store_rounded),
                  title: Text(b.name),
                  onTap: () => Navigator.pop(ctx, b),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
          ],
        ),
      );
    }

    if (targetBusiness == null) return;

    if (!context.mounted) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddDebtScreen(business: targetBusiness!),
      ),
    );
    if (result == true) {
      ref.invalidate(debtorProvider(targetBusiness.businessId));
    }
  }

  Future<void> _editDebtor(
    BuildContext context,
    DebtorModel debtor,
    BusinessModel business,
  ) async {
    final nameController = TextEditingController(text: debtor.name);
    final phoneController = TextEditingController(text: debtor.phone ?? '');
    final notesController = TextEditingController(text: debtor.notes ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        ),
        title: const Text('Edit Penghutang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            const SizedBox(height: AppSpacing.s12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Telepon'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.s12),
            TextField(
              controller: notesController,
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
              try {
                await SupabaseService.instance.updateDebtor(
                  debtorId: debtor.id,
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                  notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
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
      ref.invalidate(debtorProvider(business.businessId));
      triggerDebtRefresh(ref);
      if (!context.mounted) return;
      ErrorSnackbar.showSuccess(context, 'Penghutang berhasil diperbarui');
    }
  }

  Future<void> _deleteDebtor(
    BuildContext context,
    DebtorModel debtor,
    BusinessModel business,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        ),
        title: const Text('Hapus Penghutang'),
        content: Text(
          'Yakin ingin menghapus ${debtor.name}? Semua data hutang terkait juga akan dihapus.',
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
        await SupabaseService.instance.deleteDebtor(debtor.id);
        ref.invalidate(debtorProvider(business.businessId));
        triggerDebtRefresh(ref);
        if (!context.mounted) return;
        ErrorSnackbar.showSuccess(context, 'Penghutang berhasil dihapus');
      } catch (e) {
        if (!context.mounted) return;
        ErrorSnackbar.show(context, ErrorHandler.classify(e));
      }
    }
  }
}

class _DebtorCard extends StatelessWidget {
  final DebtorModel debtor;
  final BusinessModel business;
  final double remainingAmount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DebtorCard({
    required this.debtor,
    required this.business,
    required this.remainingAmount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.warningColorTheme(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                ),
                alignment: Alignment.center,
                child: Text(
                  _getInitials(debtor.name),
                  style: AppTheme.subtitle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.warningColorTheme(context),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debtor.name,
                      style: AppTheme.subtitle.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Row(
                      children: [
                        Text(
                          business.name,
                          style: AppTheme.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurfaceVariantColorTheme(context),
                          ),
                        ),
                        if (debtor.phone != null && debtor.phone!.isNotEmpty) ...[
                          Text(
                            ' • ',
                            style: AppTheme.caption.copyWith(fontSize: 11),
                          ),
                          Text(
                            debtor.phone!,
                            style: AppTheme.caption.copyWith(fontSize: 11),
                          ),
                        ],
                      ],
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
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    FormatHelpers.rupiah(remainingAmount),
                    style: AppTheme.subtitle.copyWith(
                      fontSize: 14,
                      color: remainingAmount > 0
                          ? AppTheme.lossColorTheme(context)
                          : AppTheme.profitColorTheme(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.s4),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: AppIconSize.s20,
                  color: AppTheme.onSurfaceVariantColorTheme(context),
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
        ),
      ),
    );
  }
}
