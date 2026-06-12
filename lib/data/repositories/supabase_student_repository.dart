import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../data/models/student_model.dart';
import '../../domain/repositories/student_repository.dart';

class SupabaseStudentRepository implements StudentRepository {
  final SupabaseClient _client;

  SupabaseStudentRepository(this._client);

  @override
  Future<StudentModel?> getMyStudent() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    // Trouver le profil de l'utilisateur, puis son enregistrement student
    final profileData = await _client
        .from(SupabaseConfig.tableProfiles)
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (profileData == null) return null;
    final profileId = profileData['id'] as String;

    final data = await _client
        .from(SupabaseConfig.tableStudents)
        .select('*, profiles(full_name, phone, avatar_url)')
        .eq('profile_id', profileId)
        .maybeSingle();

    if (data == null) return null;
    return StudentModel.fromJson(data);
  }

  @override
  Future<List<StudentModel>> getAllStudents({
    String? search,
    String? status,
  }) async {
    List<dynamic> data;
    if (status != null && status.isNotEmpty) {
      data = await _client
          .from(SupabaseConfig.tableStudents)
          .select('*, profiles(full_name, phone, avatar_url)')
          .eq('status', status)
          .order('created_at', ascending: false);
    } else {
      data = await _client
          .from(SupabaseConfig.tableStudents)
          .select('*, profiles(full_name, phone, avatar_url)')
          .order('created_at', ascending: false);
    }

    final students = data
        .map((json) => StudentModel.fromJson(json as Map<String, dynamic>))
        .toList();

    // Filtre de recherche en mémoire
    if (search != null && search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      return students.where((s) {
        return (s.fullName?.toLowerCase().contains(searchLower) ?? false) ||
            (s.phone?.contains(searchLower) ?? false) ||
            (s.registrationNumber
                    ?.toLowerCase()
                    .contains(searchLower) ??
                false);
      }).toList();
    }

    return students;
  }

  @override
  Future<StudentModel?> getStudentById(String id) async {
    final data = await _client
        .from(SupabaseConfig.tableStudents)
        .select('*, profiles(full_name, phone, avatar_url)')
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return StudentModel.fromJson(data);
  }

  @override
  Future<void> updateStudentHours(String studentId, int hours) async {
    await _client
        .from(SupabaseConfig.tableStudents)
        .update({'hours_completed': hours})
        .eq('id', studentId);
  }
}
