import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/auth_provider.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profil admin
            profileAsync.when(
              data: (profile) => _ProfileCard(profile: profile),
              loading: () =>
                  const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 20),

            // Section École
            _SettingsSection(
              title: 'Auto-école',
              items: [
                _SettingsItem(
                  icon: Icons.school,
                  label: 'Informations de l\'école',
                  subtitle: 'Nom, adresse, téléphone',
                  onTap: () => _showSchoolInfoDialog(context),
                ),
                _SettingsItem(
                  icon: Icons.schedule,
                  label: 'Horaires d\'ouverture',
                  subtitle: 'Lundi - Samedi',
                  onTap: () => _showInfoSnackbar(context, 'Fonctionnalité bientôt disponible'),
                ),
                _SettingsItem(
                  icon: Icons.euro,
                  label: 'Tarifs des formules',
                  subtitle: 'Permis B, Code seul...',
                  onTap: () => _showInfoSnackbar(context, 'Fonctionnalité bientôt disponible'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section Quiz
            _SettingsSection(
              title: 'Contenu pédagogique',
              items: [
                _SettingsItem(
                  icon: Icons.quiz,
                  label: 'Gérer les catégories quiz',
                  subtitle: 'Ajouter, modifier les catégories',
                  onTap: () =>
                      _showInfoSnackbar(context, 'Gérez les quiz depuis Supabase Dashboard'),
                ),
                _SettingsItem(
                  icon: Icons.library_books,
                  label: 'Cours PDF',
                  subtitle: 'Gérer les supports de cours',
                  onTap: () =>
                      _showInfoSnackbar(context, 'Fonctionnalité bientôt disponible'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section Sécurité
            _SettingsSection(
              title: 'Sécurité & Accès',
              items: [
                _SettingsItem(
                  icon: Icons.admin_panel_settings,
                  iconColor: AppColors.accent,
                  label: 'Modèle de sécurité admin',
                  subtitle: 'Comment fonctionne l\'accès admin',
                  onTap: () => _showSecurityModel(context),
                ),
                _SettingsItem(
                  icon: Icons.lock,
                  label: 'Changer mon mot de passe',
                  subtitle: 'Modifier vos identifiants',
                  onTap: () => _showInfoSnackbar(context, 'Utilisez "Mot de passe oublié" sur l\'écran de connexion'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section Application
            _SettingsSection(
              title: 'Application',
              items: [
                const _SettingsItem(
                  icon: Icons.info_outline,
                  label: 'Version',
                  subtitle: 'PermisConnect v1.0.0',
                  onTap: null,
                ),
                _SettingsItem(
                  icon: Icons.logout,
                  iconColor: AppColors.error,
                  label: 'Se déconnecter',
                  subtitle: 'Quitter le compte admin',
                  onTap: () async {
                    await ref.read(authActionsProvider).signOut();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSchoolInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Informations de l\'école'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.school),
              title: Text('Auto-École PermisConnect'),
              subtitle: Text('Nom de l\'établissement'),
            ),
            ListTile(
              leading: Icon(Icons.location_on),
              title: Text('Abidjan, Côte d\'Ivoire'),
              subtitle: Text('Adresse'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer')),
        ],
      ),
    );
  }

  void _showSecurityModel(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🔒 Sécurité Admin',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Comment fonctionne l\'accès administrateur ?',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12),
              Text(
                '1️⃣  TOUTE nouvelle inscription → rôle "student" automatiquement\n\n'
                '2️⃣  Aucun formulaire ne permet de choisir "admin"\n\n'
                '3️⃣  L\'admin ne peut être créé QUE via Supabase Dashboard :\n'
                '   UPDATE profiles SET role = \'admin\' WHERE user_id = \'UUID\'\n\n'
                '4️⃣  L\'app vérifie le rôle à chaque navigation\n\n'
                '5️⃣  Les pages /admin/* sont protégées par des guards dans le router\n\n'
                '6️⃣  Les règles RLS Supabase bloquent toute manipulation des données sensibles sans authentification appropriée',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  void _showInfoSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

// ── Widgets helpers ────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final dynamic profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF0D3D7A)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              (profile?.fullName ?? 'A').substring(0, 1).toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.fullName ?? 'Administrateur',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Administrateur',
                          style:
                              TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items.map((item) {
              final isLast = items.last == item;
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: (item.iconColor ?? AppColors.primary)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.iconColor ?? AppColors.primary,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      item.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: item.subtitle != null
                        ? Text(item.subtitle!,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12))
                        : null,
                    trailing: item.onTap != null
                        ? const Icon(Icons.chevron_right,
                            color: AppColors.textSecondary)
                        : null,
                    onTap: item.onTap,
                  ),
                  if (!isLast)
                    const Divider(
                        height: 1, indent: 64, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    this.iconColor,
    required this.label,
    this.subtitle,
    this.onTap,
  });
}
