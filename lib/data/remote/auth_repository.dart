import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/constants.dart';
import 'supabase_service.dart';
import '../local/models/business_model.dart';
import '../local/models/user_model.dart';

/// Repository handling all Supabase Auth operations — cloud only.
/// No LocalDatabase/Hive writes. All data fetched from Supabase on demand.
class AuthRepository {
  final SupabaseClient _supabase;
  final SupabaseService _supaService;

  AuthRepository({
    required this._supabase,
    required this._supaService,
  });

  /// Current authenticated user (from Supabase)
  User? get currentSupabaseUser => null;

  /// Current session
  Session? get currentSession => null;

  /// Whether a user is currently authenticated
  bool get isAuthenticated => false;

  /// Sign in with email and password.
  /// Returns the authenticated UserModel on success.
  Future<UserModel> signIn({
    required String identifier,
    required String password,
  }) async {
    try {
      final result = await _supabase.rpc('verify_public_password', params: {
        'p_identifier': identifier,
        'p_password': password,
      });

      if (result == null) {
        throw const AuthException('invalid login credentials');
      }

      final userId = result as String;
      final profileData = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      final user = UserModel(
        userId: userId,
        username: profileData['username'] as String? ?? identifier.split('@').first,
        role: profileData['role'] as String? ?? 'staff',
        displayName: profileData['display_name'] as String?,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keySessionUser, jsonEncode(user.toMap()));

      return user;
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw const AuthException('invalid login credentials');
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keySessionUser);
  }

  /// Try to restore session from stored credentials.
  Future<UserModel?> tryRestoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConstants.keySessionUser);
      if (userJson == null) return null;

      final cachedUser = UserModel.fromMap(jsonDecode(userJson) as Map<String, dynamic>);

      try {
        final profileData = await _supabase
            .from('users')
            .select()
            .eq('id', cachedUser.userId)
            .single();

        final freshUser = UserModel(
          userId: cachedUser.userId,
          username: profileData['username'] as String? ?? cachedUser.username,
          role: profileData['role'] as String? ?? cachedUser.role,
          displayName: profileData['display_name'] as String? ?? cachedUser.displayName,
        );

        await prefs.setString(AppConstants.keySessionUser, jsonEncode(freshUser.toMap()));
        return freshUser;
      } catch (_) {
        return cachedUser;
      }
    } catch (_) {
      return null;
    }
  }

  /// Update user role (Owner operation)
  Future<void> updateUserRole({
    required String userId,
    required String newRole,
  }) async {
    await _supabase.from('users').update({'role': newRole}).eq('id', userId);
  }

  /// Create a new user (Owner operation)
  Future<UserModel> createUser({
    required String email,
    required String password,
    required String username,
    required String role,
    required String displayName,
  }) async {
    final result = await _supabase.rpc('create_public_user', params: {
      'p_email': email,
      'p_username': username,
      'p_role': role,
      'p_password': password,
    });

    if (result == null) {
      throw Exception('Gagal membuat user');
    }

    final userId = result as String;

    await _supabase.from('users').update({'display_name': displayName}).eq('id', userId);

    return UserModel(
      userId: userId,
      username: username,
      role: role,
      displayName: displayName,
    );
  }

  /// Delete a user (Owner operation)
  Future<void> deleteUser(String userId) async {
    await _supabase.from('users').delete().eq('id', userId);
  }

  /// Update user profile (username)
  Future<void> updateUserProfile({
    required String userId,
    required String username,
  }) async {
    await _supabase
        .from('users')
        .update({'username': username})
        .eq('id', userId);
  }

  /// Update user display name
  Future<void> updateUserDisplayName({
    required String userId,
    required String displayName,
  }) async {
    await _supabase
        .from('users')
        .update({'display_name': displayName})
        .eq('id', userId);
  }

  /// Update user email (admin only - requires service_role)
  Future<void> updateUserEmail({
    required String userId,
    required String email,
  }) async {
    await _supabase
        .from('users')
        .update({'email': email})
        .eq('id', userId);
  }

  /// Update user password (admin only - requires service_role)
  Future<void> updateUserPassword({
    required String userId,
    required String password,
  }) async {
    await _supabase.rpc('update_public_user_password', params: {
      'p_user_id': userId,
      'p_new_password': password,
    });
  }

  /// Send password reset email via Supabase Auth
  Future<void> resetPassword(String email) async {
    throw Exception('Fitur lupa password dinonaktifkan. Silakan hubungi Owner untuk mengatur ulang password Anda.');
  }

  /// Update password after password recovery (must have valid recovery session)
  Future<void> updateCurrentUserPassword(String newPassword) async {
    throw Exception('Fitur reset password dinonaktifkan.');
  }

  /// Create a new business and assign the current owner to it.
  /// Returns the created [BusinessModel].
  Future<BusinessModel> createBusinessWithOwner({
    required String name,
    String? description,
    required String ownerUserId,
  }) async {
    final business = await _supaService.createBusiness(
      name: name,
      description: description,
    );
    // Assign owner to the new business
    await assignUserToBusiness(
      userId: ownerUserId,
      businessId: business.businessId,
    );
    return business;
  }

  /// Get all users (Owner operation) — cloud only
  Future<List<UserModel>> getAllUsers() async {
    return _supaService.getAllUsers();
  }

  /// Assign a user to a business (create user_businesses record)
  Future<void> assignUserToBusiness({
    required String userId,
    required int businessId,
  }) async {
    try {
      await _supabase.from('user_businesses').insert({
        'user_id': userId,
        'business_id': businessId,
      });
    } catch (_) {
      // If already exists (duplicate), ignore
    }
  }

  /// Unassign a user from a business (delete user_businesses record)
  Future<void> unassignUserFromBusiness({
    required String userId,
    required int businessId,
  }) async {
    await _supabase
        .from('user_businesses')
        .delete()
        .eq('user_id', userId)
        .eq('business_id', businessId);
  }

  /// Sync user-business assignments in batch
  Future<void> syncUserBusinessAssignments({
    required String userId,
    required List<int> assignedBusinessIds,
  }) async {
    // Get current assignments from cloud
    final currentIds = await _supaService.getBusinessIdsForUser(userId);
    final currentSet = currentIds.toSet();
    final targetSet = assignedBusinessIds.toSet();

    // Add new assignments
    for (final id in targetSet.difference(currentSet)) {
      await assignUserToBusiness(userId: userId, businessId: id);
    }

    // Remove removed assignments
    for (final id in currentSet.difference(targetSet)) {
      await unassignUserFromBusiness(userId: userId, businessId: id);
    }
  }
}
