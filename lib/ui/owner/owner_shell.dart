import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
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
    if (!mounted || businesses.isEmpty) return;

    if (businesses.length == 1) {
      TransactionSheet.show(context, businesses.first);
      return;
    }

    final selected = await showDialog<BusinessModel>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: const Text('Pilih Bisnis'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: businesses.length,
            separatorBuilder: (_, _) => Divider(height: 1, color: Theme.of(context).dividerColor),
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
    if (selected != null && mounted) {
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
              SizedBox(height: AppTheme.s16),
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
      body: PfSlidePageView(
        index: _selectedIndex,
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: PfBottomNav(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) => setState(() => _selectedIndex = index),
        onAddPressed: _handleAddTransaction,
        items: const [
          PfNavItemData(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
            label: 'Dashboard',
          ),
          PfNavItemData(
            icon: Icons.history_outlined,
            activeIcon: Icons.history_rounded,
            label: 'Riwayat',
          ),
          PfNavItemData(
            icon: Icons.assessment_outlined,
            activeIcon: Icons.assessment_rounded,
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
}

