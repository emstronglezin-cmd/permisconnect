import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../data/repositories/supabase_profile_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/profile_repository.dart';

// ─── Client Supabase ─────────────────────────────────────────────────────────

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ─── Repositories ─────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository(ref.watch(supabaseClientProvider));
});

// ─── Auth State Stream ─────────────────────────────────────────────────────────

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

// ─── Profile State ─────────────────────────────────────────────────────────────

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
      ProfileModel? profile;
      // Retry x5 car le trigger Supabase crée le profil de façon asynchrone
      for (int i = 1; i <= 5; i++) {
        profile = await _repo.getCurrentProfile();
        if (profile != null) break;
        if (i < 5) {
          debugPrint('[Profile] null, retry $i/5...');
          await Future.delayed(Duration(milliseconds: 600 * i));
        }
      }
      state = AsyncValue.data(profile);
    } catch (e, st) {
      debugPrint('[Profile] Erreur: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> update({String? fullName, String? phone, String? avatarUrl}) async {
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

// ─── Résultat d'inscription ────────────────────────────────────────────────────

enum SignUpResultType {
  /// Compte créé + session active → peut aller directement dans l'app
  successWithSession,
  /// Compte créé mais email de confirmation envoyé → attendre la confirmation
  successNeedsConfirmation,
  /// Email déjà utilisé (et déjà confirmé)
  emailAlreadyUsed,
}

class SignUpResult {
  final SignUpResultType type;
  final String? email;
  SignUpResult({required this.type, this.email});
}

// ─── Auth Actions ──────────────────────────────────────────────────────────────

final authActionsProvider = Provider<AuthActions>((ref) {
  return AuthActions(
    ref.watch(authRepositoryProvider),
    ref.watch(profileRepositoryProvider),
    ref,
  );
});

class AuthActions {
  final AuthRepository _authRepo;
  // ignore: unused_field
  final ProfileRepository _profileRepo;
  final Ref _ref;

  AuthActions(this._authRepo, this._profileRepo, this._ref);

  // ── Connexion ────────────────────────────────────────────────────────────────
  Future<void> signIn({required String email, required String password}) async {
    debugPrint('[Auth] signIn: $email');
    final response = await _authRepo.signInWithEmail(
      email: email,
      password: password,
    );
    if (response.user == null) {
      throw Exception('Connexion échouée.');
    }
    debugPrint('[Auth] signIn OK uid=${response.user!.id}');
    await _ref.read(currentProfileProvider.notifier).load();
  }

  // ── Inscription ───────────────────────────────────────────────────────────────
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    debugPrint('[Auth] signUp: $email');

    final response = await _authRepo.signUpWithEmail(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );

    debugPrint('[Auth] signUp response: '
        'user=${response.user?.id}, '
        'session=${response.session != null}, '
        'identities=${response.user?.identities?.length}');

    // Cas: email déjà utilisé ET déjà confirmé
    // Supabase retourne user mais avec identities vide = email déjà existant
    final identitiesEmpty = (response.user?.identities?.isEmpty) ?? false;
    if (identitiesEmpty) {
      debugPrint('[Auth] Email déjà utilisé (identities vide)');
      return SignUpResult(
        type: SignUpResultType.emailAlreadyUsed,
        email: email,
      );
    }

    // Cas: session active → peut se connecter directement
    if (response.session != null) {
      debugPrint('[Auth] Session active, chargement profil...');
      await Future.delayed(const Duration(milliseconds: 800));
      await _ref.read(currentProfileProvider.notifier).load();
      return SignUpResult(
        type: SignUpResultType.successWithSession,
        email: email,
      );
    }

    // Cas: pas de session → confirmation email requise
    debugPrint('[Auth] Email confirmation requise');
    return SignUpResult(
      type: SignUpResultType.successNeedsConfirmation,
      email: email,
    );
  }

  // ── Renvoyer email de confirmation ────────────────────────────────────────────
  Future<void> resendConfirmation(String email) async {
    debugPrint('[Auth] resend confirmation: $email');
    await Supabase.instance.client.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  // ── Déconnexion ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    debugPrint('[Auth] signOut');
    await _authRepo.signOut();
    _ref.read(currentProfileProvider.notifier).clear();
  }

  // ── Reset mot de passe ────────────────────────────────────────────────────────
  Future<void> resetPassword(String email) async {
    await _authRepo.resetPassword(email);
  }
}
