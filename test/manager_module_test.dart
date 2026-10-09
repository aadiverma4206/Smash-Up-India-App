import 'package:flutter_test/flutter_test.dart';
import 'package:all_stars_arena/data/models/manager_models.dart';

void main() {
  group('ALL STARS ARENA Manager Module Unit Tests', () {
    test('ManagerDashboardModel deserializes club analytics correctly', () {
      final json = {
        'club': {
          'id': 'clb_101',
          'name': 'All Stars Turf Raipur',
          'city': 'Raipur',
          'address': 'VIP Road',
          'status': 'ACTIVE',
        },
        'totalRevenue': 48500.0,
        'totalBookings': 32,
        'activeMatches': 3,
        'occupancyRatePercentage': 82.5,
        'onlineCctvCount': 4,
      };

      final dashboard = ManagerDashboardModel.fromJson(json);
      expect(dashboard.club.id, 'clb_101');
      expect(dashboard.club.name, 'All Stars Turf Raipur');
      expect(dashboard.totalRevenue, 48500.0);
      expect(dashboard.occupancyRatePercentage, 82.5);
      expect(dashboard.onlineCctvCount, 4);
    });

    test('ManagerDashboardModel handles backend payload with nested stats and missing top-level keys', () {
      final json = {
        'club': {
          'id': 'clb_103',
          'name': 'Raipur Football Arena',
        },
        'stats': {
          'totalGames': 8,
          'totalBookings': 15,
          'totalRevenueRupees': 22500,
          'cctvStats': {
            'totalCameras': 5,
            'onlineCameras': 3,
            'recordingCameras': 1,
          },
        },
      };

      final dashboard = ManagerDashboardModel.fromJson(json);
      expect(dashboard.club.id, 'clb_103');
      expect(dashboard.club.name, 'Raipur Football Arena');
      expect(dashboard.totalRevenue, 22500.0);
      expect(dashboard.totalBookings, 15);
      expect(dashboard.activeMatches, 8);
      expect(dashboard.onlineCctvCount, 3);
      expect(dashboard.occupancyRatePercentage, 0.0);
    });

    test('ManagerDashboardModel gracefully defaults all missing and null fields', () {
      final json = <String, dynamic>{};
      final dashboard = ManagerDashboardModel.fromJson(json);
      expect(dashboard.totalRevenue, 0.0);
      expect(dashboard.totalBookings, 0);
      expect(dashboard.activeMatches, 0);
      expect(dashboard.occupancyRatePercentage, 0.0);
      expect(dashboard.onlineCctvCount, 0);
      expect(dashboard.club.id, '');
    });
  });
}
