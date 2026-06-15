import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/auth_provider.dart';

/// Écran d'inscription — UNIQUEMENT pour les élèves.
/// Aucune option administrateur n'est disponible ici.
/// Les administrateurs sont créés manuellement dans Supabase Dashboard.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _emailConfirmationRequired = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _emailConfirmationRequired = false;
    });

    try {
      debugPrint('[RegisterScreen] Tentative inscription: ${_emailCtrl.text.trim()}');

      await ref.read(authActionsProvider).signUp(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            fullName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim().isEmpty
                ? null
                : _phoneCtrl.text.trim(),
          );

      if (!mounted) return;

      // Vérifier si l'utilisateur a une session active
      final client = ref.read(supabaseClientProvider);
      final session = client.auth.currentSession;

      debugPrint('[RegisterScreen] Session après signUp: ${session != null}');

      if (session == null) {
        // Email de confirmation requis par Supabase
        setState(() {
          _isLoading = false;
          _emailConfirmationRequired = true;
        });
        return;
      }

      // Session active → rediriger vers espace élève
      if (mounted) {
        context.go('/student/home');
      }
    } catch (e) {
      debugPrint('[RegisterScreen] Erreur inscription: $e');
      if (mounted) {
        setState(() {
          _errorMessage = _parseRegisterError(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  String _parseRegisterError(String error) {
    final lower = error.toLowerCase();
    debugPrint('[RegisterScreen] Parse error: $error');

    if (lower.contains('user already registered') ||
        lower.contains('already been registered') ||
        lower.contains('already registered') ||
        lower.contains('email address is already') ||
        lower.contains('duplicate')) {
      return 'Cette adresse email est déjà utilisée. Connectez-vous ou réinitialisez votre mot de passe.';
    }
    if (lower.contains('password should be at least') ||
        lower.contains('password must be') ||
        lower.contains('weak_password') ||
        lower.contains('at least 6')) {
      return 'Mot de passe trop faible. Utilisez au moins 8 caractères.';
    }
    if (lower.contains('unable to validate email') ||
        lower.contains('invalid email') ||
        lower.contains('email is invalid')) {
      return 'Adresse email invalide. Vérifiez le format (ex: nom@domaine.com).';
    }
    if (lower.contains('signup is disabled') ||
        lower.contains('signups not allowed') ||
        lower.contains('not allowed')) {
      return 'Les inscriptions sont temporairement désactivées. Réessayez plus tard.';
    }
    if (lower.contains('rate limit') ||
        lower.contains('too many requests') ||
        lower.contains('over_email_send_rate_limit')) {
      return 'Trop de tentatives. Attendez quelques minutes avant de réessayer.';
    }
    if (lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('socket') ||
        lower.contains('timeout')) {
      return 'Problème de réseau. Vérifiez votre connexion internet.';
    }
    if (lower.contains('invalid api key') ||
        lower.contains('unauthorized') ||
        lower.contains('401')) {
      return 'Erreur de configuration. Contactez le support.';
    }

    debugPrint('[RegisterScreen] Erreur non gérée: $error');
    return 'Erreur: ${error.length > 80 ? error.substring(0, 80) : error}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Écran de confirmation email
    if (_emailConfirmationRequired) {
      return _buildEmailConfirmationScreen(theme);
    }

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
                // ── En-tête ──────────────────────────────────────────
                Text(
                  'Créer un compte',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rejoignez PermisConnect dès maintenant',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Badge Élève ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.school,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Compte Élève',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Accès à vos cours, quiz et planning',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.verified,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Nom complet ──────────────────────────────────────
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Nom complet *',
                    hintText: 'Ex : Kondabo Abdoul Aziz',
                    prefixIcon: const Icon(Icons.person_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Le nom est requis';
                    }
                    if (v.trim().length < 3) {
                      return 'Nom trop court (min. 3 caractères)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── Email ────────────────────────────────────────────
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Adresse email *',
                    hintText: 'exemple@email.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'L\'email est requis';
                    }
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$')
                        .hasMatch(v.trim())) {
                      return 'Format d\'email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── Téléphone (optionnel) ────────────────────────────
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Téléphone (optionnel)',
                    hintText: '+225 07 00 00 00',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Mot de passe ─────────────────────────────────────
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe *',
                    hintText: 'Min. 8 caractères',
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
                    if (v == null || v.isEmpty) {
                      return 'Le mot de passe est requis';
                    }
                    if (v.length < 8) {
                      return 'Minimum 8 caractères requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── Confirmation mot de passe ────────────────────────
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe *',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Confirmation requise';
                    }
                    if (v != _passwordCtrl.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ── Message d'erreur ─────────────────────────────────
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
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Bouton inscription ───────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Créer mon compte Élève',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Lien vers connexion ──────────────────────────────
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Déjà un compte ? ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text(
                          'Se connecter',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
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

  /// Écran affiché si Supabase exige une confirmation email
  Widget _buildEmailConfirmationScreen(ThemeData theme) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 48,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Vérifiez vos emails',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Un lien de confirmation a été envoyé à :',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _emailCtrl.text.trim(),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Cliquez sur le lien dans l\'email pour activer votre compte, puis connectez-vous.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Aller à la connexion',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _emailConfirmationRequired = false;
                    _isLoading = false;
                  });
                },
                child: const Text('Modifier mon email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
