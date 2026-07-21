import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
import '../../core/utils/format_helpers.dart';

class OwnerActivityLogsScreen extends StatefulWidget {
  const OwnerActivityLogsScreen({super.key});

  @override
  State<OwnerActivityLogsScreen> createState() =>
      _OwnerActivityLogsScreenState();
}

class _OwnerActivityLogsScreenState extends State<OwnerActivityLogsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Selection mode
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  void _enterSelectionMode(String logId) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.clear();
      _selectedIds.add(logId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String logId) {
    setState(() {
      if (_selectedIds.contains(logId)) {
        _selectedIds.remove(logId);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(logId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedIds.length == _logs.length) {
        _selectedIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedIds.addAll(_logs.map((l) => l['id'] as String));
      }
    });
  }

  Future<void> _fetchLogs() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await _supabase
          .from('owner_activity_logs')
          .select('*, businesses(name)')
          .order('created_at', ascending: false)
          .limit(100);

      setState(() {
        _logs = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat log aktivitas: $e';
      });
    }
  }

  // ── Delete Logic ────────────────────────────────────────────

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        ),
        title: const Text('Hapus Notifikasi'),
        content: Text('Yakin ingin menghapus $count notifikasi terpilih?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.lossColorTheme(context),
              foregroundColor: AppTheme.onDangerColorTheme(context),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final ids = _selectedIds.toList();
        await _supabase
            .from('owner_activity_logs')
            .delete()
            .inFilter('id', ids);
        setState(() {
          _logs.removeWhere((l) => _selectedIds.contains(l['id']));
          _selectedIds.clear();
          _isSelectionMode = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$count notifikasi dihapus'),
              backgroundColor: AppTheme.lossColorTheme(context),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus: $e'),
              backgroundColor: AppTheme.lossColorTheme(context),
            ),
          );
        }
      }
    }
  }

  // ── Helpers ─────────────────────────────────────────────────

  IconData _getLogIcon(String tableName, String actionType) {
    if (tableName == 'transactions') {
      return Icons.receipt_long_rounded;
    } else if (tableName == 'debts') {
      return Icons.payment_rounded;
    } else {
      return Icons.inventory_2_rounded;
    }
  }

  Color _getLogIconColor(
    BuildContext context,
    String tableName,
    String actionType,
  ) {
    if (actionType == 'DELETE') {
      return AppTheme.lossColorTheme(context);
    }
    if (tableName == 'transactions') {
      return AppTheme.primaryColorTheme(context);
    } else if (tableName == 'debts') {
      return AppTheme.warningColorTheme(context);
    } else {
      return AppTheme.consignmentColorTheme(context);
    }
  }

  String _formatLogDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) {
        return 'Baru saja';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} menit yang lalu';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} jam yang lalu';
      } else if (diff.inDays == 1) {
        return 'Kemarin, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        return '${date.day} ${FormatHelpers.displayDate(dateStr).split(' ')[1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      return dateStr;
    }
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildError()
          : _logs.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _fetchLogs,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.s8),
                itemCount: _logs.length,
                itemBuilder: (context, index) => _buildLogCard(_logs[index]),
              ),
            ),
      bottomNavigationBar: _isSelectionMode ? _buildSelectionBottomBar() : null,
    );
  }

  PreferredSizeWidget _buildNormalAppBar() {
    return AppBar(
      title: const Text('Kotak Masuk Aktivitas'),
    );
  }

  PreferredSizeWidget _buildSelectionAppBar() {
    final allSelected = _selectedIds.length == _logs.length;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: _exitSelectionMode,
      ),
      title: Text(
        '${_selectedIds.length} dipilih',
        style: TextStyle(
          color: AppTheme.onSurfaceColorTheme(context),
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          tooltip: allSelected ? 'Batalkan Semua' : 'Pilih Semua',
          icon: Icon(
            allSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
            color: AppTheme.onSurfaceColorTheme(context),
          ),
          onPressed: _selectAll,
        ),
        IconButton(
          tooltip: 'Hapus Terpilih',
          icon: Icon(
            Icons.delete_rounded,
            color: AppTheme.lossColorTheme(context),
          ),
          onPressed: _deleteSelected,
        ),
      ],
    );
  }

  Widget _buildSelectionBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColorTheme(context),
        border: Border(
          top: BorderSide(
            color: AppTheme.outlineVariantColorTheme(context),
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.s20,
        right: AppSpacing.s20,
        top: AppSpacing.s12,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.s12,
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _deleteSelected,
          icon: const Icon(Icons.delete_rounded, size: 20),
          label: Text('Hapus (${_selectedIds.length}) Notifikasi'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.lossColorTheme(context),
            foregroundColor: AppTheme.onDangerColorTheme(context),
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppTheme.lossColorTheme(context),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.onSurfaceColorTheme(context)),
            ),
            const SizedBox(height: AppSpacing.s16),
            ElevatedButton(
              onPressed: _fetchLogs,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 48,
              color: AppTheme.onSurfaceVariantColorTheme(
                context,
              ).withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              'Belum ada aktivitas tercatat',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.onSurfaceVariantColorTheme(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final logId = log['id'] as String;
    final business = log['businesses'] as Map<String, dynamic>?;
    final businessName = business?['name'] as String? ?? 'Bisnis';
    final dateStr = log['created_at'] as String;
    final isSelected = _selectedIds.contains(logId);

    return Dismissible(
      key: ValueKey(logId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
            ),
            title: const Text('Hapus Notifikasi'),
            content: const Text('Yakin ingin menghapus notifikasi ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.lossColorTheme(context),
                  foregroundColor: AppTheme.onDangerColorTheme(context),
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (_) async {
        try {
          await _supabase.from('owner_activity_logs').delete().eq('id', logId);
          setState(() {
            _logs.removeWhere((l) => l['id'] == logId);
            _selectedIds.remove(logId);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Notifikasi dihapus'),
                backgroundColor: AppTheme.lossColorTheme(context),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal menghapus: $e'),
                backgroundColor: AppTheme.lossColorTheme(context),
              ),
            );
          }
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.s24),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          color: AppTheme.lossColorTheme(context),
          borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
      child: GestureDetector(
      onLongPress: () {
        if (!_isSelectionMode) {
          _enterSelectionMode(logId);
        }
      },
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(logId);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
          side: BorderSide(
            color: isSelected
                ? AppTheme.primaryColorTheme(context)
                : Colors.transparent,
            width: 2,
          ),
        ),
        color: isSelected
            ? AppTheme.primaryColorTheme(context).withValues(alpha: 0.08)
            : AppTheme.surfaceColorTheme(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selection checkbox or icon
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.s8),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 22,
                    color: isSelected
                        ? AppTheme.primaryColorTheme(context)
                        : AppTheme.onSurfaceVariantColorTheme(context),
                  ),
                )
              else
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _getLogIconColor(
                      context,
                      log['table_name'],
                      log['action_type'],
                    ).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getLogIcon(log['table_name'], log['action_type']),
                    size: 18,
                    color: _getLogIconColor(
                      context,
                      log['table_name'],
                      log['action_type'],
                    ),
                  ),
                ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            log['title'] as String? ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.onSurfaceColorTheme(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Text(
                          _formatLogDate(dateStr),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.onSurfaceVariantColorTheme(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log['body'] as String? ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurfaceColorTheme(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      businessName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariantColorTheme(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
