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
  final _passCtrl  = TextEditingController();

  bool _obscure   = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showResendButton = false; // afficher si email non confirmé

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showResendButton = false;
    });

    try {
      debugPrint('[Login] Tentative: ${_emailCtrl.text.trim()}');

      await ref.read(authActionsProvider).signIn(
            email:    _emailCtrl.text.trim(),
            password: _passCtrl.text,
          );

      if (!mounted) return;

      final profile = ref.read(currentProfileProvider).valueOrNull;
      debugPrint('[Login] Profil rôle: ${profile?.role}');

      if (profile?.role == SupabaseConfig.roleAdmin) {
        context.go('/admin/home');
      } else {
        context.go('/student/home');
      }
    } catch (e) {
      debugPrint('[Login] Erreur: $e');
      if (mounted) {
        final msg = _parseError(e.toString());
        final isNotConfirmed = e.toString().toLowerCase()
            .contains('email_not_confirmed') ||
            e.toString().toLowerCase().contains('not confirmed');
        setState(() {
          _errorMessage = msg;
          _showResendButton = isNotConfirmed;
          _isLoading = false;
        });
      }
    }
  }

  String _parseError(String raw) {
    final e = raw.toLowerCase();
    debugPrint('[Login] Parse error: $raw');

    if (e.contains('invalid login credentials') ||
        e.contains('invalid_credentials') ||
        e.contains('invalid credentials')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (e.contains('email_not_confirmed') ||
        e.contains('not confirmed') ||
        e.contains('email not confirmed')) {
      return 'Votre email n\'est pas encore confirmé.\nVérifiez votre boîte Gmail et cliquez sur le lien de confirmation.';
    }
    if (e.contains('too many requests') || e.contains('rate limit')) {
      return 'Trop de tentatives. Réessayez dans quelques minutes.';
    }
    if (e.contains('user not found') || e.contains('no user')) {
      return 'Aucun compte avec cet email. Inscrivez-vous d\'abord.';
    }
    if (e.contains('network') ||
        e.contains('socketexception') ||
        e.contains('failed host lookup') ||
        e.contains('connection refused')) {
      return 'Pas de connexion internet. Vérifiez votre réseau.';
    }
    if (e.contains('timeout')) {
      return 'Connexion trop lente. Réessayez.';
    }

    debugPrint('[Login] Erreur non gérée: $raw');
    final msg = raw.contains(':') ? raw.split(':').last.trim() : raw;
    return msg.length > 120 ? '${msg.substring(0, 120)}...' : msg;
  }

  Future<void> _resendConfirmation() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez votre email d\'abord')),
      );
      return;
    }
    try {
      await ref.read(authActionsProvider).resendConfirmation(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email de confirmation renvoyé ! Vérifiez Gmail.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().toLowerCase().contains('rate')
            ? 'Attendez quelques secondes avant de renvoyer.'
            : 'Impossible de renvoyer. Réessayez plus tard.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.orange),
        );
      }
    }
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
                // ── Logo ────────────────────────────────────────────────
                Center(
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.drive_eta,
                        size: 44, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text('PermisConnect',
                      style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                ),
                Center(
                  child: Text('Votre Auto-École Digitale',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary)),
                ),
                const SizedBox(height: 40),

                Text('Connexion',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Connectez-vous à votre compte',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 28),

                // ── Email ────────────────────────────────────────────────
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Adresse email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email requis';
                    if (!v.contains('@')) return 'Email invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Mot de passe ─────────────────────────────────────────
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _signIn(),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Mot de passe requis';
                    if (v.length < 6) return '6 caractères minimum';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // ── Mot de passe oublié ──────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showResetDialog,
                    child: const Text('Mot de passe oublié ?'),
                  ),
                ),

                // ── Erreur ───────────────────────────────────────────────
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline,
                            color: AppColors.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                                height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bouton resend si email non confirmé
                  if (_showResendButton) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _resendConfirmation,
                        icon: const Icon(Icons.email_outlined, size: 18),
                        label: const Text('Renvoyer l\'email de confirmation'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],

                // ── Bouton connexion ─────────────────────────────────────
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
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Se connecter',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Lien inscription ─────────────────────────────────────
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Pas encore de compte ? ',
                          style:
                              TextStyle(color: AppColors.textSecondary)),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: const Text('S\'inscrire',
                            style:
                                TextStyle(fontWeight: FontWeight.w600)),
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

  void _showResetDialog() {
    final ctrl = TextEditingController(text: _emailCtrl.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser le mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Un lien de réinitialisation sera envoyé à votre email.'),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'Email', border: OutlineInputBorder()),
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
              if (ctrl.text.isNotEmpty) {
                try {
                  await ref
                      .read(authActionsProvider)
                      .resetPassword(ctrl.text.trim());
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email de réinitialisation envoyé !'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) Navigator.pop(ctx);
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
