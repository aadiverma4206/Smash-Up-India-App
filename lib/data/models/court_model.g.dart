part of 'court_model.dart';

Map<String, dynamic> _$CourtModelToJson(CourtModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clubId': instance.clubId,
      'clubName': instance.clubName,
      'name': instance.name,
      'surfaceType': instance.surfaceType,
      'basePricePerHour': instance.basePricePerHour,
      'status': instance.status,
      'city': instance.city,
      'address': instance.address,
    };
