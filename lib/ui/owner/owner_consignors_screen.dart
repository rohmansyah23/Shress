import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/format_helpers.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/widgets/summary_card.dart' as summary_card;
import '../../data/local/models/business_model.dart';
import '../../data/local/models/consignor_model.dart';
import '../../providers/debt_consignment_provider.dart';
import '../../data/remote/supabase_service.dart';
import '../consignments/add_consignment_screen.dart';
import '../consignments/consignor_detail_screen.dart';

class OwnerConsignorsScreen extends ConsumerStatefulWidget {
  final List<BusinessModel> businesses;

  const OwnerConsignorsScreen({super.key, required this.businesses});

  @override
  ConsumerState<OwnerConsignorsScreen> createState() => _OwnerConsignorsScreenState();
}

class _OwnerConsignorsScreenState extends ConsumerState<OwnerConsignorsScreen> {
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
    final Map<int, List<ConsignorModel>> businessConsignors = {};
    final Map<int, Map<String, dynamic>> businessSummaries = {};
    bool isLoading = false;
    Object? error;

    for (final business in widget.businesses) {
      final consignorsAsync = ref.watch(consignorsProvider(business.businessId));
      final summaryAsync = ref.watch(consignmentSummaryProvider(business.businessId));

      consignorsAsync.when(
        data: (data) {
          businessConsignors[business.businessId] = data.cast<ConsignorModel>();
        },
        loading: () => isLoading = true,
        error: (err, _) {
          error = err;
        },
      );

      summaryAsync.when(
        data: (data) {
          businessSummaries[business.businessId] = data;
        },
        loading: () => isLoading = true,
        error: (err, _) {
          error = err;
        },
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daftar Titipan')),
        body: ErrorRetryWidget(
          message: ErrorHandler.classify(error!).userMessage,
          onRetry: () {
            for (final business in widget.businesses) {
              ref.invalidate(consignorsProvider(business.businessId));
              ref.invalidate(consignmentSummaryProvider(business.businessId));
            }
          },
        ),
      );
    }

    if (isLoading && businessConsignors.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Combine data based on current filter & search query
    final combinedConsignors = <({ConsignorModel consignor, BusinessModel business})>[];
    double totalOwed = 0;
    double totalSettled = 0;
    int consignorCount = 0;

    for (final business in widget.businesses) {
      final isFiltered = _selectedBusinessFilter != null &&
          _selectedBusinessFilter!.businessId != business.businessId;

      final summary = businessSummaries[business.businessId];
      if (summary != null && !isFiltered) {
        totalOwed += (summary['totalOwed'] as num?)?.toDouble() ?? 0;
        totalSettled += (summary['totalSettled'] as num?)?.toDouble() ?? 0;
        consignorCount += (summary['consignorCount'] as num?)?.toInt() ?? 0;
      }

      if (isFiltered) continue;

      final consignors = businessConsignors[business.businessId] ?? [];
      for (final consignor in consignors) {
        if (_searchQuery.isNotEmpty &&
            !consignor.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
          continue;
        }
        combinedConsignors.add((consignor: consignor, business: business));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Titipan'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          for (final business in widget.businesses) {
            ref.invalidate(consignorsProvider(business.businessId));
            ref.invalidate(consignmentSummaryProvider(business.businessId));
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
                      titleIcon: Icons.inventory_2_outlined,
                      titleIconColor: AppTheme.consignmentColorTheme(context),
                      unpaidAmount: totalOwed,
                      unpaidLabel: 'Belum Dibayar',
                      paidAmount: totalSettled,
                      paidLabel: 'Sudah Dibayar',
                      countValue: consignorCount,
                      countLabel: 'Jumlah Pihak Penitip',
                      countSuffix: 'pihak penitip',
                    ),
                  ),
                ],
              ),
            ),
            if (combinedConsignors.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.s48),
                  child: PfEmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'Belum ada pihak penitip',
                    subtitle: 'Tekan tombol di bawah untuk menambah pihak penitip baru',
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = combinedConsignors[index];
                    return FadeInEntrance(
                      delay: Duration(milliseconds: index * 40),
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: AppSpacing.s12,
                          right: AppSpacing.s12,
                          bottom: AppSpacing.s8,
                          top: index == 0 ? AppSpacing.s8 : 0,
                        ),
                        child: _ConsignorCard(
                          consignor: item.consignor,
                          business: item.business,
                          onTap: () async {
                            final needRefresh = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => ConsignorDetailScreen(
                                  consignor: item.consignor,
                                  business: item.business,
                                ),
                              ),
                            );
                            if (needRefresh == true) {
                              ref.invalidate(consignorsProvider(item.business.businessId));
                              ref.invalidate(consignmentSummaryProvider(item.business.businessId));
                              triggerDebtRefresh(ref);
                            }
                          },
                          onEdit: () => _editConsignor(context, item.consignor, item.business),
                          onDelete: () => _deleteConsignor(context, item.consignor, item.business),
                        ),
                      ),
                    );
                  },
                  childCount: combinedConsignors.length,
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
            onPressed: () => _addNewConsignment(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Tambah Pihak Penitip',
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
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          hintText: 'Cari nama pihak penitip...',
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
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
          filled: true,
          fillColor: AppTheme.surfaceColorTheme(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
            borderSide: BorderSide(color: AppTheme.outlineColorTheme(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
            borderSide: BorderSide(color: AppTheme.outlineColorTheme(context).withValues(alpha: 0.5)),
          ),
        ),
      ),
    );
  }

  void _addNewConsignment(BuildContext context) async {
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
        builder: (_) => AddConsignmentScreen(business: targetBusiness!),
      ),
    );
    if (result == true) {
      ref.invalidate(consignorsProvider(targetBusiness.businessId));
      ref.invalidate(consignmentSummaryProvider(targetBusiness.businessId));
      triggerDebtRefresh(ref);
    }
  }

  Future<void> _editConsignor(
    BuildContext context,
    ConsignorModel consignor,
    BusinessModel business,
  ) async {
    final nameCtrl = TextEditingController(text: consignor.name);
    final phoneCtrl = TextEditingController(text: consignor.phone ?? '');
    final notesCtrl = TextEditingController(text: consignor.notes ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusMedium)),
        title: const Text('Edit Pihak Penitip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            const SizedBox(height: AppSpacing.s12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Telepon'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.s12),
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
                  phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
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
      ref.invalidate(consignorsProvider(business.businessId));
      ref.invalidate(consignmentSummaryProvider(business.businessId));
      triggerDebtRefresh(ref);
      if (!context.mounted) return;
      ErrorSnackbar.showSuccess(context, 'Pihak penitip berhasil diperbarui');
    }
  }

  Future<void> _deleteConsignor(
    BuildContext context,
    ConsignorModel consignor,
    BusinessModel business,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusMedium)),
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
              foregroundColor: AppTheme.onDangerColorTheme(context),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.instance.deleteConsignor(consignor.id);
        ref.invalidate(consignorsProvider(business.businessId));
        ref.invalidate(consignmentSummaryProvider(business.businessId));
        triggerDebtRefresh(ref);
        if (!context.mounted) return;
        ErrorSnackbar.showSuccess(context, 'Pihak penitip berhasil dihapus');
      } catch (e) {
        if (!context.mounted) return;
        ErrorSnackbar.show(context, ErrorHandler.classify(e));
      }
    }
  }
}

class _ConsignorCard extends ConsumerWidget {
  final ConsignorModel consignor;
  final BusinessModel business;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ConsignorCard({
    required this.consignor,
    required this.business,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consignmentsAsync = ref.watch(consignmentsByConsignorProvider(consignor.id));
    final double totalActive = consignmentsAsync.when(
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
    final String statusLabel = consignmentsAsync.when(
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

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.consignmentColorTheme(context).withValues(alpha: 0.12),
                child: Text(
                  consignor.name.length >= 2
                      ? consignor.name.substring(0, 2).toUpperCase()
                      : consignor.name.toUpperCase(),
                  style: AppTheme.subtitle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.consignmentColorTheme(context),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(consignor.name, style: AppTheme.heading3),
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
                        if (consignor.phone != null && consignor.phone!.isNotEmpty) ...[
                          Text(
                            ' • ',
                            style: AppTheme.caption.copyWith(fontSize: 11),
                          ),
                          Text(
                            consignor.phone!,
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
                    FormatHelpers.rupiah(totalActive),
                    style: AppTheme.amountMedium.copyWith(
                      color: statusLabel == 'Selesai'
                          ? AppTheme.profitColorTheme(context)
                          : AppTheme.warningColorTheme(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
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
