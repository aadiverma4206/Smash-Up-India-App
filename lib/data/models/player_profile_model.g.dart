part of 'player_profile_model.dart';

Map<String, dynamic> _$PlayerProfileModelToJson(PlayerProfileModel instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'city': instance.city,
      'bio': instance.bio,
      'avatarUrl': instance.avatarUrl,
      'dateOfBirth': instance.dateOfBirth,
      'position': instance.position,
      'secondaryPosition': instance.secondaryPosition,
      'preferredFoot': instance.preferredFoot,
      'skillLevel': instance.skillLevel,
      'ovr': instance.ovr,
      'elo': instance.elo,
      'walletBalance': instance.walletBalance,
      'accountStatus': instance.accountStatus,
    };
