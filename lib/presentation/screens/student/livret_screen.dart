import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/quiz_provider.dart';
import '../../../presentation/providers/student_provider.dart';

class LivretScreen extends ConsumerWidget {
  const LivretScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(mySkillsProvider);
    final studentAsync = ref.watch(myStudentProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon Livret de Conduite'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(mySkillsProvider),
          ),
        ],
      ),
      body: studentAsync.when(
        data: (student) => skillsAsync.when(
          data: (skills) {
            // Grouper les compétences par catégorie
            final grouped = <String, List<dynamic>>{};
            for (final skill in skills) {
              final cat = skill.skillCategory ?? 'Autres';
              grouped[cat] = [...(grouped[cat] ?? []), skill];
            }

            // Progression globale
            final totalLevel = skills.isEmpty
                ? 0
                : skills.fold<int>(0, (sum, s) => sum + s.level);
            final maxLevel = skills.length * 4;
            final globalProgress =
                maxLevel > 0 ? totalLevel / maxLevel : 0.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Carte progression globale
                  _GlobalProgressCard(
                    hoursCompleted: student?.hoursCompleted ?? 0,
                    hoursRequired: student?.hoursRequired ?? 20,
                    globalProgress: globalProgress,
                  ),
                  const SizedBox(height: 20),

                  // Si aucune compétence enregistrée
                  if (skills.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.menu_book,
                              size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text(
                            'Aucune évaluation enregistrée',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Vos compétences seront enregistrées par votre moniteur lors des séances de conduite.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Sections par catégorie
                    ...grouped.entries.map((entry) => _CategorySection(
                          category: entry.key,
                          skills: entry.value,
                        )),
                  ],
                ],
              ),
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Erreur de chargement'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(mySkillsProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox(),
      ),
    );
  }
}

class _GlobalProgressCard extends StatelessWidget {
  final int hoursCompleted;
  final int hoursRequired;
  final double globalProgress;

  const _GlobalProgressCard({
    required this.hoursCompleted,
    required this.hoursRequired,
    required this.globalProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, const Color(0xFF0D3D7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progression globale',
            style: TextStyle(
                color: Colors.white70, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text(
                '$hoursCompleted / $hoursRequired heures',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: hoursRequired > 0
                  ? (hoursCompleted / hoursRequired).clamp(0.0, 1.0)
                  : 0,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(globalProgress * 100).round()}% des compétences maîtrisées',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String category;
  final List<dynamic> skills;

  const _CategorySection({required this.category, required this.skills});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              category,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          const Divider(height: 1),
          ...skills.map((skill) => _SkillRow(skill: skill)),
        ],
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  final dynamic skill;
  const _SkillRow({required this.skill});

  @override
  Widget build(BuildContext context) {
    final level = skill.level as int;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              skill.skillName ?? 'Compétence',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          // Indicateur niveau (0-4 étoiles)
          Row(
            children: List.generate(
              4,
              (i) => Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Icon(
                  i < level ? Icons.star : Icons.star_border,
                  size: 16,
                  color: i < level ? Colors.amber : Colors.grey.shade300,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
