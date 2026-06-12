import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../domain/repositories/auth_repository.dart';

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
      email: email.trim(),
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
    String? role,
    String? inviteCode,
  }) async {
    final metadata = <String, dynamic>{
      'full_name': fullName.trim(),
      'role': role ?? SupabaseConfig.roleStudent,
    };

    if (phone != null && phone.isNotEmpty) {
      metadata['phone'] = phone.trim();
    }

    // Code d'invitation admin : transmis dans les métadonnées
    // Le trigger Supabase vérifiera la validité
    if (inviteCode != null && inviteCode.isNotEmpty) {
      metadata['invite_code'] = inviteCode.trim().toUpperCase();
    }

    final response = await _client.auth.signUp(
      email: email.trim(),
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
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  @override
  Future<bool> isEmailAvailable(String email) async {
    try {
      // On tente de récupérer le profil associé à cet email
      // Si Supabase retourne une erreur d'auth, c'est que l'email existe
      return true; // Simplifié — la vraie validation se fait à l'inscription
    } catch (_) {
      return false;
    }
  }
}
