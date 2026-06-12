import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../data/models/lesson_model.dart';
import '../../domain/repositories/lesson_repository.dart';

class SupabaseLessonRepository implements LessonRepository {
  final SupabaseClient _client;

  SupabaseLessonRepository(this._client);

  static const _joinQuery =
      '*, students(profiles(full_name)), instructors(profiles(full_name)), vehicles(brand, model)';

  @override
  Future<List<LessonModel>> getMyLessons() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    // Récupérer le student_id de l'utilisateur
    final profileData = await _client
        .from(SupabaseConfig.tableProfiles)
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();
    if (profileData == null) return [];

    final studentData = await _client
        .from(SupabaseConfig.tableStudents)
        .select('id')
        .eq('profile_id', profileData['id'] as String)
        .maybeSingle();
    if (studentData == null) return [];

    final data = await _client
        .from(SupabaseConfig.tableDrivingLessons)
        .select(_joinQuery)
        .eq('student_id', studentData['id'] as String)
        .order('scheduled_at', ascending: true);

    return (data as List)
        .map((json) => LessonModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<LessonModel>> getLessonsByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final data = await _client
        .from(SupabaseConfig.tableDrivingLessons)
        .select(_joinQuery)
        .gte('scheduled_at', startOfDay.toIso8601String())
        .lt('scheduled_at', endOfDay.toIso8601String())
        .order('scheduled_at', ascending: true);

    return (data as List)
        .map((json) => LessonModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<LessonModel>> getAllLessons({
    DateTime? from,
    DateTime? to,
  }) async {
    // Construire la requête avec filtres de dates optionnels
    var baseQuery = _client
        .from(SupabaseConfig.tableDrivingLessons)
        .select(_joinQuery);

    List<dynamic> data;
    if (from != null && to != null) {
      data = await baseQuery
          .gte('scheduled_at', from.toIso8601String())
          .lte('scheduled_at', to.toIso8601String())
          .order('scheduled_at', ascending: false);
    } else if (from != null) {
      data = await baseQuery
          .gte('scheduled_at', from.toIso8601String())
          .order('scheduled_at', ascending: false);
    } else if (to != null) {
      data = await baseQuery
          .lte('scheduled_at', to.toIso8601String())
          .order('scheduled_at', ascending: false);
    } else {
      data = await baseQuery.order('scheduled_at', ascending: false);
    }

    return data
        .map((json) => LessonModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LessonModel> createLesson(Map<String, dynamic> data) async {
    final result = await _client
        .from(SupabaseConfig.tableDrivingLessons)
        .insert(data)
        .select(_joinQuery)
        .single();
    return LessonModel.fromJson(result);
  }

  @override
  Future<void> cancelLesson(String lessonId) async {
    await _client
        .from(SupabaseConfig.tableDrivingLessons)
        .update({'status': 'cancelled'})
        .eq('id', lessonId);
  }
}
