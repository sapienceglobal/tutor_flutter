import 'package:flutter/material.dart';
import '../../../services/ai_service.dart';
import '../../../services/api_service.dart';
import '../../../utils/constants.dart';
import 'ai_chat_screen.dart';

class AiBuddyScreen extends StatefulWidget {
  const AiBuddyScreen({super.key});

  @override
  State<AiBuddyScreen> createState() => _AiBuddyScreenState();
}

class _AiBuddyScreenState extends State<AiBuddyScreen> {
  bool _isLoading = true;
  List<dynamic> _sessions = [];
  bool _isLocked = false;
  String _lockMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    setState(() {
      _isLoading = true;
      _isLocked = false;
    });

    try {
      final res = await AIService.getChatSessions();
      if (res['success']) {
        setState(() {
          _sessions = res['data'] ?? [];
        });
      }
    } on ApiException catch (e) {
      if (e.featureLocked) {
        setState(() {
          _isLocked = true;
          _lockMessage = e.message;
        });
      } else {
        _showError(e.message);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _startNewChat() async {
    TextEditingController titleCtrl = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New AI Chat'),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(hintText: 'Enter chat topic'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, titleCtrl.text),
            child: const Text('Start'),
          )
        ],
      ),
    );

    if (title != null && title.trim().isNotEmpty) {
      try {
        final res = await AIService.createChatSession(title: title.trim());
        if (res['success']) {
          final newSessionId = res['data']['_id'];
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AiChatScreen(sessionId: newSessionId, title: title)),
          ).then((_) => _fetchSessions());
        }
      } on ApiException catch (e) {
        if (e.featureLocked || e.creditExhausted) {
          _showError(e.message);
        }
      } catch (e) {
        _showError('Failed to create chat: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Buddy'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isLocked
              ? _buildLockedState()
              : _buildSessionList(),
      floatingActionButton: _isLocked || _isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: _startNewChat,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('New Chat', style: TextStyle(color: Colors.white)),
            ),
    );
  }

  Widget _buildLockedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium, size: 80, color: Colors.purple),
            ),
            const SizedBox(height: 24),
            const Text(
              'Premium Feature Locked',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              _lockMessage.isNotEmpty ? _lockMessage : 'This feature requires the AI Features add-on.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSessionList() {
    if (_sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No Chats Yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with your AI Buddy!',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchSessions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final session = _sessions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(Icons.smart_toy, color: AppColors.primary),
              ),
              title: Text(
                session['title'] ?? 'AI Chat',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${session['messages']?.length ?? 0} messages',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AiChatScreen(sessionId: session['_id'], title: session['title'] ?? 'AI Chat')),
                ).then((_) => _fetchSessions());
              },
            ),
          );
        },
      ),
    );
  }
}
