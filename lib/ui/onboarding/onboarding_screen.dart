import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/error_widgets.dart';
import '../../providers/auth_provider.dart';
import '../owner/owner_shell.dart';
import '../manager/manager_shell.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

import '../../core/theme/app_icon_size.dart';

/// Multi-page onboarding wizard for new users.
/// Shown on first login when no businesses exist.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Create business form
  final _businessNameCtrl = TextEditingController();
  final _businessDescCtrl = TextEditingController();
  bool _isCreatingBusiness = false;
  bool _skipBusinessCreation = false;

  @override
  void dispose() {
    _pageController.dispose();
    _businessNameCtrl.dispose();
    _businessDescCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _finish() {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    Widget destination;
    switch (user.role) {
      case AppConstants.roleOwner:
        destination = const OwnerShell();
      case AppConstants.roleManager:
      case AppConstants.roleStaff:
        destination = const ManagerShell();
      default:
        destination = const OwnerShell();
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  Future<void> _handleCreateBusiness() async {
    if (_skipBusinessCreation) {
      _nextPage();
      return;
    }
    if (_businessNameCtrl.text.trim().isEmpty) return;

    setState(() => _isCreatingBusiness = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final repo = ref.read(authRepositoryProvider);
      await repo.createBusinessWithOwner(
        name: _businessNameCtrl.text.trim(),
        description: _businessDescCtrl.text.trim().isEmpty
            ? null
            : _businessDescCtrl.text.trim(),
        ownerUserId: user.userId,
      );

      if (!mounted) return;
      ref.invalidate(allBusinessesProvider);
      setState(() => _isCreatingBusiness = false);
      _nextPage();
    } catch (e) {
      if (mounted) {
        setState(() => _isCreatingBusiness = false);
        ErrorSnackbar.show(context, ErrorHandler.classify(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s24, AppSpacing.s16, AppSpacing.s24, 0),
              child: Row(
                children: List.generate(
                  4,
                  (i) => Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i <= _currentPage
                            ? AppTheme.primaryColorTheme(context)
                            : AppTheme.surfaceContainerHighestColorTheme(context),
                        borderRadius: BorderRadius.circular(AppRadius.s2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_currentPage < 3)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isCreatingBusiness ? null : _finish,
                  child: Text('Lewati', style: AppTheme.caption),
                ),
              ),

            // Main content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() {
                  _currentPage = page;
                  if (page == 1) _skipBusinessCreation = false;
                }),
                children: [
                  _buildWelcomePage(),
                  _buildCreateBusinessPage(),
                  _buildFeatureTourPage(),
                  _buildReadyPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ Page 1: Welcome ============

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainerColorTheme(context),
              borderRadius: BorderRadius.circular(AppRadius.radiusXL),
            ),
            child: Icon(
              Icons.account_balance_rounded,
              size: AppIconSize.s52,
              color: AppTheme.primaryColorTheme(context),
            ),
          ),
          const SizedBox(height: AppSpacing.s32),
          Text(
            'Selamat Datang di\n${AppConstants.appName}',
            textAlign: TextAlign.center,
            style: AppTheme.heading1.copyWith(color: AppTheme.primaryColorTheme(context)),
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            'Aplikasi pencatatan keuangan multi-bisnis\nuntuk membantu Anda mengelola\npemasukan dan pengeluaran dengan mudah.',
            textAlign: TextAlign.center,                  style: AppTheme.bodyText.copyWith(
                    height: 1.6,
                  ),
          ),
          const SizedBox(height: AppSpacing.s48),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _nextPage,
              child: Text('Mulai',
                  style:
                      AppTheme.subtitle),
            ),
          ),
        ],
      ),
    );
  }

  // ============ Page 2: Create Business ============

  Widget _buildCreateBusinessPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.s40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.profitColorTheme(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.radiusLarge),
            ),
            child: Icon(
              Icons.add_business_rounded,
              size: AppIconSize.s40,
              color: AppTheme.profitColorTheme(context),
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          Text(
            'Buat Bisnis Pertama Anda',
            textAlign: TextAlign.center,
            style: AppTheme.heading2,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Isi nama bisnis untuk mulai\nmencatat keuangan.',
            textAlign: TextAlign.center,
            style: AppTheme.bodyText.copyWith(
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.s32),
          TextFormField(
            controller: _businessNameCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nama Bisnis',
              prefixIcon: Icon(Icons.store_outlined),
              hintText: 'Contoh: Warung Makmur',
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          TextFormField(
            controller: _businessDescCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Deskripsi (opsional)',
              prefixIcon: Icon(Icons.description_outlined),
              hintText: 'Jenis usaha atau keterangan',
            ),
          ),
          const SizedBox(height: AppSpacing.s32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _isCreatingBusiness ? null : _handleCreateBusiness,                  child: _isCreatingBusiness
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.onPrimaryColorTheme(context)),
                    )
                  : Text('Buat Bisnis',
                      style: AppTheme.subtitle),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          TextButton(
            onPressed: () {
              setState(() => _skipBusinessCreation = true);
              _nextPage();
            },
            child: Text('Nanti Saja', style: AppTheme.caption),
          ),
          const SizedBox(height: AppSpacing.s40),
        ],
      ),
    );
  }

  // ============ Page 3: Feature Tour ============

  Widget _buildFeatureTourPage() {
    final features = [
      _FeatureItem(
        icon: Icons.trending_up_rounded,
        iconColor: AppTheme.profitColor,
        title: 'Catat Pemasukan & Pengeluaran',
        desc: 'Input transaksi harian dengan cepat.\nPilih kategori, metode bayar, dan catat HPP.',
      ),
      _FeatureItem(
        icon: Icons.bar_chart_rounded,
        iconColor: AppTheme.infoColor,
        title: 'Laporan Laba / Rugi Otomatis',
        desc: 'Lihat ringkasan keuangan dengan grafik.\nPantau tren laba rugi bisnis Anda.',
      ),
      _FeatureItem(
        icon: Icons.people_rounded,
        iconColor: AppTheme.warningColor,
        title: 'Multi-User & Multi-Bisnis',
        desc: 'Kelola beberapa bisnis sekaligus.\nTambahkan manajer atau staf untuk membantu.',
      ),
      _FeatureItem(
        icon: Icons.qr_code_rounded,
        iconColor: AppTheme.primaryColorTheme(context),
        title: 'QRIS Pembayaran',
        desc: 'Tampilkan QRIS untuk pembayaran\npelanggan. Upload dari galeri atau URL.',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.s24),
          Text(
            'Fitur Unggulan',
            textAlign: TextAlign.center,
            style: AppTheme.heading2,
          ),
          const SizedBox(height: AppSpacing.s32),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _FeatureCard(item: f),
              )),
          const SizedBox(height: AppSpacing.s24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _nextPage,
              child: Text('Lanjutkan',
                  style:
                      AppTheme.subtitle),
            ),
          ),
          const SizedBox(height: AppSpacing.s32),
        ],
      ),
    );
  }

  // ============ Page 4: Ready ============

  Widget _buildReadyPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.profitColorTheme(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.radiusXL),
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: AppIconSize.s52,
              color: AppTheme.profitColorTheme(context),
            ),
          ),
          const SizedBox(height: AppSpacing.s32),
          Text(
            'Siap Memulai!',
            textAlign: TextAlign.center,
            style: AppTheme.heading1,
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            'Anda sudah siap menggunakan ${AppConstants.appName}.\n'
            'Mulai catat transaksi dan pantau\nkeuangan bisnis Anda.',
            textAlign: TextAlign.center,                  style: AppTheme.bodyText.copyWith(
                    height: 1.6,
                  ),
          ),
          const SizedBox(height: AppSpacing.s48),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _finish,
              child: Text('Mulai Sekarang',
                  style:
                      AppTheme.subtitle),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ Supporting Widgets ============

class _FeatureItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String desc;

  const _FeatureItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.desc,
  });
}

class _FeatureCard extends StatelessWidget {
  final _FeatureItem item;

  const _FeatureCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
              ),
              child: Icon(item.icon, color: item.iconColor, size: AppIconSize.s24),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.s4),
                  Text(item.desc,
                      style: AppTheme.caption.copyWith(height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
