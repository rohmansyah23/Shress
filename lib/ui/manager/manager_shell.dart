import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../data/remote/supabase_service.dart';
import '../../data/local/models/business_model.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_widgets.dart';
import '../dashboard/qris_display_screen.dart';
import '../transaction/transaction_sheet.dart';
import '../transaction/transaction_history_screen.dart';
import '../reports/manager_report_screen.dart';
import '../profile/profile_screen.dart';
import 'manager_dashboard_screen.dart';

/// Manager/Staff Shell — single Scaffold with dynamic AppBar.
///
/// Navbar order:
///   0. Dashboard
///   1. Riwayat Transaksi
///   2. + (Tambah Transaksi)
///   3. Laporan
///   4. Profil
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
    } catch (_) {
      // Silently handle — UI will show empty state
    }
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz_rounded, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Ganti Bisnis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ..._businesses.map((b) => ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.store_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    b.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: b.description != null && b.description!.isNotEmpty
                      ? Text(
                          b.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: _selectedBusiness?.businessId == b.businessId
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppTheme.profitColor)
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
      ErrorSnackbar.showWarning(
          context, 'Pilih usaha terlebih dahulu');
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
              SizedBox(height: 16),
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: pages[_selectedIndex],
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
                _buildNavItem(1, Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Riwayat'),
                _buildAddButton(),
                _buildNavItem(3, Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Laporan'),
                _buildNavItem(4, Icons.person_outline, Icons.person_rounded, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData solidIcon, String label) {
    final isSelected = _selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 150),
              scale: isSelected ? 1.15 : 1.0,
              child: Icon(
                isSelected ? solidIcon : outlineIcon,
                color: isSelected ? activeColor : inactiveColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: _showAddTransactionSheet,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              color: colorScheme.primary,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              'Tambah',
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder(String message, {Key? key}) {
    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
