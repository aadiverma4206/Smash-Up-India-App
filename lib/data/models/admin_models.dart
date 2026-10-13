class AdminUserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final int roleId;
  final String roleName;
  final String status; // ACTIVE, SUSPENDED
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
      profileImageUrl: rawImage?.toString(),
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
    final num rev = json['totalRevenue'] ??
        json['totalRevenueRupees'] ??
        json['total_revenue'] ??
        0;

    final int games = (json['totalGames'] ?? json['total_games'] ?? 0) as int;

    return AdminDashboardModel(
      totalUsers: (json['totalUsers'] ?? json['total_users'] ?? 0) as int,
      totalManagers:
          (json['totalManagers'] ?? json['total_managers'] ?? 0) as int,
      totalPlayers: (json['totalPlayers'] ?? json['total_players'] ?? 0) as int,
      totalClubs: (json['totalClubs'] ?? json['total_clubs'] ?? 0) as int,
      totalRevenue: rev.toDouble(),
      totalRefunds:
          (json['totalRefunds'] ?? json['total_refunds'] ?? 0).toDouble(),
      pendingDisputes:
          (json['pendingDisputes'] ?? json['pending_disputes'] ?? 0) as int,
      activeRecordings: (json['activeRecordings'] ??
          json['active_recordings'] ??
          games) as int,
      onlineCameras:
          (json['onlineCameras'] ?? json['online_cameras'] ?? 0) as int,
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
  final String? userId;
  final String action;
  final String? details;
  final String? ipAddress;
  final String createdAt;

  AuditLogModel({
    required this.id,
    this.userId,
    required this.action,
    this.details,
    this.ipAddress,
    required this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: (json['id'] ?? '').toString(),
      userId: json['user_id']?.toString() ?? json['userId']?.toString(),
      action: (json['action'] ?? 'SYSTEM_EVENT').toString(),
      details: json['details']?.toString(),
      ipAddress:
          json['ip_address']?.toString() ?? json['ipAddress']?.toString(),
      createdAt: (json['created_at'] ?? json['createdAt'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'action': action,
        'details': details,
        'ipAddress': ipAddress,
        'createdAt': createdAt,
      };
}
