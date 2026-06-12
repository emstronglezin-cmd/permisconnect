import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/lesson_model.dart';
import '../../data/repositories/supabase_lesson_repository.dart';
import 'auth_provider.dart';

final lessonRepositoryProvider = Provider((ref) {
  return SupabaseLessonRepository(ref.watch(supabaseClientProvider));
});

// Leçons de l'élève connecté
final myLessonsProvider = FutureProvider<List<LessonModel>>((ref) async {
  ref.watch(authStateProvider);
  return ref.read(lessonRepositoryProvider).getMyLessons();
});

// Leçons prochaines de l'élève
final upcomingLessonsProvider = FutureProvider<List<LessonModel>>((ref) async {
  final lessons = await ref.watch(myLessonsProvider.future);
  return lessons
      .where((l) => l.isUpcoming)
      .take(5)
      .toList();
});

// Leçons par date (admin/planning)
final lessonsByDateProvider =
    FutureProvider.family<List<LessonModel>, DateTime>((ref, date) async {
  return ref.read(lessonRepositoryProvider).getLessonsByDate(date);
});

// Toutes les leçons (admin)
final allLessonsProvider =
    StateNotifierProvider<LessonsNotifier, AsyncValue<List<LessonModel>>>(
  (ref) => LessonsNotifier(ref.watch(lessonRepositoryProvider)),
);

class LessonsNotifier extends StateNotifier<AsyncValue<List<LessonModel>>> {
  final SupabaseLessonRepository _repo;

  LessonsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load({DateTime? from, DateTime? to}) async {
    state = const AsyncValue.loading();
    try {
      final lessons = await _repo.getAllLessons(from: from, to: to);
      state = AsyncValue.data(lessons);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> cancel(String lessonId) async {
    await _repo.cancelLesson(lessonId);
    await load();
  }
}
