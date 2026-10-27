import 'package:flutter/foundation.dart';
import '../core/database.dart';

class Reel {
  final int id;
  final String asset, caption;
  const Reel(this.id, this.asset, this.caption);
}

class ReelsProvider extends ChangeNotifier {
  final String mobile;
  ReelsProvider(this.mobile);

  final _db = AppDatabase.instance;
  final reels = List.generate(5, (i) => Reel(i, 'assets/videos/v${i + 1}.mp4', 'Reel #${i + 1}'));
  final liked = <int, bool>{};
  final likeCounts = <int, int>{};
  final commentCounts = <int, int>{};

  Future<void> load() async {
    for (final r in reels) {
      liked[r.id] = await _db.isLiked(r.id, mobile);
      likeCounts[r.id] = await _db.likeCount(r.id);
      commentCounts[r.id] = await _db.commentCount(r.id);
    }
    notifyListeners();
  }

  Future<void> toggleLike(int id) async {
    final now = !(liked[id] ?? false);
    liked[id] = now;
    likeCounts[id] = (likeCounts[id] ?? 0) + (now ? 1 : -1);
    notifyListeners(); // optimistic UI
    await _db.setLike(id, mobile, now);
  }

  Future<void> addComment(int id, String name, String text) async {
    await _db.addComment(id, mobile, name, text);
    commentCounts[id] = await _db.commentCount(id);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> comments(int id) => _db.comments(id);
}