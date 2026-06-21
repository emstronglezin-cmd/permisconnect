import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../data/models/student_model.dart';
import '../../domain/repositories/student_repository.dart';

class SupabaseStudentRepository implements StudentRepository {
  final SupabaseClient _client;

  SupabaseStudentRepository(this._client);

  /// Récupère l'étudiant connecté. Si aucun enregistrement student n'existe,
  /// en crée un automatiquement (auto-inscription après auth).
  @override
  Future<StudentModel?> getMyStudent() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      // 1) Récupérer le profil
      final profileData = await _client
          .from(SupabaseConfig.tableProfiles)
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (profileData == null) return null;
      final profileId = profileData['id'] as String;

      // 2) Chercher l'enregistrement student existant
      var data = await _client
          .from(SupabaseConfig.tableStudents)
          .select('*, profiles(full_name, phone, avatar_url)')
          .eq('profile_id', profileId)
          .maybeSingle();

      // 3) Si pas de student → créer automatiquement
      if (data == null) {
        try {
          data = await _client
              .from(SupabaseConfig.tableStudents)
              .insert({
                'profile_id': profileId,
                'status': 'ACTIVE',
                'hours_completed': 0,
                'hours_required': 30,
              })
              .select('*, profiles(full_name, phone, avatar_url)')
              .single();
        } catch (_) {
          // Si INSERT échoue (RLS), retourner un model vide basé sur le profil
          return StudentModel(
            id: '',
            profileId: profileId,
            status: 'ACTIVE',
            hoursCompleted: 0,
            hoursRequired: 30,
            createdAt: DateTime.now(),
          );
        }
      }

      return StudentModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<StudentModel>> getAllStudents({
    String? search,
    String? status,
  }) async {
    try {
      List<dynamic> data;
      if (status != null && status.isNotEmpty) {
        data = await _client
            .from(SupabaseConfig.tableStudents)
            .select('*, profiles(full_name, phone, avatar_url)')
            .eq('status', status.toUpperCase())
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
    } catch (_) {
      return [];
    }
  }

  @override
  Future<StudentModel?> getStudentById(String id) async {
    try {
      final data = await _client
          .from(SupabaseConfig.tableStudents)
          .select('*, profiles(full_name, phone, avatar_url)')
          .eq('id', id)
          .maybeSingle();

      if (data == null) return null;
      return StudentModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateStudentHours(String studentId, int hours) async {
    await _client
        .from(SupabaseConfig.tableStudents)
        .update({'hours_completed': hours})
        .eq('id', studentId);
  }

  Future<void> updateStudentStatus(String studentId, String status) async {
    await _client
        .from(SupabaseConfig.tableStudents)
        .update({'status': status})
        .eq('id', studentId);
  }
}
