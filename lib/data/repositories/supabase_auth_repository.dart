import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implémentation Supabase du repository d'authentification.
///
/// STRATÉGIE D'INSCRIPTION (dans l'ordre) :
///   1. Appel Edge Function `register-user` → compte pré-confirmé + session directe
///   2. Fallback : auth.signUp() standard → confirmation email ou session directe
///
/// SÉCURITÉ :
///   - Aucun rôle dans les métadonnées côté client
///   - Le rôle 'student' est assigné par trigger PostgreSQL handle_new_user()
///   - La service_role key n'est JAMAIS dans l'APK
///
/// LOGS : Tous les appels API loguent l'erreur réelle pour diagnostic
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
    debugPrint('[SupabaseAuth] 🔑 signIn: $email');
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      debugPrint('[SupabaseAuth] ✅ signIn OK: uid=${response.user?.id}');
      return response;
    } on AuthException catch (e) {
      // Log l'erreur RÉELLE de Supabase — jamais de message générique ici
      debugPrint('[SupabaseAuth] ❌ signIn AuthException:'
          '\n  message: ${e.message}'
          '\n  statusCode: ${e.statusCode}'
          '\n  code: ${e.code}');
      rethrow;
    } on SocketException catch (e) {
      debugPrint('[SupabaseAuth] ❌ signIn SocketException: $e');
      throw const AuthException(
        'Impossible de contacter le serveur. Vérifiez votre connexion.',
        statusCode: '0',
        code: 'network_error',
      );
    } catch (e) {
      debugPrint('[SupabaseAuth] ❌ signIn erreur inattendue: ${e.runtimeType}: $e');
      rethrow;
    }
  }

  // ── Inscription ────────────────────────────────────────────────────────────

  @override
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    debugPrint('[SupabaseAuth] 📝 signUp: $email');

    // TENTATIVE 1 : Edge Function (bypass confirmation email)
    try {
      final edgeResult = await _signUpViaEdgeFunction(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      if (edgeResult != null) {
        debugPrint('[SupabaseAuth] ✅ signUp via Edge Function réussi');
        return edgeResult;
      }
      debugPrint('[SupabaseAuth] ⚠️ Edge Function indisponible → fallback');
    } on AuthException {
      // AuthException de l'Edge Function → remonter directement (email déjà utilisé, etc.)
      rethrow;
    } catch (e) {
      // Erreur réseau / timeout sur Edge Function → fallback silencieux
      debugPrint('[SupabaseAuth] ⚠️ Edge Function erreur ($e) → fallback signUp standard');
    }

    // TENTATIVE 2 : auth.signUp() standard
    return await _signUpStandard(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );
  }

  // ── Edge Function ─────────────────────────────────────────────────────────

  Future<AuthResponse?> _signUpViaEdgeFunction({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    debugPrint('[SupabaseAuth] 🔄 Tentative Edge Function register-user...');

    final uri = Uri.parse('${SupabaseConfig.url}/functions/v1/register-user');
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
        .timeout(const Duration(seconds: 10));

    debugPrint('[SupabaseAuth] Edge Function → HTTP ${response.statusCode}');

    // Non déployée → fallback
    if (response.statusCode == 404) {
      debugPrint('[SupabaseAuth] Edge Function non déployée (404)');
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    debugPrint('[SupabaseAuth] Edge Function body: ${response.body.substring(0, response.body.length.clamp(0, 200))}');

    if (response.statusCode >= 400) {
      final errorCode = data['error'] as String? ?? '';
      final errorMsg = data['message'] as String? ?? data['error'] as String? ?? 'Erreur Edge Function';
      debugPrint('[SupabaseAuth] ❌ Edge Function erreur $errorCode: $errorMsg');

      if (errorCode == 'email_already_used' || response.statusCode == 409) {
        throw const AuthException('User already registered', code: 'email_exists');
      }
      throw AuthException(errorMsg, statusCode: response.statusCode.toString());
    }

    // Récupérer access_token + refresh_token
    final accessToken = data['access_token'] as String?;
    final refreshToken = data['refresh_token'] as String?;

    if (accessToken != null && refreshToken != null) {
      debugPrint('[SupabaseAuth] ✅ Tokens reçus → création session...');
      try {
        final sessionResp = await _client.auth.setSession(accessToken);
        return sessionResp;
      } catch (e) {
        debugPrint('[SupabaseAuth] ⚠️ setSession échoué: $e → signIn direct');
        // Essayer signIn direct avec les credentials
        try {
          return await _client.auth.signInWithPassword(
            email: email.trim().toLowerCase(),
            password: password,
          );
        } catch (e2) {
          debugPrint('[SupabaseAuth] ⚠️ signIn post-EdgeFunction échoué: $e2');
          return null;
        }
      }
    }

    debugPrint('[SupabaseAuth] Edge Function: pas de tokens → fallback');
    return null;
  }

  // ── Signup standard ────────────────────────────────────────────────────────

  Future<AuthResponse> _signUpStandard({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    debugPrint('[SupabaseAuth] 🔄 signUp standard: $email');
    try {
      final metadata = <String, dynamic>{'full_name': fullName.trim()};
      if (phone != null && phone.trim().isNotEmpty) {
        metadata['phone'] = phone.trim();
      }

      final response = await _client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: metadata,
      );

      debugPrint('[SupabaseAuth] ✅ signUp standard OK:'
          '\n  user=${response.user?.id}'
          '\n  email_confirmed=${response.user?.emailConfirmedAt}'
          '\n  session=${response.session != null}'
          '\n  identities=${response.user?.identities?.length}');

      return response;
    } on AuthException catch (e) {
      debugPrint('[SupabaseAuth] ❌ signUp AuthException:'
          '\n  message: ${e.message}'
          '\n  statusCode: ${e.statusCode}'
          '\n  code: ${e.code}');
      rethrow;
    } on SocketException catch (e) {
      debugPrint('[SupabaseAuth] ❌ signUp SocketException: $e');
      throw const AuthException(
        'Impossible de contacter le serveur. Vérifiez votre connexion.',
        statusCode: '0',
        code: 'network_error',
      );
    } catch (e) {
      debugPrint('[SupabaseAuth] ❌ signUp erreur inattendue: ${e.runtimeType}: $e');
      rethrow;
    }
  }

  // ── Connexion Google (via token id_token) ─────────────────────────────────

  Future<AuthResponse> signInWithGoogle({
    required String idToken,
    String? accessToken,
  }) async {
    debugPrint('[SupabaseAuth] 🔄 signIn Google...');
    try {
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      debugPrint('[SupabaseAuth] ✅ signIn Google OK: uid=${response.user?.id}');
      return response;
    } on AuthException catch (e) {
      debugPrint('[SupabaseAuth] ❌ Google Auth Exception:'
          '\n  message: ${e.message}'
          '\n  code: ${e.code}');
      rethrow;
    } catch (e) {
      debugPrint('[SupabaseAuth] ❌ Google Auth erreur: ${e.runtimeType}: $e');
      rethrow;
    }
  }

  // ── Connexion OAuth web (Google via browser) ──────────────────────────────

  Future<void> signInWithGoogleOAuth() async {
    debugPrint('[SupabaseAuth] 🔄 signIn Google OAuth...');
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.permisconnect.driving://login-callback',
    );
  }

  // ── Déconnexion ────────────────────────────────────────────────────────────

  @override
  Future<void> signOut() async {
    debugPrint('[SupabaseAuth] 🚪 signOut');
    await _client.auth.signOut();
  }

  // ── Réinitialisation mot de passe ──────────────────────────────────────────

  @override
  Future<void> resetPassword(String email) async {
    debugPrint('[SupabaseAuth] 🔄 resetPassword: $email');
    await _client.auth.resetPasswordForEmail(email.trim().toLowerCase());
  }

  // ── Vérification email disponible ─────────────────────────────────────────

  @override
  Future<bool> isEmailAvailable(String email) async {
    return true;
  }
}
