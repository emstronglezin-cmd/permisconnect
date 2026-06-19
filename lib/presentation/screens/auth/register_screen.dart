import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/widgets/google_sign_in_button.dart';

/// Inscription élève uniquement.
/// Gère 3 cas Supabase :
///   1. successWithSession → espace élève direct
///   2. successNeedsConfirmation → écran confirmation email
///   3. emailAlreadyUsed → message clair + lien login
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _isLoading      = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  // null = formulaire | 'confirm' = attente confirmation email
  String? _uiState;
  String? _registeredEmail;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Inscription email/password ─────────────────────────────────────────────
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ref.read(authActionsProvider).signUp(
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text,
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );

      if (!mounted) return;

      switch (result.type) {
        case SignUpResultType.successWithSession:
          context.go('/student/home');
          break;

        case SignUpResultType.successNeedsConfirmation:
          setState(() {
            _uiState = 'confirm';
            _registeredEmail = result.email;
            _isLoading = false;
          });
          break;

        case SignUpResultType.emailAlreadyUsed:
          setState(() {
            _errorMessage = 'Cette adresse email est déjà utilisée.\nConnectez-vous ou réinitialisez votre mot de passe.';
            _isLoading = false;
          });
          break;
      }
    } catch (e) {
      // Afficher l'erreur RÉELLE de Supabase — jamais de message générique
      debugPrint('[RegisterScreen] ❌ Erreur catch: ${e.runtimeType}: $e');
      if (mounted) {
        setState(() {
          _errorMessage = _parseError(e);
          _isLoading = false;
        });
      }
    }
  }

  // ── Inscription/connexion Google ───────────────────────────────────────────
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ref.read(authActionsProvider).signInWithGoogle();

      if (!mounted) return;

      if (result.type == SignUpResultType.successWithSession) {
        context.go('/student/home');
      }
    } catch (e) {
      debugPrint('[RegisterScreen] ❌ Google erreur: $e');
      if (mounted) {
        setState(() {
          _errorMessage = _parseError(e);
          _isGoogleLoading = false;
        });
      }
    }
  }

  // ── Renvoyer email de confirmation ─────────────────────────────────────────
  Future<void> _resendConfirmation() async {
    if (_registeredEmail == null) return;
    try {
      await ref.read(authActionsProvider).resendConfirmation(_registeredEmail!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email de confirmation renvoyé !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().toLowerCase().contains('rate')
            ? 'Attendez quelques secondes avant de renvoyer.'
            : 'Impossible de renvoyer. Réessayez.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.orange),
        );
      }
    }
  }

  // ── Parsing erreurs — AFFICHE L'ERREUR RÉELLE ─────────────────────────────
  String _parseError(Object error) {
    final raw = error.toString();
    final e = raw.toLowerCase();
    debugPrint('[RegisterScreen] _parseError: $raw');

    // Erreurs Supabase AuthException spécifiques
    if (e.contains('user already registered') ||
        e.contains('already registered') ||
        e.contains('already been registered') ||
        e.contains('email_exists') ||
        e.contains('email already')) {
      return 'Email déjà utilisé. Connectez-vous ou réinitialisez votre mot de passe.';
    }
    if (e.contains('email_not_confirmed') || e.contains('not confirmed')) {
      return 'Email non confirmé. Vérifiez votre boîte mail et cliquez sur le lien de confirmation.';
    }
    if (e.contains('password') && (e.contains('least') || e.contains('weak') || e.contains('short'))) {
      return 'Mot de passe trop faible. Utilisez au moins 8 caractères variés.';
    }
    if (e.contains('invalid email') || (e.contains('email') && e.contains('invalid'))) {
      return 'Adresse email invalide.';
    }
    if (e.contains('over_email_send_rate_limit') ||
        e.contains('rate limit') ||
        e.contains('too many requests')) {
      return 'Trop de tentatives. Attendez quelques minutes.';
    }
    if (e.contains('signup') && e.contains('disabled')) {
      return 'Les inscriptions sont temporairement désactivées.';
    }
    if (e.contains('network_error') || e.contains('code: network_error')) {
      return 'Impossible de contacter le serveur. Vérifiez votre connexion internet.';
    }

    // ERREUR RÉSEAU RÉELLE (SocketException, etc.)
    if (e.contains('socketexception') ||
        e.contains('failed host lookup') ||
        e.contains('connection refused') ||
        e.contains('os error')) {
      return 'Pas de connexion internet. Vérifiez votre réseau.';
    }
    if (e.contains('timeoutexception') || (e.contains('timeout') && !e.contains('session'))) {
      return 'Connexion trop lente. Réessayez.';
    }
    if (e.contains('annulée') || e.contains('cancelled') || e.contains('canceled')) {
      return 'Connexion Google annulée.';
    }
    if (e.contains('non configuré') || e.contains('not configured') || e.contains('client id')) {
      return 'Google Sign-In non configuré. Utilisez l\'inscription par email.';
    }

    // ⚠️ PAS DE MESSAGE GÉNÉRIQUE — afficher l'erreur brute (tronquée pour l'UI)
    // Cela permet de voir exactement ce que Supabase retourne
    final parts = raw.split(':');
    final msg = parts.length > 1 ? parts.last.trim() : raw;
    final display = msg.length > 150 ? '${msg.substring(0, 150)}...' : msg;
    debugPrint('[RegisterScreen] Erreur non classifiée affichée: $display');
    return display;
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_uiState == 'confirm') return _buildConfirmScreen();
    return _buildFormScreen();
  }

  // ── Formulaire principal ───────────────────────────────────────────────────
  Widget _buildFormScreen() {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Text('Créer un compte',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Rejoignez PermisConnect dès maintenant',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 20),

                // Badge élève
                _BadgeEleve(),
                const SizedBox(height: 20),

                // ── Bouton Google ──────────────────────────────────────────
                GoogleSignInButton(
                  onPressed: (_isLoading || _isGoogleLoading) ? null : _signInWithGoogle,
                  isLoading: _isGoogleLoading,
                  label: 'Continuer avec Google',
                ),
                const SizedBox(height: 16),

                // Séparateur
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('ou',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),

                // Nom
                _buildField(
                  controller: _nameCtrl,
                  label: 'Nom complet *',
                  hint: 'Ex : Kondabo Abdoul Aziz',
                  icon: Icons.person_outlined,
                  action: TextInputAction.next,
                  caps: TextCapitalization.words,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Nom requis';
                    if (v.trim().length < 3) return 'Min. 3 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Email
                _buildField(
                  controller: _emailCtrl,
                  label: 'Adresse email *',
                  hint: 'exemple@gmail.com',
                  icon: Icons.email_outlined,
                  action: TextInputAction.next,
                  keyboard: TextInputType.emailAddress,
                  autocorrect: false,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email requis';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$')
                        .hasMatch(v.trim())) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Téléphone
                _buildField(
                  controller: _phoneCtrl,
                  label: 'Téléphone (optionnel)',
                  hint: '+225 07 00 00 00',
                  icon: Icons.phone_outlined,
                  action: TextInputAction.next,
                  keyboard: TextInputType.phone,
                ),
                const SizedBox(height: 14),

                // Mot de passe
                _buildPasswordField(
                  controller: _passCtrl,
                  label: 'Mot de passe *',
                  hint: 'Min. 8 caractères',
                  obscure: _obscurePass,
                  toggle: () => setState(() => _obscurePass = !_obscurePass),
                  action: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Mot de passe requis';
                    if (v.length < 8) return 'Minimum 8 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Confirmation
                _buildPasswordField(
                  controller: _confirmCtrl,
                  label: 'Confirmer le mot de passe *',
                  obscure: _obscureConfirm,
                  toggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  action: TextInputAction.done,
                  onSubmit: (_) => _register(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirmation requise';
                    if (v != _passCtrl.text) return 'Mots de passe différents';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Erreur
                if (_errorMessage != null) _ErrorBox(message: _errorMessage!),

                // Bouton inscription
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _isGoogleLoading) ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Créer mon compte Élève',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),

                const SizedBox(height: 20),

                // Lien connexion
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Déjà un compte ? ',
                          style: TextStyle(color: AppColors.textSecondary)),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Se connecter',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Écran confirmation email ───────────────────────────────────────────────
  Widget _buildConfirmScreen() {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.mark_email_read_outlined,
                    size: 48, color: Colors.green),
              ),
              const SizedBox(height: 28),
              Text('Vérifiez vos emails',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Un email de confirmation a été envoyé à :',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _registeredEmail ?? '',
                      style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '1. Ouvrez votre application Gmail\n'
                '2. Trouvez l\'email de PermisConnect\n'
                '3. Cliquez sur "Confirmer votre email"\n'
                '4. Revenez ici et connectez-vous',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(height: 1.8, color: Colors.black87),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.login),
                  label: const Text('Se connecter après confirmation',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _resendConfirmation,
                icon: const Icon(Icons.refresh),
                label: const Text('Renvoyer l\'email'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() {
                  _uiState = null;
                  _errorMessage = null;
                }),
                child: const Text('← Modifier mon email',
                    style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers UI ─────────────────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    required TextInputAction action,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization caps = TextCapitalization.none,
    bool autocorrect = true,
    String? Function(String?)? validator,
    void Function(String)? onSubmit,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      textInputAction: action,
      textCapitalization: caps,
      autocorrect: autocorrect,
      onFieldSubmitted: onSubmit,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required bool obscure,
    required VoidCallback toggle,
    required TextInputAction action,
    String? Function(String?)? validator,
    void Function(String)? onSubmit,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: action,
      onFieldSubmitted: onSubmit,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(obscure
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined),
          onPressed: toggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
    );
  }
}

// ─── Widgets réutilisables ────────────────────────────────────────────────────

class _BadgeEleve extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.school, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Compte Élève',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text('Accès à vos cours, quiz et planning',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.verified, color: AppColors.primary, size: 20),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: TextStyle(
                      color: AppColors.error, fontSize: 13, height: 1.4)),
            ),
          ],
        ),
      ),
    );
  }
}
