import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../data/remote/supabase_service.dart';
import '../../data/local/models/business_model.dart';
import '../../core/theme/app_theme.dart';
import '../dashboard/qris_display_screen.dart';
import '../transaction/transaction_sheet.dart';
import '../reports/manager_report_screen.dart';
import '../profile/profile_screen.dart';

/// Manager/Staff Shell with Bottom Navigation.
/// Navbar order:
///   1. Pilih Usaha (Business Selection)
///   2. QRIS (Display QRIS)
///   3. + (Tambah Transaksi)
///   4. Laporan/Grafik (Financial reports)
///   5. Profil (Profile - email, photo, password, logout)
class ManagerShell extends ConsumerStatefulWidget {
  const ManagerShell({super.key});

  @override
  ConsumerState<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends ConsumerState<ManagerShell> {
  int _selectedIndex = 0;
  BusinessModel? _selectedBusiness;

  // Keep a copy of businesses for quick switching
  List<BusinessModel> _businesses = [];

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  Future<void> _loadBusinesses() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final businesses = await SupabaseService.instance
        .getAccessibleBusinesses(user.userId, user.role);
    if (mounted && businesses.isNotEmpty) {
      setState(() {
        _businesses = businesses;
        _selectedBusiness ??= businesses.first;
      });
    }
  }

  void _showAddTransactionSheet() {
    if (_selectedBusiness == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih usaha terlebih dahulu')),
      );
      return;
    }
    TransactionSheet.show(context, _selectedBusiness!);
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

    // Build pages list
    final pages = <Widget>[
      // Tab 1: Pilih Usaha / Active Business Dashboard
      _buildBusinessDashboard(),

      // Tab 2: QRIS Display
      _selectedBusiness != null
          ? QrisDisplayScreen(business: _selectedBusiness!)
          : const Center(child: Text('Pilih usaha terlebih dahulu')),

      // Tab 3: Plus button - handled by onTap, placeholder
      const SizedBox.shrink(),

      // Tab 4: Laporan/Grafik
      _selectedBusiness != null
          ? ManagerReportScreen(business: _selectedBusiness!)
          : const Center(child: Text('Pilih usaha terlebih dahulu')),

      // Tab 5: Profil
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            // Plus button — show transaction sheet
            _showAddTransactionSheet();
            return;
          }
          setState(() => _selectedIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: Icon(_selectedBusiness != null
                ? Icons.store_outlined
                : Icons.store_mall_directory_outlined),
            selectedIcon: Icon(_selectedBusiness != null
                ? Icons.store_rounded
                : Icons.store_mall_directory_rounded),
            label: _selectedBusiness != null
                ? _selectedBusiness!.name.length > 8
                    ? '${_selectedBusiness!.name.substring(0, 8)}...'
                    : _selectedBusiness!.name
                : 'Pilih Usaha',
          ),
          const NavigationDestination(
            icon: Icon(Icons.qr_code_outlined),
            selectedIcon: Icon(Icons.qr_code_rounded),
            label: 'QRIS',
          ),
          const NavigationDestination(
            icon: Icon(Icons.add_circle_outline, size: 32),
            selectedIcon: Icon(Icons.add_circle, size: 32),
            label: 'Tambah',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Laporan',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessDashboard() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadBusinesses();
      },
      child: _businesses.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.business_rounded,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('Tidak ada bisnis tersedia',
                            style: AppTheme.heading3
                                .copyWith(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text('Hubungi Owner untuk mendapatkan akses',
                            style: AppTheme.caption),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Pilih Bisnis', style: AppTheme.heading2),
                const SizedBox(height: 16),
                ..._businesses.map((b) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() {
                            _selectedBusiness = b;
                            _selectedIndex = 1; // Go to QRIS tab
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(Icons.store_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(b.name, style: AppTheme.heading3),
                                    if (b.description != null &&
                                        b.description!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(b.description!,
                                          style: AppTheme.caption,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ],
                                    if (_selectedBusiness?.businessId ==
                                        b.businessId) ...[
                                      const SizedBox(height: 4),
                                      const Text('✓ Sedang aktif',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.profitColor,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ],
                                ),
                              ),
                              if (_selectedBusiness?.businessId ==
                                  b.businessId)
                                Icon(Icons.check_circle_rounded,
                                    color: AppTheme.profitColor)
                              else
                                Icon(Icons.chevron_right_rounded,
                                    color: Colors.grey.shade400),
                            ],
                          ),
                        ),
                      ),
                    )),
              ],
            ),
    );
  }
}
