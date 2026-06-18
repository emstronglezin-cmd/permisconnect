import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implémentation Supabase du repository d'authentification.
///
/// STRATÉGIE D'INSCRIPTION :
///   1. Appel à l'Edge Function `register-user` (crée compte pré-confirmé + session)
///   2. Si Edge Function non disponible → fallback vers auth.signUp() standard
///
/// SÉCURITÉ :
///   - Jamais de rôle dans les métadonnées côté client
///   - Le rôle 'student' est assigné par le trigger PostgreSQL handle_new_user()
///   - La service_role key n'est JAMAIS exposée dans l'APK
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository(this._client);

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  User? get currentUser => _client.auth.currentUser;

  // ── Connexion ──────────────────────────────────────────────────────────────

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

  // ── Inscription ────────────────────────────────────────────────────────────

  @override
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    // TENTATIVE 1: Edge Function (bypasse la confirmation email)
    // Fonctionne si l'Edge Function est déployée sur Supabase Dashboard
    try {
      final edgeResult = await _signUpViaEdgeFunction(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      if (edgeResult != null) {
        debugPrint('[Auth] ✅ Inscription via Edge Function réussie');
        return edgeResult;
      }
    } catch (e) {
      debugPrint('[Auth] Edge Function indisponible, fallback: $e');
    }

    // TENTATIVE 2: Fallback — auth.signUp() standard Supabase
    // L'utilisateur devra confirmer son email
    debugPrint('[Auth] ⚡ Fallback: auth.signUp() standard');
    return await _signUpStandard(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );
  }

  // ── Edge Function (inscription sans confirmation email) ───────────────────

  /// Appelle l'Edge Function `register-user` qui crée un compte pré-confirmé.
  /// Retourne null si la fonction n'est pas déployée (404).
  Future<AuthResponse?> _signUpViaEdgeFunction({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final uri = Uri.parse(
      '${SupabaseConfig.url}/functions/v1/register-user',
    );

    final body = <String, dynamic>{
      'email': email.trim().toLowerCase(),
      'password': password,
      'full_name': fullName.trim(),
    };
    if (phone != null && phone.trim().isNotEmpty) {
      body['phone'] = phone.trim();
    }

    final response = await http
        .post(
          uri,
          headers: {
            'apikey': SupabaseConfig.publishableKey,
            'Authorization': 'Bearer ${SupabaseConfig.publishableKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    debugPrint('[Auth] Edge Function status: ${response.statusCode}');

    // Edge Function non déployée → fallback
    if (response.statusCode == 404) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // Erreur côté Edge Function
    if (response.statusCode >= 400) {
      final errorCode = data['error'] as String? ?? '';
      final errorMsg = data['message'] as String? ?? data['error'] ?? 'Erreur inconnue';

      if (errorCode == 'email_already_used' || response.statusCode == 409) {
        throw AuthException('User already registered');
      }
      throw AuthException(errorMsg);
    }

    // Succès : récupérer les tokens et créer la session
    final accessToken = data['access_token'] as String?;
    final refreshToken = data['refresh_token'] as String?;

    if (accessToken != null && refreshToken != null) {
      debugPrint('[Auth] Tokens reçus, création session...');
      // Établir la session Flutter avec les tokens reçus
      final sessionResp = await _client.auth.setSession(accessToken);
      return sessionResp;
    }

    // Edge Function a créé le compte mais pas de session (erreur signin côté serveur)
    // → Retourner une réponse sans session (déclenchera l'écran de confirmation)
    debugPrint('[Auth] Edge Function: compte créé sans session, login manuel requis');
    return null; // déclenchera le fallback auth.signUp qui retournera needsConfirmation
  }

  // ── Signup standard (fallback) ─────────────────────────────────────────────

  Future<AuthResponse> _signUpStandard({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final metadata = <String, dynamic>{'full_name': fullName.trim()};
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

  // ── Déconnexion ────────────────────────────────────────────────────────────

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── Réinitialisation mot de passe ──────────────────────────────────────────

  @override
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim().toLowerCase());
  }

  // ── Vérification disponibilité email ──────────────────────────────────────

  @override
  Future<bool> isEmailAvailable(String email) async {
    return true;
  }
}
