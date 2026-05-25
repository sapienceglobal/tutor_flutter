import 'package:flutter/material.dart';
import '../../services/exam_service.dart';
import '../../utils/constants.dart';
import 'exam_instructions_screen.dart';
import 'student_exam_result_screen.dart';

class StudentExamsScreen extends StatefulWidget {
  final bool embedded;
  const StudentExamsScreen({super.key, this.embedded = false});

  @override
  State<StudentExamsScreen> createState() => _StudentExamsScreenState();
}

class _StudentExamsScreenState extends State<StudentExamsScreen> {
  bool _isLoading = true;
  List<dynamic> _exams = [];

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    setState(() => _isLoading = true);
    try {
      final res = await ExamService.getAllStudentExams();
      if (res['success']) {
        setState(() {
          _exams = res['exams'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading exams: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Gate check before opening any exam
  Future<void> _attemptExam(dynamic exam) async {
    final examId = exam['_id'];
    final int attemptCount = exam['attemptCount'] ?? 0;
    final bool isScheduled = exam['isScheduled'] ?? false;
    final String? startDateStr = exam['startDate'];
    final String? endDateStr = exam['endDate'];

    // 1. Schedule enforcement
    if (isScheduled) {
      final now = DateTime.now();
      if (startDateStr != null) {
        final start = DateTime.tryParse(startDateStr);
        if (start != null && now.isBefore(start)) {
          _showBlockedDialog(
            'Exam Not Available Yet',
            'This exam starts on ${_formatDate(start)}. Please come back later.',
            Icons.schedule,
            Colors.orange,
          );
          return;
        }
      }
      if (endDateStr != null) {
        final end = DateTime.tryParse(endDateStr);
        if (end != null && now.isAfter(end)) {
          _showBlockedDialog(
            'Exam Expired',
            'This exam ended on ${_formatDate(end)}. You can no longer take it.',
            Icons.event_busy,
            Colors.red,
          );
          return;
        }
      }
    }

    // 2. Attempt limit check via backend
    try {
      _showLoadingOverlay();
      final canAttemptRes = await ExamService.checkCanAttempt(examId);
      if (mounted) Navigator.of(context).pop(); // close loading overlay

      if (canAttemptRes['success'] != true) {
        _showBlockedDialog(
          'Error',
          canAttemptRes['message'] ?? 'Unable to verify exam eligibility.',
          Icons.error_outline,
          Colors.red,
        );
        return;
      }

      final bool canAttempt = canAttemptRes['canAttempt'] ?? false;
      final int maxAttempts = canAttemptRes['maxAttempts'] ?? 1;
      final int existingAttempts = canAttemptRes['existingAttempts'] ?? attemptCount;

      if (!canAttempt) {
        _showBlockedDialog(
          'Maximum Attempts Reached',
          'You have used all $existingAttempts of $maxAttempts allowed attempts for this exam.',
          Icons.block,
          Colors.red,
        );
        return;
      }

      // 3. All checks passed — navigate to instructions screen
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ExamInstructionsScreen(
              examId: examId,
              existingAttempts: existingAttempts,
              maxAttempts: maxAttempts,
            ),
          ),
        ).then((_) => _fetchExams());
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // close loading overlay
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showLoadingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showBlockedDialog(String title, String message, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color))),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _exams.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
                onRefresh: _fetchExams,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _exams.length,
                  itemBuilder: (context, index) {
                    final exam = _exams[index];
                    return _buildExamCard(exam);
                  },
                ),
              );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Exams'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: body,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Exams Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Exams from your enrolled courses will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(dynamic exam) {
    final int attemptCount = exam['attemptCount'] ?? 0;
    final lastAttempt = exam['lastAttempt'];
    final bool isScheduled = exam['isScheduled'] ?? false;
    final String? startDateStr = exam['startDate'];
    final String? endDateStr = exam['endDate'];

    // Determine exam status for UI
    _ExamStatus status = _ExamStatus.available;
    String buttonText = 'Start Exam';
    Color buttonColor = AppColors.primary;
    bool buttonEnabled = true;

    // Check schedule
    if (isScheduled) {
      final now = DateTime.now();
      if (startDateStr != null) {
        final start = DateTime.tryParse(startDateStr);
        if (start != null && now.isBefore(start)) {
          status = _ExamStatus.notStarted;
          buttonText = 'Starts ${_formatDate(start)}';
          buttonColor = Colors.grey;
          buttonEnabled = false;
        }
      }
      if (endDateStr != null && status == _ExamStatus.available) {
        final end = DateTime.tryParse(endDateStr);
        if (end != null && now.isAfter(end)) {
          status = _ExamStatus.expired;
          buttonText = 'Expired';
          buttonColor = Colors.red.shade300;
          buttonEnabled = false;
        }
      }
    }

    // Check attempt status (only if schedule allows)
    bool isCompletedState = false;
    if (status == _ExamStatus.available) {
      if (attemptCount > 0 && lastAttempt != null) {
        status = _ExamStatus.attempted;
        buttonText = 'View Result';
        buttonColor = Colors.teal;
        isCompletedState = true;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.assignment, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam['title'] ?? 'Exam',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exam['courseTitle'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status, lastAttempt),
              ],
            ),

            // Last attempt score
            if (lastAttempt != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (lastAttempt['isPassed'] ?? false)
                      ? Colors.green.withValues(alpha: 0.08)
                      : Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (lastAttempt['isPassed'] ?? false)
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      (lastAttempt['isPassed'] ?? false) ? Icons.check_circle : Icons.info_outline,
                      size: 16,
                      color: (lastAttempt['isPassed'] ?? false) ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Last Score: ${lastAttempt['score'] ?? '—'} • ${(lastAttempt['isPassed'] ?? false) ? 'Passed ✅' : 'Not Passed'}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: (lastAttempt['isPassed'] ?? false) ? Colors.green[800] : Colors.orange[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatInfo(Icons.timer_outlined, '${exam['duration'] ?? 0} Mins'),
                _buildStatInfo(Icons.format_list_numbered, '${exam['totalQuestions'] ?? 0} Qs'),
                _buildStatInfo(Icons.replay, 'Attempts: $attemptCount'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: buttonEnabled
                    ? () {
                        if (isCompletedState) {
                          final String? attemptId = exam['lastAttemptId'] ?? (lastAttempt != null ? lastAttempt['_id']?.toString() : null);
                          if (attemptId != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StudentExamResultScreen(attemptId: attemptId),
                              ),
                            ).then((_) => _fetchExams());
                          } else {
                            _attemptExam(exam);
                          }
                        } else {
                          _attemptExam(exam);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(_ExamStatus status, dynamic lastAttempt) {
    switch (status) {
      case _ExamStatus.attempted:
        final passed = lastAttempt?['isPassed'] ?? false;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: passed ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            passed ? 'Passed' : 'Attempted',
            style: TextStyle(
              color: passed ? Colors.green : Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case _ExamStatus.expired:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Expired',
            style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        );
      case _ExamStatus.notStarted:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Upcoming',
            style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        );
      case _ExamStatus.available:
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStatInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[800],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

enum _ExamStatus { available, attempted, expired, notStarted }
