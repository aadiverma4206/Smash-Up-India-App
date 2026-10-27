import 'package:json_annotation/json_annotation.dart';

part 'court_model.g.dart';

double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

class ClubModel {
  final String id;
  final String name;
  final String city;
  final String address;

  ClubModel({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
  });

  factory ClubModel.fromJson(Map<String, dynamic> json) {
    return ClubModel(
      id: (json['id'] ?? json['club_id'] ?? '').toString(),
      name: (json['name'] ?? json['club_name'] ?? 'All Stars Turf').toString(),
      city: (json['city'] ?? 'Raipur').toString(),
      address: (json['address'] ?? 'VIP Road, Raipur').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'city': city,
        'address': address,
      };
}

@JsonSerializable(createFactory: false)
class CourtModel {
  final String id;
  final String clubId;
  final String clubName;
  final String name;
  final String surfaceType;
  final double basePricePerHour;
  final String status;
  final String city;
  final String address;

  CourtModel({
    required this.id,
    required this.clubId,
    required this.clubName,
    required this.name,
    required this.surfaceType,
    required this.basePricePerHour,
    required this.status,
    required this.city,
    required this.address,
  });

  factory CourtModel.fromJson(Map<String, dynamic> json) {
    return CourtModel(
      id: (json['id'] ?? json['court_id'] ?? '').toString(),
      clubId: (json['clubId'] ?? json['club_id'] ?? '').toString(),
      clubName:
          (json['clubName'] ?? json['club_name'] ?? 'Arena Turf').toString(),
      name: (json['name'] ?? json['court_name'] ?? 'Court 1').toString(),
      surfaceType:
          (json['surfaceType'] ?? json['surface'] ?? '3G Turf').toString(),
      basePricePerHour: _parseDouble(
          json['basePricePerHour'] ??
              json['base_price'] ??
              json['base_price_per_hour'],
          0.0),
      status: (json['status'] ?? 'AVAILABLE').toString(),
      city: (json['city'] ?? 'Raipur').toString(),
      address: (json['address'] ?? '').toString(),
    );
  }

  CourtModel copyWith({
    String? id,
    String? clubId,
    String? clubName,
    String? name,
    String? surfaceType,
    double? basePricePerHour,
    String? status,
    String? city,
    String? address,
  }) {
    return CourtModel(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      clubName: clubName ?? this.clubName,
      name: name ?? this.name,
      surfaceType: surfaceType ?? this.surfaceType,
      basePricePerHour: basePricePerHour ?? this.basePricePerHour,
      status: status ?? this.status,
      city: city ?? this.city,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toJson() => _$CourtModelToJson(this);
}

class CourtSlotModel {
  final String id;
  final String courtId;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final String status;
  final String title;
  final String source;

  CourtSlotModel({
    required this.id,
    required this.courtId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.title,
    required this.source,
  });

  factory CourtSlotModel.fromJson(Map<String, dynamic> json) {
    return CourtSlotModel(
      id: (json['id'] ?? '').toString(),
      courtId: (json['courtId'] ?? json['court_id'] ?? '').toString(),
      bookingDate:
          (json['bookingDate'] ?? json['booking_date'] ?? '').toString(),
      startTime: (json['startTime'] ?? json['start_time'] ?? '').toString(),
      endTime: (json['endTime'] ?? json['end_time'] ?? '').toString(),
      status: (json['status'] ?? 'CONFIRMED').toString(),
      title: (json['title'] ?? 'Turf Booking').toString(),
      source: (json['source'] ?? 'BOOKING').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'courtId': courtId,
        'bookingDate': bookingDate,
        'startTime': startTime,
        'endTime': endTime,
        'status': status,
        'title': title,
        'source': source,
      };

  int get startMinutes {
    final parts = startTime.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return h * 60 + m;
    }
    return 0;
  }

  int get endMinutes {
    final parts = endTime.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return h * 60 + m;
    }
    return 0;
  }
}
