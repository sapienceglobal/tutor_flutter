import 'package:flutter/material.dart';
import '../../../services/exam_reevaluation_service.dart';
import '../../../utils/constants.dart';
import 'package:intl/intl.dart';

class TutorReevaluationRequestsScreen extends StatefulWidget {
  const TutorReevaluationRequestsScreen({super.key});

  @override
  State<TutorReevaluationRequestsScreen> createState() => _TutorReevaluationRequestsScreenState();
}

class _TutorReevaluationRequestsScreenState extends State<TutorReevaluationRequestsScreen> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  List<dynamic> _requests = [];
  Map<String, dynamic>? _summary;
  String _statusFilter = 'pending';
  String _searchQuery = '';
  int _page = 1;
  bool _hasMore = false;

  final Map<String, TextEditingController> _remarksControllers = {};
  final Map<String, TextEditingController> _scoreControllers = {};
  String? _processingId;

  @override
  void initState() {
    super.initState();
    _loadRequests(isInitial: true);
  }

  @override
  void dispose() {
    for (final c in _remarksControllers.values) {
      c.dispose();
    }
    for (final c in _scoreControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadRequests({bool isInitial = false}) async {
    if (isInitial) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isRefreshing = true);
    }

    try {
      final res = await ExamReevaluationService.getReevaluationRequests(
        status: _statusFilter,
        search: _searchQuery,
        page: _page,
      );
      if (res['success'] == true && mounted) {
        setState(() {
          _requests = res['requests'] ?? [];
          _summary = res['summary'];
          final pagination = res['pagination'] ?? {};
          final int totalPages = pagination['pages'] ?? 1;
          _hasMore = _page < totalPages;
        });
      }
    } catch (e) {
      debugPrint('Reevaluation load error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _handleReview(dynamic request, String decision) async {
    final requestId = request['_id']?.toString() ?? '';
    final remarks = _remarksControllers[requestId]?.text.trim() ?? '';
    final scoreText = _scoreControllers[requestId]?.text.trim() ?? '';
    double? revisedScore;

    if (decision == 'approved' && scoreText.isNotEmpty) {
      revisedScore = double.tryParse(scoreText);
      if (revisedScore == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid revised score.')),
        );
        return;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${decision == 'approved' ? 'Approve' : 'Reject'} Request'),
        content: Text('Are you sure you want to $decision this re-evaluation request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: decision == 'approved' ? AppColors.success : AppColors.error,
            ),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _processingId = requestId);

    try {
      final res = await ExamReevaluationService.reviewReevaluationRequest(
        requestId: requestId,
        decision: decision,
        tutorRemarks: remarks,
        revisedScore: revisedScore,
      );

      if (res['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Request updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _remarksControllers[requestId]?.clear();
        _scoreControllers[requestId]?.clear();
        _loadRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Review failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingId = null);
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'rejected': return const Color(0xFFF43F5E);
      case 'approved': return const Color(0xFF10B981);
      default: return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _summary?['pending'] ?? 0;
    final approvedCount = _summary?['approved'] ?? 0;
    final rejectedCount = _summary?['rejected'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Re-evaluations', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isRefreshing ? null : () => _loadRequests(),
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildStatusTab('pending', 'Pending ($pendingCount)', Colors.orange),
                  const SizedBox(width: 8),
                  _buildStatusTab('approved', 'Approved ($approvedCount)', Colors.green),
                  const SizedBox(width: 8),
                  _buildStatusTab('rejected', 'Rejected ($rejectedCount)', Colors.red),
                ],
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) {
                _searchQuery = v;
                Future.delayed(const Duration(milliseconds: 400), () {
                  if (_searchQuery == v) _loadRequests();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search requests by student or exam...',
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
          ),

          // Requests List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _requests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'No re-evaluation requests found',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _requests.length,
                        itemBuilder: (context, idx) {
                          final item = _requests[idx];
                          return _buildRequestCard(item);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTab(String value, String label, Color color) {
    final bool isSelected = _statusFilter == value;
    return InkWell(
      onTap: () {
        setState(() {
          _statusFilter = value;
          _page = 1;
        });
        _loadRequests();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.4) : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(dynamic item) {
    final requestId = item['_id']?.toString() ?? '';
    final studentName = item['studentId']?['name']?.toString() ?? 'Student';
    final examTitle = item['attemptId']?['examId']?['title']?.toString() ?? 'Exam';
    final studentReason = item['studentReason']?.toString() ?? 'No reason provided';
    final tutorRemarks = item['tutorRemarks']?.toString();
    final status = item['status']?.toString() ?? 'pending';
    final double maxScore = (item['attemptId']?['examId']?['totalPoints'] ?? 0).toDouble();
    final double currentScore = (item['attemptId']?['score'] ?? 0).toDouble();
    final double? revisedScore = item['revisedScore'] != null ? (item['revisedScore'] as num).toDouble() : null;
    final createdAt = item['createdAt']?.toString();

    _remarksControllers.putIfAbsent(requestId, () => TextEditingController());
    _scoreControllers.putIfAbsent(requestId, () => TextEditingController(text: revisedScore?.toString() ?? ''));

    String formattedDate = '';
    if (createdAt != null) {
      try {
        formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(createdAt).toLocal());
      } catch (_) {}
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.08),
                  child: Text(
                    studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(examTitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
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
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _statusColor(status)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Current Score: $currentScore / $maxScore', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                if (revisedScore != null)
                  Text('Revised Score: $revisedScore / $maxScore', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.success)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Student Reason:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            Text(
              studentReason,
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
            ),
            if (formattedDate.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(formattedDate, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
              ),
            if (tutorRemarks != null && tutorRemarks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tutor Remarks:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(tutorRemarks, style: const TextStyle(fontSize: 12, height: 1.4)),
                  ],
                ),
              ),
            ],

            // Input fields and actions for Pending requests
            if (status == 'pending') ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Revised Score', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _scoreControllers[requestId],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'e.g. 8.5',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Remarks / Feedback', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _remarksControllers[requestId],
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Provide tutor remarks...',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _processingId == requestId ? null : () => _handleReview(item, 'rejected'),
                    icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                    label: const Text('Reject', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _processingId == requestId ? null : () => _handleReview(item, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: _processingId == requestId
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
