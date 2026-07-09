import 'package:supabase_flutter/supabase_flutter.dart';
import '../local/database.dart';
import '../local/models/user_business_model.dart';
import '../local/models/user_model.dart';

/// Repository handling all Supabase Auth operations + local user caching.
class AuthRepository {
  final SupabaseClient _supabase;
  final LocalDatabase _localDb;

  AuthRepository({
    required SupabaseClient supabase,
    required LocalDatabase localDb,
  })  : _supabase = supabase,
        _localDb = localDb;

  /// Current authenticated user (from Supabase)
  User? get currentSupabaseUser => _supabase.auth.currentUser;

  /// Current session
  Session? get currentSession => _supabase.auth.currentSession;

  /// Whether a user is currently authenticated
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// Sign in with email and password.
  /// Returns the authenticated User on success.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Login gagal: Tidak ada data user');
    }

    // Fetch user profile from public.users table
    final profileData = await _supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .single();

    final userModel = UserModel(
      userId: user.id,
      username: profileData['username'] as String? ?? user.email ?? 'User',
      role: profileData['role'] as String? ?? 'staff',
    );

    // Cache locally
    await _localDb.saveUser(userModel);

    return userModel;
  }

  /// Sign up a new user (Owner-only operation, typically via Supabase Dashboard)
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String username,
    required String role,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': username,
        'role': role,
      },
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Registrasi gagal');
    }

    final userModel = UserModel(
      userId: user.id,
      username: username,
      role: role,
    );

    await _localDb.saveUser(userModel);
    return userModel;
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Try to restore session from stored credentials.
  /// Returns the cached UserModel if session is valid.
  Future<UserModel?> tryRestoreSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return null;

      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // Try to get from local cache first
      final cached = _localDb.getUserByAuthId(user.id);
      if (cached != null) return cached;

      // Fetch from server if not cached
      final profileData = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      final userModel = UserModel(
        userId: user.id,
        username: profileData['username'] as String? ?? user.email ?? 'User',
        role: profileData['role'] as String? ?? 'staff',
      );

      await _localDb.saveUser(userModel);
      return userModel;
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

    // Update local cache
    final cached = _localDb.getUserByAuthId(userId);
    if (cached != null) {
      final updated = UserModel(
        userId: cached.userId,
        username: cached.username,
        role: newRole,
        lastSyncedAt: cached.lastSyncedAt,
        createdAt: cached.createdAt,
      );
      await _localDb.saveUser(updated);
    }
  }

  /// Get all users (Owner operation)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final data = await _supabase.from('users').select();
      final users = (data as List)
          .map((json) => UserModel(
                userId: json['id'] as String,
                username: json['username'] as String,
                role: json['role'] as String,
              ))
          .toList();

      // Cache locally
      for (final user in users) {
        await _localDb.saveUser(user);
      }

      return users;
    } catch (e) {
      // Fallback to local cache
      return _localDb.getAllUsers();
    }
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

    // Save locally
    final ub = UserBusinessModel(
      userId: userId,
      businessId: businessId,
    );
    await _localDb.saveUserBusiness(ub);
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

    // Remove locally
    await _localDb.deleteUserBusiness(userId, businessId);
  }

  /// Sync user-business assignments in batch
  Future<void> syncUserBusinessAssignments({
    required String userId,
    required List<int> assignedBusinessIds,
  }) async {
    // Get current assignments
    final current = _localDb.getBusinessesForUser(userId);
    final currentIds = current.map((e) => e.businessId).toSet();
    final targetIds = assignedBusinessIds.toSet();

    // Add new assignments
    for (final id in targetIds.difference(currentIds)) {
      await assignUserToBusiness(userId: userId, businessId: id);
    }

    // Remove removed assignments
    for (final id in currentIds.difference(targetIds)) {
      await unassignUserFromBusiness(userId: userId, businessId: id);
    }
  }
}
