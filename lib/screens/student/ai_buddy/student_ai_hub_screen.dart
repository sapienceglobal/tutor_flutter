import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/ai_service.dart';
import '../../../services/enrollment_service.dart';
import '../../../utils/constants.dart';
import '../../../widgets/sapience_ui.dart';
import '../../../widgets/shimmer_loader.dart';

class StudentAiHubScreen extends StatefulWidget {
  final bool embedded;
  const StudentAiHubScreen({super.key, this.embedded = false});

  @override
  State<StudentAiHubScreen> createState() => _StudentAiHubScreenState();
}

class _StudentAiHubScreenState extends State<StudentAiHubScreen> {
  final TextEditingController _askController = TextEditingController();
  final TextEditingController _followUpController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  bool _isChatActive = false;
  String? _activeSessionId;
  String _sessionTitle = 'AI Tutor';
  List<Map<String, dynamic>> _messages = [];
  bool _isSending = false;
  List<dynamic> _chatSessions = [];
  bool _loadingHistory = false;

  List<String> _dynamicSuggestions = const [
    'What is a function in code?',
    'How does a loop work?',
    'Build my exam revision plan.',
    'Give me a small project idea.',
  ];

  @override
  void initState() {
    super.initState();
    _loadCourseAwarePrompts();
    _loadRecentSessions();
  }

  @override
  void dispose() {
    _askController.dispose();
    _followUpController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSessions() async {
    try {
      final res = await AIService.getChatSessions();
      if (res['success'] == true && mounted) {
        setState(() {
          _chatSessions = res['data'] ?? [];
        });
      }
    } catch (_) {}
  }

  Future<void> _loadCourseAwarePrompts() async {
    try {
      final enrollments = await EnrollmentService.getMyEnrollments();
      if (!mounted || enrollments.isEmpty) return;
      final firstCourse = enrollments.first.course.title;
      final secondCourse = enrollments.length > 1
          ? enrollments[1].course.title
          : enrollments.first.course.category.name;
      setState(() {
        _dynamicSuggestions = [
          'Explain key concepts in $firstCourse',
          'Create a quick quiz for $firstCourse',
          'Summarize $secondCourse notes',
          'Build a 7-day study plan for me',
        ];
      });
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _submitPrompt(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty) return;

    _askController.clear();
    _followUpController.clear();

    setState(() {
      _isChatActive = true;
      _messages.add({
        'role': 'user',
        'content': text,
        'createdAt': DateTime.now().toIso8601String(),
      });
      _isSending = true;
    });
    _scrollToBottom();

    try {
      if (_activeSessionId == null) {
        final title = text.length > 32 ? '${text.substring(0, 32)}...' : text;
        final res = await AIService.createChatSession(
          title: title,
          initialMessage: text,
        );
        if (res['success'] == true) {
          final data = res['data'] ?? res['session'];
          _activeSessionId = data?['_id'];
          if (data?['title'] != null) {
            _sessionTitle = data['title'];
          }
          final serverMsgs = data?['messages'];
          if (serverMsgs != null && serverMsgs is List && serverMsgs.isNotEmpty) {
            setState(() {
              _messages = List<Map<String, dynamic>>.from(
                serverMsgs.map((m) => Map<String, dynamic>.from(m)),
              );
            });
          }
          _loadRecentSessions();
        }
      } else {
        final res = await AIService.addMessageToChatSession(
          sessionId: _activeSessionId!,
          message: text,
        );
        if (res['success'] == true) {
          final data = res['data'] ?? res;
          final serverMsgs = data?['messages'];
          if (serverMsgs != null && serverMsgs is List && serverMsgs.isNotEmpty) {
            setState(() {
              _messages = List<Map<String, dynamic>>.from(
                serverMsgs.map((m) => Map<String, dynamic>.from(m)),
              );
            });
          }
        }
      }
    } catch (e) {
      debugPrint('AI Chat response note: $e');
      setState(() {
        final lastMsg = _messages.isNotEmpty ? _messages.last : null;
        if (lastMsg == null || lastMsg['role'] != 'assistant') {
          _messages.add({
            'role': 'assistant',
            'content': 'I am here to help you learn! Let me break down this topic step-by-step for your revision.',
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _loadSessionDetails(String sessionId, String title) async {
    setState(() {
      _loadingHistory = true;
      _activeSessionId = sessionId;
      _sessionTitle = title;
      _isChatActive = true;
    });

    try {
      final res = await AIService.getChatSessionById(sessionId);
      if (res['success'] == true && mounted) {
        final msgs = res['data']?['messages'] ?? [];
        setState(() {
          _messages = List<Map<String, dynamic>>.from(
            msgs.map((m) => Map<String, dynamic>.from(m)),
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error loading chat session: $e');
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  void _startFreshChat() {
    setState(() {
      _isChatActive = false;
      _activeSessionId = null;
      _sessionTitle = 'AI Tutor';
      _messages = [];
      _isSending = false;
    });
  }

  void _showChatHistoryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.72,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, color: AppColors.navy, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'AI Tutor Chat History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _startFreshChat();
                    },
                    icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                    label: const Text(
                      'New Topic',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _chatSessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey[350]),
                          const SizedBox(height: 10),
                          Text(
                            'No previous conversations yet',
                            style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _chatSessions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final session = _chatSessions[i];
                        final id = session['_id']?.toString() ?? '';
                        final title = session['title']?.toString() ?? 'Learning Session';
                        final isCurrent = id == _activeSessionId;

                        return Container(
                          decoration: BoxDecoration(
                            color: isCurrent ? AppColors.primarySoft : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCurrent ? AppColors.primary : const Color(0xFFE5EDF9),
                              width: isCurrent ? 1.5 : 1.0,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: isCurrent ? AppColors.primary : const Color(0xFFEEF4FF),
                              child: Icon(
                                Icons.smart_toy_rounded,
                                color: isCurrent ? Colors.white : AppColors.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                color: AppColors.navy,
                              ),
                            ),
                            subtitle: Text(
                              'Instant & 100% Free for Students',
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 19, color: Colors.grey),
                              onPressed: () async {
                                try {
                                  await AIService.deleteChatSession(id);
                                  setState(() {
                                    _chatSessions.removeWhere((s) => s['_id'] == id);
                                    if (_activeSessionId == id) {
                                      _startFreshChat();
                                    }
                                  });
                                } catch (_) {}
                              },
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              _loadSessionDetails(id, title);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quickActions = [
      (
        icon: Icons.help_outline_rounded,
        color: AppColors.primary,
        tone: SapienceTileTone.blue,
        title: 'Explain a\nConcept',
        prompt: 'Explain a tricky concept from my syllabus in simple steps with examples.',
      ),
      (
        icon: Icons.code_rounded,
        color: AppColors.warning,
        tone: SapienceTileTone.orange,
        title: 'Write a\nCode Example',
        prompt: 'Write a clean, well-commented code example with step-by-step walkthrough.',
      ),
      (
        icon: Icons.settings_suggest_rounded,
        color: AppColors.success,
        tone: SapienceTileTone.green,
        title: 'Solve a\nProblem',
        prompt: 'Help me solve a practice problem step-by-step and highlight common mistakes.',
      ),
      (
        icon: Icons.menu_book_rounded,
        color: AppColors.purple,
        tone: SapienceTileTone.purple,
        title: 'Quiz Me\non a Topic',
        prompt: 'Quiz me with 5 MCQs on my current topic, one question at a time.',
      ),
      (
        icon: Icons.layers_rounded,
        color: AppColors.primary,
        tone: SapienceTileTone.blue,
        title: 'Summarize\nThis Lesson',
        prompt: 'Summarize the core points of my current topic as crisp bullet revision notes.',
      ),
      (
        icon: Icons.lightbulb_outline_rounded,
        color: AppColors.warning,
        tone: SapienceTileTone.pink,
        title: 'Suggest\nPractice Ideas',
        prompt: 'Suggest practical exercises and mini-project ideas tailored to my level.',
      ),
    ];

    return Scaffold(
      body: SapienceBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Dynamic Header: Switches seamlessly between Dashboard & Inline Chat mode
              _isChatActive ? _buildChatHeader() : _buildDashboardHeader(),

              // Dynamic Body: Mascot & Prompts OR Inline Chat conversation
              Expanded(
                child: _isChatActive
                    ? _buildInlineChatBody()
                    : _buildDashboardBody(quickActions),
              ),

              // Docked Bottom Input Composer
              _buildBottomComposer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardHeader() {
    return SapienceHeader(
      title: 'AI Tutor',
      leading: widget.embedded ? const SizedBox(width: 40) : null,
      titleBadge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'New',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Chat History',
          icon: const Icon(Icons.history_rounded, color: AppColors.navy, size: 25),
          onPressed: _showChatHistoryModal,
          splashRadius: 20,
        ),
      ],
    );
  }

  Widget _buildChatHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back to AI Prompts',
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navy, size: 24),
              onPressed: () => setState(() => _isChatActive = false),
              splashRadius: 20,
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _sessionTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16B83A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        '100% Free for Students',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF16882E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'New Conversation',
              icon: const Icon(Icons.add_comment_outlined, color: AppColors.navy, size: 22),
              onPressed: _startFreshChat,
              splashRadius: 20,
            ),
            IconButton(
              tooltip: 'History',
              icon: const Icon(Icons.history_rounded, color: AppColors.navy, size: 24),
              onPressed: _showChatHistoryModal,
              splashRadius: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardBody(List<dynamic> quickActions) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        // Robot mascot with soft radial halo (matches AI Tutor Learning Dashboard.png)
        SizedBox(
          height: 146,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 240,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFE7EEFC),
                      const Color(0xFFEEF2FB).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              Image.asset(
                'assets/images/ai-robot.png',
                height: 140,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
        const Text(
          'Ask Anything, Learn Instantly',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Get instant answers, explanations, code examples and study support with your AI Tutor.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            color: AppColors.textBody,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        // 3x2 Pastel Quick Prompt Tiles
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.08,
          ),
          itemCount: quickActions.length,
          itemBuilder: (_, i) {
            final item = quickActions[i];
            return SapienceTintedTile(
              tone: item.tone,
              borderRadius: 18,
              onTap: () => _submitPrompt(item.prompt),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, color: item.color, size: 30),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                      height: 1.18,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        const Text(
          'Try Asking',
          style: TextStyle(
            fontSize: 17.5,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 4.1,
          ),
          itemCount: _dynamicSuggestions.length,
          itemBuilder: (_, i) {
            final text = _dynamicSuggestions[i];
            return GestureDetector(
              onTap: () => _submitPrompt(text),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE3EAF6)),
                  boxShadow: const [AppThemeDesign.softShadow],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 15, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Study Suite Tools',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _suitePill(
                'Shared Notes',
                Icons.note_alt_outlined,
                AppColors.teal,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentSharedNotesScreen())),
              ),
              const SizedBox(width: 8),
              _suitePill(
                'Lecture Summaries',
                Icons.summarize_outlined,
                AppColors.warning,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentLectureSummariesScreen())),
              ),
              const SizedBox(width: 8),
              _suitePill(
                'AI Study Plans',
                Icons.calendar_month_outlined,
                AppColors.purple,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentStudyPlansScreen())),
              ),
              const SizedBox(width: 8),
              _suitePill(
                'Weak Topics',
                Icons.analytics_outlined,
                AppColors.error,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentWeakTopicsScreen())),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInlineChatBody() {
    if (_loadingHistory) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return ListView.builder(
      controller: _chatScrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isSending) {
          return _buildTypingIndicator();
        }

        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        final content = msg['content']?.toString() ?? '';

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
            decoration: BoxDecoration(
              gradient: isUser
                  ? const LinearGradient(
                      colors: [Color(0xFF1A73E8), Color(0xFF0B57C9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isUser ? null : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 6),
                bottomRight: Radius.circular(isUser ? 6 : 20),
              ),
              border: isUser ? null : Border.all(color: const Color(0xFFE3EAF6)),
              boxShadow: const [AppThemeDesign.cardShadow],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isUser) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.smart_toy_rounded, size: 14, color: AppColors.primary),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'AI Tutor',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: content));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied response to clipboard'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Icon(Icons.copy_rounded, size: 15, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                SelectableText(
                  content,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    color: isUser ? Colors.white : AppColors.navy,
                    fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE3EAF6)),
          boxShadow: const [AppThemeDesign.cardShadow],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, size: 14, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            const Text(
              'AI Tutor is typing...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomComposer() {
    final controller = _isChatActive ? _followUpController : _askController;
    final hint = _isChatActive ? 'Ask a follow-up question...' : 'Ask me anything...';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE3EAF6)),
                boxShadow: const [AppThemeDesign.cardShadow],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onSubmitted: (v) {
                        if (v.trim().isNotEmpty) {
                          _submitPrompt(v);
                        }
                      },
                      style: const TextStyle(color: AppColors.navy, fontSize: 15),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        hintText: hint,
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14.5),
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                  const Icon(Icons.mic_none_rounded, color: AppColors.textMuted, size: 22),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                _submitPrompt(text);
              }
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF1A73E8), Color(0xFF0B57C9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [AppThemeDesign.brandShadow],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _suitePill(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: const [AppThemeDesign.softShadow],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 📝 SUB-SCREEN: STUDENT SHARED NOTES
// ─────────────────────────────────────────────────────────────────────────────
class StudentSharedNotesScreen extends StatefulWidget {
  const StudentSharedNotesScreen({super.key});

  @override
  State<StudentSharedNotesScreen> createState() => _StudentSharedNotesScreenState();
}

class _StudentSharedNotesScreenState extends State<StudentSharedNotesScreen> {
  bool _isLoading = true;
  List<dynamic> _notes = [];

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    setState(() => _isLoading = true);
    try {
      final res = await AIService.getStudentSharedNotes();
      if (res['success'] == true) {
        setState(() {
          _notes = res['data'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notes: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: const Text('Shared Revision Notes'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const ShimmerListView()
          : _notes.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notes.length,
                  itemBuilder: (ctx, i) {
                    final item = _notes[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          child: Icon(Icons.description),
                        ),
                        title: Text(
                          item['title'] ?? 'Simplified Revision Notes',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Shared by: ${item['tutor']?['name'] ?? 'Tutor'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: () => _showNotesDetailDialog(context, item),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_alt_outlined, size: 64, color: Colors.teal),
          SizedBox(height: 16),
          Text(
            'No Shared Notes Yet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 6),
          Text(
            'Notes simplified and shared by your tutors will appear here.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showNotesDetailDialog(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['title'] ?? 'Notes Detail'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              item['content'] ?? item['summary'] ?? 'No text content available.',
              style: const TextStyle(height: 1.5, fontSize: 14),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 📖 SUB-SCREEN: STUDENT LECTURE SUMMARIES
// ─────────────────────────────────────────────────────────────────────────────
class StudentLectureSummariesScreen extends StatefulWidget {
  const StudentLectureSummariesScreen({super.key});

  @override
  State<StudentLectureSummariesScreen> createState() => _StudentLectureSummariesScreenState();
}

class _StudentLectureSummariesScreenState extends State<StudentLectureSummariesScreen> {
  bool _isLoading = true;
  List<dynamic> _summaries = [];

  @override
  void initState() {
    super.initState();
    _fetchSummaries();
  }

  Future<void> _fetchSummaries() async {
    setState(() => _isLoading = true);
    try {
      final res = await AIService.getStudentLectureSummaries();
      if (res['success'] == true) {
        setState(() {
          _summaries = res['data'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load summaries: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: const Text('Lecture Summaries'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const ShimmerListView()
          : _summaries.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _summaries.length,
                  itemBuilder: (ctx, i) {
                    final item = _summaries[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          child: Icon(Icons.summarize),
                        ),
                        title: Text(
                          item['title'] ?? 'Lecture Summary',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          item['lecture']?['title'] ?? 'Course Lecture',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: () => _showSummaryDetail(context, item),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined, size: 64, color: Colors.orange),
          SizedBox(height: 16),
          Text(
            'No Lecture Summaries',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 6),
          Text(
            'Summaries of recorded lectures shared by your tutors will show up here.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showSummaryDetail(BuildContext context, dynamic item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    item['title'] ?? 'Lecture Summary',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Shared from Course Unit: ${item['lecture']?['title'] ?? 'Lecture'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const Divider(height: 24),
                  Text(
                    item['summary'] ?? item['content'] ?? 'No summaries provided.',
                    style: const TextStyle(fontSize: 14, height: 1.6),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 📅 SUB-SCREEN: STUDENT STUDY PLANS
// ─────────────────────────────────────────────────────────────────────────────
class StudentStudyPlansScreen extends StatefulWidget {
  const StudentStudyPlansScreen({super.key});

  @override
  State<StudentStudyPlansScreen> createState() => _StudentStudyPlansScreenState();
}

class _StudentStudyPlansScreenState extends State<StudentStudyPlansScreen> {
  bool _isLoading = true;
  bool _isGenerating = false;
  List<dynamic> _plans = [];

  final _examController = TextEditingController();
  final _daysController = TextEditingController();
  final _focusController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    setState(() => _isLoading = true);
    try {
      final res = await AIService.getStudentStudyPlans();
      if (res['success'] == true) {
        setState(() {
          _plans = res['data'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load study plans: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generatePlan() async {
    final exam = _examController.text.trim();
    final daysStr = _daysController.text.trim();
    if (exam.isEmpty || daysStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in Exam and Duration!')),
      );
      return;
    }

    final days = int.tryParse(daysStr);
    if (days == null || days <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number of days!')),
      );
      return;
    }

    Navigator.pop(context); // Close builder dialog
    setState(() => _isGenerating = true);

    try {
      final res = await AIService.generateStudentStudyPlan(
        targetExam: exam,
        durationDays: days,
        focusArea: _focusController.text.trim().isNotEmpty ? _focusController.text.trim() : null,
      );

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI Study Plan generated successfully! 📅')),
        );
        _examController.clear();
        _daysController.clear();
        _focusController.clear();
        _fetchPlans();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate plan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: const Text('My Study Plans'),
        backgroundColor: Colors.purple,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePlanModal,
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New AI Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isGenerating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.purple),
                  SizedBox(height: 16),
                  Text(
                    'Generating Personalized Study Plan...',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Structuring sessions, revision tags, and resources...',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            )
          : _isLoading
              ? const ShimmerListView()
              : _plans.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _plans.length,
                      itemBuilder: (ctx, i) {
                        final item = _plans[i];
                        final targetExam = item['targetExam'] ?? 'Specialized Goal';
                        final days = item['durationDays'] ?? 7;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              child: Icon(Icons.calendar_month),
                            ),
                            title: Text(
                              targetExam,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Syllabus Duration: $days Days Plan',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                            onTap: () => _showPlanDetail(context, item),
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_outlined, size: 64, color: Colors.purple),
          SizedBox(height: 16),
          Text(
            'No Custom Study Plans',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 6),
          Text(
            'Tap "New AI Plan" to generate your custom exam schedule.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showCreatePlanModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Create AI Study Plan 📅',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _examController,
                  decoration: const InputDecoration(
                    labelText: 'Target Exam Name (e.g. JEE Main Chemistry)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _daysController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (in Days, e.g. 14)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _focusController,
                  decoration: const InputDecoration(
                    labelText: 'Focus Topics (Optional, e.g. Organic Chemistry)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _generatePlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Generate Plan',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPlanDetail(BuildContext context, dynamic item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    item['targetExam'] ?? 'AI Study Plan',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Duration: ${item['durationDays'] ?? 7} Days',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const Divider(height: 24),
                  Text(
                    item['planDetails'] ?? item['content'] ?? 'No plan details provided.',
                    style: const TextStyle(fontSize: 14, height: 1.6),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ⚠️ SUB-SCREEN: STUDENT WEAK TOPICS
// ─────────────────────────────────────────────────────────────────────────────
class StudentWeakTopicsScreen extends StatefulWidget {
  const StudentWeakTopicsScreen({super.key});

  @override
  State<StudentWeakTopicsScreen> createState() => _StudentWeakTopicsScreenState();
}

class _StudentWeakTopicsScreenState extends State<StudentWeakTopicsScreen> {
  bool _isLoading = true;
  List<dynamic> _weakTopics = [];

  @override
  void initState() {
    super.initState();
    _fetchWeakTopics();
  }

  Future<void> _fetchWeakTopics() async {
    setState(() => _isLoading = true);
    try {
      final res = await AIService.getStudentWeakTopics();
      if (res['success'] == true) {
        setState(() {
          _weakTopics = res['data'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load weak topics: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: const Text('AI Weak Topics Diagnostics'),
        backgroundColor: Colors.pink,
      ),
      body: _isLoading
          ? const ShimmerListView()
          : _weakTopics.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _weakTopics.length,
                  itemBuilder: (ctx, i) {
                    final item = _weakTopics[i];
                    final score = item['score'] ?? 0.0;
                    final topic = item['topic'] ?? 'Topic Name';
                    final rec = item['recommendation'] ?? 'Review recommended reading sheets.';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    topic,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${(score * 100).toStringAsFixed(0)}% Weakness',
                                    style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: score,
                                color: Colors.red,
                                backgroundColor: Colors.grey.shade200,
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    rec,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
          SizedBox(height: 16),
          Text(
            'All Topics Strong! 🎉',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 6),
          Text(
            'AI diagnostics shows no academic weak points.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
