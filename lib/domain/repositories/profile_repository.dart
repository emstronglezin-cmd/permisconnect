import '../../data/models/profile_model.dart';

abstract class ProfileRepository {
  /// Récupérer le profil de l'utilisateur connecté
  Future<ProfileModel?> getCurrentProfile();

  /// Récupérer un profil par user_id
  Future<ProfileModel?> getProfileByUserId(String userId);

  /// Mettre à jour le profil
  Future<ProfileModel> updateProfile({
    required String profileId,
    String? fullName,
    String? phone,
    String? avatarUrl,
  });
}
