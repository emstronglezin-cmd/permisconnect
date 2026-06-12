import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../data/models/profile_model.dart';
import '../../domain/repositories/profile_repository.dart';

class SupabaseProfileRepository implements ProfileRepository {
  final SupabaseClient _client;

  SupabaseProfileRepository(this._client);

  @override
  Future<ProfileModel?> getCurrentProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    return getProfileByUserId(userId);
  }

  @override
  Future<ProfileModel?> getProfileByUserId(String userId) async {
    final data = await _client
        .from(SupabaseConfig.tableProfiles)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (data == null) return null;
    return ProfileModel.fromJson(data);
  }

  @override
  Future<ProfileModel> updateProfile({
    required String profileId,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (fullName != null) updates['full_name'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    final data = await _client
        .from(SupabaseConfig.tableProfiles)
        .update(updates)
        .eq('id', profileId)
        .select()
        .single();

    return ProfileModel.fromJson(data);
  }
}
