import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/widgets/trend_chart.dart';
import '../../providers/theme_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

import '../../core/theme/app_icon_size.dart';

// ═══════════════════════════════════════════════════════════════
// WIDGETBOOK — Design System Component Documentation
// ═══════════════════════════════════════════════════════════════

class WidgetBookScreen extends ConsumerStatefulWidget {
  const WidgetBookScreen({super.key});

  @override
  ConsumerState<WidgetBookScreen> createState() => _WidgetBookScreenState();
}

class _WidgetBookScreenState extends ConsumerState<WidgetBookScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('WidgetBook'),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () {
              ref.read(themeModeProvider.notifier).setThemeMode(
                    isDark ? ThemeMode.light : ThemeMode.dark,
                  );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s8,
              AppSpacing.s16,
              AppSpacing.s12,
            ),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari komponen...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.s32),
              children: [
                if (_matches('colors')) const _ColorsSection(),
                if (_matches('typography'))
                  const _TypographySection(),
                if (_matches('spacing')) const _SpacingSection(),
                if (_matches('buttons')) const _ButtonsSection(),
                if (_matches('cards')) const _CardsSection(),
                if (_matches('inputs')) const _InputsSection(),
                if (_matches('navigation')) const _NavigationSection(),
                if (_matches('badges')) const _BadgesSection(),
                if (_matches('skeletons')) const _SkeletonSection(),
                if (_matches('empty')) const _EmptyStateSection(),
                if (_matches('header')) const _HeaderSection(),
                if (_matches('transaction')) const _TransactionCardSection(),
                if (_matches('quick')) const _QuickActionsSection(),
                if (_matches('stat')) const _StatRowSection(),
                if (_matches('error')) const _ErrorSection(),
                if (_matches('snackbar')) const _SnackbarSection(),
                if (_matches('chart')) const _ChartSection(),
                if (_matches('anim')) const _AnimationSection(),
                if (_matches('shadow')) const _ShadowSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _matches(String keyword) {
    if (_searchQuery.isEmpty) return true;
    return keyword.contains(_searchQuery);
  }

}

// ═══════════════════════════════════════════════════════════════
// COLORS SECTION
// ═══════════════════════════════════════════════════════════════

class _ColorsSection extends StatefulWidget {
  const _ColorsSection();

  @override
  State<_ColorsSection> createState() => _ColorsSectionState();
}

class _ColorsSectionState extends State<_ColorsSection> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors = [
      ('Primary', isDark ? AppTheme.darkPrimary : AppTheme.primary,
          'primary / darkPrimary'),
      ('Accent', isDark ? AppTheme.darkAccent : AppTheme.accent,
          'accent / darkAccent'),
      ('Background', isDark ? AppTheme.darkBackground : AppTheme.background,
          'background / darkBackground'),
      ('Secondary\nBg', isDark ? AppTheme.darkSecondaryBackground : AppTheme.surfaceContainer,
          'surfaceContainer / darkSurface'),
      ('Card', isDark ? AppTheme.darkCard : AppTheme.card,
          'card / darkCard'),
      ('Elevated Card', isDark ? AppTheme.darkCardElevated : AppTheme.card,
          'card / darkCardElevated'),
      ('Primary Text', isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
          'textPrimary / darkTextPrimary'),
      ('Secondary\nText', isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
          'textSecondary / darkTextSecondary'),
      ('Divider', isDark ? AppTheme.darkDivider : AppTheme.divider,
          'divider / darkDivider'),
    ];

    final semanticColors = [
      ('Success', AppTheme.success, 'success'),
      ('Warning', AppTheme.warning, 'warning'),
      ('Danger', AppTheme.danger, 'danger'),
      ('Profit', AppTheme.profitColorTheme(context),
          'profitColorTheme(ctx)'),
      ('Loss', AppTheme.lossColorTheme(context),
          'lossColorTheme(ctx)'),
      ('Warning\nTheme', AppTheme.warningColorTheme(context),
          'warningColorTheme(ctx)'),
      ('Info', AppTheme.infoColorTheme(context),
          'infoColorTheme(ctx)'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WidgetBookHeader(
            title: 'Colors',
            subtitle: 'PocketFund color palette — light & dark mode',
          ),
          const SizedBox(height: AppSpacing.s12),

          // Theme colors
          Text('Theme Colors', style: AppTheme.subtitle),
          const SizedBox(height: AppSpacing.s8),
          _ColorPalette(colors: themeColors),
          const SizedBox(height: AppSpacing.s20),

          // Semantic colors
          Text('Semantic Colors', style: AppTheme.subtitle),
          const SizedBox(height: AppSpacing.s8),
          _ColorPalette(colors: semanticColors),
          const SizedBox(height: AppSpacing.s8),

          // Color value reference
          const _CodeHint(
            'Status colors use AppTheme.profitColorTheme(context) for theme-aware.',
          ),
        ],
      ),
    );
  }
}

class _ColorPalette extends StatelessWidget {
  final List<(String, Color, String)> colors;
  const _ColorPalette({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s12,
      children: colors.map((c) {
        final (label, color, code) = c;
        return Tooltip(
          message: code,
          child: SizedBox(
            width: (MediaQuery.of(context).size.width - 48) / 4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius:
                        BorderRadius.circular(AppRadius.radiusSmall),
                    border: Border.all(
                      color: AppTheme.onSurfaceColorTheme(context)
                          .withValues(alpha: 0.1),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onSurfaceColorTheme(context),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TYPOGRAPHY SECTION
// ═══════════════════════════════════════════════════════════════

class _TypographySection extends StatelessWidget {
  const _TypographySection();

  @override
  Widget build(BuildContext context) {
    final styles = [
      ('display', AppTheme.display, 'AppTheme.display'),
      ('heading1', AppTheme.heading1, 'AppTheme.heading1'),
      ('heading2', AppTheme.heading2, 'AppTheme.heading2'),
      ('heading3', AppTheme.heading3, 'AppTheme.heading3'),
      ('title', AppTheme.title, 'AppTheme.title'),
      ('subtitle', AppTheme.subtitle, 'AppTheme.subtitle'),
      ('bodyText', AppTheme.bodyText, 'AppTheme.bodyText'),
      ('caption', AppTheme.caption, 'AppTheme.caption'),
      ('buttonText', AppTheme.buttonText, 'AppTheme.buttonText'),
      ('amountLarge', AppTheme.amountLarge, 'AppTheme.amountLarge'),
      ('amountMedium', AppTheme.amountMedium, 'AppTheme.amountMedium'),
      ('labelSmall', AppTheme.labelSmall, 'AppTheme.labelSmall'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WidgetBookHeader(
            title: 'Typography',
            subtitle: 'Inter font — all text styles in the design system',
          ),
          const SizedBox(height: AppSpacing.s12),
          ...styles.map((s) {
            final (name, style, code) = s;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _CodeBadge(code),
                      const SizedBox(width: AppSpacing.s8),
                      Text(
                        '${style.fontSize?.toInt()}pt / '
                        '${style.fontWeight?.value}w',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.onSurfaceVariantColorTheme(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text('Sheress Finansial — Laba Rp 1.234.567.890',
                      style: style),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SPACING SECTION
// ═══════════════════════════════════════════════════════════════

class _SpacingSection extends StatelessWidget {
  const _SpacingSection();

  @override
  Widget build(BuildContext context) {
    final spacings = [
      ('s2', AppSpacing.s2),
      ('s4', AppSpacing.s4),
      ('s8', AppSpacing.s8),
      ('s12', AppSpacing.s12),
      ('s16', AppSpacing.s16),
      ('s20', AppSpacing.s20),
      ('s24', AppSpacing.s24),
      ('s32', AppSpacing.s32),
      ('s40', AppSpacing.s40),
      ('s48', AppSpacing.s48),
      ('s56', AppSpacing.s56),
      ('s64', AppSpacing.s64),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WidgetBookHeader(
            title: 'Spacing',
            subtitle: '8-point grid system — use AppTheme.s{n} constants',
          ),
          const SizedBox(height: AppSpacing.s12),
          ...spacings.map((s) {
            final (name, value) = s;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s8),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: _CodeBadge(name),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColorTheme(context)
                            .withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppRadius.radiusSmall),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: value.clamp(0, 300),
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColorTheme(context)
                                  .withValues(alpha: 0.4),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.radiusSmall),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Text(
                    '${value.toInt()}px',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurfaceVariantColorTheme(context),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: AppSpacing.s8),
          const _CodeHint('Prefer 8-point multiples. Avoid s6/s14.'),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BUTTONS SECTION
// ═══════════════════════════════════════════════════════════════

class _ButtonsSection extends StatelessWidget {
  const _ButtonsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WidgetBookHeader(
            title: 'Buttons',
            subtitle:
                'System buttons + PfButton custom component',
          ),
          const SizedBox(height: AppSpacing.s12),

          // PfButton variants
          Text('PfButton — Custom', style: AppTheme.subtitle),
          const SizedBox(height: AppSpacing.s8),
          const _CodeBadge('PfButton'),
          const SizedBox(height: AppSpacing.s8),
          PfButton(
            label: 'Primary',
            onPressed: () {},
            variant: PfButtonVariant.primary,
          ),
          const SizedBox(height: AppSpacing.s8),
          PfButton(
            label: 'With Icon',
            icon: Icons.add_rounded,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.s8),
          PfButton(
            label: 'Loading State',
            isLoading: true,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.s8),
          Row(
            children: [
              PfButton(
                label: 'Inline',
                onPressed: () {},
                isExpanded: false,
              ),
              const SizedBox(width: AppSpacing.s12),
              PfButton(
                label: 'Ghost',
                onPressed: () {},
                isExpanded: false,
                variant: PfButtonVariant.ghost,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s20),

          // System buttons
          Text('System Buttons', style: AppTheme.subtitle),
          const SizedBox(height: AppSpacing.s8),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded, size: AppIconSize.s20),
            label: const Text('FilledButton'),
          ),
          const SizedBox(height: AppSpacing.s8),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined, size: AppIconSize.s20),
            label: const Text('OutlinedButton'),
          ),
          const SizedBox(height: AppSpacing.s8),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.warning_amber_rounded, size: AppIconSize.s20),
            label: const Text('TextButton'),
          ),
          const SizedBox(height: AppSpacing.s20),

          // Icon buttons
          Text('Icon Buttons', style: AppTheme.subtitle),
          const SizedBox(height: AppSpacing.s8),
          Row(
            children: [
              IconButton(
                onPressed: null,
                icon: const Icon(Icons.favorite_outline_rounded),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.favorite_outline_rounded),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primaryColorTheme(context)
                      .withValues(alpha: 0.1),
                ),
              ),
              const Spacer(),
              FloatingActionButton.small(
                onPressed: () {},
                child: const Icon(Icons.add_rounded),
              ),
              const SizedBox(width: AppSpacing.s8),
              FloatingActionButton(
                onPressed: () {},
                child: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CARDS SECTION
// ═══════════════════════════════════════════════════════════════

class _CardsSection extends StatelessWidget {
  const _CardsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WidgetBookHeader(
            title: 'Cards',
            subtitle:
                'PfCard, SummaryCard, NetProfitCard, PfBalanceCard',
          ),
          const SizedBox(height: AppSpacing.s12),

          // PfCard
          Text('PfCard', style: AppTheme.subtitle),
          const _CodeBadge('PfCard'),
          const SizedBox(height: AppSpacing.s8),
          PfCard(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: const Text(
              'PfCard with custom padding. Tappable cards wrap content in InkWell.',
            ),
          ),
          const SizedBox(height: AppSpacing.s20),

          // SummaryCard
          Text('SummaryCard', style: AppTheme.subtitle),
          const _CodeBadge('SummaryCard'),
          const SizedBox(height: AppSpacing.s8),
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: 'Pemasukan',
                  amount: 50_000_000,
                  icon: Icons.trending_up_rounded,
                  color: AppTheme.profitColorTheme(context),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: SummaryCard(
                  title: 'Pengeluaran',
                  amount: 25_000_000,
                  icon: Icons.trending_down_rounded,
                  color: AppTheme.lossColorTheme(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s20),

          // NetProfitCard
          Text('NetProfitCard', style: AppTheme.subtitle),
          const _CodeBadge('NetProfitCard'),
          const SizedBox(height: AppSpacing.s8),
          const NetProfitCard(
            netProfit: 25_000_000,
            style: NetProfitCardStyle.row,
          ),
          const SizedBox(height: AppSpacing.s8),
          const NetProfitCard(
            netProfit: -5_000_000,
            style: NetProfitCardStyle.accentBar,
          ),
          const SizedBox(height: AppSpacing.s20),

          // PfBalanceCard
          Text('PfBalanceCard', style: AppTheme.subtitle),
          const _CodeBadge('PfBalanceCard'),
          const SizedBox(height: AppSpacing.s8),
          Row(
            children: [
              Expanded(
                child: PfBalanceCard(
                  title: 'Piutang',
                  amount: 15_000_000,
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppTheme.warningColorTheme(context),
                  activeCount: 5,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: PfBalanceCard(
                  title: 'Titipan',
                  amount: 8_000_000,
                  icon: Icons.inventory_2_rounded,
                  color: AppTheme.infoColorTheme(context),
                  activeCount: 3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// INPUTS SECTION
// ═══════════════════════════════════════════════════════════════

class _InputsSection extends StatefulWidget {
  const _InputsSection();

  @override
  State<_InputsSection> createState() => _InputsSectionState();
}

class _InputsSectionState extends State<_InputsSection> {
  final _enabledCtrl = TextEditingController(text: 'Teks input');
  final _disabledCtrl = TextEditingController(text: 'Input nonaktif');

  @override
  void dispose() {
    _enabledCtrl.dispose();
    _disabledCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WidgetBookHeader(
            title: 'Inputs',
            subtitle: 'TextField with various states',
          ),
          const SizedBox(height: AppSpacing.s12),

          TextField(
            controller: _enabledCtrl,
            decoration: const InputDecoration(
              labelText: 'Enabled',
              prefixIcon: Icon(Icons.person_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Focused (tap here)',
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Type something...',
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          TextField(
            controller: _disabledCtrl,
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'Disabled',
              prefixIcon: Icon(Icons.lock_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          TextField(
            decoration: InputDecoration(
              labelText: 'With Error',
              prefixIcon: const Icon(Icons.error_outline_rounded),
              errorText: 'Field ini wajib diisi',
              errorStyle: TextStyle(
                fontSize: 12,
                color: AppTheme.lossColorTheme(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// NAVIGATION SECTION
// ═══════════════════════════════════════════════════════════════

class _NavigationSection extends StatefulWidget {
  const _NavigationSection();

  @override
  State<_NavigationSection> createState() => _NavigationSectionState();
}

class _NavigationSectionState extends State<_NavigationSection> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final items = const [
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
        icon: Icons.person_outlined,
        activeIcon: Icons.person_rounded,
        label: 'Profil',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WidgetBookHeader(
            title: 'Bottom Navigation',
            subtitle:
                'PfBottomNav — shared tab bar with gradient add button',
          ),
          const SizedBox(height: AppSpacing.s8),
          const _CodeBadge('PfBottomNav'),
          const SizedBox(height: AppSpacing.s12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
              border: Border.all(
                color: AppTheme.outlineVariantColorTheme(context),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: PfBottomNav(
              selectedIndex: _selectedIndex,
              onItemSelected: (i) => setState(() => _selectedIndex = i),
              onAddPressed: () {},
              items: items,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          const _CodeHint(
            'Nav items + add button at center. Animated selection. Gradient + shadow on add.',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BADGES SECTION
// ═══════════════════════════════════════════════════════════════

class _BadgesSection extends StatelessWidget {
  const _BadgesSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WidgetBookHeader(
            title: 'Badges',
            subtitle:
                'AppBadge — role badges & profit/loss labels',
          ),
          const SizedBox(height: AppSpacing.s12),
          Text('Role Badges', style: AppTheme.subtitle),
          const _CodeBadge('AppBadge.role()'),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              AppBadge.role('owner'),
              AppBadge.role('manager'),
              AppBadge.role('staff'),
            ],
          ),
          const SizedBox(height: AppSpacing.s20),

          Text('Profit/Loss Badges', style: AppTheme.subtitle),
          const _CodeBadge('AppBadge.profitLoss()'),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              AppBadge.profitLoss(1_000_000),
              AppBadge.profitLoss(-500_000),
            ],
          ),
          const SizedBox(height: AppSpacing.s20),

          Text('Custom Badges', style: AppTheme.subtitle),
          const _CodeBadge('AppBadge(label:, color:)'),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              const AppBadge(
                label: 'AKTIF',
                color: AppTheme.success,
              ),
              const AppBadge(
                label: 'PENDING',
                color: AppTheme.warning,
              ),
              AppBadge(
                label: 'DITOLAK',
                color: AppTheme.lossColorTheme(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SKELETON SECTION
// ═══════════════════════════════════════════════════════════════

class _SkeletonSection extends StatelessWidget {
  const _SkeletonSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WidgetBookHeader(
            title: 'Skeletons',
            subtitle:
                'PfSkeleton & PfSkeletonCard — shimmer loading',
          ),
          const SizedBox(height: AppSpacing.s12),
          Text('PfSkeleton', style: AppTheme.subtitle),
          const _CodeBadge('PfSkeleton'),
          const SizedBox(height: AppSpacing.s8),
          Column(
            children: [
              const PfSkeleton(height: 14),
              const SizedBox(height: AppSpacing.s8),
              const PfSkeleton(width: 0.6, height: 12),
              const SizedBox(height: AppSpacing.s8),
              const PfSkeleton(width: 0.4, height: 12),
            ],
          ),
          const SizedBox(height: AppSpacing.s20),

          Text('PfSkeletonCard', style: AppTheme.subtitle),
          const _CodeBadge('PfSkeletonCard'),
          const SizedBox(height: AppSpacing.s8),
          const PfSkeletonCard(lines: 4),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EMPTY STATE SECTION
// ═══════════════════════════════════════════════════════════════

class _EmptyStateSection extends StatelessWidget {
  const _EmptyStateSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WidgetBookHeader(
            title: 'Empty States',
            subtitle:
                'PfEmptyState — icon + message + optional action',
          ),
          const SizedBox(height: AppSpacing.s12),
          const _CodeBadge('PfEmptyState'),
          const SizedBox(height: AppSpacing.s8),
          Container(
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
              border: Border.all(
                color: AppTheme.outlineColorTheme(context),
              ),
            ),
            child: const PfEmptyState(
              icon: Icons.inbox_rounded,
              title: 'Belum Ada Data',
              subtitle:
                  'Data akan muncul setelah Anda menambahkan transaksi pertama.',
              actionLabel: 'Tambah Transaksi',
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SECTION HEADER
// ═══════════════════════════════════════════════════════════════

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WidgetBookHeader(
            title: 'Section Headers',
            subtitle:
                'PfSectionHeader — title + optional subtitle & trailing',
          ),
          const SizedBox(height: AppSpacing.s12),
          const _CodeBadge('PfSectionHeader'),
          const SizedBox(height: AppSpacing.s8),
          const PfSectionHeader(
            title: 'Ringkasan Keuangan',
            subtitle: 'Periode Juli 2026',
          ),
          const SizedBox(height: AppSpacing.s8),
          const PfSectionHeader(
            title: 'Transaksi Terbaru',
            trailing: Text(
              'Lihat Semua',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TRANSACTION CARD
// ═══════════════════════════════════════════════════════════════

class _TransactionCardSection extends StatelessWidget {
  const _TransactionCardSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WidgetBookHeader(
            title: 'Transaction Card',
            subtitle:
                'TransactionCard — list item with icon, amount, actions',
          ),
          const SizedBox(height: AppSpacing.s12),
          const _CodeBadge('TransactionCard'),
          const SizedBox(height: AppSpacing.s8),
          TransactionCard(
            title: 'Penjualan',
            subtitle: 'Tunai • Toko Utama',
            amount: 'Rp 2.500.000',
            isIncome: true,
            icon: Icons.trending_up_rounded,
            color: AppTheme.profitColorTheme(context),
            onEdit: () {},
            onDelete: () {},
          ),
          const SizedBox(height: AppSpacing.s8),
          TransactionCard(
            title: 'Belanja Stok',
            subtitle: 'Transfer • Supplier A',
            amount: 'Rp 1.200.000',
            isIncome: false,
            icon: Icons.shopping_cart_outlined,
            color: AppTheme.lossColorTheme(context),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// QUICK ACTIONS
// ═══════════════════════════════════════════════════════════════

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WidgetBookHeader(
            title: 'Quick Actions',
            subtitle:
                'QuickActionButton — grid-friendly action tiles',
          ),
          const SizedBox(height: AppSpacing.s12),
          const _CodeBadge('QuickActionButton'),
          const SizedBox(height: AppSpacing.s8),
          Row(
            children: [
              Expanded(
                child: QuickActionButton(
                  icon: Icons.add_circle_outline,
                  label: 'Tambah Transaksi',
                  color: AppTheme.profitColorTheme(context),
                  onTap: () {},
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: QuickActionButton(
                  icon: Icons.receipt_long_outlined,
                  label: 'Titipan Harian',
                  color: AppTheme.infoColorTheme(context),
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Row(
            children: [
              Expanded(
                child: QuickActionButton(
                  icon: Icons.people_outline_rounded,
                  label: 'Piutang',
                  color: AppTheme.warningColorTheme(context),
                  onTap: () {},
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: QuickActionButton(
                  icon: Icons.bar_chart_rounded,
                  label: 'Laporan',
                  color: AppTheme.infoColorTheme(context),
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STAT ROW
// ═══════════════════════════════════════════════════════════════

class _StatRowSection extends StatelessWidget {
  const _StatRowSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WidgetBookHeader(
            title: 'Stat Rows',
            subtitle:
                'PfStatRow — label-value pairs for detail screens',
          ),
          const SizedBox(height: AppSpacing.s12),
          const _CodeBadge('PfStatRow'),
          const SizedBox(height: AppSpacing.s8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                children: [
                  const PfStatRow(label: 'Tanggal', value: '12 Juli 2026'),
                  const PfStatRow(
                      label: 'Kategori', value: 'Makanan & Minuman'),
                  const PfStatRow(
                    label: 'Status',
                    value: 'LUNAS',
                    valueColor: AppTheme.success,
                  ),
                  PfStatRow(
                    label: 'Total',
                    value: 'Rp 2.500.000',
                    valueColor: AppTheme.primaryColorTheme(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ERROR WIDGETS SECTION
// ═══════════════════════════════════════════════════════════════

class _ErrorSection extends StatelessWidget {
  const _ErrorSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WidgetBookHeader(
            title: 'Error Widgets',
            subtitle:
                'ErrorRetryWidget, OfflineBanner',
          ),
          const SizedBox(height: AppSpacing.s12),

          // OfflineBanner
          Text('OfflineBanner', style: AppTheme.subtitle),
          const _CodeBadge('OfflineBanner'),
          const SizedBox(height: AppSpacing.s8),
          const OfflineBanner(isOffline: true),
          const SizedBox(height: AppSpacing.s20),

          // ErrorRetryWidget
          Text('ErrorRetryWidget', style: AppTheme.subtitle),
          const _CodeBadge('ErrorRetryWidget'),
          const SizedBox(height: AppSpacing.s8),
          Container(
            height: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
              border: Border.all(
                color: AppTheme.outlineColorTheme(context),
              ),
            ),
            child: const ErrorRetryWidget(
              message: 'Gagal memuat data. Periksa koneksi internet Anda.',
              icon: Icons.cloud_off_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SNACKBAR DEMO SECTION
// ═══════════════════════════════════════════════════════════════

class _SnackbarSection extends StatelessWidget {
  const _SnackbarSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WidgetBookHeader(
            title: 'Snackbars',
            subtitle:
                'ErrorSnackbar — themed success / error / warning / info',
          ),
          const SizedBox(height: AppSpacing.s12),
          const _CodeBadge('ErrorSnackbar'),
          const SizedBox(height: AppSpacing.s12),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              _SnackbarButton(
                label: 'Success',
                color: AppTheme.profitColorTheme(context),
                onTap: () => ErrorSnackbar.showSuccess(
                  context,
                  'Data berhasil disimpan!',
                ),
              ),
              _SnackbarButton(
                label: 'Error',
                color: AppTheme.lossColorTheme(context),
                onTap: () => ErrorSnackbar.showError(
                  context,
                  'Gagal menyimpan data. Coba lagi.',
                ),
              ),
              _SnackbarButton(
                label: 'Warning',
                color: AppTheme.warningColorTheme(context),
                onTap: () => ErrorSnackbar.showWarning(
                  context,
                  'Koneksi tidak stabil.',
                ),
              ),
              _SnackbarButton(
                label: 'Info',
                color: AppTheme.infoColorTheme(context),
                onTap: () => ErrorSnackbar.showInfo(
                  context,
                  'Update tersedia.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SnackbarButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SnackbarButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      avatar: Icon(Icons.play_arrow_rounded, size: AppIconSize.s16, color: color),
      onPressed: onTap,
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CHART SECTION
// ═══════════════════════════════════════════════════════════════

class _ChartSection extends StatelessWidget {
  const _ChartSection();

  @override
  Widget build(BuildContext context) {
    final data = [
      const TrendDataPoint(month: '2026-01', netProfit: 5_000_000),
      const TrendDataPoint(month: '2026-02', netProfit: 7_500_000),
      const TrendDataPoint(month: '2026-03', netProfit: 4_200_000),
      const TrendDataPoint(month: '2026-04', netProfit: -1_000_000),
      const TrendDataPoint(month: '2026-05', netProfit: 6_800_000),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WidgetBookHeader(
            title: 'Chart',
            subtitle:
                'TrendChart — line chart with green/red dots',
          ),
          const SizedBox(height: AppSpacing.s12),
          const _CodeBadge('TrendChart'),
          const SizedBox(height: AppSpacing.s8),
          SizedBox(
            height: 240,
            child: TrendChart(
              data: data,
              title: 'Tren Laba/Rugi',
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ANIMATION SECTION
// ═══════════════════════════════════════════════════════════════

class _AnimationSection extends StatefulWidget {
  const _AnimationSection();

  @override
  State<_AnimationSection> createState() => _AnimationSectionState();
}

class _AnimationSectionState extends State<_AnimationSection> {
  int _demoIndex = 0;
  bool _showFadeCard = false;
  int _refreshKey = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WidgetBookHeader(
            title: 'Animations',
            subtitle:
                'FadeInEntrance, PfSlidePageView',
          ),
          const SizedBox(height: AppSpacing.s12),

          // FadeInEntrance
          Text('FadeInEntrance', style: AppTheme.subtitle),
          const _CodeBadge('FadeInEntrance'),
          const SizedBox(height: AppSpacing.s8),
          FilledButton(
            onPressed: () {
              setState(() {
                _refreshKey++;
                _showFadeCard = true;
              });
            },
            child: const Text('Refresh Demo'),
          ),
          const SizedBox(height: AppSpacing.s8),
          if (_showFadeCard)
            FadeInEntrance(
              key: ValueKey('fade_$_refreshKey'),
              child: PfCard(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColorTheme(context)
                            .withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppRadius.radiusSmall),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: AppTheme.primaryColorTheme(context),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Text(
                        'Animasi fade + slide up 400ms',
                        style: AppTheme.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.s20),

          // PfSlidePageView
          Text('PfSlidePageView', style: AppTheme.subtitle),
          const _CodeBadge('PfSlidePageView'),
          const SizedBox(height: AppSpacing.s8),
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
              border: Border.all(
                color: AppTheme.outlineColorTheme(context),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Expanded(
                  child: PfSlidePageView(
                    index: _demoIndex,
                    child: Center(
                      key: ValueKey('page_$_demoIndex'),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.s16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              [
                                Icons.dashboard_rounded,
                                Icons.history_rounded,
                                Icons.assessment_rounded,
                              ][_demoIndex],
                              size: AppIconSize.s40,
                              color: AppTheme.primaryColorTheme(context),
                            ),
                            const SizedBox(height: AppSpacing.s8),
                            Text(
                              [
                                'Halaman Dashboard',
                                'Halaman Riwayat',
                                'Halaman Laporan',
                              ][_demoIndex],
                              style: AppTheme.title,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _demoIndex > 0
                          ? () => setState(() => _demoIndex--)
                          : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Text(
                      '${_demoIndex + 1} / 3',
                      style: AppTheme.caption,
                    ),
                    IconButton(
                      onPressed: _demoIndex < 2
                          ? () => setState(() => _demoIndex++)
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SHADOW SECTION
// ═══════════════════════════════════════════════════════════════

class _ShadowSection extends StatelessWidget {
  const _ShadowSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WidgetBookHeader(
            title: 'Shadows',
            subtitle:
                'AppTheme.softShadow & AppTheme.mediumShadow',
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColorTheme(context),
                        borderRadius:
                            BorderRadius.circular(AppRadius.radiusSmall),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: const Center(
                        child: Text(
                          'softShadow',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColorTheme(context),
                        borderRadius:
                            BorderRadius.circular(AppRadius.radiusSmall),
                        boxShadow: AppTheme.mediumShadow,
                      ),
                      child: const Center(
                        child: Text(
                          'mediumShadow',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Container(
                  height: 176,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColorTheme(context),
                    borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColorTheme(context)
                            .withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Custom\naccent shadow',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SHARED HELPERS
// ═══════════════════════════════════════════════════════════════

class _WidgetBookHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _WidgetBookHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.heading3),
        const SizedBox(height: AppSpacing.s2),
        Text(subtitle,
            style: AppTheme.caption.copyWith(fontSize: 12)),
      ],
    );
  }
}

class _CodeBadge extends StatelessWidget {
  final String code;
  const _CodeBadge(this.code);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primaryColorTheme(context).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.s4),
        border: Border.all(
          color: AppTheme.primaryColorTheme(context).withValues(alpha: 0.15),
        ),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontSize: 11,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w500,
          color: AppTheme.primaryColorTheme(context),
        ),
      ),
    );
  }
}

class _CodeHint extends StatelessWidget {
  final String text;
  const _CodeHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHighestColorTheme(context)
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: AppIconSize.s16,
            color: AppTheme.onSurfaceVariantColorTheme(context),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.onSurfaceVariantColorTheme(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
