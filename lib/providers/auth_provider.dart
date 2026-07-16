import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/constants.dart';
import '../core/services/fcm_service.dart';
import '../data/local/models/business_model.dart';
import '../data/local/models/user_model.dart';
import '../data/remote/auth_repository.dart';
import '../data/remote/supabase_service.dart';

// ==================== Providers ====================

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    supabase: Supabase.instance.client,
    supaService: SupabaseService.instance,
  );
});

// ==================== Auth State ====================

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
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

  Future<void> _tryRestoreSession() async {
    try {
      final user = await _authRepo.tryRestoreSession();
      if (user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
        );
        FcmService.instance.setUserId(user.userId);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    state = state.copyWith(errorMessage: null);

    try {
      final user = await _authRepo.signIn(
        identifier: identifier,
        password: password,
      );

      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );

      FcmService.instance.setUserId(user.userId);

      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: _mapAuthError(e),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await FcmService.instance.deactivateToken();
    FcmService.instance.clearUserId();
    await _authRepo.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Send password reset email to the given email address
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _authRepo.resetPassword(email);
      return null; // success
    } catch (e) {
      return _mapAuthError(e);
    }
  }

  /// Update password after password recovery (requires valid recovery session)
  Future<String?> updatePasswordAfterRecovery(String newPassword) async {
    try {
      await _authRepo.updateCurrentUserPassword(newPassword);
      return null; // success
    } catch (e) {
      return _mapAuthError(e);
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    return _authRepo.getAllUsers();
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    await _authRepo.updateUserRole(userId: userId, newRole: newRole);
    if (state.user?.userId == userId) {
      state = state.copyWith(
        user: UserModel(
          userId: state.user!.userId,
          username: state.user!.username,
          role: newRole,
          displayName: state.user!.displayName,
        ),
      );
    }
  }

  Future<void> updateUserDisplayName(String userId, String newDisplayName) async {
    await _authRepo.updateUserDisplayName(userId: userId, displayName: newDisplayName);
    if (state.user?.userId == userId) {
      final updatedUser = UserModel(
        userId: state.user!.userId,
        username: state.user!.username,
        role: state.user!.role,
        displayName: newDisplayName,
      );
      state = state.copyWith(user: updatedUser);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keySessionUser, jsonEncode(updatedUser.toMap()));
    }
  }

  String _mapAuthError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('invalid login credentials') ||
        message.contains('email atau password') ||
        message.contains('login gagal') ||
        message.contains('invalid_credentials')) {
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

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).status == AuthStatus.authenticated;
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final currentUserRoleProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).user?.role;
});

// ==================== Data Providers ====================

/// All businesses (owner sees all, manager/staff filtered)
final allBusinessesProvider = FutureProvider<List<BusinessModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return SupabaseService.instance.getAccessibleBusinesses(user.userId, user.role);
});

/// Businesses accessible by a specific user
final accessibleBusinessesProvider = FutureProvider<List<BusinessModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return SupabaseService.instance.getAccessibleBusinesses(user.userId, user.role);
});

/// All registered users (Owner only)
final allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final repo = ref.read(authRepositoryProvider);
  return repo.getAllUsers();
});
