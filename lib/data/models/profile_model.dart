import '../../core/config/supabase_config.dart';
import '../../domain/entities/user_entity.dart';

class ProfileModel {
  final String id;
  final String userId;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final String? schoolId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProfileModel({
    required this.id,
    required this.userId,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    required this.role,
    this.schoolId,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isAdmin => role == SupabaseConfig.roleAdmin;
  bool get isStudent => role == SupabaseConfig.roleStudent;
  bool get isInstructor => role == SupabaseConfig.roleInstructor;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Utilisateur',
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? SupabaseConfig.roleStudent,
      schoolId: json['school_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'role': role,
      'school_id': schoolId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? role,
    bool? isActive,
  }) {
    return ProfileModel(
      id: id,
      userId: userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      schoolId: schoolId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      userId: userId,
      fullName: fullName,
      phone: phone,
      avatarUrl: avatarUrl,
      role: role,
      createdAt: createdAt,
    );
  }
}
