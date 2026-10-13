import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/image_utils.dart';

part 'user_model.g.dart';

@JsonSerializable(createFactory: false)
class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final int roleId;
  final String? roleName;
  final String status;
  final String? city;
  final String? profileImageUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.roleId,
    this.roleName,
    required this.status,
    this.city,
    this.profileImageUrl,
  });

  bool get isAdmin => roleId == 1 || (roleName?.toUpperCase() == 'ADMIN');
  bool get isManager => roleId == 2 || (roleName?.toUpperCase() == 'MANAGER');
  bool get isPlayer => roleId == 3 || (roleName?.toUpperCase() == 'PLAYER');

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawImage = (json['profileImageUrl'] ??
            json['profile_image_url'] ??
            json['avatar_url'])
        ?.toString();
    return UserModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      roleId: (json['roleId'] ?? json['role_id'] ?? 3) as int,
      roleName: json['roleName']?.toString() ?? json['role_name']?.toString(),
      status: (json['status'] ?? 'ACTIVE').toString(),
      city: json['city']?.toString(),
      profileImageUrl: rawImage.sanitizedNetworkUrl,
    );
  }

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
