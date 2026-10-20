import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  late final Database _db;

  Future<void> init() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final path = join(docsDir.path, 'all_stars_arena.db');

    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cached_data (
            key TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS local_notifications (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            type TEXT NOT NULL,
            data_json TEXT,
            is_read INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS local_notifications (
              id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL,
              title TEXT NOT NULL,
              body TEXT NOT NULL,
              type TEXT NOT NULL,
              data_json TEXT,
              is_read INTEGER NOT NULL DEFAULT 0,
              created_at TEXT NOT NULL
            )
          ''');
        }
      },
    );

    await pruneOldNotifications(maxAge: const Duration(days: 3));
    await pruneExpiredCache();
  }

  Future<void> upsertLocalNotifications(
      String userId, List<Map<String, dynamic>> items) async {
    final batch = _db.batch();
    for (final item in items) {
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty) continue;

      final title = item['title']?.toString() ?? 'Notification';
      final body =
          item['body']?.toString() ?? item['message']?.toString() ?? '';
      final type = item['type']?.toString() ?? 'SYSTEM';
      final isRead = (item['isRead'] == true || item['is_read'] == 1) ? 1 : 0;
      final createdAt = item['createdAt']?.toString() ??
          item['created_at']?.toString() ??
          DateTime.now().toIso8601String();

      dynamic dataObj = item['data'];
      String? dataJsonStr;
      if (dataObj != null) {
        if (dataObj is Map) {
          dataJsonStr = jsonEncode(dataObj);
        } else if (dataObj is String) {
          dataJsonStr = dataObj;
        }
      }

      batch.insert(
        'local_notifications',
        {
          'id': id,
          'user_id': userId,
          'title': title,
          'body': body,
          'type': type,
          'data_json': dataJsonStr,
          'is_read': isRead,
          'created_at': createdAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    await pruneOldNotifications(maxAge: const Duration(days: 3));
  }

  Future<List<Map<String, dynamic>>> getLocalNotifications(
      String userId) async {
    await pruneOldNotifications(maxAge: const Duration(days: 3));
    final rows = await _db.query(
      'local_notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return rows.map((row) {
      Map<String, dynamic>? dataMap;
      final dataStr = row['data_json'] as String?;
      if (dataStr != null && dataStr.isNotEmpty) {
        try {
          dataMap = jsonDecode(dataStr) as Map<String, dynamic>?;
        } catch (_) {}
      }

      return {
        'id': row['id'],
        'userId': row['user_id'],
        'title': row['title'],
        'body': row['body'],
        'type': row['type'],
        'data': dataMap,
        'isRead': (row['is_read'] as int?) == 1,
        'createdAt': row['created_at'],
      };
    }).toList();
  }

  Future<void> pruneOldNotifications(
      {Duration maxAge = const Duration(days: 3)}) async {
    try {
      final cutoffIso = DateTime.now().subtract(maxAge).toIso8601String();
      await _db.delete(
        'local_notifications',
        where: 'created_at < ?',
        whereArgs: [cutoffIso],
      );
    } catch (_) {}
  }

  Future<void> markLocalNotificationRead(String id) async {
    await _db.update(
      'local_notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAllLocalNotificationsRead(String userId) async {
    await _db.update(
      'local_notifications',
      {'is_read': 1},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> cacheData(String key, String jsonPayload) async {
    await _db.insert(
      'cached_data',
      {
        'key': key,
        'payload': jsonPayload,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getCachedData(String key) async {
    final results = await _db.query(
      'cached_data',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return results.first['payload'] as String?;
    }
    return null;
  }

  Future<String?> getValidCachedData(String key,
      {Duration maxAge = const Duration(days: 5)}) async {
    try {
      final results = await _db.query(
        'cached_data',
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );

      if (results.isNotEmpty) {
        final updatedAtStr = results.first['updated_at'] as String?;
        if (updatedAtStr != null) {
          final updatedAt = DateTime.tryParse(updatedAtStr);
          if (updatedAt != null) {
            final difference = DateTime.now().difference(updatedAt);
            if (difference <= maxAge) {
              return results.first['payload'] as String?;
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> pruneExpiredCache(
      {Duration maxAge = const Duration(days: 5)}) async {
    try {
      final expiryCutoff = DateTime.now().subtract(maxAge).toIso8601String();
      await _db.delete(
        'cached_data',
        where: 'updated_at < ?',
        whereArgs: [expiryCutoff],
      );
    } catch (_) {}
  }

  Future<void> clearCache() async {
    await _db.delete('cached_data');
    await _db.delete('local_notifications');
  }

  Future<void> clearAllData() async {
    await _db.delete('cached_data');
    await _db.delete('local_notifications');
    try {
      await _db.execute('VACUUM;');
    } catch (_) {}
  }

  Future<int> getCachedCount() async {
    final count = Sqflite.firstIntValue(
      await _db.rawQuery('SELECT COUNT(*) FROM cached_data'),
    );
    return count ?? 0;
  }
}
