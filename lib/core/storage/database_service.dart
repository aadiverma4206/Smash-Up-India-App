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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cached_data (
            key TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
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

  Future<void> clearCache() async {
    await _db.delete('cached_data');
  }

  Future<void> clearAllData() async {
    await _db.delete('cached_data');
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
