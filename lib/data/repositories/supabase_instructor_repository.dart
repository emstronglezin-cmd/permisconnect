import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../data/models/instructor_model.dart';

class SupabaseInstructorRepository {
  final SupabaseClient _client;

  SupabaseInstructorRepository(this._client);

  Future<List<InstructorModel>> getAllInstructors() async {
    final data = await _client
        .from(SupabaseConfig.tableInstructors)
        .select('*, profiles(full_name, phone, avatar_url)')
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) =>
            InstructorModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<InstructorModel?> getInstructorById(String id) async {
    final data = await _client
        .from(SupabaseConfig.tableInstructors)
        .select('*, profiles(full_name, phone, avatar_url)')
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return InstructorModel.fromJson(data);
  }
}
