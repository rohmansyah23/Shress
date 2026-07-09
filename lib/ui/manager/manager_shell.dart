import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../data/remote/supabase_service.dart';
import '../../data/local/models/business_model.dart';
import '../../core/theme/app_theme.dart';
import '../dashboard/qris_display_screen.dart';
import '../transaction/transaction_sheet.dart';
import '../transaction/transaction_history_screen.dart';
import '../reports/manager_report_screen.dart';
import '../profile/profile_screen.dart';

/// Manager/Staff Shell with Bottom Navigation.
/// Navbar order:
///   0. Pilih Usaha (Business Selection)
///   1. Riwayat Transaksi
///   2. + (Tambah Transaksi)
///   3. Laporan (Financial summary)
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

  void _showQris() {
    if (_selectedBusiness == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih usaha terlebih dahulu')),
      );
      return;
    }
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

    final showAppBar = _selectedIndex == 0 || _selectedIndex == 2;

    final pages = <Widget>[
      _buildBusinessDashboard(),
      _selectedBusiness != null
          ? TransactionHistoryScreen(
              key: ValueKey(_selectedBusiness!.businessId),
              business: _selectedBusiness!,
            )
          : const Center(child: Text('Pilih usaha terlebih dahulu')),
      const SizedBox.shrink(),
      _selectedBusiness != null
          ? ManagerReportScreen(business: _selectedBusiness!)
          : const Center(child: Text('Pilih usaha terlebih dahulu')),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('SSRS Finance'),
              actions: [
                if (_selectedBusiness != null)
                  IconButton(
                    icon: const Icon(Icons.qr_code_rounded),
                    tooltip: 'QRIS Pembayaran',
                    onPressed: _showQris,
                  ),
              ],
            )
          : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
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
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Riwayat',
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
                ..._businesses.map((b) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() {
                            _selectedBusiness = b;
                            _selectedIndex = 1;
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
