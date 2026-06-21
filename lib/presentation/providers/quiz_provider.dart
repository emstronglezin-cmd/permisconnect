import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/quiz_model.dart';
import '../../data/repositories/supabase_quiz_repository.dart';
import '../../domain/repositories/quiz_repository.dart';
import 'auth_provider.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return SupabaseQuizRepository(ref.watch(supabaseClientProvider));
});

// Catégories de quiz
final quizCategoriesProvider =
    FutureProvider<List<QuizCategoryModel>>((ref) async {
  return ref.watch(quizRepositoryProvider).getCategories();
});

// Questions d'une catégorie
final quizQuestionsProvider =
    FutureProvider.family<List<QuizQuestionModel>, String>(
  (ref, categoryId) async {
    return ref
        .watch(quizRepositoryProvider)
        .getQuestionsByCategory(categoryId);
  },
);

// Historique des tentatives
final myQuizAttemptsProvider =
    FutureProvider<List<QuizAttemptModel>>((ref) async {
  ref.watch(authStateProvider);
  return ref.read(quizRepositoryProvider).getMyAttempts();
});

// Compétences de conduite
final mySkillsProvider =
    FutureProvider<List<StudentSkillModel>>((ref) async {
  ref.watch(authStateProvider);
  return ref.read(quizRepositoryProvider).getMySkills();
});

// ─── Session Quiz Duolingo ────────────────────────────────────────────────────

enum AnswerState { unanswered, correct, incorrect }

class DuoQuestionState {
  final QuizQuestionModel question;
  final int? selectedIndex;
  final AnswerState answerState;

  const DuoQuestionState({
    required this.question,
    this.selectedIndex,
    this.answerState = AnswerState.unanswered,
  });

  DuoQuestionState copyWith({
    int? selectedIndex,
    AnswerState? answerState,
  }) {
    return DuoQuestionState(
      question: question,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      answerState: answerState ?? this.answerState,
    );
  }
}

class QuizSessionState {
  final List<QuizQuestionModel> questions;
  final int currentIndex;
  final Map<int, int> answers; // index question → index réponse choisie
  final bool isFinished;
  final DateTime startTime;
  // Duolingo extras
  final int hearts; // vies restantes (max 5)
  final int xpEarned; // XP gagnés cette session
  final int streak; // série de bonnes réponses
  final int maxStreak; // meilleure série
  final AnswerState currentAnswerState;
  final bool showExplanation;

  const QuizSessionState({
    required this.questions,
    this.currentIndex = 0,
    this.answers = const {},
    this.isFinished = false,
    required this.startTime,
    this.hearts = 5,
    this.xpEarned = 0,
    this.streak = 0,
    this.maxStreak = 0,
    this.currentAnswerState = AnswerState.unanswered,
    this.showExplanation = false,
  });

  QuizQuestionModel? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  bool get isLastQuestion => currentIndex == questions.length - 1;

  int get correctAnswers {
    int count = 0;
    for (final entry in answers.entries) {
      final question = questions[entry.key];
      if (question.correctOptionIndex == entry.value) count++;
    }
    return count;
  }

  int get score => correctAnswers;
  int get totalQuestions => questions.length;
  double get percentage =>
      totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0;

  int get durationSeconds =>
      DateTime.now().difference(startTime).inSeconds;

  double get progress =>
      totalQuestions > 0 ? (currentIndex / totalQuestions) : 0.0;

  bool get isAlive => hearts > 0;

  QuizSessionState copyWith({
    int? currentIndex,
    Map<int, int>? answers,
    bool? isFinished,
    int? hearts,
    int? xpEarned,
    int? streak,
    int? maxStreak,
    AnswerState? currentAnswerState,
    bool? showExplanation,
  }) {
    return QuizSessionState(
      questions: questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      isFinished: isFinished ?? this.isFinished,
      startTime: startTime,
      hearts: hearts ?? this.hearts,
      xpEarned: xpEarned ?? this.xpEarned,
      streak: streak ?? this.streak,
      maxStreak: maxStreak ?? this.maxStreak,
      currentAnswerState:
          currentAnswerState ?? this.currentAnswerState,
      showExplanation: showExplanation ?? this.showExplanation,
    );
  }
}

final quizSessionProvider =
    StateNotifierProvider.autoDispose<QuizSessionNotifier, QuizSessionState?>(
  (ref) => QuizSessionNotifier(),
);

class QuizSessionNotifier extends StateNotifier<QuizSessionState?> {
  QuizSessionNotifier() : super(null);

  void start(List<QuizQuestionModel> questions) {
    state = QuizSessionState(
      questions: questions,
      startTime: DateTime.now(),
    );
  }

  /// Appelé quand l'utilisateur sélectionne une réponse
  /// Retourne true si correct
  bool answer(int answerIndex) {
    final s = state;
    if (s == null || s.isFinished) return false;
    if (s.currentAnswerState != AnswerState.unanswered) return false;

    final question = s.currentQuestion!;
    final isCorrect = answerIndex == question.correctOptionIndex;

    final newAnswers = Map<int, int>.from(s.answers)
      ..[s.currentIndex] = answerIndex;

    int newHearts = s.hearts;
    int newStreak = s.streak;
    int newMaxStreak = s.maxStreak;
    int newXp = s.xpEarned;

    if (isCorrect) {
      newStreak++;
      newMaxStreak = newStreak > newMaxStreak ? newStreak : newMaxStreak;
      // XP bonus selon streak
      newXp += newStreak >= 3 ? 15 : 10;
    } else {
      newHearts = (s.hearts - 1).clamp(0, 5);
      newStreak = 0;
    }

    state = s.copyWith(
      answers: newAnswers,
      hearts: newHearts,
      xpEarned: newXp,
      streak: newStreak,
      maxStreak: newMaxStreak,
      currentAnswerState:
          isCorrect ? AnswerState.correct : AnswerState.incorrect,
      showExplanation: true,
    );

    return isCorrect;
  }

  /// Avancer à la question suivante
  void next() {
    final s = state;
    if (s == null) return;

    // Plus de vies → game over
    if (s.hearts == 0) {
      state = s.copyWith(isFinished: true);
      return;
    }

    if (s.isLastQuestion) {
      state = s.copyWith(isFinished: true);
    } else {
      state = s.copyWith(
        currentIndex: s.currentIndex + 1,
        currentAnswerState: AnswerState.unanswered,
        showExplanation: false,
      );
    }
  }

  void reset() => state = null;
}
