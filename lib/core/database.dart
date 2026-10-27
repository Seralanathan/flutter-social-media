import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final instance = AppDatabase._();
  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'app.db');
    return openDatabase(path, version: 1, onCreate: (d, _) async {
      await d.execute(
          'CREATE TABLE users(mobile TEXT PRIMARY KEY, name TEXT, salt TEXT, hash TEXT)');
      await d.execute(
          'CREATE TABLE likes(video_id INTEGER, mobile TEXT, PRIMARY KEY(video_id, mobile))');
      await d.execute(
          'CREATE TABLE comments(id INTEGER PRIMARY KEY AUTOINCREMENT, video_id INTEGER, '
              'mobile TEXT, name TEXT, text TEXT, created_at INTEGER)');
    });
  }

  // ---- users
  Future<Map<String, dynamic>?> getUser(String mobile) async {
    final r = await (await db).query('users', where: 'mobile=?', whereArgs: [mobile]);
    return r.isEmpty ? null : r.first;
  }

  Future<void> insertUser(String mobile, String name, String salt, String hash) async =>
      (await db).insert('users', {'mobile': mobile, 'name': name, 'salt': salt, 'hash': hash});

  // ---- likes
  Future<bool> isLiked(int videoId, String mobile) async =>
      (await (await db).query('likes',
          where: 'video_id=? AND mobile=?', whereArgs: [videoId, mobile]))
          .isNotEmpty;

  Future<int> likeCount(int videoId) async => Sqflite.firstIntValue(await (await db)
      .rawQuery('SELECT COUNT(*) FROM likes WHERE video_id=?', [videoId])) ??
      0;

  Future<void> setLike(int videoId, String mobile, bool like) async {
    final d = await db;
    if (like) {
      await d.insert('likes', {'video_id': videoId, 'mobile': mobile},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      await d.delete('likes', where: 'video_id=? AND mobile=?', whereArgs: [videoId, mobile]);
    }
  }

  // ---- comments
  Future<List<Map<String, dynamic>>> comments(int videoId) async => (await db)
      .query('comments', where: 'video_id=?', whereArgs: [videoId], orderBy: 'created_at DESC');

  Future<int> commentCount(int videoId) async => Sqflite.firstIntValue(await (await db)
      .rawQuery('SELECT COUNT(*) FROM comments WHERE video_id=?', [videoId])) ??
      0;

  Future<void> addComment(int videoId, String mobile, String name, String text) async =>
      (await db).insert('comments', {
        'video_id': videoId,
        'mobile': mobile,
        'name': name,
        'text': text,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
}