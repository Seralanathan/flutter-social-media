import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../auth/auth_provider.dart';
import 'reels_provider.dart';

class ReelsScreen extends StatefulWidget {
  final bool tabActive;
  const ReelsScreen({super.key, required this.tabActive});
  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final reels = context.read<ReelsProvider>().reels;
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: reels.length,
      onPageChanged: (i) => setState(() => _page = i),
      itemBuilder: (_, i) => ReelItem(reel: reels[i], active: widget.tabActive && i == _page),
    );
  }
}

class ReelItem extends StatefulWidget {
  final Reel reel;
  final bool active;
  const ReelItem({super.key, required this.reel, required this.active});
  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  late final VideoPlayerController _c;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.asset(widget.reel.asset)
      ..initialize().then((_) {
        if (!mounted) return;
        _c.setLooping(true);
        if (widget.active) _c.play();
        setState(() => _ready = true);
      });
  }

  @override
  void didUpdateWidget(ReelItem old) {
    super.didUpdateWidget(old);
    if (!_ready || old.active == widget.active) return;
    widget.active ? _c.play() : _c.pause();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ReelsProvider>(),
        child: CommentsSheet(videoId: widget.reel.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ReelsProvider>();
    final id = widget.reel.id;
    final isLiked = p.liked[id] ?? false;

    return Container(
      color: Colors.black,
      child: Stack(fit: StackFit.expand, children: [
        GestureDetector(
          onTap: () => setState(() => _c.value.isPlaying ? _c.pause() : _c.play()),
          child: _ready
              ? FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(width: _c.value.size.width, height: _c.value.size.height, child: VideoPlayer(_c)))
              : const Center(child: CircularProgressIndicator()),
        ),
        Positioned(
          right: 12,
          bottom: 100,
          child: Column(children: [
            _action(isLiked ? Icons.favorite : Icons.favorite_border, '${p.likeCounts[id] ?? 0}',
                    () => p.toggleLike(id), color: isLiked ? Colors.red : Colors.white),
            const SizedBox(height: 20),
            _action(Icons.comment, '${p.commentCounts[id] ?? 0}', _openComments),
            const SizedBox(height: 20),
            _action(Icons.share, 'Share', () => Share.share('Check out ${widget.reel.caption} on Socially!')),
          ]),
        ),
        Positioned(
          left: 16,
          bottom: 100,
          child: Text(widget.reel.caption,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap, {Color color = Colors.white}) => Column(children: [
    IconButton(icon: Icon(icon, color: color, size: 32), onPressed: onTap),
    Text(label, style: const TextStyle(color: Colors.white)),
  ]);
}

class CommentsSheet extends StatefulWidget {
  final int videoId;
  const CommentsSheet({super.key, required this.videoId});
  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final r = await context.read<ReelsProvider>().comments(widget.videoId);
    if (mounted) setState(() => _items = r);
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final name = context.read<AuthProvider>().user!.name;
    await context.read<ReelsProvider>().addComment(widget.videoId, name, text);
    _ctrl.clear();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: 420,
        child: Column(children: [
          const Padding(padding: EdgeInsets.all(12), child: Text('Comments', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('No comments yet'))
                : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (_, i) => ListTile(
                leading: CircleAvatar(child: Text(_items[i]['name'][0].toUpperCase())),
                title: Text(_items[i]['name']),
                subtitle: Text(_items[i]['text']),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(hintText: 'Add a comment...', border: OutlineInputBorder()))),
              IconButton(icon: const Icon(Icons.send), onPressed: _send),
            ]),
          ),
        ]),
      ),
    );
  }
}