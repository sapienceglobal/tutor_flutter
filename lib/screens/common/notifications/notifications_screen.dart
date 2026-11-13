import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  bool _unreadOnly = false;
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final res = await NotificationService.getNotifications(
      unreadOnly: _unreadOnly,
      limit: 50,
    );
    if (!mounted) return;
    setState(() {
      final rawList = res['notifications'];
      if (rawList is List) {
        _notifications = rawList
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else {
        _notifications = [];
      }
      _unreadCount = (res['unreadCount'] as num?)?.toInt() ??
          _notifications.where((n) => n['isRead'] != true).length;
      _isLoading = false;
    });
  }

  Future<void> _markAsRead(Map<String, dynamic> item, int index) async {
    if (item['isRead'] == true) return;
    final id = item['_id']?.toString();
    if (id == null) return;

    setState(() {
      _notifications[index]['isRead'] = true;
      if (_unreadCount > 0) _unreadCount--;
    });
    await NotificationService.markAsRead(id);
  }

  Future<void> _markAllAsRead() async {
    if (_unreadCount == 0) return;
    final ok = await NotificationService.markAllAsRead();
    if (!mounted) return;
    if (ok) {
      setState(() {
        for (final n in _notifications) {
          n['isRead'] = true;
        }
        _unreadCount = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: Color(0xFF0F9D58),
        ),
      );
    }
  }

  Future<void> _deleteNotification(String id, int index) async {
    final removed = _notifications[index];
    setState(() {
      _notifications.removeAt(index);
      if (removed['isRead'] != true && _unreadCount > 0) {
        _unreadCount--;
      }
    });
    await NotificationService.deleteNotification(id);
  }

  String _formatTimestamp(dynamic rawDate) {
    if (rawDate == null) return 'Just now';
    try {
      final dt = DateTime.parse(rawDate.toString()).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('dd MMM, hh:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  ({IconData icon, Color bg, Color fg}) _styleForType(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('exam') || t.contains('quiz')) {
      return (
        icon: Icons.assignment_turned_in_rounded,
        bg: const Color(0xFFFDF3E1),
        fg: const Color(0xFFD97706),
      );
    }
    if (t.contains('live') || t.contains('class')) {
      return (
        icon: Icons.videocam_rounded,
        bg: const Color(0xFFFDE8EE),
        fg: const Color(0xFFE11D48),
      );
    }
    if (t.contains('course') || t.contains('enroll') || t.contains('lesson')) {
      return (
        icon: Icons.menu_book_rounded,
        bg: const Color(0xFFEFEDFF),
        fg: const Color(0xFF5B4CF0),
      );
    }
    if (t.contains('payment') || t.contains('fee') || t.contains('subscription')) {
      return (
        icon: Icons.account_balance_wallet_rounded,
        bg: const Color(0xFFE7F7ED),
        fg: const Color(0xFF0F9D58),
      );
    }
    if (t.contains('message') || t.contains('warning')) {
      return (
        icon: Icons.chat_bubble_rounded,
        bg: const Color(0xFFE0F7F6),
        fg: const Color(0xFF00897B),
      );
    }
    return (
      icon: Icons.notifications_rounded,
      bg: const Color(0xFFEFEDFF),
      fg: const Color(0xFF5B4CF0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              'Notifications',
              style: TextStyle(
                color: const Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEDFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount new',
                  style: TextStyle(
                    color: const Color(0xFF5B4CF0),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 16, color: Color(0xFF5B4CF0)),
              label: Text(
                'Mark all read',
                style: TextStyle(
                  color: const Color(0xFF5B4CF0),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE3E7EF))),
            ),
            child: Row(
              children: [
                _buildFilterPill('All Activity', !_unreadOnly, () {
                  if (_unreadOnly) {
                    setState(() => _unreadOnly = false);
                    _loadNotifications();
                  }
                }),
                const SizedBox(width: 8),
                _buildFilterPill('Unread ($_unreadCount)', _unreadOnly, () {
                  if (!_unreadOnly) {
                    setState(() => _unreadOnly = true);
                    _loadNotifications();
                  }
                }),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5B4CF0)),
            )
          : RefreshIndicator(
              color: const Color(0xFF5B4CF0),
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFEDFF),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.notifications_none_rounded,
                                  size: 34,
                                  color: Color(0xFF5B4CF0),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _unreadOnly ? 'No unread notifications' : 'You\'re all caught up!',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Course updates, live classes, and exam alerts will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = _notifications[index];
                        final id = item['_id']?.toString() ?? '$index';
                        final isRead = item['isRead'] == true;
                        final title = item['title']?.toString() ?? 'Notification';
                        final message = item['message']?.toString() ?? '';
                        final timeLabel = _formatTimestamp(item['createdAt']);
                        final style = _styleForType(item['type']?.toString());

                        return Dismissible(
                          key: ValueKey(id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _deleteNotification(id, index),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDE8EE),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE11D48)),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _markAsRead(item, index),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isRead ? Colors.white : const Color(0xFFF9F8FF),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isRead
                                      ? const Color(0xFFE3E7EF)
                                      : const Color(0xFF5B4CF0).withOpacity(0.32),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: style.bg,
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Icon(style.icon, color: style.fg, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: isRead ? FontWeight.w700 : FontWeight.w800,
                                                  color: const Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                            if (!isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                margin: const EdgeInsets.only(left: 8),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF5B4CF0),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (message.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            message,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: const Color(0xFF475569),
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              timeLabel,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF94A3B8),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => _deleteNotification(id, index),
                                              child: Text(
                                                'Dismiss',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(0xFF64748B),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildFilterPill(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF5B4CF0) : const Color(0xFFF2F4F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? const Color(0xFF5B4CF0) : const Color(0xFFE3E7EF),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
