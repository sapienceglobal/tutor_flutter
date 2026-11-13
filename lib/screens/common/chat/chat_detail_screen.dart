import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/message_service.dart';
import '../../../services/socket_service.dart';
import '../../../utils/constants.dart';

class ChatDetailScreen extends StatefulWidget {
  final String partnerId;
  final String partnerName;
  final String? partnerImage;
  final String? courseTitle;
  final String? courseId;

  const ChatDetailScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
    this.partnerImage,
    this.courseTitle,
    this.courseId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final List<dynamic> _messages = [];
  bool _loading = true;
  bool _submitting = false;
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchMessagesAndMarkRead();
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
    _messageCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessagesAndMarkRead() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    try {
      final res = await MessageService.getConversationMessages(token: token, partnerId: widget.partnerId);
      if (res['success'] == true) {
        setState(() {
          _messages.clear();
          _messages.addAll(res['messages'] ?? []);
          _loading = false;
        });
        _scrollToBottom();
      }
      // Silently mark as read
      await MessageService.markAsRead(token: token, partnerId: widget.partnerId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chat history: $e'), behavior: SnackBarBehavior.floating),
        );
      }
      setState(() => _loading = false);
    }
  }

  void _handleIncomingChatMessage(dynamic data) {
    if (data == null || !mounted) return;
    try {
      final msg = Map<String, dynamic>.from(data);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.user?.id;
      final currentUserRole = authProvider.user?.role;
      final partnerId = widget.partnerId;

      bool matchesConversation = false;
      if (currentUserRole == 'tutor') {
        matchesConversation = (msg['studentId'] == partnerId);
      } else if (currentUserRole == 'student') {
        matchesConversation = (msg['tutorId'] == partnerId);
      }

      if (matchesConversation) {
        msg['isOwn'] = (msg['senderId'] == currentUserId || (msg['senderRole'] != null && msg['senderRole'] == currentUserRole));
        
        setState(() {
          final alreadyExists = _messages.any((m) => m['_id'] == msg['_id']);
          if (!alreadyExists) {
            _messages.add(msg);
          }
        });
        _scrollToBottom();

        final token = authProvider.token;
        if (token != null) {
          MessageService.markAsRead(token: token, partnerId: partnerId);
        }
      }
    } catch (e) {
      debugPrint('Error handling incoming chat message: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() {
      _submitting = true;
      _messageCtrl.clear();
    });

    try {
      final res = await MessageService.sendMessage(
        token: token,
        partnerId: widget.partnerId,
        body: text,
        courseId: widget.courseId,
      );
      if (res['success'] == true) {
        setState(() {
          _messages.add(res['message']);
        });
        _scrollToBottom();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textMain,
        elevation: 0.5,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: widget.partnerImage != null ? NetworkImage(widget.partnerImage!) : null,
              child: widget.partnerImage == null
                  ? Text(
                      widget.partnerName.isNotEmpty ? widget.partnerName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.partnerName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (widget.courseTitle != null && widget.courseTitle!.isNotEmpty)
                    Text(
                      widget.courseTitle!,
                      style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) => _buildMessageBubble(_messages[i]),
                  ),
                ),
                _buildInputSection(),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isOwn = msg['isOwn'] == true;
    final body = msg['body'] ?? '';
    final sentAtStr = msg['sentAt'];
    String timeLabel = '';
    if (sentAtStr != null) {
      final dateTime = DateTime.parse(sentAtStr).toLocal();
      timeLabel = DateFormat('jm').format(dateTime);
    }

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isOwn ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isOwn ? 16 : 4),
            bottomRight: Radius.circular(isOwn ? 4 : 16),
          ),
          boxShadow: const [AppThemeDesign.softShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              body,
              style: TextStyle(
                color: isOwn ? Colors.white : AppColors.textMain,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeLabel,
              style: TextStyle(
                color: isOwn ? Colors.white.withValues(alpha: 0.6) : Colors.grey[400],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageCtrl,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
