import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

/// Utilisateur Supabase actuel (null si non connecté)
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

  /// Charge le profil — avec retry si le trigger n'a pas encore créé la ligne
  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      // Retry jusqu'à 5 fois (le trigger Supabase peut prendre 1-2s)
      ProfileModel? profile;
      for (int attempt = 1; attempt <= 5; attempt++) {
        profile = await _repo.getCurrentProfile();
        if (profile != null) break;

        if (attempt < 5) {
          debugPrint('[ProfileNotifier] Profil null, retry $attempt/5...');
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
      state = AsyncValue.data(profile);
    } catch (e, st) {
      debugPrint('[ProfileNotifier] Erreur chargement profil: $e');
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
      debugPrint('[ProfileNotifier] Erreur mise à jour profil: $e');
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
  // ignore: unused_field
  final ProfileRepository _profileRepo;
  final Ref _ref;

  AuthActions(this._authRepo, this._profileRepo, this._ref);

  /// Connexion email + mot de passe
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    debugPrint('[AuthActions] signIn: $email');
    final response = await _authRepo.signInWithEmail(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Connexion échouée : aucun utilisateur retourné.');
    }

    debugPrint('[AuthActions] signIn OK uid=${response.user!.id}');
    // Charger le profil après connexion
    await _ref.read(currentProfileProvider.notifier).load();
  }

  /// Inscription : rôle TOUJOURS 'student' (trigger Supabase).
  /// Ne passe AUCUN paramètre role ou inviteCode.
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    debugPrint('[AuthActions] signUp: $email / $fullName');

    final response = await _authRepo.signUpWithEmail(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );

    debugPrint('[AuthActions] signUp response: '
        'user=${response.user?.id} '
        'session=${response.session != null}');

    // Supabase peut retourner un user sans session si email confirmation activée
    if (response.user == null) {
      throw Exception(
          'Inscription échouée : aucun utilisateur retourné par Supabase.');
    }

    // Si pas de session → email de confirmation envoyé
    if (response.session == null) {
      debugPrint('[AuthActions] Email confirmation requis');
      // On ne charge pas le profil — l'utilisateur doit confirmer son email
      return;
    }

    // Session active → charger le profil (avec retry pour le trigger)
    debugPrint('[AuthActions] Session active, chargement profil...');
    await _ref.read(currentProfileProvider.notifier).load();
  }

  Future<void> signOut() async {
    debugPrint('[AuthActions] signOut');
    await _authRepo.signOut();
    _ref.read(currentProfileProvider.notifier).clear();
  }

  Future<void> resetPassword(String email) async {
    await _authRepo.resetPassword(email);
  }
}
