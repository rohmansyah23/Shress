import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/error_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/skeleton_widgets.dart';
import '../../data/local/models/business_model.dart';
import '../../data/local/models/user_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/auth_provider.dart';

/// Provider that fetches all users directly from Supabase (cloud-only)
final allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final repo = ref.read(authRepositoryProvider);
  return repo.getAllUsers();
});

/// Provider for a specific user's business assignments (Supabase cloud)
final userBusinessIdsProvider =
    FutureProvider.family<Set<int>, String>((ref, userId) async {
  final ids = await SupabaseService.instance.getBusinessIdsForUser(userId);
  return ids.toSet();
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

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return Column(
      children: [
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
                          size: 64, color: Colors.grey.shade400),
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
                      onRoleChanged: (newRole) =>
                          _handleRoleChange(user, newRole),
                      onBusinessesChanged: (selectedIds) =>
                          _handleBusinessAssign(user, selectedIds),
                    );
                  },
                ),
              );
            },
            loading: () => const SkeletonUserList(),
            error: (error, _) => ErrorRetryWidget(
              message: ErrorHandler.classify(error).userMessage,
              onRetry: () => ref.invalidate(allUsersProvider),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Akses bisnis untuk ${user.username} diperbarui'),
          backgroundColor: AppTheme.profitColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignedIdsAsync = ref.watch(userBusinessIdsProvider(user.userId));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _roleColor(user.role).withValues(alpha: 0.15),
                  child: Text(_roleEmoji(user.role),
                      style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
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
                          color: Colors.black87),
                      items: const [
                        DropdownMenuItem(
                            value: 'owner',
                            child: Text('👑 Owner')),
                        DropdownMenuItem(
                            value: 'manager',
                            child: Text('📋 Manager')),
                        DropdownMenuItem(
                            value: 'staff',
                            child: Text('👤 Staff')),
                      ],
                      onChanged: (value) {
                        if (value != null) onRoleChanged(value);
                      },
                    ),
                  ),
                ),
              ],
            ),

            if (user.role != AppConstants.roleOwner) ...[
              const Divider(height: 24),
              Text('Akses ke Bisnis:',
                  style: AppTheme.caption.copyWith(
                      fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 8),

              // Show assigned IDs when loading
              assignedIdsAsync.when(
                data: (assignedIds) {
                  if (businesses.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('Belum ada bisnis',
                          style:
                              AppTheme.caption.copyWith(fontSize: 12)),
                    );
                  }
                  return Column(
                    children: businesses.map((biz) {
                      final isChecked = assignedIds.contains(biz.businessId);
                      return CheckboxListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: EdgeInsets.zero,
                        title: Text(biz.name,
                            style: const TextStyle(fontSize: 13)),
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
                    }).toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(8),
                  child: LinearProgressIndicator(),
                ),
                error: (e, _) => Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    ErrorHandler.classify(e).userMessage,
                    style: AppTheme.caption.copyWith(color: AppTheme.lossColor),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

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
