import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/quiz_provider.dart';

class QuizResultScreen extends ConsumerWidget {
  const QuizResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(quizSessionProvider);

    if (session == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Résultat introuvable'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/student/quiz'),
                child: const Text('Retour aux quiz'),
              ),
            ],
          ),
        ),
      );
    }

    final percentage = session.percentage;
    final isPassed = percentage >= 70;
    final color = isPassed ? AppColors.success : AppColors.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Résultat visuel
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.1),
                  border: Border.all(color: color, width: 4),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${percentage.round()}%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      isPassed ? 'Réussi !' : 'Échoué',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              Text(
                isPassed
                    ? '🎉 Félicitations !'
                    : '💪 Continuez vos efforts !',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isPassed
                    ? 'Vous avez réussi ce quiz avec succès !'
                    : 'La note de passage est 70%. Révisez et réessayez.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 32),

              // Statistiques détaillées
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _ResultRow(
                      icon: Icons.check_circle,
                      iconColor: AppColors.success,
                      label: 'Bonnes réponses',
                      value:
                          '${session.correctAnswers} / ${session.totalQuestions}',
                    ),
                    const Divider(height: 24),
                    _ResultRow(
                      icon: Icons.cancel,
                      iconColor: AppColors.error,
                      label: 'Mauvaises réponses',
                      value:
                          '${session.totalQuestions - session.correctAnswers} / ${session.totalQuestions}',
                    ),
                    const Divider(height: 24),
                    _ResultRow(
                      icon: Icons.timer,
                      iconColor: AppColors.primary,
                      label: 'Durée',
                      value: _formatDuration(session.durationSeconds),
                    ),
                    const Divider(height: 24),
                    _ResultRow(
                      icon: Icons.star,
                      iconColor: Colors.amber,
                      label: 'Score',
                      value: '${session.score} pts',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Boutons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(quizSessionProvider.notifier).reset();
                    context.go('/student/quiz');
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refaire un quiz'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(quizSessionProvider.notifier).reset();
                    context.go('/student/home');
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Retour à l\'accueil'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _ResultRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ],
    );
  }
}
