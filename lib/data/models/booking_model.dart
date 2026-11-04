import 'package:json_annotation/json_annotation.dart';

part 'booking_model.g.dart';

double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

@JsonSerializable(createFactory: false)
class BookingModel {
  final String id;
  final String courtId;
  final String courtName;
  final String clubName;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final double totalAmount;
  final String status;
  final String? playerName;
  final String? playerPhone;

  BookingModel({
    required this.id,
    required this.courtId,
    required this.courtName,
    required this.clubName,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.totalAmount,
    required this.status,
    this.playerName,
    this.playerPhone,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: (json['id'] ?? json['booking_id'] ?? '').toString(),
      courtId: (json['courtId'] ?? json['court_id'] ?? '').toString(),
      courtName:
          (json['courtName'] ?? json['court_name'] ?? json['court'] ?? 'Court')
              .toString(),
      clubName: (json['clubName'] ??
              json['club_name'] ??
              json['club_id'] ??
              'Smash Up India')
          .toString(),
      bookingDate:
          (json['bookingDate'] ?? json['booking_date'] ?? '').toString(),
      startTime: (json['startTime'] ?? json['start_time'] ?? '').toString(),
      endTime: (json['endTime'] ?? json['end_time'] ?? '').toString(),
      totalAmount: _parseDouble(json['totalAmount'] ??
          json['amount_paid'] ??
          json['total_amount'] ??
          json['amount']),
      status: (json['status'] ?? 'CONFIRMED').toString(),
      playerName: json['playerName']?.toString() ??
          json['player_name']?.toString() ??
          json['user_name']?.toString(),
      playerPhone: json['playerPhone']?.toString() ??
          json['player_phone']?.toString() ??
          json['user_phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => _$BookingModelToJson(this);
}
