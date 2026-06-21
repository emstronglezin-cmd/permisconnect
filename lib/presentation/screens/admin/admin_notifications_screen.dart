import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/lesson_provider.dart';
import '../../../presentation/providers/student_provider.dart';

class AdminNotificationsScreen extends ConsumerWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // On génère des notifications dynamiques basées sur les données réelles
    final studentsAsync = ref.watch(studentsListProvider);
    final lessonsAsync = ref.watch(allLessonsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Tout lire',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Résumé alertes
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(
              children: [
                _AlertChip(
                  label: 'Alertes',
                  count: 3,
                  color: AppColors.error,
                ),
                SizedBox(width: 10),
                _AlertChip(
                  label: 'Infos',
                  count: 5,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // Notifications dynamiques cours du jour
                lessonsAsync.when(
                  data: (lessons) {
                    final today = DateTime.now();
                    final todayLessons = lessons.where((l) {
                      return l.scheduledAt.year == today.year &&
                          l.scheduledAt.month == today.month &&
                          l.scheduledAt.day == today.day;
                    }).toList();

                    if (todayLessons.isNotEmpty) {
                      return _NotifCard(
                        icon: Icons.event,
                        iconColor: AppColors.primary,
                        title: '${todayLessons.length} cours aujourd\'hui',
                        subtitle:
                            '${todayLessons.where((l) => l.status.toUpperCase() == "SCHEDULED").length} cours planifiés ce jour',
                        time: 'Aujourd\'hui',
                        isRead: false,
                        onTap: () {},
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // Notifications dynamiques nouveaux élèves
                studentsAsync.when(
                  data: (students) {
                    final recentStudents = students.where((s) {
                      // Simuler les nouveaux élèves des 7 derniers jours
                      return s.status.toUpperCase() == 'ACTIVE';
                    }).length;

                    if (recentStudents > 0) {
                      return _NotifCard(
                        icon: Icons.person_add,
                        iconColor: AppColors.success,
                        title: '$recentStudents élèves actifs',
                        subtitle:
                            'Total des élèves actifs dans le système',
                        time: 'Mis à jour',
                        isRead: true,
                        onTap: () {},
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 8),

                // Notifications statiques
                _NotifCard(
                  icon: Icons.warning_amber,
                  iconColor: Colors.orange,
                  title: 'Maintenance véhicule',
                  subtitle:
                      'Vérifiez les dates de prochaine maintenance pour vos véhicules',
                  time: 'Il y a 2h',
                  isRead: false,
                  onTap: () {},
                ),

                _NotifCard(
                  icon: Icons.quiz,
                  iconColor: const Color(0xFF58CC02),
                  title: 'Quiz disponibles',
                  subtitle:
                      'Pensez à insérer les questions quiz via Supabase Dashboard (insert_quiz_data.sql)',
                  time: 'Important',
                  isRead: false,
                  onTap: () {},
                ),

                _NotifCard(
                  icon: Icons.payments,
                  iconColor: AppColors.success,
                  title: 'Suivi des paiements',
                  subtitle:
                      'Validez les paiements en attente dans l\'onglet Paiements',
                  time: 'Il y a 1j',
                  isRead: true,
                  onTap: () {},
                ),

                _NotifCard(
                  icon: Icons.security,
                  iconColor: AppColors.primary,
                  title: 'Système sécurisé',
                  subtitle:
                      'Toutes les inscriptions sont automatiquement en rôle "étudiant". Seul l\'admin peut promouvoir via Dashboard.',
                  time: 'Permanent',
                  isRead: true,
                  onTap: () {},
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────

class _AlertChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _AlertChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(
                '$count',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;
  final bool isRead;
  final VoidCallback onTap;

  const _NotifCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: isRead ? 1 : 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      time,
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
