import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
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
  User? get currentSupabaseUser => _supabase.auth.currentUser;

  /// Current session
  Session? get currentSession => _supabase.auth.currentSession;

  /// Whether a user is currently authenticated
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// Sign in with email and password.
  /// Returns the authenticated UserModel on success.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    // Step 1: Try standard Supabase Auth sign in
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        // Fetch user profile from public.users table
        final profileData = await _supabase
            .from('users')
            .select()
            .eq('id', user.id)
            .single();

        return UserModel(
          userId: user.id,
          username: profileData['username'] as String? ?? user.email ?? 'User',
          role: profileData['role'] as String? ?? 'staff',
        );
      }
    } on AuthException catch (e) {
      if (!e.message.toLowerCase().contains('invalid login credentials') &&
          !e.message.toLowerCase().contains('invalid_credentials')) {
        rethrow;
      }
    }

    // Step 2 (Fallback): Verify against public.users.password_hash via RPC
    try {
      final rpc = await _supabase.rpc('verify_public_password', params: {
        'p_email': email,
        'p_password': password,
      }).single();

      final userId = rpc as String;
      final profileData = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return UserModel(
        userId: userId,
        username: profileData['username'] as String? ?? email.split('@').first,
        role: profileData['role'] as String? ?? 'staff',
      );
    } catch (_) {
      // RPC might not exist — ignore
    }

    throw AuthException('invalid login credentials');
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Try to restore session from stored credentials.
  Future<UserModel?> tryRestoreSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return null;

      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // Fetch fresh profile from Supabase
      final profileData = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      return UserModel(
        userId: user.id,
        username: profileData['username'] as String? ?? user.email ?? 'User',
        role: profileData['role'] as String? ?? 'staff',
      );
    } catch (e) {
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
  }) async {
    final response = await _supabase.auth.admin.createUser(
      AdminUserAttributes(
        email: email,
        password: password,
        emailConfirm: true,
        userMetadata: {'username': username, 'role': role},
      ),
    );
    final authUser = response.user;
    if (authUser == null) throw Exception('Gagal membuat user');

    // Insert profile into public.users
    await _supabase.from('users').insert({
      'id': authUser.id,
      'username': username,
      'role': role,
      'email': email,
    });

    return UserModel(
      userId: authUser.id,
      username: username,
      role: role,
    );
  }

  /// Delete a user (Owner operation)
  Future<void> deleteUser(String userId) async {
    // Delete user_businesses first
    await _supabase.from('user_businesses').delete().eq('user_id', userId);
    // Delete profile
    await _supabase.from('users').delete().eq('id', userId);
    // Delete auth user
    await _supabase.auth.admin.deleteUser(userId);
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

  /// Update user email (admin only - requires service_role)
  Future<void> updateUserEmail({
    required String userId,
    required String email,
  }) async {
    await _supabase.auth.admin.updateUserById(
      userId,
      attributes: AdminUserAttributes(email: email),
    );
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
    await _supabase.auth.admin.updateUserById(
      userId,
      attributes: AdminUserAttributes(password: password),
    );
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
