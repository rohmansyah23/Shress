import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../providers/auth_provider.dart';
import 'owner_dashboard_tab.dart';
import 'owner_history_screen.dart';
import 'owner_businesses_tab.dart';
import '../reports/owner_report_screen.dart';
import '../profile/profile_screen.dart';
import '../../core/theme/app_spacing.dart';

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
        return 'Bisnis Saya';
      case 3:
        return 'Laporan Keuangan';
      case 4:
        return 'Profil Saya';
      default:
        return 'Sheress';
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
              SizedBox(height: AppSpacing.s16),
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
      OwnerBusinessesTab(
        key: const ValueKey('owner_businesses'),
        onTabSwitch: (index) => setState(() => _selectedIndex = index),
      ),
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
        showCenterAddButton: false,
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
            icon: Icons.store_outlined,
            activeIcon: Icons.store_rounded,
            label: 'Bisnis',
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

