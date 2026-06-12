import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../data/repositories/supabase_profile_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/profile_repository.dart';

// ─── Client Supabase ────────────────────────────────────────────────────────

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ─── Repositories ────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository(ref.watch(supabaseClientProvider));
});

// ─── Auth State Stream ────────────────────────────────────────────────────────

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Utilisateur Supabase actuel (peut être null si non connecté)
final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

// ─── Profile State ────────────────────────────────────────────────────────────

final currentProfileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<ProfileModel?>>(
  (ref) => ProfileNotifier(ref.watch(profileRepositoryProvider)),
);

class ProfileNotifier extends StateNotifier<AsyncValue<ProfileModel?>> {
  final ProfileRepository _repo;

  ProfileNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repo.getCurrentProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> update({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      final updated = await _repo.updateProfile(
        profileId: current.id,
        fullName: fullName,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() => state = const AsyncValue.data(null);
}

// ─── Auth Actions ─────────────────────────────────────────────────────────────

final authActionsProvider = Provider<AuthActions>((ref) {
  return AuthActions(
    ref.watch(authRepositoryProvider),
    ref.watch(profileRepositoryProvider),
    ref,
  );
});

class AuthActions {
  final AuthRepository _authRepo;
  final ProfileRepository _profileRepo;
  final Ref _ref;

  AuthActions(this._authRepo, this._profileRepo, this._ref);

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _authRepo.signInWithEmail(email: email, password: password);
    // Recharger le profil après connexion
    await _ref.read(currentProfileProvider.notifier).load();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String role = SupabaseConfig.roleStudent,
    String? inviteCode,
  }) async {
    await _authRepo.signUpWithEmail(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      role: role,
      inviteCode: inviteCode,
    );
    // Charger le profil créé par le trigger Supabase
    await Future.delayed(const Duration(milliseconds: 500));
    await _ref.read(currentProfileProvider.notifier).load();
  }

  Future<void> signOut() async {
    await _authRepo.signOut();
    _ref.read(currentProfileProvider.notifier).clear();
  }

  Future<void> resetPassword(String email) async {
    await _authRepo.resetPassword(email);
  }
}
