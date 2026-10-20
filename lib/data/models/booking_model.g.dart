part of 'booking_model.dart';

Map<String, dynamic> _$BookingModelToJson(BookingModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'courtId': instance.courtId,
      'courtName': instance.courtName,
      'clubName': instance.clubName,
      'bookingDate': instance.bookingDate,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'totalAmount': instance.totalAmount,
      'status': instance.status,
      'playerName': instance.playerName,
      'playerPhone': instance.playerPhone,
    };
