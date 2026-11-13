import 'package:flutter/material.dart';
import '../../../services/discussion_service.dart';
import '../../../utils/constants.dart';
import 'package:intl/intl.dart';

class TutorDiscussionsScreen extends StatefulWidget {
  const TutorDiscussionsScreen({super.key});

  @override
  State<TutorDiscussionsScreen> createState() => _TutorDiscussionsScreenState();
}

class _TutorDiscussionsScreenState extends State<TutorDiscussionsScreen> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  List<dynamic> _comments = [];
  List<dynamic> _courses = [];
  Map<String, dynamic>? _summary;
  String _statusFilter = 'all';
  String _courseFilter = 'all';
  String _searchQuery = '';
  final Map<String, TextEditingController> _replyControllers = {};
  String? _submittingReplyFor;
  String? _moderatingFor;

  final List<Map<String, String>> _statusOptions = [
    {'value': 'all', 'label': 'All Status'},
    {'value': 'visible', 'label': 'Visible'},
    {'value': 'flagged', 'label': 'Flagged'},
    {'value': 'resolved', 'label': 'Resolved'},
    {'value': 'hidden', 'label': 'Hidden'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchModeration(isInitial: true);
  }

  @override
  void dispose() {
    for (final c in _replyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchModeration({bool isInitial = false}) async {
    if (isInitial) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isRefreshing = true);
    }

    try {
      final res = await DiscussionService.getModerationComments(
        status: _statusFilter,
        courseId: _courseFilter,
        search: _searchQuery,
      );
      if (res['success'] == true && mounted) {
        setState(() {
          _comments = res['comments'] ?? [];
          _courses = res['courses'] ?? [];
          _summary = res['summary'];
        });
      }
    } catch (e) {
      debugPrint('Discussion fetch error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _moderate(String commentId, String action) async {
    setState(() => _moderatingFor = commentId);
    try {
      final res = await DiscussionService.moderateComment(
        commentId: commentId,
        action: action,
      );
      if (res['success'] == true && res['comment'] != null && mounted) {
        setState(() {
          _comments = _comments.map((c) {
            if (c['_id'] == commentId) return res['comment'];
            return c;
          }).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Comment updated'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _moderatingFor = null);
        _fetchModeration();
      }
    }
  }

  Future<void> _submitReply(String commentId) async {
    final controller = _replyControllers[commentId];
    final text = controller?.text.trim() ?? '';
    if (text.isEmpty) return;

    setState(() => _submittingReplyFor = commentId);
    try {
      final res = await DiscussionService.replyToComment(
        commentId: commentId,
        text: text,
      );
      if (res['success'] == true && res['comment'] != null && mounted) {
        setState(() {
          _comments = _comments.map((c) {
            if (c['_id'] == commentId) return res['comment'];
            return c;
          }).toList();
        });
        controller?.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reply posted'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reply: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submittingReplyFor = null);
        _fetchModeration();
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'hidden': return const Color(0xFFF43F5E);
      case 'flagged': return const Color(0xFFF59E0B);
      case 'resolved': return const Color(0xFF10B981);
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'hidden': return Icons.visibility_off_outlined;
      case 'flagged': return Icons.flag_outlined;
      case 'resolved': return Icons.check_circle_outline;
      default: return Icons.chat_bubble_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Discussion Forum', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final pendingReplies = _comments.where((c) => c['tutorReply'] == null).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Discussion Forum', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isRefreshing ? null : () => _fetchModeration(),
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchModeration(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── HEADER CARD ───
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.forum_outlined, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Discussion Forum',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Moderate lesson discussions and reply to comments',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── STATS ROW ───
              Row(
                children: [
                  _buildStatChip('Total', '${_comments.length}', Colors.indigo),
                  const SizedBox(width: 8),
                  _buildStatChip('Pending', '$pendingReplies', Colors.orange),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    'Flagged',
                    '${_comments.where((c) => c['status'] == 'flagged').length}',
                    Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ─── FILTERS ───
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _statusFilter,
                          isExpanded: true,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                          items: _statusOptions
                              .map((o) => DropdownMenuItem(
                                    value: o['value'],
                                    child: Text(o['label']!),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            setState(() => _statusFilter = v!);
                            _fetchModeration();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _courseFilter,
                          isExpanded: true,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                          items: [
                            const DropdownMenuItem(value: 'all', child: Text('All Courses')),
                            ..._courses.map((c) => DropdownMenuItem(
                                  value: c['_id']?.toString() ?? '',
                                  child: Text(
                                    c['title']?.toString() ?? 'Course',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )),
                          ],
                          onChanged: (v) {
                            setState(() => _courseFilter = v!);
                            _fetchModeration();
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ─── SEARCH ───
              TextField(
                onChanged: (v) {
                  _searchQuery = v;
                  Future.delayed(const Duration(milliseconds: 400), () {
                    if (_searchQuery == v) _fetchModeration();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search comments...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),

              // ─── COMMENT CARDS ───
              if (_comments.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        Icon(Icons.forum_outlined, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'No discussions found',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...(_comments.map((comment) => _buildCommentCard(comment)).toList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color.withOpacity(0.7), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentCard(dynamic comment) {
    final commentId = comment['_id']?.toString() ?? '';
    final status = comment['status']?.toString() ?? 'visible';
    final text = comment['text']?.toString() ?? '';
    final studentName = comment['userId']?['name']?.toString() ?? 'Student';
    final lessonTitle = comment['lessonId']?['title']?.toString() ?? 'Unknown Lesson';
    final tutorReply = comment['tutorReply'];
    final createdAt = comment['createdAt']?.toString();

    // Get or create reply controller
    _replyControllers.putIfAbsent(commentId, () => TextEditingController());
    final replyController = _replyControllers[commentId]!;

    String formattedDate = '';
    if (createdAt != null) {
      try {
        formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(createdAt).toLocal());
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(lessonTitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _statusColor(status).withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon(status), size: 12, color: _statusColor(status)),
                    const SizedBox(width: 4),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _statusColor(status)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Comment text
          Text(text, style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF374151))),
          if (formattedDate.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(formattedDate, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
            ),

          // Tutor reply (if exists)
          if (tutorReply != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.12)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified, size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tutorReply['text']?.toString() ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Actions Row
          Row(
            children: [
              // Moderation buttons
              if (status != 'resolved')
                _buildActionButton(
                  'Resolve',
                  Icons.check_circle_outline,
                  AppColors.success,
                  _moderatingFor == commentId ? null : () => _moderate(commentId, 'resolve'),
                ),
              const SizedBox(width: 6),
              if (status != 'hidden')
                _buildActionButton(
                  'Hide',
                  Icons.visibility_off_outlined,
                  AppColors.error,
                  _moderatingFor == commentId ? null : () => _moderate(commentId, 'hide'),
                ),
              const SizedBox(width: 6),
              if (status != 'flagged')
                _buildActionButton(
                  'Flag',
                  Icons.flag_outlined,
                  AppColors.warning,
                  _moderatingFor == commentId ? null : () => _moderate(commentId, 'flag'),
                ),
            ],
          ),

          // Reply box (if no reply yet)
          if (tutorReply == null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: replyController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Write a reply...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 38,
                  height: 38,
                  child: ElevatedButton(
                    onPressed: _submittingReplyFor == commentId ? null : () => _submitReply(commentId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _submittingReplyFor == commentId
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
