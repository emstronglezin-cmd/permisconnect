import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // AppBar stylisé
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1E65C5),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1450A0), Color(0xFF3D7DD4)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.person_rounded,
                                      color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Bonjour 👋',
                                        style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 13,
                                            color: Colors.white.withValues(alpha: 0.8))),
                                    const Text('Kouamé Issa',
                                        style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white)),
                                  ],
                                ),
                              ],
                            ),
                            Stack(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.notifications_outlined,
                                      color: Colors.white, size: 22),
                                ),
                                Positioned(
                                  right: 8, top: 8,
                                  child: Container(
                                    width: 10, height: 10,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF7F27),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Carte progression globale
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              _buildStat('22/30h', 'Conduite'),
                              _buildDivider(),
                              _buildStat('75%', 'Code'),
                              _buildDivider(),
                              _buildStat('8j', 'Prochain cours'),
                            ],
                          ),
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
                // Prochain cours
                _buildNextLesson(context),
                const SizedBox(height: 24),

                // Modules d'apprentissage
                const Text('Modules',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 14),

                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildModuleCard(
                      context,
                      icon: Icons.quiz_rounded,
                      label: 'Code de la Route',
                      subtitle: '120 questions',
                      progress: 0.75,
                      color: const Color(0xFF1E65C5),
                      route: '/student/quiz',
                    ),
                    _buildModuleCard(
                      context,
                      icon: Icons.calendar_month_rounded,
                      label: 'Mon Agenda',
                      subtitle: '2 cours prévus',
                      progress: 0.6,
                      color: const Color(0xFF27AE60),
                      route: '/student/agenda',
                    ),
                    _buildModuleCard(
                      context,
                      icon: Icons.menu_book_rounded,
                      label: 'Livret',
                      subtitle: '18/25 compétences',
                      progress: 0.72,
                      color: const Color(0xFFFF7F27),
                      route: '/student/livret',
                    ),
                    _buildModuleCard(
                      context,
                      icon: Icons.emoji_events_rounded,
                      label: 'Mes Scores',
                      subtitle: 'Historique quiz',
                      progress: 0.85,
                      color: const Color(0xFF9B59B6),
                      route: '/student/quiz',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Progression par catégorie
                const Text('Progression par thème',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 14),

                _buildProgressCard('Panneaux de signalisation', 0.80, const Color(0xFFE74C3C)),
                const SizedBox(height: 10),
                _buildProgressCard('Priorités & Intersections', 0.65, const Color(0xFFF39C12)),
                const SizedBox(height: 10),
                _buildProgressCard('Vitesses & Distances', 0.55, const Color(0xFF3498DB)),
                const SizedBox(height: 10),
                _buildProgressCard('Sécurité Routière', 0.90, const Color(0xFF27AE60)),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.75))),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1, height: 30,
      color: Colors.white.withValues(alpha: 0.3),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildNextLesson(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF27AE60).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Prochain cours',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.white70)),
                const Text('Conduite en Ville',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 13, color: Colors.white70),
                    const SizedBox(width: 4),
                    const Text('Jeu 22 - 14h00',
                        style: TextStyle(fontSize: 12, color: Colors.white70)),
                    const SizedBox(width: 12),
                    const Icon(Icons.person_outline_rounded, size: 13, color: Colors.white70),
                    const SizedBox(width: 4),
                    const Text('M. Ouédraogo',
                        style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Confirmé',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required double progress,
    required Color color,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Spacer(),
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E))),
            Text(subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text('${(progress * 100).toInt()}%',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(String title, double progress, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_stories_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('${(progress * 100).toInt()}%',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}
