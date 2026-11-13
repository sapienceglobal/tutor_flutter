import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/message_service.dart';
import '../../../services/socket_service.dart';
import '../../../utils/constants.dart';
import 'chat_detail_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<dynamic> _conversations = [];
  bool _loading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchConversations();
    _initSocketListener();
  }

  void _initSocketListener() {
    final socket = SocketService().socket;
    if (socket != null) {
      socket.on('chat_message', _handleIncomingChatMessage);
    }
  }

  @override
  void dispose() {
    final socket = SocketService().socket;
    if (socket != null) {
      socket.off('chat_message', _handleIncomingChatMessage);
    }
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchConversations({String? search}) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    if (search == null) setState(() => _loading = true);
    try {
      final res = await MessageService.getConversations(token: token);
      if (res['success'] == true) {
        setState(() {
          _conversations = res['conversations'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load conversations: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleIncomingChatMessage(dynamic data) {
    if (data == null || !mounted) return;
    _fetchConversations(search: _searchCtrl.text.trim().isNotEmpty ? _searchCtrl.text.trim() : null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Inbox', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textMain,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) {
                // Filter local conversations or reload
                _fetchConversations(search: val.trim());
              },
              decoration: InputDecoration(
                hintText: 'Search chats...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _conversations.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _fetchConversations,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _conversations.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) => _buildConversationTile(_conversations[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.forum_outlined, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('No Conversations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
          const SizedBox(height: 8),
          Text('Messages from your active enrollments will appear here.', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> convo) {
    final counterpart = convo['counterpart'] ?? {};
    final counterpartId = convo['counterpartId'] ?? '';
    final name = counterpart['name'] ?? 'User';
    final profileImage = counterpart['profileImage'];
    final lastMessage = convo['lastMessage'] ?? {};
    final body = lastMessage['body'] ?? '';
    final isOwn = lastMessage['isOwn'] ?? false;
    final unreadCount = convo['unreadCount'] ?? 0;
    final course = convo['course'] ?? {};
    final courseTitle = course['title'] ?? '';

    final sentAtStr = lastMessage['sentAt'] ?? lastMessage['createdAt'];
    String timeLabel = '';
    if (sentAtStr != null) {
      final dateTime = DateTime.parse(sentAtStr).toLocal();
      final diff = DateTime.now().difference(dateTime);
      if (diff.inDays == 0) {
        timeLabel = DateFormat('jm').format(dateTime);
      } else if (diff.inDays == 1) {
        timeLabel = 'Yesterday';
      } else {
        timeLabel = DateFormat('dd MMM').format(dateTime);
      }
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              partnerId: counterpartId,
              partnerName: name,
              partnerImage: profileImage,
              courseTitle: courseTitle,
              courseId: course['_id'],
            ),
          ),
        ).then((_) => _fetchConversations());
      },
      borderRadius: AppThemeDesign.borderRadiusMedium,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppThemeDesign.borderRadiusMedium,
          boxShadow: const [AppThemeDesign.softShadow],
          border: Border.all(color: Colors.grey.shade100, width: 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: profileImage != null ? NetworkImage(profileImage) : null,
              child: profileImage == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                            color: AppColors.textMain,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeLabel,
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (courseTitle.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        courseTitle,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    isOwn ? 'You: $body' : body,
                    style: TextStyle(
                      fontSize: 13,
                      color: unreadCount > 0 ? AppColors.textMain : Colors.grey[500],
                      fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
