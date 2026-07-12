import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../data/remote/supabase_service.dart';
import '../../data/local/models/business_model.dart';
import '../../core/constants/constants.dart';
import '../dashboard/qris_display_screen.dart';
import '../transaction/transaction_sheet.dart';
import '../transaction/transaction_history_screen.dart';
import '../reports/manager_report_screen.dart';
import '../profile/profile_screen.dart';
import 'manager_dashboard_screen.dart';

class ManagerShell extends ConsumerStatefulWidget {
  const ManagerShell({super.key});

  @override
  ConsumerState<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends ConsumerState<ManagerShell> {
  int _selectedIndex = 0;
  BusinessModel? _selectedBusiness;
  List<BusinessModel> _businesses = [];

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  String get _appBarTitle {
    switch (_selectedIndex) {
      case 0:
        return _selectedBusiness?.name ?? AppConstants.appName;
      case 1:
        return _selectedBusiness?.name ?? 'Riwayat Transaksi';
      case 3:
        return 'Laporan Keuangan';
      case 4:
        return 'Profil Saya';
      default:
        return AppConstants.appName;
    }
  }

  Future<void> _loadBusinesses() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final businesses = await SupabaseService.instance
          .getAccessibleBusinesses(user.userId, user.role);

      if (!mounted) return;

      setState(() {
        _businesses = businesses;
        _selectedBusiness ??= businesses.isNotEmpty ? businesses.first : null;
      });
    } catch (_) {}
  }

  void _switchBusiness(BusinessModel business) {
    setState(() {
      _selectedBusiness = business;
      _selectedIndex = 0;
    });
  }

  void _showBusinessPicker() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.s20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.s20),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz_rounded, size: 20),
                  const SizedBox(width: AppTheme.s8),
                  Text(
                    'Ganti Bisnis',
                    style: AppTheme.title,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.s12),
            const Divider(height: 1),
            const SizedBox(height: AppTheme.s8),
            ..._businesses.map((b) => ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      Icons.store_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    b.name,
                    style: AppTheme.subtitle,
                  ),
                  subtitle: b.description != null && b.description!.isNotEmpty
                      ? Text(b.description!, maxLines: 1, overflow: TextOverflow.ellipsis)
                      : null,
                  trailing: _selectedBusiness?.businessId == b.businessId
                      ? Icon(Icons.check_circle_rounded, color: AppTheme.accent)
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(ctx);
                    _switchBusiness(b);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showAddTransactionSheet() {
    if (_selectedBusiness == null) {
      ErrorSnackbar.showWarning(context, 'Pilih usaha terlebih dahulu');
      return;
    }
    TransactionSheet.show(context, _selectedBusiness!);
  }

  void _showQris() {
    if (_selectedBusiness == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QrisDisplayScreen(business: _selectedBusiness!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppTheme.s16),
              Text('Memuat sesi...'),
            ],
          ),
        ),
      );
    }

    final pages = <Widget>[
      _selectedBusiness != null
          ? ManagerDashboardScreen(
              key: ValueKey('manager_dashboard_${_selectedBusiness!.businessId}'),
              selectedBusiness: _selectedBusiness!,
              businesses: _businesses,
              showAppBar: false,
              onSwitchBusiness: _showBusinessPicker,
              onShowQris: _showQris,
              onNavigateToRiwayat: () => setState(() => _selectedIndex = 1),
            )
          : _buildEmptyPlaceholder('Pilih usaha untuk memulai', key: const ValueKey('empty_dashboard')),
      _selectedBusiness != null
          ? TransactionHistoryScreen(
              key: ValueKey('manager_history_${_selectedBusiness!.businessId}'),
              business: _selectedBusiness!,
              showAppBar: false,
            )
          : _buildEmptyPlaceholder('Pilih usaha untuk melihat riwayat', key: const ValueKey('empty_history')),
      const SizedBox.shrink(key: ValueKey('manager_empty')),
      _selectedBusiness != null
          ? ManagerReportScreen(
              key: ValueKey('manager_report_${_selectedBusiness!.businessId}'),
              business: _selectedBusiness!,
              showAppBar: false,
            )
          : _buildEmptyPlaceholder('Pilih usaha untuk melihat laporan', key: const ValueKey('empty_report')),
      const ProfileScreen(
        key: ValueKey('manager_profile'),
        showAppBar: false,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
        actions: _selectedIndex == 0 && _selectedBusiness != null
            ? [
                IconButton(
                  icon: const Icon(Icons.qr_code_rounded),
                  tooltip: 'QRIS Pembayaran',
                  onPressed: _showQris,
                ),
              ]
            : null,
      ),
      body: PfSlidePageView(
        index: _selectedIndex,
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: PfBottomNav(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) => setState(() => _selectedIndex = index),
        onAddPressed: _showAddTransactionSheet,
        items: const [
          PfNavItemData(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
            label: 'Dashboard',
          ),
          PfNavItemData(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_rounded,
            label: 'Riwayat',
          ),
          PfNavItemData(
            icon: Icons.bar_chart_outlined,
            activeIcon: Icons.bar_chart_rounded,
            label: 'Laporan',
          ),
          PfNavItemData(
            icon: Icons.person_outline,
            activeIcon: Icons.person_rounded,
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder(String message, {Key? key}) {
    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.s32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              ),
              child: Icon(
                Icons.store_rounded,
                size: 36,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: AppTheme.s16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.bodyText,
            ),
          ],
        ),
      ),
    );
  }
}


