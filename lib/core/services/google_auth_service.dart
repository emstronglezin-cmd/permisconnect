import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service d'authentification Google pour PermisConnect.
/// Compatible google_sign_in 7.2.x (singleton + initialize()).
///
/// CONFIGURATION REQUISE (à faire par le développeur) :
///
/// 1. Google Cloud Console → https://console.cloud.google.com/
///    - APIs & Services → Credentials
///    - Create OAuth 2.0 Client ID → Web application
///    - Authorized redirect URIs: https://hruisploxlmhigbsnzbn.supabase.co/auth/v1/callback
///    - Copier le Web Client ID (format: xxxxx.apps.googleusercontent.com)
///
/// 2. Supabase Dashboard → Authentication → Providers → Google
///    - Activer Google provider
///    - Coller Client ID (Web) + Client Secret
///    - Sauvegarder
///
/// 3. Remplacer kGoogleWebClientId ci-dessous par votre vrai Client ID
///
/// PLACEHOLDER — À REMPLACER AVANT UTILISATION :
const String kGoogleWebClientId =
    'VOTRE_WEB_CLIENT_ID.apps.googleusercontent.com';

class GoogleAuthService {
  static GoogleAuthService? _instance;
  static GoogleAuthService get instance {
    _instance ??= GoogleAuthService._();
    return _instance!;
  }

  GoogleAuthService._();

  bool _initialized = false;

  /// Vrai si les credentials Google sont configurés par le développeur
  bool get isConfigured =>
      kGoogleWebClientId != 'VOTRE_WEB_CLIENT_ID.apps.googleusercontent.com' &&
      kGoogleWebClientId.isNotEmpty &&
      kGoogleWebClientId.contains('.apps.googleusercontent.com');

  /// Initialise le SDK Google Sign-In (doit être appelé une fois)
  Future<void> initialize() async {
    if (_initialized) return;
    if (!isConfigured) {
      debugPrint('[GoogleAuth] ⚠️ Google Client ID non configuré — skip init');
      return;
    }
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: kGoogleWebClientId,
      );
      _initialized = true;
      debugPrint('[GoogleAuth] ✅ GoogleSignIn initialisé');
    } catch (e) {
      debugPrint('[GoogleAuth] ⚠️ Erreur init GoogleSignIn: $e');
    }
  }

  /// Connexion Google + session Supabase
  Future<AuthResponse> signIn() async {
    debugPrint('[GoogleAuth] 🔄 Début connexion Google...');

    if (!isConfigured) {
      throw Exception(
        'Google Sign-In non encore configuré.\n'
        'Voir GOOGLE_SIGNIN_SETUP.md pour les instructions.\n'
        'Utilisez l\'inscription par email pour l\'instant.',
      );
    }

    if (!_initialized) {
      await initialize();
    }

    // Authentification Google (API 7.x — méthode authenticate())
    GoogleSignInAccount googleUser;
    try {
      googleUser = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      debugPrint('[GoogleAuth] ❌ GoogleSignInException: ${e.code} — ${e.description}');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw Exception('Connexion Google annulée.');
      }
      throw Exception('Erreur Google: ${e.description ?? e.code.name}');
    } catch (e) {
      debugPrint('[GoogleAuth] ❌ authenticate() erreur: ${e.runtimeType}: $e');
      rethrow;
    }

    debugPrint('[GoogleAuth] ✅ Compte Google: ${googleUser.email}');

    // Récupérer idToken (disponible via .authentication sur google_sign_in 7.x)
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final String? idToken = googleAuth.idToken;

    debugPrint('[GoogleAuth] idToken: ${idToken != null ? "✅ (${idToken.length} chars)" : "❌ null"}');

    if (idToken == null) {
      throw Exception(
        'idToken Google null.\n'
        'Vérifiez que serverClientId est bien configuré dans GoogleSignIn.initialize().',
      );
    }

    // Authentification Supabase avec l'idToken Google
    debugPrint('[GoogleAuth] 🔄 Supabase signInWithIdToken...');
    try {
      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      debugPrint('[GoogleAuth] ✅ Session Supabase créée: uid=${response.user?.id}');
      return response;
    } on AuthException catch (e) {
      debugPrint('[GoogleAuth] ❌ Supabase AuthException:'
          '\n  message: ${e.message}'
          '\n  code: ${e.code}'
          '\n  statusCode: ${e.statusCode}');
      rethrow;
    } catch (e) {
      debugPrint('[GoogleAuth] ❌ Erreur Supabase: ${e.runtimeType}: $e');
      rethrow;
    }
  }

  /// Déconnexion Google (sans bloquer le signOut Supabase)
  Future<void> signOut() async {
    if (!isConfigured || !_initialized) return;
    try {
      await GoogleSignIn.instance.signOut();
      debugPrint('[GoogleAuth] ✅ signOut Google OK');
    } catch (e) {
      debugPrint('[GoogleAuth] ⚠️ signOut Google erreur (ignorée): $e');
    }
  }
}
