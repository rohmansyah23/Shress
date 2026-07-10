import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/models/business_model.dart';
import '../../providers/auth_provider.dart';
import '../transaction/transaction_sheet.dart';
import 'owner_dashboard_tab.dart';
import 'owner_history_screen.dart';
import '../reports/owner_report_screen.dart';
import '../profile/profile_screen.dart';

class OwnerShell extends ConsumerStatefulWidget {
  const OwnerShell({super.key});

  @override
  ConsumerState<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends ConsumerState<OwnerShell> {
  int _selectedIndex = 0;

  String get _appBarTitle {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Riwayat Transaksi';
      case 2:
        return '';
      case 3:
        return 'Laporan Keuangan';
      case 4:
        return 'Profil Saya';
      default:
        return 'Sheress';
    }
  }

  void _handleAddTransaction() async {
    final businesses = await ref.read(allBusinessesProvider.future);
    if (!context.mounted || businesses.isEmpty) return;

    if (businesses.length == 1) {
      TransactionSheet.show(context, businesses.first);
      return;
    }

    final selected = await showDialog<BusinessModel>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Pilih Bisnis'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: businesses.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) => ListTile(
              leading: const Icon(Icons.store_rounded),
              title: Text(businesses[i].name),
              onTap: () => Navigator.pop(ctx, businesses[i]),
            ),
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
    if (selected != null && context.mounted) {
      TransactionSheet.show(context, selected);
    }
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
              Text('Memuat profil...'),
            ],
          ),
        ),
      );
    }

    final pages = <Widget>[
      OwnerDashboardTab(
        key: const ValueKey('owner_dashboard'),
        user: user,
        showAppBar: false,
        onTabSwitch: (index) => setState(() => _selectedIndex = index),
      ),
      const OwnerHistoryScreen(
        key: ValueKey('owner_history'),
        showAppBar: false,
      ),
      const SizedBox.shrink(key: ValueKey('owner_empty')),
      const OwnerReportScreen(
        key: ValueKey('owner_report'),
        showAppBar: false,
      ),
      const ProfileScreen(
        key: ValueKey('owner_profile'),
        showAppBar: false,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
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
                _buildNavItem(1, Icons.history_outlined, Icons.history_rounded, 'Riwayat'),
                _buildAddButton(),
                _buildNavItem(3, Icons.assessment_outlined, Icons.assessment_rounded, 'Laporan'),
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
        onTap: _handleAddTransaction,
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
}
