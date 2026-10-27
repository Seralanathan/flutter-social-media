import 'package:flutter/material.dart';

class Post {
  final String user, caption, avatar, image;
  final int likes;
  const Post(this.user, this.caption, this.avatar, this.image, this.likes);
}

final _posts = List.generate(
  12,
      (i) => Post('user_$i', 'Sample caption number $i #flutter', 'https://i.pravatar.cc/100?img=${i + 1}',
      'https://picsum.photos/seed/post$i/600/600', 20 + i * 7),
);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Socially', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView.builder(
        itemCount: _posts.length + 1,
        itemBuilder: (_, i) => i == 0 ? const StoriesBar() : PostCard(post: _posts[i - 1]),
      ),
    );
  }
}

class StoriesBar extends StatelessWidget {
  const StoriesBar({super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 100,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      itemCount: 10,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, i) => StoryAvatar(name: i == 0 ? 'Your story' : 'user_$i', url: 'https://i.pravatar.cc/100?img=${i + 20}'),
    ),
  );
}

// class StoryAvatar extends StatelessWidget {
//   final String name, url;
//   const StoryAvatar({super.key, required this.name, required this.url});
//   @override
//   Widget build(BuildContext context) => Column(children: [
//     Container(
//       padding: const EdgeInsets.all(2),
//       decoration: const BoxDecoration(
//           shape: BoxShape.circle, gradient: LinearGradient(colors: [Colors.purple, Colors.orange])),
//       child: CircleAvatar(radius: 28, backgroundImage: NetworkImage(url)),
//     ),
//     const SizedBox(height: 4),
//     Text(name, style: const TextStyle(fontSize: 11)),
//   ]);
// }


class StoryAvatar extends StatelessWidget {
  final String name, url;

  const StoryAvatar({
    super.key,
    required this.name,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.orange],
              ),
            ),
            child: CircleAvatar(
              radius: 27,
              backgroundImage: NetworkImage(url),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});
  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool liked = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ListTile(leading: CircleAvatar(backgroundImage: NetworkImage(p.avatar)), title: Text(p.user), trailing: const Icon(Icons.more_vert)),
      Image.network(p.image, width: double.infinity, height: 360, fit: BoxFit.cover,
          loadingBuilder: (c, w, prog) => prog == null ? w : const SizedBox(height: 360, child: Center(child: CircularProgressIndicator()))),
      Row(children: [
        IconButton(
          icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? Colors.red : null),
          onPressed: () => setState(() => liked = !liked),
        ),
        const Icon(Icons.chat_bubble_outline),
      const SizedBox(width: 12),
      const Icon(Icons.send_outlined),
    ]),
    Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('${p.likes + (liked ? 1 : 0)} likes', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 16), child: Text('${p.user}  ${p.caption}')),
    ]);
  }
}