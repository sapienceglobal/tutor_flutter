import 'package:flutter/material.dart';
import '../../services/exam_service.dart';
import '../../utils/constants.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_retry.dart';
import '../../utils/page_transitions.dart';
import 'exam_instructions_screen.dart';
import 'student_exam_result_screen.dart';

class StudentPracticeSetsScreen extends StatefulWidget {
  const StudentPracticeSetsScreen({super.key});

  @override
  State<StudentPracticeSetsScreen> createState() => _StudentPracticeSetsScreenState();
}

class _StudentPracticeSetsScreenState extends State<StudentPracticeSetsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _practiceSets = [];

  @override
  void initState() {
    super.initState();
    _fetchPracticeSets();
  }

  Future<void> _fetchPracticeSets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final res = await ExamService.getAllStudentExams();
      if (res['success']) {
        final List allExams = res['exams'] ?? [];
        setState(() {
          _practiceSets = allExams.where((e) => e['type'] == 'practice').toList();
        });
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Failed to load practice sets';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _attemptPractice(dynamic exam) async {
    final examId = exam['_id'];
    final int attemptCount = exam['attemptCount'] ?? 0;

    try {
      _showLoadingOverlay();
      final canAttemptRes = await ExamService.checkCanAttempt(examId);
      if (mounted) Navigator.of(context).pop(); // close loading overlay

      if (canAttemptRes['success'] != true) {
        _showBlockedDialog(
          'Error',
          canAttemptRes['message'] ?? 'Unable to verify practice eligibility.',
          Icons.error_outline,
          Colors.red,
        );
        return;
      }

      final bool canAttempt = canAttemptRes['canAttempt'] ?? false;
      final int maxAttempts = canAttemptRes['maxAttempts'] ?? 100; // Practice usually has high/infinite limits
      final int existingAttempts = canAttemptRes['existingAttempts'] ?? attemptCount;

      if (!canAttempt) {
        _showBlockedDialog(
          'Maximum Attempts Reached',
          'You have completed all $existingAttempts allowed practice sessions.',
          Icons.block,
          Colors.red,
        );
        return;
      }

      if (mounted) {
        Navigator.of(context).pushSlideUp(
          ExamInstructionsScreen(
            examId: examId,
            existingAttempts: existingAttempts,
            maxAttempts: maxAttempts,
          ),
        ).then((_) => _fetchPracticeSets());
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // close loading overlay
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting practice: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showLoadingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.teal)),
    );
  }

  void _showBlockedDialog(String title, String message, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppThemeDesign.borderRadiusMedium),
        title: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color))),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Practice & Skill Building', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const ShimmerListView(itemCount: 4)
          : _errorMessage != null
              ? ErrorRetryWidget(
                  message: _errorMessage!,
                  onRetry: _fetchPracticeSets,
                )
              : _practiceSets.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: Colors.teal,
                      onRefresh: _fetchPracticeSets,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _practiceSets.length,
                        itemBuilder: (ctx, i) {
                          return _buildPracticeCard(_practiceSets[i]);
                        },
                      ),
                    ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: Icons.psychology_outlined,
      title: 'No Practice Sets Available',
      subtitle: 'Your instructors have not published any self-paced practice sets yet.',
      iconColor: Colors.teal,
    );
  }

  Widget _buildPracticeCard(dynamic exam) {
    final title = exam['title'] ?? 'Practice Set';
    final courseTitle = exam['courseTitle'] ?? 'General Preparation';
    final duration = exam['duration'] ?? 30;
    final totalQs = exam['totalQuestions'] ?? 0;
    final attemptCount = exam['attemptCount'] ?? 0;
    final lastAttempt = exam['lastAttempt'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppThemeDesign.borderRadiusMedium,
        boxShadow: const [AppThemeDesign.cardShadow],
        border: Border.all(color: Colors.teal.withValues(alpha: 0.08), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: AppThemeDesign.borderRadiusMedium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Teal Accent Bar
            Container(height: 4, color: Colors.teal),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PRACTICE MODE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (attemptCount > 0)
                        Row(
                          children: [
                            const Icon(Icons.emoji_events_outlined, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              'Practiced $attemptCount times',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    courseTitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMiniBadge(Icons.timer_outlined, '${duration}m'),
                      const SizedBox(width: 8),
                      _buildMiniBadge(Icons.help_outline, '$totalQs Questions'),
                    ],
                  ),
                  if (lastAttempt != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Last score: ${lastAttempt['score'] ?? '—'}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              final String? attemptId = exam['lastAttemptId'] ?? (lastAttempt != null ? lastAttempt['_id']?.toString() : null);
                              if (attemptId != null) {
                                Navigator.of(context).pushSlideUp(
                                  StudentExamResultScreen(attemptId: attemptId),
                                );
                              }
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(40, 20),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Review', style: TextStyle(fontSize: 12, color: Colors.teal)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _attemptPractice(exam),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Start Practice'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
