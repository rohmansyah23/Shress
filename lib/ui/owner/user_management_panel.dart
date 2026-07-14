import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/error_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/error_widgets.dart';
import '../../data/local/models/business_model.dart';
import '../../data/local/models/user_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/auth_provider.dart';
import 'user_form_screen.dart';

final userBusinessIdsProvider =
    FutureProvider.family<Set<int>, String>((ref, userId) async {
  final ids = await SupabaseService.instance.getBusinessIdsForUser(userId);
  return ids.toSet();
});

final userManagementRefreshProvider = StateProvider<int>((ref) => 0);

class UserManagementPanel extends ConsumerStatefulWidget {
  final bool showAppBar;

  const UserManagementPanel({super.key, this.showAppBar = true});

  @override
  ConsumerState<UserManagementPanel> createState() =>
      _UserManagementPanelState();
}

class _UserManagementPanelState extends ConsumerState<UserManagementPanel> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<BusinessModel> _businesses = [];

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinesses() async {
    final businesses = await SupabaseService.instance.getAllBusinesses();
    if (mounted) setState(() => _businesses = businesses);
  }

  Future<void> _openAddUser() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const UserFormScreen()),
    );
    if (result == true) {
      ref.invalidate(allUsersProvider);
    }
  }

  Future<void> _openEditUser(UserModel user) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => UserFormScreen(user: user)),
    );
    if (result == true) {
      ref.invalidate(allUsersProvider);
    }
  }

  Future<void> _handleRoleChange(UserModel user, String newRole) async {
    if (user.role == newRole) return;
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.updateUserRole(userId: user.userId, newRole: newRole);
      if (!mounted) return;
      ref.invalidate(allUsersProvider);

      if (newRole == AppConstants.roleOwner) {
        final assignments =
            await SupabaseService.instance.getBusinessIdsForUser(user.userId);
        for (final businessId in assignments) {
          await repo.unassignUserFromBusiness(
            userId: user.userId,
            businessId: businessId,
          );
        }
        ref.read(userManagementRefreshProvider.notifier).state++;
      }

      if (!mounted) return;
      ErrorSnackbar.showSuccess(
          context, 'Role ${user.username} diubah ke ${_roleLabel(newRole)}');
    } catch (e) {
      if (!mounted) return;
      ErrorSnackbar.show(context, ErrorHandler.classify(e));
    }
  }

  Future<void> _handleBusinessAssign(
      UserModel user, Set<int> selectedIds) async {
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.syncUserBusinessAssignments(
        userId: user.userId,
        assignedBusinessIds: selectedIds.toList(),
      );
      if (!mounted) return;
      ref.invalidate(allUsersProvider);
      ref.invalidate(userBusinessIdsProvider(user.userId));
      if (!mounted) return;
      ErrorSnackbar.showSuccess(
          context, 'Akses bisnis untuk ${user.username} diperbarui');
    } catch (e) {
      if (!mounted) return;
      ErrorSnackbar.show(context, ErrorHandler.classify(e));
    }
  }

  Future<void> _confirmDeleteUser(UserModel user) async {
    if (user.role == AppConstants.roleOwner) {
      ErrorSnackbar.showMessage(context, 'Tidak dapat menghapus Owner');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
        title: const Text('Hapus User'),
        content: Text('Yakin ingin menghapus user "${user.username}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.lossColorTheme(context),
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.deleteUser(user.userId);
      if (!mounted) return;
      ref.invalidate(allUsersProvider);
      ErrorSnackbar.showSuccess(
          context, 'User "${user.username}" berhasil dihapus');
    } catch (e) {
      if (!mounted) return;
      ErrorSnackbar.show(context, ErrorHandler.classify(e));
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case AppConstants.roleOwner:
        return 'Owner';
      case AppConstants.roleManager:
        return 'Manager';
      case AppConstants.roleStaff:
        return 'Staff';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    final body = _buildBody(usersAsync);
    if (!widget.showAppBar) return body;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),

      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddUser,
        child: const Icon(Icons.person_add_rounded),
      ),
      body: body,
    );
  }

  Widget _buildBody(AsyncValue<List<UserModel>> usersAsync) {
    return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari user...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: usersAsync.when(
              data: (users) {
                final filtered = users.where((u) {
                  if (_searchQuery.isEmpty) return true;
                  return u.username.toLowerCase().contains(_searchQuery) ||
                      u.role.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search_rounded,
                            size: 64, color: AppTheme.secondaryText),
                        const SizedBox(height: AppTheme.s16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Tidak ada user ditemukan'
                              : 'Belum ada user terdaftar',
                          style: AppTheme.caption.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(allUsersProvider);
                    ref.read(userManagementRefreshProvider.notifier).state++;
                    await _loadBusinesses();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final user = filtered[index];
                      return _UserCard(
                        key: ValueKey(user.userId),
                        user: user,
                        businesses: _businesses,
                        onTap: () => _openEditUser(user),
                        onEdit: () => _openEditUser(user),
                        onRoleChanged: (newRole) =>
                            _handleRoleChange(user, newRole),
                        onBusinessesChanged: (selectedIds) =>
                            _handleBusinessAssign(user, selectedIds),
                        onDelete: () => _confirmDeleteUser(user),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorRetryWidget(
                message: ErrorHandler.classify(error).userMessage,
                onRetry: () => ref.invalidate(allUsersProvider),
              ),
            ),
          ),
      ],
    );
  }
}

class _UserCard extends ConsumerWidget {
  final UserModel user;
  final List<BusinessModel> businesses;
  final VoidCallback? onTap;
  final VoidCallback onEdit;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<Set<int>> onBusinessesChanged;
  final VoidCallback onDelete;

  const _UserCard({
    super.key,
    required this.user,
    required this.businesses,
    this.onTap,
    required this.onEdit,
    required this.onRoleChanged,
    required this.onBusinessesChanged,
    required this.onDelete,
  });

  Color _roleColor(BuildContext context, String role) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lightColor = AppBadge.roleColor(role);
    if (!isDark) return lightColor;
    // Dark mode: use lighter variants for contrast
    switch (role) {
      case AppConstants.roleOwner:
        return const Color(0xFFFFB74D); // lighter amber
      case AppConstants.roleManager:
        return const Color(0xFF64B5F6); // lighter blue
      case AppConstants.roleStaff:
        return const Color(0xFF80CBC4); // lighter teal
      default:
        return Colors.grey;
    }
  }

  String _initials(String username) {
    final parts = username.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return username.length >= 2
        ? username.substring(0, 2).toUpperCase()
        : username.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignedIdsAsync = ref.watch(userBusinessIdsProvider(user.userId));

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.s16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      _roleColor(context, user.role).withValues(alpha: 0.15),
                  child: Text(
                    _initials(user.displayName?.isNotEmpty == true
                        ? user.displayName!
                        : user.username),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _roleColor(context, user.role),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName?.isNotEmpty == true
                            ? user.displayName!
                            : user.username,
                        style: AppTheme.heading3,
                      ),
                      if (user.displayName?.isNotEmpty == true)
                        Text(
                          '@${user.username}',
                          style: AppTheme.caption.copyWith(fontSize: 12),
                        ),
                      const SizedBox(height: 2),
                      AppBadge.role(user.role),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit User'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline_rounded,
                            color: AppTheme.lossColorTheme(context)),
                        title: Text('Hapus User',
                            style: TextStyle(
                                color: AppTheme.lossColorTheme(context))),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (user.role != AppConstants.roleOwner) ...[
            const SizedBox(height: AppTheme.s4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('Role:',
                      style: AppTheme.caption.copyWith(fontSize: 12)),
                  const SizedBox(width: AppTheme.s8),
                  SizedBox(
                    height: 32,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: user.role,
                        icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _roleColor(context, user.role)),
                        items: const [
                          DropdownMenuItem(
                              value: 'manager',
                              child: Text('Manager')),
                          DropdownMenuItem(
                              value: 'staff',
                              child: Text('Staff')),
                        ],
                        onChanged: (value) {
                          if (value != null) onRoleChanged(value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Akses ke Bisnis:',
                  style: AppTheme.caption.copyWith(
                      fontWeight: FontWeight.w600, fontSize: 12)),
            ),
            const SizedBox(height: AppTheme.s4),
            assignedIdsAsync.when(
              data: (assignedIds) {
                if (businesses.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.all(AppTheme.s16),
                    child: Text('Belum ada bisnis',
                        style: AppTheme.caption),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: businesses.map((biz) {
                      final isChecked = assignedIds.contains(biz.businessId);
                      return FilterChip(
                        label: Text(biz.name, style: const TextStyle(fontSize: 12)),
                        selected: isChecked,
                        onSelected: (checked) {
                          final updated = Set<int>.from(assignedIds);
                          if (checked) {
                            updated.add(biz.businessId);
                          } else {
                            updated.remove(biz.businessId);
                          }
                          onBusinessesChanged(updated);
                        },
                        showCheckmark: true,
                        selectedColor:
                            _roleColor(context, user.role).withValues(alpha: 0.15),
                        checkmarkColor: _roleColor(context, user.role),
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  ErrorHandler.classify(e).userMessage,
                  style:
                      AppTheme.caption.copyWith(color: AppTheme.lossColor),
                ),
              ),
            ),
          ] else
            const SizedBox(height: AppTheme.s12),
        ],
      ),
      ),
    );
  }
}
