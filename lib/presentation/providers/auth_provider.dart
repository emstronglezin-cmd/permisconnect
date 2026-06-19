import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/google_auth_service.dart';
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

  // ── Connexion email/password ───────────────────────────────────────────────
  Future<void> signIn({required String email, required String password}) async {
    debugPrint('[AuthActions] 🔑 signIn: $email');
    final response = await _authRepo.signInWithEmail(
      email: email,
      password: password,
    );
    if (response.user == null) {
      throw const AuthException('Connexion échouée. Utilisateur introuvable.');
    }
    debugPrint('[AuthActions] ✅ signIn OK uid=${response.user!.id}');
    await Future.delayed(const Duration(milliseconds: 500));
    await _ref.read(currentProfileProvider.notifier).load();
  }

  // ── Inscription email/password ─────────────────────────────────────────────
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    debugPrint('[AuthActions] 📝 signUp: $email');

    final response = await _authRepo.signUpWithEmail(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );

    debugPrint('[AuthActions] signUp réponse:'
        '\n  user=${response.user?.id}'
        '\n  session=${response.session != null}'
        '\n  identities=${response.user?.identities?.length}'
        '\n  emailConfirmed=${response.user?.emailConfirmedAt}');

    // Email déjà utilisé : Supabase retourne user avec identities vide
    final identitiesEmpty = (response.user?.identities?.isEmpty) ?? false;
    if (identitiesEmpty) {
      debugPrint('[AuthActions] ⚠️ Email déjà utilisé (identities=[])');
      return SignUpResult(type: SignUpResultType.emailAlreadyUsed, email: email);
    }

    // Session active → connexion directe (mailer_autoconfirm=true ou Edge Function)
    if (response.session != null) {
      debugPrint('[AuthActions] ✅ Session active → chargement profil...');
      await Future.delayed(const Duration(milliseconds: 800));
      await _ref.read(currentProfileProvider.notifier).load();
      return SignUpResult(type: SignUpResultType.successWithSession, email: email);
    }

    // Pas de session → confirmation email requise
    debugPrint('[AuthActions] 📧 Confirmation email requise');
    return SignUpResult(type: SignUpResultType.successNeedsConfirmation, email: email);
  }

  // ── Connexion Google ───────────────────────────────────────────────────────
  Future<SignUpResult> signInWithGoogle() async {
    debugPrint('[AuthActions] 🔄 signInWithGoogle...');
    try {
      final response = await GoogleAuthService.instance.signIn();

      if (response.user == null) {
        throw const AuthException('Connexion Google échouée.');
      }

      debugPrint('[AuthActions] ✅ Google OK: uid=${response.user!.id}');

      // Charger le profil (le trigger crée le profil si nouveau user)
      await Future.delayed(const Duration(milliseconds: 800));
      await _ref.read(currentProfileProvider.notifier).load();

      return SignUpResult(
        type: SignUpResultType.successWithSession,
        email: response.user!.email,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('[AuthActions] ❌ Google erreur: $e');
      rethrow;
    }
  }

  /// Indique si Google Sign-In est configuré (Client ID présent)
  bool get isGoogleSignInConfigured => GoogleAuthService.instance.isConfigured;

  // ── Renvoyer email de confirmation ─────────────────────────────────────────
  Future<void> resendConfirmation(String email) async {
    debugPrint('[AuthActions] 📧 resend confirmation: $email');
    await Supabase.instance.client.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  // ── Déconnexion ────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    debugPrint('[AuthActions] 🚪 signOut');
    await GoogleAuthService.instance.signOut();
    await _authRepo.signOut();
    _ref.read(currentProfileProvider.notifier).clear();
  }

  // ── Reset mot de passe ─────────────────────────────────────────────────────
  Future<void> resetPassword(String email) async {
    debugPrint('[AuthActions] 🔄 resetPassword: $email');
    await _authRepo.resetPassword(email);
  }
}
