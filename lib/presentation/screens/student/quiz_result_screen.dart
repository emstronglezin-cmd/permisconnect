import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/quiz_provider.dart';

class QuizResultScreen extends ConsumerStatefulWidget {
  const QuizResultScreen({super.key});

  @override
  ConsumerState<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends ConsumerState<QuizResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _scoreCtrl;
  late Animation<double> _scoreAnim;
  late AnimationController _entranceCtrl;
  late Animation<double> _entranceAnim;
  late AnimationController _confettiCtrl;
  final List<_ConfettiParticle> _particles = [];
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();

    _scoreCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scoreAnim = CurvedAnimation(
      parent: _scoreCtrl,
      curve: Curves.easeOutCubic,
    );

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _entranceAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOutBack,
    );

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Générer les particules confetti
    _generateParticles();

    // Lancer les animations avec délai
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _entranceCtrl.forward();
          _scoreCtrl.forward();
          final session = ref.read(quizSessionProvider);
          if (session != null && session.percentage >= 70) {
            _confettiCtrl.repeat();
          }
        }
      });
    });
  }

  void _generateParticles() {
    final colors = [
      const Color(0xFF58CC02),
      const Color(0xFFFF9F00),
      const Color(0xFF1CB0F6),
      const Color(0xFFFF4B4B),
      const Color(0xFF9B59B6),
    ];
    for (int i = 0; i < 40; i++) {
      _particles.add(_ConfettiParticle(
        x: _rng.nextDouble(),
        y: -_rng.nextDouble() * 0.3,
        size: _rng.nextDouble() * 8 + 4,
        color: colors[_rng.nextInt(colors.length)],
        speed: _rng.nextDouble() * 0.6 + 0.3,
        angle: _rng.nextDouble() * 2 * math.pi,
        rotSpeed: _rng.nextDouble() * 4 - 2,
      ));
    }
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    _entranceCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

    final isPassed = session.percentage >= 70;
    final primaryColor =
        isPassed ? const Color(0xFF58CC02) : const Color(0xFFFF4B4B);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Confetti (si réussi)
          if (isPassed)
            AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (_, __) {
                return CustomPaint(
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _confettiCtrl.value,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: FadeTransition(
                opacity: _entranceAnim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(_entranceAnim),
                  child: Column(
                    children: [
                      // Emoji principal
                      Text(
                        isPassed ? '🏆' : '💪',
                        style: const TextStyle(fontSize: 72),
                      ),
                      const SizedBox(height: 16),

                      // Titre
                      Text(
                        isPassed
                            ? 'Bravo ! Tu as réussi !'
                            : 'Continue les efforts !',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isPassed
                            ? 'Tu maîtrises bien cette catégorie !'
                            : 'La note de passage est 70%. Révise et réessaie !',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Cercle score animé
                      ScaleTransition(
                        scale: _entranceAnim,
                        child: _buildScoreCircle(session, primaryColor),
                      ),
                      const SizedBox(height: 32),

                      // Stats XP / Cœurs / Série
                      _buildXpRow(session),
                      const SizedBox(height: 20),

                      // Carte stats détaillées
                      _buildStatsCard(session),
                      const SizedBox(height: 32),

                      // Boutons
                      _buildButtons(context, session),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCircle(QuizSessionState session, Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: AnimatedBuilder(
            animation: _scoreAnim,
            builder: (_, __) {
              return CircularProgressIndicator(
                value: _scoreAnim.value * (session.percentage / 100),
                strokeWidth: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(color),
              );
            },
          ),
        ),
        Column(
          children: [
            AnimatedBuilder(
              animation: _scoreAnim,
              builder: (_, __) {
                final current =
                    (session.percentage * _scoreAnim.value).round();
                return Text(
                  '$current%',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                );
              },
            ),
            Text(
              session.percentage >= 70 ? 'Réussi !' : 'Pas encore',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildXpRow(QuizSessionState session) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _XpBadge(
          icon: '⭐',
          value: '${session.xpEarned}',
          label: 'XP gagnés',
          color: const Color(0xFFFF9F00),
        ),
        _XpBadge(
          icon: '🔥',
          value: '${session.maxStreak}',
          label: 'Meilleure série',
          color: const Color(0xFFFF6B00),
        ),
        _XpBadge(
          icon: '❤️',
          value: '${session.hearts}/5',
          label: 'Vies restantes',
          color: const Color(0xFFFF4B4B),
        ),
      ],
    );
  }

  Widget _buildStatsCard(QuizSessionState session) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _StatRow(
            icon: Icons.check_circle_rounded,
            iconColor: const Color(0xFF58CC02),
            label: 'Bonnes réponses',
            value:
                '${session.correctAnswers} / ${session.totalQuestions}',
          ),
          const SizedBox(height: 12),
          _StatRow(
            icon: Icons.cancel_rounded,
            iconColor: const Color(0xFFFF4B4B),
            label: 'Mauvaises réponses',
            value:
                '${session.totalQuestions - session.correctAnswers} / ${session.totalQuestions}',
          ),
          const SizedBox(height: 12),
          _StatRow(
            icon: Icons.timer_rounded,
            iconColor: AppColors.primary,
            label: 'Durée',
            value: _formatDuration(session.durationSeconds),
          ),
          const SizedBox(height: 12),
          _StatRow(
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFFF9F00),
            label: 'Score XP total',
            value: '${session.xpEarned} XP',
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context, QuizSessionState session) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () {
              ref.read(quizSessionProvider.notifier).reset();
              context.go('/student/quiz');
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'Réessayer un quiz',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
              ref.read(quizSessionProvider.notifier).reset();
              context.go('/student/home');
            },
            icon: const Icon(Icons.home_rounded),
            label: const Text(
              'Retour à l\'accueil',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }
}

// ── Widgets helpers ────────────────────────────────────────────────────────

class _XpBadge extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color color;

  const _XpBadge({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          ),
          child: Center(
            child: Text(icon, style: const TextStyle(fontSize: 24)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ── Confetti ───────────────────────────────────────────────────────────────

class _ConfettiParticle {
  final double x;
  double y;
  final double size;
  final Color color;
  final double speed;
  double angle;
  final double rotSpeed;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speed,
    required this.angle,
    required this.rotSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (p.y + progress * p.speed) % 1.2;
      final x = p.x + math.sin(progress * 4 + p.angle) * 0.05;

      final paint = Paint()..color = p.color.withValues(alpha: 0.85);
      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(progress * p.rotSpeed);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.5),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => true;
}
