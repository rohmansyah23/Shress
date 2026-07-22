import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
import '../../core/utils/format_helpers.dart';
import '../../providers/auth_provider.dart';

class StaffNotificationScreen extends ConsumerStatefulWidget {
  const StaffNotificationScreen({super.key});

  @override
  ConsumerState<StaffNotificationScreen> createState() =>
      _StaffNotificationScreenState();
}

class _StaffNotificationScreenState
    extends ConsumerState<StaffNotificationScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Selection mode
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  // Sender name cache
  final Map<String, String> _senderNameCache = {};

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // ── Selection ──────────────────────────────────────────────

  void _enterSelectionMode(String id) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.clear();
      _selectedIds.add(id);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedIds.length == _notifications.length) {
        _selectedIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedIds.addAll(_notifications.map((n) => n['id'] as String));
      }
    });
  }

  // ── Data ───────────────────────────────────────────────────

  Future<void> _fetchNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = ref.read(currentUserProvider);
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sesi tidak valid';
        });
        return;
      }

      final userRole = user.role;

      // Fetch all notifications targeted to this user's role
      final response = await _supabase
          .from('owner_notifications')
          .select()
          .or('target_role.eq.all,target_role.eq.$userRole')
          .order('created_at', ascending: false)
          .limit(100);

      // Client-side filter: check target_user_ids
      final filtered = (response as List).where((n) {
        final targetIds = n['target_user_ids'];
        if (targetIds == null || (targetIds as List).isEmpty) return true;
        return targetIds.contains(user.userId);
      }).toList();

      // Resolve sender names
      final senderIds = filtered
          .map((n) => n['sender_id'] as String)
          .toSet()
          .toList();
      if (senderIds.isNotEmpty) {
        await _resolveSenderNames(senderIds);
      }

      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(filtered);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat notifikasi: $e';
        });
      }
    }
  }

  Future<void> _resolveSenderNames(List<String> senderIds) async {
    try {
      final users = await _supabase
          .from('users')
          .select('id, display_name, username')
          .inFilter('id', senderIds);

      for (final u in users) {
        final id = u['id'] as String;
        final name =
            (u['display_name'] as String?) ??
            (u['username'] as String?) ??
            'Pemilik';
        _senderNameCache[id] = name;
      }
    } catch (_) {}
  }

  String _getSenderName(String senderId) {
    return _senderNameCache[senderId] ?? 'Pemilik';
  }

  // ── Delete Logic ───────────────────────────────────────────

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        ),
        title: const Text('Hapus Pesan'),
        content: Text('Yakin ingin menghapus $count pesan terpilih?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          PfButton(
            label: 'Hapus',
            variant: PfButtonVariant.danger,
            isExpanded: false,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final ids = _selectedIds.toList();
        await _supabase
            .from('owner_notifications')
            .delete()
            .inFilter('id', ids);
        setState(() {
          _notifications.removeWhere((n) => _selectedIds.contains(n['id']));
          _selectedIds.clear();
          _isSelectionMode = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$count pesan dihapus'),
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

  // ── Helpers ────────────────────────────────────────────────

  String _formatDate(String dateStr) {
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

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildError()
          : _notifications.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.s8),
                itemCount: _notifications.length,
                itemBuilder: (context, index) =>
                    _buildNotificationCard(_notifications[index]),
              ),
            ),
      bottomNavigationBar: _isSelectionMode ? _buildSelectionBottomBar() : null,
    );
  }

  PreferredSizeWidget _buildNormalAppBar() {
    return AppBar(
      title: const Text('Kotak Masuk'),
    );
  }

  PreferredSizeWidget _buildSelectionAppBar() {
    final allSelected = _selectedIds.length == _notifications.length;
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
      child: PfButton(
        label: 'Hapus (${_selectedIds.length}) Pesan',
        icon: Icons.delete_rounded,
        variant: PfButtonVariant.danger,
        onPressed: _deleteSelected,
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
              onPressed: _fetchNotifications,
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
              Icons.mail_outline_rounded,
              size: 48,
              color: AppTheme.onSurfaceVariantColorTheme(
                context,
              ).withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              'Belum ada pesan dari pemilik',
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

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final id = notification['id'] as String;
    final senderId = notification['sender_id'] as String;
    final title = notification['title'] as String? ?? '';
    final body = notification['body'] as String? ?? '';
    final dateStr = notification['created_at'] as String;
    final isSelected = _selectedIds.contains(id);
    final senderName = _getSenderName(senderId);

    return Dismissible(
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
            ),
            title: const Text('Hapus Pesan'),
            content: const Text('Yakin ingin menghapus pesan ini?'),
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
          await _supabase.from('owner_notifications').delete().eq('id', id);
          setState(() {
            _notifications.removeWhere((n) => n['id'] == id);
            _selectedIds.remove(id);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Pesan dihapus'),
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
        if (!_isSelectionMode) _enterSelectionMode(id);
      },
      onTap: () {
        if (_isSelectionMode) _toggleSelection(id);
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
                    color: AppTheme.primaryColorTheme(
                      context,
                    ).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.campaign_rounded,
                    size: 18,
                    color: AppTheme.primaryColorTheme(context),
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
                            title,
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
                          _formatDate(dateStr),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.onSurfaceVariantColorTheme(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurfaceColorTheme(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'Dari: $senderName',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariantColorTheme(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
