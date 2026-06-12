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

// ─── Session Quiz en cours ────────────────────────────────────────────────────

class QuizSessionState {
  final List<QuizQuestionModel> questions;
  final int currentIndex;
  final Map<int, int> answers; // index question → index réponse choisie
  final bool isFinished;
  final DateTime startTime;

  const QuizSessionState({
    required this.questions,
    this.currentIndex = 0,
    this.answers = const {},
    this.isFinished = false,
    required this.startTime,
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

  QuizSessionState copyWith({
    int? currentIndex,
    Map<int, int>? answers,
    bool? isFinished,
  }) {
    return QuizSessionState(
      questions: questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      isFinished: isFinished ?? this.isFinished,
      startTime: startTime,
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

  void answer(int answerIndex) {
    final s = state;
    if (s == null || s.isFinished) return;

    final newAnswers = Map<int, int>.from(s.answers)
      ..[s.currentIndex] = answerIndex;

    if (s.isLastQuestion) {
      state = s.copyWith(answers: newAnswers, isFinished: true);
    } else {
      state = s.copyWith(
        answers: newAnswers,
        currentIndex: s.currentIndex + 1,
      );
    }
  }

  void reset() => state = null;
}
