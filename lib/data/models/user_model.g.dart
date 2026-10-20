part of 'user_model.dart';

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'roleId': instance.roleId,
      'roleName': instance.roleName,
      'status': instance.status,
      'city': instance.city,
      'profileImageUrl': instance.profileImageUrl,
      'isAdmin': instance.isAdmin,
      'isManager': instance.isManager,
      'isPlayer': instance.isPlayer,
    };
