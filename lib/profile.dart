import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../reels/reels_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifications = true;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(Icons.logout_rounded, size: 40),
        title: const Text('Log out?'),
        content: const Text('You will need to log in again to continue.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
        ],
      ),
    );
    if (ok == true && mounted) context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = context.watch<AuthProvider>().user;
    final reels = context.watch<ReelsProvider>();

    if (user == null) return const SizedBox.shrink();

    final likedCount = reels.liked.values.where((v) => v).length;
    final commentTotal = reels.commentCounts.values.fold<int>(0, (a, b) => a + b);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ---------- Header ----------
        Container(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 24, 20, 56),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  _initials(user.name),
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(user.name,
                style: TextStyle(color: cs.onPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.phone_android_rounded, size: 16, color: cs.onPrimary),
                const SizedBox(width: 6),
                Text('+91 ${user.mobile}', style: TextStyle(color: cs.onPrimary)),
              ]),
            ),
          ]),
        ),

        // ---------- Stats (overlaps the header) ----------
        Transform.translate(
          offset: const Offset(0, -32),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 6))],
              ),
              child: Row(children: [
                _Stat(icon: Icons.favorite_rounded, color: Colors.redAccent, value: '$likedCount', label: 'Liked'),
                _divider(cs),
                _Stat(icon: Icons.chat_bubble_rounded, color: cs.primary, value: '$commentTotal', label: 'Comments'),
                _divider(cs),
                _Stat(icon: Icons.play_circle_rounded, color: cs.tertiary, value: '${reels.reels.length}', label: 'Reels'),
              ]),
            ),
          ),
        ),

        // ---------- Settings ----------
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120), // 120 clears the floating nav bar
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Settings', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              child: Column(children: [
                SwitchListTile(
                  secondary: _iconBox(Icons.notifications_rounded, cs),
                  title: const Text('Notifications'),
                  value: _notifications,
                  onChanged: (v) => setState(() => _notifications = v),
                ),
                _tile(Icons.lock_rounded, 'Privacy & security', cs),
                _tile(Icons.help_rounded, 'Help & support', cs),
                _tile(Icons.info_rounded, 'About', cs, onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Socially',
                    applicationVersion: '1.0.0',
                  );
                }),
              ]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.error,
                  side: BorderSide(color: cs.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                onPressed: _confirmLogout,
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _divider(ColorScheme cs) => Container(height: 36, width: 1, color: cs.outlineVariant);

  Widget _iconBox(IconData icon, ColorScheme cs) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
    child: Icon(icon, color: cs.onPrimaryContainer, size: 20),
  );

  Widget _tile(IconData icon, String title, ColorScheme cs, {VoidCallback? onTap}) => ListTile(
    leading: _iconBox(icon, cs),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap ?? () {},
  );
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value, label;
  const _Stat({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Icon(icon, color: color),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]),
  );
}