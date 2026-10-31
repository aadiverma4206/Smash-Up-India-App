import '../../core/utils/image_utils.dart';

class AdminUserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final int roleId;
  final String roleName;
  final String status;
  final String? city;
  final String? profileImageUrl;
  final String createdAt;

  AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.roleId,
    required this.roleName,
    required this.status,
    this.city,
    this.profileImageUrl,
    required this.createdAt,
  });

  bool get isSuspended => status.toUpperCase() == 'SUSPENDED';
  bool get isPlayer => roleId == 3 || roleName.toUpperCase() == 'PLAYER';
  bool get isManager => roleId == 2 || roleName.toUpperCase() == 'MANAGER';
  bool get isAdmin => roleId == 1 || roleName.toUpperCase() == 'ADMIN';

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    final int parsedRoleId = (json['roleId'] ?? json['role_id'] ?? 3) as int;

    String parsedRoleName =
        (json['roleName'] ?? json['role_name'] ?? '').toString();
    if (parsedRoleName.isEmpty) {
      switch (parsedRoleId) {
        case 1:
          parsedRoleName = 'ADMIN';
          break;
        case 2:
          parsedRoleName = 'MANAGER';
          break;
        case 3:
          parsedRoleName = 'PLAYER';
          break;
        default:
          parsedRoleName = 'USER';
      }
    }

    final rawImage = json['profileImageUrl'] ??
        json['profile_image_url'] ??
        json['avatar_url'] ??
        json['image_url'] ??
        json['avatar'];

    return AdminUserModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Unknown User').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      roleId: parsedRoleId,
      roleName: parsedRoleName,
      status: (json['status'] ?? 'ACTIVE').toString(),
      city: json['city']?.toString(),
      profileImageUrl: rawImage?.toString().sanitizedNetworkUrl,
      createdAt: (json['createdAt'] ?? json['created_at'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'roleId': roleId,
        'roleName': roleName,
        'status': status,
        'city': city,
        'profileImageUrl': profileImageUrl,
        'createdAt': createdAt,
      };
}

class AdminDashboardModel {
  final int totalUsers;
  final int totalManagers;
  final int totalPlayers;
  final int totalClubs;
  final double totalRevenue;
  final double totalRefunds;
  final int pendingDisputes;
  final int activeRecordings;
  final int onlineCameras;

  AdminDashboardModel({
    required this.totalUsers,
    required this.totalManagers,
    required this.totalPlayers,
    required this.totalClubs,
    required this.totalRevenue,
    required this.totalRefunds,
    required this.pendingDisputes,
    required this.activeRecordings,
    required this.onlineCameras,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    final int games = parseInt(json['totalGames'] ?? json['total_games']);
    int courts = parseInt(
      json['totalCourts'] ??
          json['total_courts'] ??
          json['totalClubs'] ??
          json['total_clubs'],
    );
    if (courts <= 0) courts = 2;

    return AdminDashboardModel(
      totalUsers: parseInt(json['totalUsers'] ?? json['total_users']),
      totalManagers: parseInt(json['totalManagers'] ?? json['total_managers']),
      totalPlayers: parseInt(json['totalPlayers'] ?? json['total_players']),
      totalClubs: courts,
      totalRevenue: parseDouble(
        json['totalRevenue'] ??
            json['totalRevenueRupees'] ??
            json['total_revenue'] ??
            json['revenue'],
      ),
      totalRefunds: parseDouble(
        json['totalRefunds'] ??
            json['totalRefundsRupees'] ??
            json['total_refunds'] ??
            json['refunds'],
      ),
      pendingDisputes: parseInt(
        json['pendingDisputes'] ?? json['pending_disputes'],
      ),
      activeRecordings: parseInt(
        json['activeRecordings'] ?? json['active_recordings'] ?? games,
      ),
      onlineCameras: parseInt(
        json['onlineCameras'] ?? json['online_cameras'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalUsers': totalUsers,
        'totalManagers': totalManagers,
        'totalPlayers': totalPlayers,
        'totalClubs': totalClubs,
        'totalRevenue': totalRevenue,
        'totalRefunds': totalRefunds,
        'pendingDisputes': pendingDisputes,
        'activeRecordings': activeRecordings,
        'onlineCameras': onlineCameras,
      };
}

class AuditLogModel {
  final String id;
  final String? adminId;
  final String? adminName;
  final String? userId;
  final String action;
  final String? target;
  final String? details;
  final String? ipAddress;
  final String createdAt;

  AuditLogModel({
    required this.id,
    this.adminId,
    this.adminName,
    this.userId,
    required this.action,
    this.target,
    this.details,
    this.ipAddress,
    required this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: (json['id'] ?? '').toString(),
      adminId: json['admin_id']?.toString() ?? json['adminId']?.toString(),
      adminName: json['admin_name']?.toString() ?? json['adminName']?.toString(),
      userId: json['user_id']?.toString() ?? json['userId']?.toString(),
      action: (json['action'] ?? 'SYSTEM_EVENT').toString(),
      target: json['target']?.toString(),
      details: json['details']?.toString(),
      ipAddress:
          json['ip_address']?.toString() ?? json['ipAddress']?.toString(),
      createdAt: (json['created_at'] ?? json['createdAt'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'adminId': adminId,
        'adminName': adminName,
        'userId': userId,
        'action': action,
        'target': target,
        'details': details,
        'ipAddress': ipAddress,
        'createdAt': createdAt,
      };
}

class AdminPaymentSummaryModel {
  final double totalRevenue;
  final double totalRefunds;
  final double netRevenue;
  final int totalTransactions;

  AdminPaymentSummaryModel({
    required this.totalRevenue,
    required this.totalRefunds,
    required this.netRevenue,
    required this.totalTransactions,
  });

  factory AdminPaymentSummaryModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return AdminPaymentSummaryModel(
      totalRevenue: parseDouble(json['totalRevenue'] ?? json['total_revenue']),
      totalRefunds: parseDouble(json['totalRefunds'] ?? json['total_refunds']),
      netRevenue: parseDouble(json['netRevenue'] ?? json['net_revenue']),
      totalTransactions:
          (json['totalTransactions'] ?? json['total_transactions'] ?? 0) as int,
    );
  }
}

class AdminPaymentModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String? userAvatar;
  final double amount;
  final String status;
  final String type;
  final String? matchId;
  final String matchTitle;
  final String? matchTime;
  final String clubName;
  final String courtName;
  final String score;
  final String? videoUrl;
  final bool hasVideo;
  final double refundAmount;
  final String? refundReason;
  final String createdAt;

  AdminPaymentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    this.userAvatar,
    required this.amount,
    required this.status,
    required this.type,
    this.matchId,
    required this.matchTitle,
    this.matchTime,
    required this.clubName,
    required this.courtName,
    required this.score,
    this.videoUrl,
    required this.hasVideo,
    required this.refundAmount,
    this.refundReason,
    required this.createdAt,
  });

  factory AdminPaymentModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return AdminPaymentModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? json['user_id'] ?? '').toString(),
      userName: (json['userName'] ?? json['user_name'] ?? 'Player').toString(),
      userEmail: (json['userEmail'] ?? json['user_email'] ?? '').toString(),
      userPhone: (json['userPhone'] ?? json['user_phone'] ?? '').toString(),
      userAvatar: json['userAvatar'] ?? json['user_avatar'],
      amount: parseDouble(json['amount']),
      status: (json['status'] ?? 'CONFIRMED').toString().toUpperCase(),
      type: (json['type'] ?? 'MATCH_BOOKING').toString(),
      matchId: json['matchId'] ?? json['match_id'],
      matchTitle:
          (json['matchTitle'] ?? json['match_title'] ?? 'Turf Slot Match')
              .toString(),
      matchTime: (json['matchTime'] ?? json['match_time'])?.toString(),
      clubName: (json['clubName'] ?? json['club_name'] ?? 'All Stars Arena')
          .toString(),
      courtName:
          (json['courtName'] ?? json['court_name'] ?? 'Main Arena').toString(),
      score: (json['score'] ?? '0 - 0').toString(),
      videoUrl: json['videoUrl'] ?? json['video_url'],
      hasVideo: json['hasVideo'] == true || json['has_video'] == true,
      refundAmount: parseDouble(json['refundAmount'] ?? json['refund_amount']),
      refundReason: json['refundReason'] ?? json['refund_reason'],
      createdAt: (json['createdAt'] ??
              json['created_at'] ??
              DateTime.now().toIso8601String())
          .toString(),
    );
  }
}
