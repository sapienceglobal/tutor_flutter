import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/enrollment_model.dart';
import '../../../providers/enrollment_provider.dart';
import '../../../services/ai_service.dart';
import '../../../services/api_service.dart';
import '../../../services/enrollment_service.dart';
import '../../../utils/constants.dart';

class AiBuddyScreen extends StatefulWidget {
  final String? initialPrompt;
  const AiBuddyScreen({super.key, this.initialPrompt});

  @override
  State<AiBuddyScreen> createState() => _AiBuddyScreenState();
}

class _AiBuddyScreenState extends State<AiBuddyScreen> {
  bool _isLoading = true;
  bool _isSending = false;
  bool _isLocked = false;
  String _lockMessage = '';

  String? _activeSessionId;
  String _sessionTitle = 'AI Buddy';
  List<dynamic> _messages = [];
  List<EnrollmentModel> _enrolledCourses = [];
  String? _selectedCourseId;
  List<dynamic> _chatSessions = [];

  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _suggestions = [
    {"label": "📚 Study Plan", "prompt": "Suggest a complete weekly study plan for my exams."},
    {"label": "🧪 Science Concept", "prompt": "Explain the concept of photosynthesis in simple terms."},
    {"label": "📝 Notes Draft", "prompt": "Help me draft a concise revision note for my next physics exam."},
    {"label": "❓ Solve Doubt", "prompt": "I have a doubt regarding algebraic equations. Can you solve an example step-by-step?"},
  ];

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
      _isLocked = false;
    });

    try {
      // 1. Fetch Enrolled Courses using global Provider for absolute compatibility and robustness
      try {
        final enrollmentProvider = Provider.of<EnrollmentProvider>(context, listen: false);
        await enrollmentProvider.fetchMyEnrollments();
        setState(() {
          _enrolledCourses = enrollmentProvider.activeEnrollments;
        });
      } catch (e) {
        print('⚠️ Error loading enrolled courses via Provider: $e');
        // Fallback to direct service call
        try {
          final courses = await EnrollmentService.getMyEnrollments(status: 'active');
          setState(() {
            _enrolledCourses = courses;
          });
        } catch (err) {
          print('⚠️ Fallback direct fetch failed: $err');
        }
      }

      // 2. Fetch Chat Sessions for Sidebar History
      final res = await AIService.getChatSessions();
      if (res['success']) {
        final List<dynamic> sessions = res['data'] ?? [];
        setState(() {
          _chatSessions = sessions;
        });

        if (sessions.isNotEmpty) {
          // Grab the latest session
          _activeSessionId = sessions[0]['_id'];
          _sessionTitle = sessions[0]['title'] ?? 'AI Buddy';
          await _fetchSessionDetails(_activeSessionId!);
        } else {
          // No session exists, automatically create a fresh premium session
          await _createNewSession();
        }
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
      if (mounted) {
        setState(() => _isLoading = false);
        if (widget.initialPrompt != null &&
            widget.initialPrompt!.trim().isNotEmpty &&
            !_isLocked) {
          final p = widget.initialPrompt!.trim();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _sendMessage(customText: p);
          });
        }
      }
    }
  }

  Future<void> _fetchSessionDetails(String sessionId) async {
    try {
      final res = await AIService.getChatSessionById(sessionId);
      if (res['success']) {
        setState(() {
          _messages = res['data']['messages'] ?? [];
        });
        _scrollToBottom();
      }
    } catch (e) {
      _showError('Failed to load chat history: $e');
    }
  }

  Future<void> _createNewSession() async {
    try {
      final res = await AIService.createChatSession(
        title: 'AI Study Assistant',
        courseId: _selectedCourseId, // Pass this to trigger Vector Search/RAG
      );
      if (res['success']) {
        final newSession = res['data'];
        setState(() {
          _activeSessionId = newSession['_id'];
          _sessionTitle = newSession['title'] ?? 'AI Study Assistant';
          _messages = newSession['messages'] ?? [];
          
          // Add to chatSessions history list if not present
          final exists = _chatSessions.any((s) => s['_id'] == _activeSessionId);
          if (!exists) {
            _chatSessions.insert(0, newSession);
          }
        });
        _scrollToBottom();
      }
    } on ApiException catch (e) {
      if (e.creditExhausted) {
        _showCreditExhaustedDialog(e.message);
      } else if (e.featureLocked) {
        setState(() {
          _isLocked = true;
          _lockMessage = e.message;
        });
      } else {
        _showError(e.message);
      }
      rethrow;
    } catch (e) {
      _showError('Failed to start a new chat: $e');
      rethrow;
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    try {
      final res = await AIService.deleteChatSession(sessionId);
      if (res['success']) {
        setState(() {
          _chatSessions.removeWhere((s) => s['_id'] == sessionId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat thread deleted successfully. 🗑️'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (_activeSessionId == sessionId) {
          if (_chatSessions.isNotEmpty) {
            final latestSession = _chatSessions[0];
            setState(() {
              _isLoading = true;
              _activeSessionId = latestSession['_id'];
              _sessionTitle = latestSession['title'] ?? 'AI Buddy';
            });
            await _fetchSessionDetails(_activeSessionId!);
            setState(() {
              _isLoading = false;
            });
          } else {
            setState(() {
              _isLoading = true;
            });
            await _createNewSession();
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      _showError('Failed to delete chat thread: $e');
    }
  }

  Future<void> _resetChat() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _createNewSession();
    } catch (_) {}
    setState(() {
      _isLoading = false;
    });
    if (_activeSessionId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fresh AI Buddy Chat Session Started! ✨'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  Future<void> _sendMessage({String? customText}) async {
    final text = (customText ?? _msgController.text).trim();
    if (text.isEmpty) return;

    if (_activeSessionId == null) {
      setState(() => _isSending = true);
      try {
        await _createNewSession();
      } catch (_) {
        setState(() => _isSending = false);
        return;
      }
      if (_activeSessionId == null) {
        _showError('AI Study Assistant feature is currently locked or requires subscription upgrade.');
        setState(() => _isSending = false);
        return;
      }
    }

    setState(() {
      _messages.add({"role": "user", "content": text});
      _isSending = true;
      if (customText == null) _msgController.clear();
    });
    _scrollToBottom();

    try {
      final res = await AIService.addMessageToChatSession(
        sessionId: _activeSessionId!,
        message: text,
      );
      if (res['success']) {
        setState(() {
          _messages = res['data']['messages'] ?? [];
          if (res['sessionTitle'] != null) {
            _sessionTitle = res['sessionTitle'];
            final idx = _chatSessions.indexWhere((s) => s['_id'] == _activeSessionId);
            if (idx != -1) {
              _chatSessions[idx]['title'] = _sessionTitle;
            }
          }
        });
        _scrollToBottom();
      }
    } on ApiException catch (e) {
      if (e.creditExhausted) {
        _showCreditExhaustedDialog(e.message);
      } else {
        _showError(e.message);
      }
    } catch (e) {
      _showError('Failed to send message: $e');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showCreditExhaustedDialog(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppThemeDesign.borderRadiusMedium),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Credits Exhausted', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(msg, style: const TextStyle(fontSize: 15, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Okay', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          )
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF), // Soft purple page background matching website P.pageBg
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5B21B6), Color(0xFF7C3AED), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 2,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Buddy Chat',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Row(
                    children: [
                      Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
                      SizedBox(width: 4),
                      Text(
                        'Active Now',
                        style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      drawer: _isLocked || _isLoading ? null : Drawer(
        child: Container(
          color: const Color(0xFF1E1B4B), // Premium Indigo theme matching student sidebar
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drawer Header
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.school, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Sapience AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                // Divider
                Divider(color: Colors.white.withOpacity(0.1), height: 1),
                
                // New Chat Button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close Drawer
                      _resetChat();
                    },
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text(
                      'New Chat',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.15),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                    ),
                  ),
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'CHAT HISTORY',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                
                // Sessions List
                Expanded(
                  child: _chatSessions.isEmpty
                      ? const Center(
                          child: Text(
                            'No past chats found',
                            style: TextStyle(color: Colors.white30, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _chatSessions.length,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemBuilder: (context, index) {
                            final session = _chatSessions[index];
                            final isSelected = session['_id'] == _activeSessionId;
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                onTap: () async {
                                  Navigator.pop(context); // Close Drawer
                                  setState(() {
                                    _isLoading = true;
                                    _activeSessionId = session['_id'];
                                    _sessionTitle = session['title'] ?? 'AI Buddy';
                                    _selectedCourseId = session['courseId']?['_id'];
                                  });
                                  await _fetchSessionDetails(_activeSessionId!);
                                  setState(() {
                                    _isLoading = false;
                                  });
                                },
                                dense: true,
                                leading: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: isSelected ? Colors.white : Colors.white60,
                                  size: 16,
                                ),
                                title: Text(
                                  session['title'] ?? 'AI Buddy',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 16),
                                  color: Colors.redAccent.withOpacity(0.8),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Chat?'),
                                        content: const Text('Are you sure you want to delete this chat thread?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _deleteSession(session['_id']);
                                            },
                                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
                
                // Drawer Footer
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Sapience AI v2.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.2),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _isLocked
              ? _buildLockedState()
              : Column(
                  children: [
                    _buildSubHeaderToolbar(),
                    Expanded(
                      child: _messages.isEmpty ? _buildWelcomeView() : _buildChatArea(),
                    ),
                    if (_isSending) _buildTypingIndicator(),
                    if (!_isLocked) _buildMessageInput(),
                  ],
                ),
    );
  }

  Widget _buildSubHeaderToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          const Icon(Icons.article_outlined, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedCourseId,
                hint: const Text(
                  'Ask from Course (Free Context)',
                  style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'General Doubt Solving',
                      style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ..._enrolledCourses.map((enr) {
                    return DropdownMenuItem<String?>(
                      value: enr.course.id,
                      child: Text(
                        enr.course.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    );
                  }),
                ],
                onChanged: (courseId) async {
                  setState(() {
                    _selectedCourseId = courseId;
                    _isLoading = true;
                  });
                  
                  // Start a fresh session with the selected courseId RAG context!
                  await _createNewSession();
                  
                  setState(() {
                    _isLoading = false;
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(courseId == null 
                          ? 'Context switched to General Doubt Solving!' 
                          : 'Context upgraded with Course Vector Knowledge! 📚'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // RAG Active badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: _selectedCourseId == null
                  ? const LinearGradient(colors: [Colors.grey, Colors.black54])
                  : const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (_selectedCourseId == null ? Colors.grey : const Color(0xFF10B981)).withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _selectedCourseId == null ? Icons.info_outline : Icons.auto_awesome,
                  color: Colors.white,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  _selectedCourseId == null ? 'Normal' : 'RAG Active',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                color: const Color(0xFF7C3AED).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium, size: 80, color: Color(0xFF7C3AED)),
            ),
            const SizedBox(height: 24),
            const Text(
              'AI Buddy Locked',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              _lockMessage.isNotEmpty ? _lockMessage : 'This feature requires the AI Features subscription.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              label: const Text('Go Back', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          // Immersive Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B21B6), Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppThemeDesign.borderRadiusLarge,
              boxShadow: const [AppThemeDesign.brandShadow],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.help_outline, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 16),
                const Text(
                  'AI Doubt Solver 🧠',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Type any academic doubt, request study plans, or seek concise revision summaries instantly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'QUICK START PROMPTS',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          // Horizontal list of beautiful suggested prompts
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final sug = _suggestions[index];
                return GestureDetector(
                  onTap: () => _sendMessage(customText: sug['prompt']),
                  child: Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12, bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppThemeDesign.borderRadiusMedium,
                      border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.14)),
                      boxShadow: const [AppThemeDesign.softShadow],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sug['label']!,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E1B4B)),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            sug['prompt']!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          // How it works card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.06),
              borderRadius: AppThemeDesign.borderRadiusMedium,
              border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💡 Tips for premium answers',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7C3AED), fontSize: 14),
                ),
                const SizedBox(height: 12),
                _buildTipItem('Be specific — mention subject, chapter, or core rules.'),
                _buildTipItem('Ask to generate practice tests for instant mock prep.'),
                _buildTipItem('Tap the refresh icon in the header to restart fresh logs.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E1B4B), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        return _buildChatBubble(msg['content'] ?? '', isUser);
      },
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser ? null : Colors.white,
          borderRadius: BorderRadius.circular(AppThemeDesign.radiusMedium).copyWith(
            bottomRight: isUser ? Radius.zero : const Radius.circular(AppThemeDesign.radiusMedium),
            bottomLeft: !isUser ? Radius.zero : const Radius.circular(AppThemeDesign.radiusMedium),
          ),
          border: isUser ? null : Border.all(color: const Color(0xFF7C3AED).withOpacity(0.1)),
          boxShadow: const [AppThemeDesign.softShadow],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : const Color(0xFF1E1B4B),
            fontSize: 14.5,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            const Icon(Icons.smart_toy, size: 16, color: Color(0xFF7C3AED)),
            const SizedBox(width: 6),
            const Text(
              'AI Buddy is typing',
              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            _buildBouncingDot(0),
            _buildBouncingDot(1),
            _buildBouncingDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildBouncingDot(int index) {
    return Container(
      width: 4,
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: const BoxDecoration(color: Color(0xFF7C3AED), shape: BoxShape.circle),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12).copyWith(bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              decoration: InputDecoration(
                hintText: 'Ask your AI Study Buddy...',
                filled: true,
                fillColor: const Color(0xFFF5F3FF),
                border: OutlineInputBorder(
                  borderRadius: AppThemeDesign.borderRadiusLarge,
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isSending ? null : () => _sendMessage(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
