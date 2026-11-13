import 'package:flutter/material.dart';
import '../../services/exam_service.dart';
import '../../utils/constants.dart';
import '../../utils/page_transitions.dart';
import '../../widgets/error_retry.dart';
import '../../widgets/sapience_ui.dart';
import '../../widgets/shimmer_loader.dart';
import 'analytics/student_analytics_screen.dart';
import 'exam_instructions_screen.dart';
import 'student_exam_result_screen.dart';
import 'student_practice_sets_screen.dart';

class StudentExamsScreen extends StatefulWidget {
  final bool embedded;
  const StudentExamsScreen({super.key, this.embedded = false});

  @override
  State<StudentExamsScreen> createState() => _StudentExamsScreenState();
}

class _StudentExamsScreenState extends State<StudentExamsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _exams = [];
  int _tabIndex = 0; // 0: All Tests, 1: Available, 2: Completed

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final res = await ExamService.getAllStudentExams();
      if (!mounted) return;
      if (res['success'] == true) {
        setState(() => _exams = res['exams'] ?? []);
      } else {
        setState(() => _errorMessage = res['message'] ?? 'Failed to load exams');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredExams {
    if (_tabIndex == 1) {
      return _exams.where((e) => (e['attemptCount'] ?? 0) == 0).toList();
    } else if (_tabIndex == 2) {
      return _exams.where((e) => (e['attemptCount'] ?? 0) > 0).toList();
    }
    return _exams;
  }

  Future<void> _attemptExam(dynamic exam) async {
    final examId = exam['_id'];
    final int attemptCount = exam['attemptCount'] ?? 0;
    final bool isScheduled = exam['isScheduled'] ?? false;
    final String? startDateStr = exam['startDate'];
    final String? endDateStr = exam['endDate'];

    if (isScheduled) {
      final now = DateTime.now();
      if (startDateStr != null) {
        final start = DateTime.tryParse(startDateStr);
        if (start != null && now.isBefore(start)) {
          _showBlockedDialog(
            'Exam Not Available Yet',
            'This exam starts on ${_formatDate(start)}. Please come back later.',
            Icons.schedule_rounded,
            AppColors.warning,
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
            Icons.event_busy_rounded,
            AppColors.error,
          );
          return;
        }
      }
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
      final canAttemptRes = await ExamService.checkCanAttempt(examId);
      if (mounted) Navigator.of(context).pop();

      if (canAttemptRes['success'] != true) {
        _showBlockedDialog(
          'Error',
          canAttemptRes['message'] ?? 'Unable to verify exam eligibility.',
          Icons.error_outline_rounded,
          AppColors.error,
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
          Icons.block_rounded,
          AppColors.error,
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
        ).then((_) => _fetchExams());
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showBlockedDialog(String title, String message, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.navy),
              ),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14, color: AppColors.textBody, height: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final exams = _filteredExams;

    return Scaffold(
      body: SapienceBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SapienceHeader(
                title: 'Tests & Exams',
                leading: widget.embedded ? const SizedBox(width: 40) : null,
                actions: [
                  IconButton(
                    tooltip: 'Practice Sets',
                    icon: const Icon(Icons.quiz_outlined, color: AppColors.navy, size: 23),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentPracticeSetsScreen()),
                    ),
                    splashRadius: 20,
                  ),
                  IconButton(
                    tooltip: 'Performance',
                    icon: const Icon(Icons.workspace_premium_outlined, color: AppColors.navy, size: 25),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentAnalyticsScreen()),
                    ),
                    splashRadius: 20,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: SapienceSegmentedTabs(
                  tabs: const ['All Tests', 'Available', 'Completed'],
                  currentIndex: _tabIndex,
                  flat: true,
                  onChanged: (i) => setState(() => _tabIndex = i),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const ShimmerListView(itemCount: 5)
                    : _errorMessage != null
                        ? ErrorRetryWidget(
                            message: _errorMessage!,
                            onRetry: _fetchExams,
                          )
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: _fetchExams,
                            child: exams.isEmpty
                                ? ListView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      const SizedBox(height: 60),
                                      SapienceCard(
                                        margin: const EdgeInsets.symmetric(horizontal: 24),
                                        padding: const EdgeInsets.all(24),
                                        child: const Column(
                                          children: [
                                            Icon(Icons.assignment_turned_in_rounded,
                                                size: 48, color: AppColors.primary),
                                            SizedBox(height: 12),
                                            Text(
                                              'No tests available right now',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.navy,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Tests assigned in your courses or institute will appear here.',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.separated(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                    itemCount: exams.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                                    itemBuilder: (_, i) => _buildExamCard(exams[i], i),
                                  ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamCard(dynamic exam, int index) {
    final title = exam['title']?.toString() ?? 'Untitled Exam';
    final totalQuestions = exam['totalQuestions'] ?? 0;
    final duration = exam['duration'] ?? 30;
    final int attemptCount = exam['attemptCount'] ?? 0;
    final int maxAttempts = exam['maxAttempts'] ?? 1;
    final String lastAttemptId =
        (exam['lastAttemptId'] ?? exam['lastAttempt']?['_id'] ?? '').toString();
    final bool hasAttempts = attemptCount > 0 && lastAttemptId.isNotEmpty;
    final bool hasRemainingAttempts = attemptCount < maxAttempts;

    final bool isScheduled = exam['isScheduled'] == true;
    final now = DateTime.now();
    bool isLockedSchedule = false;
    if (isScheduled && exam['startDate'] != null) {
      final start = DateTime.tryParse(exam['startDate'].toString());
      if (start != null && now.isBefore(start)) {
        isLockedSchedule = true;
      }
    }
    if (isScheduled && exam['endDate'] != null) {
      final end = DateTime.tryParse(exam['endDate'].toString());
      if (end != null && now.isAfter(end) && !hasAttempts) {
        isLockedSchedule = true;
      }
    }

    final bool isLocked = isLockedSchedule || (!hasAttempts && !hasRemainingAttempts);

    const badgePalettes = [
      (bg: Color(0xFFE2EEFF), fg: Color(0xFF0B5CFF), icon: Icons.code_rounded),
      (bg: Color(0xFFFFE8E8), fg: Color(0xFFEA580C), icon: Icons.terminal_rounded),
      (bg: Color(0xFFDDF6FB), fg: Color(0xFF0A9FCF), icon: Icons.science_rounded),
      (bg: Color(0xFFEFE7FD), fg: Color(0xFF7C3AED), icon: Icons.storage_rounded),
      (bg: Color(0xFFFFF0D8), fg: Color(0xFFE68A00), icon: Icons.design_services_rounded),
    ];
    final badge = badgePalettes[index % badgePalettes.length];

    return SapienceCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: badge.bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(badge.icon, color: badge.fg, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.description_outlined, size: 15, color: AppColors.navy),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '$totalQuestions Questions • $duration Mins',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textBody,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (hasAttempts) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        'Attempted ($attemptCount/$maxAttempts)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isLocked)
            SapiencePlayCircle(
              locked: true,
              size: 44,
              onTap: () => _attemptExam(exam),
            )
          else if (hasAttempts)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SapienceButton(
                  label: 'Result',
                  variant: SapienceButtonVariant.green,
                  height: 34,
                  fontSize: 13,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => StudentExamResultScreen(attemptId: lastAttemptId)),
                  ),
                ),
                if (hasRemainingAttempts) ...[
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: () => _attemptExam(exam),
                    child: const Text(
                      'Retake',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            )
          else
            SapienceButton(
              label: 'Start',
              variant: SapienceButtonVariant.blue,
              height: 38,
              fontSize: 14.5,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              onTap: () => _attemptExam(exam),
            ),
        ],
      ),
    );
  }
}
