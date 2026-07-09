import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/models/business_model.dart';
import '../../providers/auth_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../profile/profile_screen.dart';
import '../reports/owner_report_screen.dart';
import 'owner_history_screen.dart';
import 'user_management_panel.dart';

class BusinessOwnerShell extends ConsumerStatefulWidget {
  final BusinessModel business;

  const BusinessOwnerShell({super.key, required this.business});

  @override
  ConsumerState<BusinessOwnerShell> createState() => _BusinessOwnerShellState();
}

class _BusinessOwnerShellState extends ConsumerState<BusinessOwnerShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = <Widget>[
      DashboardScreen(
        business: widget.business,
        onNavigateToRiwayat: () => setState(() => _selectedIndex = 1),
      ),
      OwnerHistoryScreen(
        initialBusinessId: widget.business.businessId,
        initialFilter: OwnerDateFilter.thisWeek,
      ),
      const UserManagementPanel(),
      OwnerReportScreen(
        initialBusinessId: widget.business.businessId,
        initialPeriod: OwnerPeriodFilter.thisWeek,
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment_rounded),
            label: 'Laporan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
