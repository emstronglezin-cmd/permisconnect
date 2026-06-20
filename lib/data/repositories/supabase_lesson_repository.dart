import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../data/models/lesson_model.dart';
import '../../domain/repositories/lesson_repository.dart';

class SupabaseLessonRepository implements LessonRepository {
  final SupabaseClient _client;

  SupabaseLessonRepository(this._client);

  static const _joinQuery =
      '*, instructors(id, profiles(full_name)), vehicles(brand, model)';

  @override
  Future<List<LessonModel>> getMyLessons() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // Récupérer le profil
      final profileData = await _client
          .from(SupabaseConfig.tableProfiles)
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      if (profileData == null) return [];

      // Récupérer le student_id
      final studentData = await _client
          .from(SupabaseConfig.tableStudents)
          .select('id')
          .eq('profile_id', profileData['id'] as String)
          .maybeSingle();
      if (studentData == null) return [];

      // Le schéma utilise scheduled_date (DATE) + start_time (TIME)
      final data = await _client
          .from(SupabaseConfig.tableDrivingLessons)
          .select(_joinQuery)
          .eq('student_id', studentData['id'] as String)
          .order('scheduled_date', ascending: true)
          .order('start_time', ascending: true);

      return (data as List)
          .map((json) => LessonModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<LessonModel>> getLessonsByDate(DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final data = await _client
          .from(SupabaseConfig.tableDrivingLessons)
          .select(_joinQuery)
          .eq('scheduled_date', dateStr)
          .order('start_time', ascending: true);

      return (data as List)
          .map((json) => LessonModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<LessonModel>> getAllLessons({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      List<dynamic> data;
      var baseQuery = _client
          .from(SupabaseConfig.tableDrivingLessons)
          .select(_joinQuery);

      if (from != null && to != null) {
        final fromStr = _dateToStr(from);
        final toStr = _dateToStr(to);
        data = await baseQuery
            .gte('scheduled_date', fromStr)
            .lte('scheduled_date', toStr)
            .order('scheduled_date', ascending: false);
      } else if (from != null) {
        data = await baseQuery
            .gte('scheduled_date', _dateToStr(from))
            .order('scheduled_date', ascending: false);
      } else if (to != null) {
        data = await baseQuery
            .lte('scheduled_date', _dateToStr(to))
            .order('scheduled_date', ascending: false);
      } else {
        data = await baseQuery.order('scheduled_date', ascending: false);
      }

      return data
          .map((json) => LessonModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  String _dateToStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
        .update({'status': 'CANCELLED'})
        .eq('id', lessonId);
  }
}
