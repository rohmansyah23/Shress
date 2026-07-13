import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/format_helpers.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/widgets/summary_card.dart' as summary_card;
import '../../data/local/models/business_model.dart';
import '../../data/local/models/debtor_model.dart';
import '../../providers/debtor_provider.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/debt_consignment_provider.dart';
import 'add_debt_screen.dart';
import 'debtor_detail_screen.dart';

String _getInitials(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.isEmpty) return '?';
  if (words.length == 1) return words[0][0].toUpperCase();
  return '${words[0][0]}${words[1][0]}'.toUpperCase();
}

class DebtorsScreen extends ConsumerWidget {
  final BusinessModel business;

  const DebtorsScreen({super.key, required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtorAsync = ref.watch(debtorProvider(business.businessId));

    return debtorAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Piutang')),
        body: ErrorRetryWidget(
          message: ErrorHandler.classify(e).userMessage,
          onRetry: () => ref.refresh(debtorProvider(business.businessId)),
        ),
      ),
      data: (data) {
        final debtors = data.debtors;
        final summary = data.summary;
        final debtorTotals = data.debtorTotals;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Piutang'),
          ),
          body: RefreshIndicator(
            onRefresh: () async => await ref.refresh(debtorProvider(business.businessId)),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.s12,
                      AppTheme.s16,
                      AppTheme.s12,
                      0,
                    ),
                    child: summary_card.SummaryCard(
                      title: 'Ringkasan Piutang',
                      titleIcon: Icons.account_balance_wallet_outlined,
                      titleIconColor: AppTheme.infoColorTheme(context),
                      summary: summary,
                    ),
                  ),
                ),
                if (debtors.isEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height - 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: AppTheme.s8),
                            Text(
                              'Belum ada penghutang',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: AppTheme.s12),
                            Text(
                              'Tekan + untuk menambah hutang baru',
                              style: AppTheme.caption.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final debtor = debtors[index];
                        final total = debtorTotals[debtor.id] ?? 0;
                        return FadeInEntrance(
                          delay: Duration(milliseconds: index * 50),
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: AppTheme.s12,
                              right: AppTheme.s12,
                              bottom: AppTheme.s8,
                              top: index == 0 ? AppTheme.s8 : 0,
                            ),
                            child: _DebtorCard(
                              debtor: debtor,
                              remainingAmount: total,
                              onTap: () async {
                                final needRefresh = await Navigator.of(context).push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) => DebtorDetailScreen(
                                      debtor: debtor,
                                      business: business,
                                    ),
                                  ),
                                );
                                if (needRefresh == true) {
                                  ref.invalidate(debtorProvider(business.businessId));
                                }
                              },
                              onEdit: () => _editDebtor(context, ref, debtor),
                              onDelete: () => _deleteDebtor(context, ref, debtor),
                            ),
                          ),
                        );
                      },
                      childCount: debtors.length,
                    ),
                  ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: EdgeInsets.fromLTRB(
              AppTheme.s16,
              0,
              AppTheme.s16,
              MediaQuery.of(context).viewInsets.bottom + AppTheme.s16,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => AddDebtScreen(business: business),
                    ),
                  );
                  if (result == true) {
                    ref.invalidate(debtorProvider(business.businessId));
                  }
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Tambah Hutang',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _editDebtor(
    BuildContext context,
    WidgetRef ref,
    DebtorModel debtor,
  ) async {
    final nameController = TextEditingController(text: debtor.name);
    final phoneController = TextEditingController(text: debtor.phone ?? '');
    final notesController = TextEditingController(text: debtor.notes ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: const Text('Edit Penghutang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            const SizedBox(height: AppTheme.s12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Telepon'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppTheme.s12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Catatan'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await SupabaseService.instance.updateDebtor(
                  debtorId: debtor.id,
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim().isEmpty
                      ? null
                      : phoneController.text.trim(),
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx, true);
              } catch (e) {
                if (!ctx.mounted) return;
                ErrorSnackbar.show(ctx, ErrorHandler.classify(e));
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result == true) {
      ref.invalidate(debtorProvider(business.businessId));
      triggerDebtRefresh(ref);
      if (!context.mounted) return;
      ErrorSnackbar.showSuccess(context, 'Penghutang berhasil diperbarui');
    }
  }

  Future<void> _deleteDebtor(
    BuildContext context,
    WidgetRef ref,
    DebtorModel debtor,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: const Text('Hapus Penghutang'),
        content: Text(
          'Yakin ingin menghapus ${debtor.name}? Semua data hutang terkait juga akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.lossColorTheme(context),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.instance.deleteDebtor(debtor.id);
        ref.invalidate(debtorProvider(business.businessId));
        triggerDebtRefresh(ref);
        if (!context.mounted) return;
        ErrorSnackbar.showSuccess(context, 'Penghutang berhasil dihapus');
      } catch (e) {
        if (!context.mounted) return;
        ErrorSnackbar.show(context, ErrorHandler.classify(e));
      }
    }
  }
}

class _DebtorCard extends StatelessWidget {
  final DebtorModel debtor;
  final double remainingAmount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DebtorCard({
    required this.debtor,
    required this.remainingAmount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.s12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.warningColorTheme(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                alignment: Alignment.center,
                child: Text(
                  _getInitials(debtor.name),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.warningColorTheme(context),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.s12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debtor.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (debtor.phone != null && debtor.phone!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          debtor.phone!,
                          style: AppTheme.caption.copyWith(fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Sisa Hutang',
                    style: AppTheme.caption.copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: AppTheme.s4),
                  Text(
                    FormatHelpers.rupiah(remainingAmount),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: remainingAmount > 0
                          ? AppTheme.lossColorTheme(context)
                          : AppTheme.profitColorTheme(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppTheme.s4),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: AppTheme.s8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppTheme.lossColorTheme(context),
                        ),
                        const SizedBox(width: AppTheme.s8),
                        Text(
                          'Hapus',
                          style: TextStyle(color: AppTheme.lossColorTheme(context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}