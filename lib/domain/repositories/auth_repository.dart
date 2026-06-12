import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  /// Stream de l'état d'authentification
  Stream<AuthState> get authStateChanges;

  /// Utilisateur Supabase actuel
  User? get currentUser;

  /// Connexion email + mot de passe
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  });

  /// Inscription avec email + mot de passe
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? role,
    String? inviteCode,
  });

  /// Déconnexion
  Future<void> signOut();

  /// Réinitialisation du mot de passe
  Future<void> resetPassword(String email);

  /// Vérification si l'email est déjà utilisé
  Future<bool> isEmailAvailable(String email);
}
