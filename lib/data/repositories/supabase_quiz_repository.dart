import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../data/models/quiz_model.dart';
import '../../domain/repositories/quiz_repository.dart';

class SupabaseQuizRepository implements QuizRepository {
  final SupabaseClient _client;

  SupabaseQuizRepository(this._client);

  @override
  Future<List<QuizCategoryModel>> getCategories() async {
    final data = await _client
        .from(SupabaseConfig.tableQuizCategories)
        .select()
        .eq('is_active', true)
        .order('name');

    return (data as List)
        .map((json) =>
            QuizCategoryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<QuizQuestionModel>> getQuestionsByCategory(
    String categoryId, {
    int limit = 20,
  }) async {
    final data = await _client
        .from(SupabaseConfig.tableQuizQuestions)
        .select()
        .eq('category_id', categoryId)
        .limit(limit);

    final questions = (data as List)
        .map((json) =>
            QuizQuestionModel.fromJson(json as Map<String, dynamic>))
        .toList();

    // Mélanger les questions
    questions.shuffle();
    return questions;
  }

  @override
  Future<QuizAttemptModel> saveAttempt({
    required String studentId,
    required String categoryId,
    required int score,
    required int totalQuestions,
    required int correctAnswers,
    required int durationSeconds,
  }) async {
    final data = await _client
        .from(SupabaseConfig.tableQuizAttempts)
        .insert({
          'student_id': studentId,
          'category_id': categoryId,
          'score': score,
          'total_questions': totalQuestions,
          'correct_answers': correctAnswers,
          'duration_seconds': durationSeconds,
        })
        .select()
        .single();

    return QuizAttemptModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<QuizAttemptModel>> getMyAttempts() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

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
        .from(SupabaseConfig.tableQuizAttempts)
        .select()
        .eq('student_id', studentData['id'] as String)
        .order('created_at', ascending: false)
        .limit(50);

    return (data as List)
        .map((json) =>
            QuizAttemptModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<StudentSkillModel>> getMySkills() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

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
        .from(SupabaseConfig.tableStudentSkills)
        .select('*, driving_skills(name, category)')
        .eq('student_id', studentData['id'] as String);

    return (data as List)
        .map((json) =>
            StudentSkillModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
