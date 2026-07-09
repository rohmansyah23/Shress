import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/database.dart';
import '../../data/local/models/business_model.dart';
import '../../data/local/models/user_model.dart';
import '../../providers/auth_provider.dart';

/// Provider that fetches all users (from server, falling back to local cache)
final allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final repo = ref.read(authRepositoryProvider);
  return repo.getAllUsers();
});

/// Provider for a specific user's business assignments (sync - Hive reads)
final userBusinessIdsProvider =
    Provider.family<Set<int>, String>((ref, userId) {
  ref.watch(userManagementRefreshProvider);
  final assignments = LocalDatabase.instance.getBusinessesForUser(userId);
  return assignments.map((e) => e.businessId).toSet();
});

/// Trigger to refresh user data
final userManagementRefreshProvider = StateProvider<int>((ref) => 0);

/// Complete User/RBAC Management Panel for Owner
class UserManagementPanel extends ConsumerStatefulWidget {
  const UserManagementPanel({super.key});

  @override
  ConsumerState<UserManagementPanel> createState() =>
      _UserManagementPanelState();
}

class _UserManagementPanelState extends ConsumerState<UserManagementPanel> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);
    final businesses = LocalDatabase.instance.getAllBusinesses();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
          ),
        ),

        // User list
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
                      Icon(
                        Icons.person_search_rounded,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
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
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    return _UserCard(
                      key: ValueKey(user.userId),
                      user: user,
                      businesses: businesses,
                      onRoleChanged: (newRole) =>
                          _handleRoleChange(user, newRole),
                      onBusinessesChanged: (selectedIds) =>
                          _handleBusinessAssign(user, selectedIds),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppTheme.lossColor),
                  const SizedBox(height: 16),
                  Text('Gagal memuat user', style: AppTheme.caption),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(allUsersProvider),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRoleChange(UserModel user, String newRole) async {
    if (user.role == newRole) return;

    try {
      final repo = ref.read(authRepositoryProvider);

      await repo.updateUserRole(userId: user.userId, newRole: newRole);

      if (!mounted) return;
      ref.invalidate(allUsersProvider);

      // If role changed from manager/staff to owner, clear business assignments
      if (newRole == AppConstants.roleOwner) {
        final assignments =
            LocalDatabase.instance.getBusinessesForUser(user.userId);
        for (final a in assignments) {
          await repo.unassignUserFromBusiness(
            userId: user.userId,
            businessId: a.businessId,
          );
        }
        ref.read(userManagementRefreshProvider.notifier).state++;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Role ${user.username} diubah ke ${_roleLabel(newRole)}'),
          backgroundColor: AppTheme.profitColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah role: $e'),
          backgroundColor: AppTheme.lossColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
      ref.read(userManagementRefreshProvider.notifier).state++;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Akses bisnis untuk ${user.username} diperbarui'),
          backgroundColor: AppTheme.profitColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui akses: $e'),
          backgroundColor: AppTheme.lossColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
}

/// Individual user card with role and business assignment controls
class _UserCard extends ConsumerWidget {
  final UserModel user;
  final List<BusinessModel> businesses;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<Set<int>> onBusinessesChanged;

  const _UserCard({
    super.key,
    required this.user,
    required this.businesses,
    required this.onRoleChanged,
    required this.onBusinessesChanged,
  });

  Color _roleColor(String role) {
    switch (role) {
      case AppConstants.roleOwner:
        return AppTheme.primaryColor;
      case AppConstants.roleManager:
        return AppTheme.infoColor;
      case AppConstants.roleStaff:
        return AppTheme.secondaryColor;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignedIds = ref.watch(userBusinessIdsProvider(user.userId));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User header row
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      _roleColor(user.role).withValues(alpha: 0.15),
                  child: Text(
                    _roleEmoji(user.role),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.username, style: AppTheme.heading3),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${user.userId.length > 12 ? '${user.userId.substring(0, 12)}...' : user.userId}',
                        style: AppTheme.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),

                // Role dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: user.role,
                      icon: const Icon(Icons.arrow_drop_down, size: 20),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'owner',
                          child: Text('👑 Owner'),
                        ),
                        DropdownMenuItem(
                          value: 'manager',
                          child: Text('📋 Manager'),
                        ),
                        DropdownMenuItem(
                          value: 'staff',
                          child: Text('👤 Staff'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) onRoleChanged(value);
                      },
                    ),
                  ),
                ),
              ],
            ),

            // Business assignment (only for Manager/Staff)
            if (user.role != AppConstants.roleOwner) ...[
              const Divider(height: 24),
              Text(
                'Akses ke Bisnis:',
                style: AppTheme.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),

              if (businesses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Belum ada bisnis',
                    style: AppTheme.caption.copyWith(fontSize: 12),
                  ),
                )
              else
                ...businesses.map((biz) {
                  final isChecked = assignedIds.contains(biz.businessId);
                  return CheckboxListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                    title: Text(biz.name, style: const TextStyle(fontSize: 13)),
                    value: isChecked,
                    onChanged: (checked) {
                      final updated = Set<int>.from(assignedIds);
                      if (checked == true) {
                        updated.add(biz.businessId);
                      } else {
                        updated.remove(biz.businessId);
                      }
                      onBusinessesChanged(updated);
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }

  String _roleEmoji(String role) {
    switch (role) {
      case AppConstants.roleOwner:
        return '👑';
      case AppConstants.roleManager:
        return '📋';
      case AppConstants.roleStaff:
        return '👤';
      default:
        return '❓';
    }
  }
}
