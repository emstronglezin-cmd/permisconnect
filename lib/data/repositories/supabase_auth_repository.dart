import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implémentation Supabase du repository d'authentification.
///
/// SÉCURITÉ : signUpWithEmail() n'envoie JAMAIS de rôle dans les métadonnées.
/// Le rôle 'student' est assigné exclusivement par le trigger PostgreSQL
/// handle_new_user() côté Supabase (SECURITY DEFINER).
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository(this._client);

  @override
  Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    return response;
  }

  @override
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    // SÉCURITÉ : On n'envoie QUE les informations de profil basiques.
    // Le rôle est TOUJOURS défini à 'student' par le trigger Supabase.
    // Aucun code d'invitation, aucun champ role ici.
    final metadata = <String, dynamic>{
      'full_name': fullName.trim(),
    };

    if (phone != null && phone.trim().isNotEmpty) {
      metadata['phone'] = phone.trim();
    }

    final response = await _client.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: metadata,
    );

    return response;
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(
      email.trim().toLowerCase(),
    );
  }

  @override
  Future<bool> isEmailAvailable(String email) async {
    // La validation réelle se fait lors de l'inscription
    return true;
  }
}
