import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/quiz_provider.dart';
import '../../../presentation/providers/student_provider.dart';

class QuizSessionScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String categoryName;

  const QuizSessionScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  ConsumerState<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends ConsumerState<QuizSessionScreen> {
  int? _selectedAnswer;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    // Démarrer la session quand les questions sont chargées
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuestions();
    });
  }

  Future<void> _loadQuestions() async {
    final questions = await ref.read(
      quizQuestionsProvider(widget.categoryId).future,
    );
    if (questions.isNotEmpty) {
      ref.read(quizSessionProvider.notifier).start(questions);
    }
  }

  void _onAnswer(int index) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = index;
      _answered = true;
    });
  }

  void _next() {
    final session = ref.read(quizSessionProvider);
    if (session == null) return;

    if (_selectedAnswer != null) {
      ref.read(quizSessionProvider.notifier).answer(_selectedAnswer!);
    }

    final updatedSession = ref.read(quizSessionProvider);
    setState(() {
      _selectedAnswer = null;
      _answered = false;
    });

    if (updatedSession?.isFinished == true) {
      _saveAndNavigate(updatedSession!);
    }
  }

  Future<void> _saveAndNavigate(dynamic session) async {
    // Sauvegarder la tentative si l'étudiant est identifié
    try {
      final student = await ref.read(myStudentProvider.future);
      if (student != null) {
        await ref.read(quizRepositoryProvider).saveAttempt(
              studentId: student.id,
              categoryId: widget.categoryId,
              score: session.score,
              totalQuestions: session.totalQuestions,
              correctAnswers: session.correctAnswers,
              durationSeconds: session.durationSeconds,
            );
      }
    } catch (_) {}

    if (mounted) {
      context.go(
        '/student/quiz/session/${widget.categoryId}/result',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(quizSessionProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.categoryName),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (session.isFinished) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.categoryName),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final question = session.currentQuestion;
    if (question == null) {
      return const Scaffold(
        body: Center(child: Text('Aucune question disponible')),
      );
    }

    final progress =
        (session.currentIndex + 1) / session.questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showQuitDialog(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ),
      body: Column(
        children: [
          // En-tête
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Question ${session.currentIndex + 1} / ${session.questions.length}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image si disponible
                  if (question.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        question.imageUrl!,
                        fit: BoxFit.contain,
                        height: 180,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Question
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      question.question,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Réponses
                  ...List.generate(question.options.length, (i) {
                    Color? optionColor;
                    if (_answered) {
                      if (i == question.correctOptionIndex) {
                        optionColor = AppColors.success;
                      } else if (i == _selectedAnswer) {
                        optionColor = AppColors.error;
                      }
                    } else if (i == _selectedAnswer) {
                      optionColor = AppColors.primary;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: _answered ? null : () => _onAnswer(i),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: optionColor != null
                                ? optionColor.withValues(alpha: 0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: optionColor ??
                                  Colors.grey.shade300,
                              width: optionColor != null ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: optionColor ??
                                      Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + i),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: optionColor != null
                                          ? Colors.white
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  question.options[i],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: optionColor,
                                  ),
                                ),
                              ),
                              if (_answered) ...[
                                if (i == question.correctOptionIndex)
                                  Icon(Icons.check_circle,
                                      color: AppColors.success)
                                else if (i == _selectedAnswer)
                                  Icon(Icons.cancel, color: AppColors.error),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  // Explication
                  if (_answered && question.explanation != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              question.explanation!,
                              style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bouton Suivant / Valider
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    _answered ? _next : (_selectedAnswer != null ? _next : null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _answered
                      ? (_selectedAnswer == question.correctOptionIndex
                          ? AppColors.success
                          : AppColors.primary)
                      : AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _answered
                      ? (session.isLastQuestion
                          ? 'Voir les résultats'
                          : 'Question suivante')
                      : 'Valider',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter le quiz ?'),
        content: const Text(
            'Votre progression sera perdue. Voulez-vous vraiment quitter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuer'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(quizSessionProvider.notifier).reset();
              Navigator.pop(ctx);
              context.go('/student/quiz');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }
}
