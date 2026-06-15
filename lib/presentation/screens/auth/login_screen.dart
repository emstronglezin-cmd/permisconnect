import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('[LoginScreen] Tentative connexion: ${_emailCtrl.text.trim()}');

      await ref.read(authActionsProvider).signIn(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );

      if (!mounted) return;

      // Lire le profil et rediriger selon le rôle
      final profile = ref.read(currentProfileProvider).valueOrNull;
      debugPrint('[LoginScreen] Profil après login: ${profile?.role}');

      if (profile?.role == SupabaseConfig.roleAdmin) {
        context.go('/admin/home');
      } else {
        context.go('/student/home');
      }
    } catch (e) {
      debugPrint('[LoginScreen] Erreur connexion: $e');
      if (mounted) {
        setState(() {
          _errorMessage = _parseAuthError(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  String _parseAuthError(String error) {
    final lower = error.toLowerCase();

    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials') ||
        lower.contains('email or password')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (lower.contains('email not confirmed') ||
        lower.contains('not confirmed')) {
      return 'Votre email n\'est pas encore confirmé. Vérifiez votre boîte mail.';
    }
    if (lower.contains('too many requests') ||
        lower.contains('rate limit')) {
      return 'Trop de tentatives. Réessayez dans quelques minutes.';
    }
    if (lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('socket')) {
      return 'Problème de connexion réseau.';
    }
    if (lower.contains('user not found') ||
        lower.contains('no user')) {
      return 'Aucun compte trouvé avec cet email.';
    }

    debugPrint('[LoginScreen] Erreur non gérée: $error');
    return 'Erreur de connexion. Réessayez.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Logo ───────────────────────────────────────────────
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.drive_eta,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'PermisConnect',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'Votre Auto-École Digitale',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                Text(
                  'Connexion',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connectez-vous à votre compte',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Email ──────────────────────────────────────────────
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Adresse email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email requis';
                    if (!v.contains('@')) return 'Email invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Mot de passe ───────────────────────────────────────
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _signIn(),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Mot de passe requis';
                    if (v.length < 6) return '6 caractères minimum';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // ── Mot de passe oublié ────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showResetPasswordDialog,
                    child: const Text('Mot de passe oublié ?'),
                  ),
                ),

                // ── Message d'erreur ───────────────────────────────────
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 8),

                // ── Bouton Connexion ───────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Se connecter',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Lien inscription ───────────────────────────────────
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Pas encore de compte ? ',
                        style:
                            TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: const Text(
                          'S\'inscrire',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showResetPasswordDialog() {
    final emailCtrl = TextEditingController(text: _emailCtrl.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser le mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Un lien de réinitialisation sera envoyé à votre adresse email.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailCtrl.text.isNotEmpty) {
                try {
                  await ref
                      .read(authActionsProvider)
                      .resetPassword(emailCtrl.text.trim());
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Email de réinitialisation envoyé !'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}
