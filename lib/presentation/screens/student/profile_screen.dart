import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1E65C5),
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1450A0), Color(0xFF3D7DD4)],
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 90, height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              child: const Icon(Icons.person_rounded,
                                  color: Colors.white, size: 50),
                            ),
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                width: 26, height: 26,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF7F27),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit_rounded,
                                    color: Colors.white, size: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Kouamé Issa',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF7F27).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Élève - Formule Standard',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Carte résumé
                _buildSummaryCard(),
                const SizedBox(height: 20),

                // Informations personnelles
                _buildSection('Informations personnelles', [
                  _buildInfoTile(Icons.email_outlined, 'Email', 'kouame.issa@email.com'),
                  _buildInfoTile(Icons.phone_outlined, 'Téléphone', '+226 70 12 34 56'),
                  _buildInfoTile(Icons.calendar_today_outlined, 'Inscription', '15 Janvier 2024'),
                  _buildInfoTile(Icons.school_outlined, 'Formule', 'Standard - 30h de conduite'),
                ]),
                const SizedBox(height: 16),

                // Paramètres
                _buildSection('Paramètres', [
                  _buildSettingTile(Icons.notifications_outlined, 'Notifications',
                    trailing: Switch(
                      value: true,
                      onChanged: (_) {},
                      activeColor: const Color(0xFF1E65C5),
                    )),
                  _buildSettingTile(Icons.language_outlined, 'Langue', subtitle: 'Français'),
                  _buildSettingTile(Icons.dark_mode_outlined, 'Thème sombre',
                    trailing: Switch(
                      value: false,
                      onChanged: (_) {},
                      activeColor: const Color(0xFF1E65C5),
                    )),
                  _buildSettingTile(Icons.offline_bolt_outlined, 'Mode hors-ligne',
                    subtitle: 'Quiz disponibles sans connexion',
                    trailing: Switch(
                      value: true,
                      onChanged: (_) {},
                      activeColor: const Color(0xFF1E65C5),
                    )),
                ]),
                const SizedBox(height: 16),

                // Aide et support
                _buildSection('Aide et support', [
                  _buildSettingTile(Icons.help_outline_rounded, 'Centre d\'aide'),
                  _buildSettingTile(Icons.bug_report_outlined, 'Signaler un problème'),
                  _buildSettingTile(Icons.info_outline_rounded, 'À propos', subtitle: 'Version 1.0.0'),
                ]),
                const SizedBox(height: 16),

                // Bouton déconnexion
                Container(
                  margin: const EdgeInsets.only(bottom: 80),
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.logout_rounded, color: Color(0xFFE74C3C)),
                    label: const Text('Se déconnecter',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFFE74C3C),
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE74C3C)),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7F27), Color(0xFFFF9A52)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7F27).withValues(alpha: 0.3),
            blurRadius: 16, offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem('22h', 'Conduite', Colors.white),
          _buildStatDivider(),
          _buildStatItem('75%', 'Score code', Colors.white),
          _buildStatDivider(),
          _buildStatItem('38 500 F', 'Restant', Colors.white70),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color textColor) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor)),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1, height: 32,
      color: Colors.white.withValues(alpha: 0.3),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E65C5), size: 20),
      title: Text(label,
          style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Color(0xFF9CA3AF))),
      subtitle: Text(value,
          style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A2E))),
      dense: true,
    );
  }

  Widget _buildSettingTile(IconData icon, String title,
      {String? subtitle, Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6B7280), size: 22),
      title: Text(title,
          style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A2E))),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded,
          color: Color(0xFFD1D5DB), size: 20),
      dense: true,
    );
  }
}
