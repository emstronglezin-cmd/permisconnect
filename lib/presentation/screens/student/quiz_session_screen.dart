import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/quiz_model.dart';
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

class _QuizSessionScreenState extends ConsumerState<QuizSessionScreen>
    with TickerProviderStateMixin {
  bool _noQuestions = false;
  bool _sessionStarted = false;

  // Animations
  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;
  late AnimationController _feedbackCtrl;
  late Animation<double> _feedbackAnim;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  double _targetProgress = 0.0;
  int _selectedIndex = -1;
  bool _hasAnswered = false;

  @override
  void initState() {
    super.initState();

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _progressAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut),
    );

    _feedbackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _feedbackAnim = CurvedAnimation(
      parent: _feedbackCtrl,
      curve: Curves.easeOutBack,
    );

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounceAnim = CurvedAnimation(
      parent: _bounceCtrl,
      curve: Curves.elasticOut,
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuestions();
    });
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _feedbackCtrl.dispose();
    _shakeCtrl.dispose();
    _bounceCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final questions =
          await ref.read(quizQuestionsProvider(widget.categoryId).future);
      if (mounted) {
        if (questions.isNotEmpty) {
          ref.read(quizSessionProvider.notifier).start(questions);
          setState(() => _sessionStarted = true);
        } else {
          setState(() => _noQuestions = true);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _noQuestions = true);
    }
  }

  void _onSelectAnswer(int index) {
    if (_hasAnswered) return;

    setState(() {
      _selectedIndex = index;
      _hasAnswered = true;
    });

    final isCorrect =
        ref.read(quizSessionProvider.notifier).answer(index);

    // Animations selon résultat
    _feedbackCtrl.forward(from: 0);
    if (isCorrect) {
      _bounceCtrl.forward(from: 0);
    } else {
      _shakeCtrl.forward(from: 0).then((_) => _shakeCtrl.reverse());
    }

    // Mettre à jour barre de progression
    final session = ref.read(quizSessionProvider);
    if (session != null) {
      final newProgress = (session.currentIndex + 1) / session.questions.length;
      _animateProgress(newProgress);
    }
  }

  void _animateProgress(double newVal) {
    final oldVal = _targetProgress;
    _targetProgress = newVal;
    _progressAnim = Tween<double>(begin: oldVal, end: newVal).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut),
    );
    _progressCtrl.forward(from: 0);
  }

  void _onNext() {
    final session = ref.read(quizSessionProvider);
    if (session == null) return;

    setState(() {
      _selectedIndex = -1;
      _hasAnswered = false;
    });

    ref.read(quizSessionProvider.notifier).next();

    final updated = ref.read(quizSessionProvider);
    if (updated?.isFinished == true) {
      _saveAndNavigate(updated!);
    }
  }

  Future<void> _saveAndNavigate(QuizSessionState session) async {
    try {
      final student = await ref.read(myStudentProvider.future);
      if (student != null && student.id.isNotEmpty) {
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
      context.go('/student/quiz/session/${widget.categoryId}/result');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_noQuestions) return _buildNoQuestions();

    final session = ref.watch(quizSessionProvider);

    if (!_sessionStarted || session == null) {
      return _buildLoading();
    }

    if (session.isFinished) {
      return _buildLoading();
    }

    final question = session.currentQuestion;
    if (question == null) return _buildLoading();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showQuitDialog();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(session),
              _buildProgressBar(session),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStreakBanner(session),
                      const SizedBox(height: 16),
                      _buildQuestionCard(question, session),
                      const SizedBox(height: 24),
                      _buildOptions(question, session),
                      if (_hasAnswered && session.showExplanation)
                        _buildExplanation(question, session),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(session, question),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header avec cœurs, XP, fermer ─────────────────────────────────────────

  Widget _buildTopBar(QuizSessionState session) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          // Bouton fermer
          GestureDetector(
            onTap: _showQuitDialog,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          // Compteur de questions
          Expanded(
            child: Text(
              '${session.currentIndex + 1} / ${session.totalQuestions}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          // Cœurs (vies)
          Row(
            children: List.generate(5, (i) {
              return Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Icon(
                  i < session.hearts ? Icons.favorite : Icons.favorite_border,
                  color: i < session.hearts
                      ? const Color(0xFFFF4B4B)
                      : Colors.grey.shade300,
                  size: 18,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Barre de progression animée ────────────────────────────────────────────

  Widget _buildProgressBar(QuizSessionState session) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AnimatedBuilder(
        animation: _progressAnim,
        builder: (_, __) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progressAnim.value,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF58CC02)),
            ),
          );
        },
      ),
    );
  }

  // ── Bannière streak ────────────────────────────────────────────────────────

  Widget _buildStreakBanner(QuizSessionState session) {
    if (session.streak < 2) return const SizedBox.shrink();
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9F00), Color(0xFFFF6B00)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              '${session.streak} en série !',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Carte question ─────────────────────────────────────────────────────────

  Widget _buildQuestionCard(
      QuizQuestionModel question, QuizSessionState session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Catégorie / badge
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.categoryName,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Image si disponible
        if (question.imageUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              question.imageUrl!,
              fit: BoxFit.cover,
              height: 160,
              width: double.infinity,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Texte question
        Text(
          question.question,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ── Options de réponse ─────────────────────────────────────────────────────

  Widget _buildOptions(
      QuizQuestionModel question, QuizSessionState session) {
    return Column(
      children: List.generate(question.options.length, (i) {
        final isSelected = _selectedIndex == i;
        final isCorrect = i == question.correctOptionIndex;
        final answered = session.currentAnswerState != AnswerState.unanswered;

        Color borderColor = const Color(0xFFE5E5E5);
        Color bgColor = Colors.white;
        Color textColor = AppColors.textPrimary;
        Widget? trailingIcon;

        if (answered) {
          if (isCorrect) {
            borderColor = const Color(0xFF58CC02);
            bgColor = const Color(0xFF58CC02).withValues(alpha: 0.08);
            textColor = const Color(0xFF3A8C00);
            trailingIcon = const Icon(Icons.check_circle_rounded,
                color: Color(0xFF58CC02), size: 22);
          } else if (isSelected && !isCorrect) {
            borderColor = const Color(0xFFFF4B4B);
            bgColor = const Color(0xFFFF4B4B).withValues(alpha: 0.08);
            textColor = const Color(0xFFCC0000);
            trailingIcon = const Icon(Icons.cancel_rounded,
                color: Color(0xFFFF4B4B), size: 22);
          }
        } else if (isSelected) {
          borderColor = AppColors.primary;
          bgColor = AppColors.primary.withValues(alpha: 0.06);
        }

        final letterLabels = ['A', 'B', 'C', 'D', 'E', 'F'];
        final letter = i < letterLabels.length ? letterLabels[i] : '${i + 1}';

        Widget card = GestureDetector(
          onTap: _hasAnswered ? null : () => _onSelectAnswer(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                if (!answered && isSelected)
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Row(
              children: [
                // Lettre
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: answered && isCorrect
                        ? const Color(0xFF58CC02)
                        : answered && isSelected && !isCorrect
                            ? const Color(0xFFFF4B4B)
                            : isSelected
                                ? AppColors.primary
                                : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: (answered && (isCorrect || (isSelected && !isCorrect))) ||
                                isSelected
                            ? Colors.white
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    question.options[i],
                    style: TextStyle(
                      color: textColor,
                      fontWeight:
                          answered && isCorrect ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  trailingIcon,
                ],
              ],
            ),
          ),
        );

        // Shake animation pour la mauvaise réponse
        if (answered &&
            isSelected &&
            !isCorrect &&
            session.currentAnswerState == AnswerState.incorrect) {
          card = AnimatedBuilder(
            animation: _shakeAnim,
            builder: (_, child) {
              final offset =
                  math.sin(_shakeAnim.value * math.pi * 6) * 6;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: card,
          );
        }

        // Bounce animation pour la bonne réponse
        if (answered && isCorrect) {
          card = ScaleTransition(scale: _bounceAnim, child: card);
        }

        return card;
      }),
    );
  }

  // ── Explication ────────────────────────────────────────────────────────────

  Widget _buildExplanation(
      QuizQuestionModel question, QuizSessionState session) {
    final isCorrect = session.currentAnswerState == AnswerState.correct;

    return ScaleTransition(
      scale: _feedbackAnim,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCorrect
              ? const Color(0xFF58CC02).withValues(alpha: 0.08)
              : const Color(0xFFFF4B4B).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCorrect
                ? const Color(0xFF58CC02)
                : const Color(0xFFFF4B4B),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  isCorrect ? '✅' : '❌',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  isCorrect ? 'Excellente réponse !' : 'Pas tout à fait…',
                  style: TextStyle(
                    color: isCorrect
                        ? const Color(0xFF3A8C00)
                        : const Color(0xFFCC0000),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if (isCorrect) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF58CC02),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+${session.streak >= 3 ? 15 : 10} XP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (question.explanation != null &&
                question.explanation!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                question.explanation!,
                style: TextStyle(
                  color: isCorrect
                      ? const Color(0xFF3A8C00)
                      : const Color(0xFF880000),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Bouton bas de page ─────────────────────────────────────────────────────

  Widget _buildBottomBar(
      QuizSessionState session, QuizQuestionModel question) {
    final answered = _hasAnswered;
    final isCorrect = session.currentAnswerState == AnswerState.correct;

    if (!answered) {
      // Avant réponse : bouton désactivé si rien sélectionné
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _selectedIndex >= 0 ? () => _onSelectAnswer(_selectedIndex) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedIndex >= 0
                  ? AppColors.primary
                  : Colors.grey.shade200,
              foregroundColor: _selectedIndex >= 0
                  ? Colors.white
                  : Colors.grey.shade400,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Vérifier',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      );
    }

    // Après réponse : bouton Continuer
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: isCorrect
            ? const Color(0xFF58CC02).withValues(alpha: 0.08)
            : const Color(0xFFFF4B4B).withValues(alpha: 0.08),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isCorrect ? const Color(0xFF58CC02) : const Color(0xFFFF4B4B),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            session.isLastQuestion ? 'Voir les résultats' : 'Continuer',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/student/quiz'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnim,
              child: const Icon(
                Icons.quiz_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Préparation du quiz...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pas de questions ───────────────────────────────────────────────────────

  Widget _buildNoQuestions() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/student/quiz'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz_outlined, size: 80, color: Colors.grey.shade200),
              const SizedBox(height: 24),
              const Text(
                'Aucune question disponible',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Les questions pour "${widget.categoryName}" seront bientôt disponibles.\n\nConsultez le guide dans l\'onglet Livret pour réviser en attendant.',
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.go('/student/quiz'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour aux catégories'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dialog quitter ─────────────────────────────────────────────────────────

  void _showQuitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Quitter le quiz ?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
            'Votre progression sera perdue. Voulez-vous vraiment quitter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuer le quiz'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(quizSessionProvider.notifier).reset();
              Navigator.pop(ctx);
              context.go('/student/quiz');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B4B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }
}
