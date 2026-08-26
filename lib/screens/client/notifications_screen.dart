import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).markAllRead();
    });
  }

  String _ago(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifications = Provider.of<NotificationProvider>(context).notifications;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppTheme.creamBg,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryMaroon,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              tooltip: 'Clear all',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear all notifications?'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await Provider.of<NotificationProvider>(context, listen: false).clearAll();
                }
              },
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 14),
                Text('No notifications yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : Colors.grey[500])),
              ]),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (_, i) {
                final n = notifications[i];
                return Container(
                  key: ValueKey(n.id),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: n.read ? null : Border.all(color: AppTheme.primaryMaroon.withOpacity(0.3)),
                    boxShadow: AppTheme.clayCardShadow(isDark: isDark),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: AppTheme.primaryMaroon.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.notifications_rounded, size: 18, color: AppTheme.primaryMaroon),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(n.title,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
                        if (n.body.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(n.body, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[600])),
                        ],
                        const SizedBox(height: 6),
                        Text(_ago(n.receivedAt), style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                      ]),
                    ),
                  ]),
                );
              },
            ),
    );
  }
}
