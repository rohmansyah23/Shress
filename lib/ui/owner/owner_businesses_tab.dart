import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/format_helpers.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/local/models/business_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/business_providers.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart';
import '../dashboard/qris_display_screen.dart';
import '../dashboard/qris_upload_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../reports/owner_report_screen.dart';
import '../transaction/transaction_sheet.dart';
import '../transaction/transaction_history_screen.dart';
import 'create_business_screen.dart';

enum BusinessSortOption {
  nameAZ('Nama (A - Z)'),
  highestProfit('Laba Terbesar'),
  lowestProfit('Rugi Terbesar');

  final String label;
  const BusinessSortOption(this.label);
}

class OwnerBusinessesTab extends ConsumerStatefulWidget {
  final void Function(int index)? onTabSwitch;

  const OwnerBusinessesTab({super.key, this.onTabSwitch});

  @override
  ConsumerState<OwnerBusinessesTab> createState() => _OwnerBusinessesTabState();
}

class _OwnerBusinessesTabState extends ConsumerState<OwnerBusinessesTab> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  BusinessSortOption _sortOption = BusinessSortOption.nameAZ;
  bool _isProcessing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showEditDialog(BusinessModel business) {
    final nameCtrl = TextEditingController(text: business.name);
    final descCtrl = TextEditingController(text: business.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.radiusMedium)),
        title: const Text('Edit Bisnis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: nameCtrl,
              labelText: 'Nama Bisnis',
              hintText: 'Masukkan nama bisnis',
            ),
            const SizedBox(height: AppSpacing.s12),
            AppTextField(
              controller: descCtrl,
              labelText: 'Deskripsi',
              hintText: 'Masukkan deskripsi',
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

              Navigator.pop(ctx);
              setState(() => _isProcessing = true);

              try {
                await SupabaseService.instance.updateBusiness(
                  businessId: business.businessId,
                  name: name,
                  description: descCtrl.text.trim(),
                );
                ref.invalidate(allBusinessesProvider);
                ref.invalidate(transactionRefreshProvider);
                if (mounted) {
                  ErrorSnackbar.showSuccess(context, 'Bisnis berhasil diperbarui');
                }
              } catch (e) {
                if (mounted) {
                  ErrorSnackbar.show(context, ErrorHandler.classify(e));
                }
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BusinessModel business) {
    final confirmController = TextEditingController();
    var isMatch = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.radiusMedium)),
          title: const Text('Hapus Bisnis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tindakan ini tidak bisa dibatalkan. Semua transaksi dan data terkait akan dihapus secara permanen.',
                style: TextStyle(color: AppTheme.onSurfaceVariantColorTheme(dialogCtx), fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.s12),
              Text.rich(
                TextSpan(
                  text: 'Ketik ',
                  children: [
                    TextSpan(
                      text: business.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' untuk konfirmasi:'),
                  ],
                ),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.s8),
              AppTextField(
                controller: confirmController,
                hintText: 'Nama bisnis',
                onChanged: (val) {
                  setStateDialog(() {
                    isMatch = val.trim() == business.name;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isMatch ? AppTheme.lossColorTheme(dialogCtx) : Colors.grey.shade400,
                foregroundColor: isMatch ? AppTheme.onDangerColorTheme(dialogCtx) : Colors.grey.shade600,
              ),
              onPressed: isMatch
                  ? () async {
                      Navigator.pop(ctx);
                      setState(() => _isProcessing = true);
                      try {
                        await SupabaseService.instance.deleteBusiness(business.businessId);
                        ref.invalidate(allBusinessesProvider);
                        ref.invalidate(transactionRefreshProvider);
                        if (mounted) {
                          ErrorSnackbar.showSuccess(context, 'Bisnis berhasil dihapus');
                        }
                      } catch (e) {
                        if (mounted) {
                          ErrorSnackbar.show(context, ErrorHandler.classify(e));
                        }
                      } finally {
                        if (mounted) setState(() => _isProcessing = false);
                      }
                    }
                  : null,
              child: const Text('Hapus'),
            ),
          ],
        ),
      ),
    );
  }

  void _openQrisUpload(BusinessModel business) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QrisUploadScreen(business: business),
      ),
    );
    if (result == true) {
      ref.invalidate(allBusinessesProvider);
    }
  }

  void _viewQris(BusinessModel business) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QrisDisplayScreen(business: business),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessesAsync = ref.watch(allBusinessesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => CreateBusinessScreen(),
            ),
          );
          if (result == true) {
            ref.invalidate(allBusinessesProvider);
            ref.invalidate(transactionRefreshProvider);
          }
        },
        tooltip: 'Buat Bisnis Baru',
        child: const Icon(Icons.add_business_rounded),
      ),
      body: Stack(
        children: [
          businessesAsync.when(
            data: (businesses) {
              final Map<int, double> businessNetProfits = {};
              final Map<int, double> businessTotalIncomes = {};
              final Map<int, bool> businessLoading = {};
              for (final b in businesses) {
                final summaryVal = ref.watch(businessSummaryProvider(b.businessId));
                summaryVal.when(
                  data: (sum) {
                    businessNetProfits[b.businessId] = (sum['netProfit'] as num?)?.toDouble() ?? 0.0;
                    businessTotalIncomes[b.businessId] = (sum['totalIncome'] as num?)?.toDouble() ?? 0.0;
                    businessLoading[b.businessId] = false;
                  },
                  loading: () {
                    businessLoading[b.businessId] = true;
                  },
                  error: (_, _) {
                    businessLoading[b.businessId] = false;
                  },
                );
              }

              if (businesses.isEmpty) {
                return _buildEmptyBusinesses();
              }

              var filteredList = businesses.where((b) {
                if (_searchQuery.isEmpty) return true;
                return b.name.toLowerCase().contains(_searchQuery.toLowerCase());
              }).toList();

              switch (_sortOption) {
                case BusinessSortOption.nameAZ:
                  filteredList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                  break;
                case BusinessSortOption.highestProfit:
                  filteredList.sort((a, b) {
                    final profitA = businessNetProfits[a.businessId] ?? 0.0;
                    final profitB = businessNetProfits[b.businessId] ?? 0.0;
                    return profitB.compareTo(profitA);
                  });
                  break;
                case BusinessSortOption.lowestProfit:
                  filteredList.sort((a, b) {
                    final profitA = businessNetProfits[a.businessId] ?? 0.0;
                    final profitB = businessNetProfits[b.businessId] ?? 0.0;
                    return profitA.compareTo(profitB);
                  });
                  break;
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(allBusinessesProvider);
                  for (final b in businesses) {
                    ref.invalidate(businessSummaryProvider(b.businessId));
                  }
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  children: [
                    Row(
                      children: [
                        Text(
                          'Total: ${businesses.length} Bisnis',
                          style: AppTheme.subtitle.copyWith(fontSize: 15),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 150,
                          child: _buildSortDropdown(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    _buildSearchBar(),
                    const SizedBox(height: AppSpacing.s16),
                    if (filteredList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s48),
                        child: Center(
                          child: Text(
                            'Tidak ada bisnis ditemukan',
                            style: AppTheme.caption,
                          ),
                        ),
                      )
                    else
                      ...List.generate(filteredList.length, (index) {
                        final b = filteredList[index];
                        final profit = businessNetProfits[b.businessId];
                        final totalIncome = businessTotalIncomes[b.businessId];
                        final loading = businessLoading[b.businessId] ?? true;

                        final hasQris = b.qrisImageUrl != null && b.qrisImageUrl!.isNotEmpty;

                        return FadeInEntrance(
                          delay: Duration(milliseconds: index * 40),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                            child: _BusinessCardItem(
                              business: b,
                              netProfit: profit,
                              totalIncome: totalIncome,
                              isLoadingSummary: loading,
                              hasQris: hasQris,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DashboardScreen(
                                      business: b,
                                      showAppBar: true,
                                      onNavigateToRiwayat: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => TransactionHistoryScreen(
                                              business: b,
                                              showAppBar: true,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                              popupMenu: PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert_rounded,
                                  color: AppTheme.onSurfaceVariantColorTheme(context),
                                  size: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                                ),
                                onSelected: (value) {
                                  switch (value) {
                                    case 'add_tx':
                                      TransactionSheet.show(context, b);
                                      break;
                                    case 'report':
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => OwnerReportScreen(
                                            initialBusinessId: b.businessId,
                                            initialPeriod: OwnerPeriodFilter.thisWeek,
                                          ),
                                        ),
                                      );
                                      break;
                                    case 'view_qris':
                                      _viewQris(b);
                                      break;
                                    case 'manage_qris':
                                      _openQrisUpload(b);
                                      break;
                                    case 'edit':
                                      _showEditDialog(b);
                                      break;
                                    case 'delete':
                                      _confirmDelete(b);
                                      break;
                                  }
                                },
                                 itemBuilder: (context) => [
                                  PopupMenuItem<String>(
                                    value: 'add_tx',
                                    height: 36,
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
                                    child: Text(
                                      'Tambah Transaksi',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.normal,
                                        color: AppTheme.onSurfaceColorTheme(context),
                                      ),
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'report',
                                    height: 36,
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
                                    child: Text(
                                      'Laporan Keuangan',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.normal,
                                        color: AppTheme.onSurfaceColorTheme(context),
                                      ),
                                    ),
                                  ),
                                  if (hasQris)
                                    PopupMenuItem<String>(
                                      value: 'view_qris',
                                      height: 36,
                                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
                                      child: Text(
                                        'Lihat QRIS',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.normal,
                                          color: AppTheme.onSurfaceColorTheme(context),
                                        ),
                                      ),
                                    ),
                                  PopupMenuItem<String>(
                                    value: 'manage_qris',
                                    height: 36,
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
                                    child: Text(
                                      'Kelola QRIS',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.normal,
                                        color: AppTheme.onSurfaceColorTheme(context),
                                      ),
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'edit',
                                    height: 36,
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
                                    child: Text(
                                      'Edit Bisnis',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.normal,
                                        color: AppTheme.onSurfaceColorTheme(context),
                                      ),
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  PopupMenuItem<String>(
                                    value: 'delete',
                                    height: 36,
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
                                    child: Text(
                                      'Hapus Bisnis',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.normal,
                                        color: AppTheme.lossColorTheme(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: AppSpacing.s48),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorRetryWidget(
              message: ErrorHandler.classify(error).userMessage,
              onRetry: () => ref.invalidate(allBusinessesProvider),
            ),
          ),
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return AppTextField(
      controller: _searchController,
      hintText: 'Cari nama bisnis...',
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
    );
  }

  Widget _buildSortDropdown() {
    return AppDropdown<BusinessSortOption>(
      initialValue: _sortOption,
      items: BusinessSortOption.values.map((option) {
        return DropdownMenuItem<BusinessSortOption>(
          value: option,
          child: Text(
            option.label,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.onSurfaceColorTheme(context),
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() => _sortOption = value);
      },
    );
  }

  Widget _buildEmptyBusinesses() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainerColorTheme(context),
                borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
              ),
              child: Icon(
                Icons.store_rounded,
                size: AppIconSize.s32,
                color: AppTheme.primaryColorTheme(context),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            const Text(
              'Belum memiliki bisnis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Silakan buat bisnis pertama Anda\nuntuk mulai mencatat keuangan.',
              textAlign: TextAlign.center,
              style: AppTheme.caption.copyWith(height: 1.5),
            ),
            const SizedBox(height: AppSpacing.s20),
            FilledButton.icon(
              icon: const Icon(Icons.add_business_rounded, size: AppIconSize.s18),
              label: const Text('Buat Bisnis Baru'),
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => CreateBusinessScreen(),
                  ),
                );
                if (result == true) {
                  ref.invalidate(allBusinessesProvider);
                  ref.invalidate(transactionRefreshProvider);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessCardItem extends StatelessWidget {
  final BusinessModel business;
  final double? netProfit;
  final double? totalIncome;
  final bool isLoadingSummary;
  final bool hasQris;
  final VoidCallback onTap;
  final Widget popupMenu;

  const _BusinessCardItem({
    required this.business,
    required this.netProfit,
    required this.totalIncome,
    required this.isLoadingSummary,
    required this.hasQris,
    required this.onTap,
    required this.popupMenu,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isProfit = netProfit != null && netProfit! >= 0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                  gradient: LinearGradient(
                    colors: [
                      isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08),
                      isDark ? AppTheme.accent : AppTheme.primary,
                      (isDark ? AppTheme.accent : AppTheme.primary).withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.1, 1.0],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.store_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            business.name,
                            style: AppTheme.heading3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasQris) ...[
                          const SizedBox(width: AppSpacing.s6),
                          Icon(
                            Icons.qr_code_2_rounded,
                            size: 16,
                            color: AppTheme.primaryColorTheme(context),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    if (isLoadingSummary)
                      const Text('Memuat...', style: TextStyle(fontSize: 12))
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Omzet: ${FormatHelpers.rupiah(totalIncome ?? 0.0)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.onSurfaceVariantColorTheme(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isProfit
                                      ? AppTheme.profitColorTheme(context)
                                      : AppTheme.lossChartColor(context),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s6),
                              Expanded(
                                child: Text(
                                  netProfit != null
                                      ? 'Laba Bersih: ${FormatHelpers.rupiah(netProfit!)}'
                                      : 'Belum ada data',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isProfit
                                        ? AppTheme.profitColorTheme(context)
                                        : AppTheme.lossColorTheme(context),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              popupMenu,
            ],
          ),
        ),
      ),
    );
  }
}
