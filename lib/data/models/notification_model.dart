import 'package:json_annotation/json_annotation.dart';

part 'notification_model.g.dart';

@JsonSerializable()
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['createdAt'] ??
        json['created_at'] ??
        json['createdAtIso'] ??
        json['timestamp'] ??
        json['date'];
    String createdAtStr = '';
    if (rawDate != null) {
      createdAtStr = rawDate.toString();
    }
    return NotificationModel(
      id: (json['id'] ?? json['notification_id'] ?? '').toString(),
      title: (json['title'] ?? 'Notification').toString(),
      body: (json['body'] ?? json['message'] ?? '').toString(),
      type: (json['type'] ?? 'SYSTEM').toString(),
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : null,
      isRead: json['isRead'] ?? json['is_read'] ?? json['read'] ?? false,
      createdAt: createdAtStr,
    );
  }
  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);
}
