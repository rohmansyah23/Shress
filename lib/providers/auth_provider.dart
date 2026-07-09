import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/constants.dart';
import '../data/local/database.dart';
import '../data/local/models/user_model.dart';
import '../data/remote/auth_repository.dart';

// ==================== Auth Repository Provider ====================

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    supabase: Supabase.instance.client,
    localDb: LocalDatabase.instance,
  );
});

// ==================== Auth State ====================

enum AuthStatus {
  unknown, // Initial loading
  authenticated, // Logged in
  unauthenticated, // Not logged in
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  bool get isOwner => user?.role == AppConstants.roleOwner;
  bool get isManager => user?.role == AppConstants.roleManager;
  bool get isStaff => user?.role == AppConstants.roleStaff;
}

// ==================== Auth Notifier ====================

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;

  AuthNotifier(this._authRepo) : super(const AuthState()) {
    _tryRestoreSession();
  }

  /// Try to restore session on app start
  Future<void> _tryRestoreSession() async {
    try {
      final user = await _authRepo.tryRestoreSession();
      if (user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
        );
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Login with email and password
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(errorMessage: null);

    try {
      final user = await _authRepo.signIn(
        email: email,
        password: password,
      );

      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: _mapAuthError(e),
      );
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authRepo.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Get all users (Owner operation)
  Future<List<UserModel>> getAllUsers() async {
    return _authRepo.getAllUsers();
  }

  /// Update user role
  Future<void> updateUserRole(String userId, String newRole) async {
    await _authRepo.updateUserRole(userId: userId, newRole: newRole);
    // Refresh local state if the updated user is the current user
    if (state.user?.userId == userId) {
      state = state.copyWith(
        user: UserModel(
          userId: state.user!.userId,
          username: state.user!.username,
          role: newRole,
        ),
      );
    }
  }

  /// Map auth errors to user-friendly messages in Bahasa Indonesia
  String _mapAuthError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Email atau password salah';
    }
    if (message.contains('user not found')) {
      return 'User tidak ditemukan';
    }
    if (message.contains('email already registered')) {
      return 'Email sudah terdaftar';
    }
    if (message.contains('weak password')) {
      return 'Password terlalu lemah (min. 6 karakter)';
    }
    if (message.contains('network')) {
      return 'Tidak ada koneksi internet';
    }
    return 'Terjadi kesalahan, silakan coba lagi';
  }
}

// ==================== Auth Provider ====================

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepo);
});

// ==================== Derived Providers ====================

/// Check if the current user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).status == AuthStatus.authenticated;
});

/// Get current user model
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

/// Get current user role
final currentUserRoleProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).user?.role;
});
