import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuizResultScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final int correctAnswers;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scoreAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scoreAnim = Tween<double>(begin: 0, end: widget.score.toDouble()).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPassed = widget.score >= 70;
    final wrongAnswers = widget.totalQuestions - widget.correctAnswers;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isPassed
                ? [const Color(0xFF1B7E41), const Color(0xFF27AE60)]
                : [const Color(0xFFC0392B), const Color(0xFFE74C3C)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône résultat
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3),
                  ),
                  child: Icon(
                    isPassed ? Icons.emoji_events_rounded : Icons.replay_rounded,
                    color: Colors.white,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isPassed ? 'Félicitations ! 🎉' : 'Continuez vos efforts !',
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  isPassed
                      ? 'Vous avez réussi ce quiz !'
                      : 'Vous pouvez faire mieux. Réessayez !',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 40),

                // Score animé
                AnimatedBuilder(
                  animation: _scoreAnim,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${_scoreAnim.value.round()}%',
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 64,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                          Text('Score obtenu',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.8))),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // Détails
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                          Icons.check_circle_rounded,
                          '${widget.correctAnswers}',
                          'Bonnes réponses',
                          Colors.white,
                          const Color(0xFF27AE60)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                          Icons.cancel_rounded,
                          '$wrongAnswers',
                          'Mauvaises réponses',
                          Colors.white,
                          const Color(0xFFE74C3C)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                          Icons.quiz_rounded,
                          '${widget.totalQuestions}',
                          'Questions totales',
                          Colors.white,
                          Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Boutons
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => context.go('/student/quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: isPassed
                          ? const Color(0xFF27AE60)
                          : const Color(0xFFE74C3C),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      elevation: 4,
                    ),
                    child: Text(
                      'Choisir un autre thème',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isPassed
                              ? const Color(0xFF27AE60)
                              : const Color(0xFFE74C3C)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/student/home'),
                  child: const Text('Retour à l\'accueil',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color iconColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: accentColor, size: 24),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.75))),
        ],
      ),
    );
  }
}
