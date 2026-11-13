import 'package:flutter/material.dart';
import '../../services/exam_service.dart';
import '../../utils/constants.dart';
import '../../widgets/sapience_ui.dart';
import 'exam_instructions_screen.dart';

class StudentExamResultScreen extends StatefulWidget {
  final String attemptId;

  const StudentExamResultScreen({super.key, required this.attemptId});

  @override
  State<StudentExamResultScreen> createState() => _StudentExamResultScreenState();
}

class _StudentExamResultScreenState extends State<StudentExamResultScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  dynamic _attemptData;
  List<dynamic> _analysis = [];
  String _qFilter = 'all'; // 'all', 'correct', 'incorrect', 'unanswered'
  final Set<int> _expandedQuestions = {}; // Indexes of expanded question rows

  @override
  void initState() {
    super.initState();
    _fetchResultDetails();
  }

  Future<void> _fetchResultDetails() async {
    try {
      final res = await ExamService.getAttemptDetails(widget.attemptId);
      if (res['success'] == true && res['attempt'] != null) {
        setState(() {
          _attemptData = res['attempt'];
          _analysis = res['attempt']['analysis'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Failed to load scorecard details.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error loading scorecard: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _getGradeInfo(double pct) {
    if (pct >= 90) {
      return {'grade': 'A+', 'color': const Color(0xFF10B981), 'bg': const Color(0xFFE6F4EA), 'label': 'Outstanding'};
    } else if (pct >= 80) {
      return {'grade': 'A', 'color': const Color(0xFF10B981), 'bg': const Color(0xFFE6F4EA), 'label': 'Excellent'};
    } else if (pct >= 70) {
      return {'grade': 'B+', 'color': Colors.blue, 'bg': Colors.blue.shade50, 'label': 'Very Good'};
    } else if (pct >= 60) {
      return {'grade': 'B', 'color': Colors.blue, 'bg': Colors.blue.shade50, 'label': 'Good'};
    } else if (pct >= 50) {
      return {'grade': 'C', 'color': Colors.orange, 'bg': Colors.orange.shade50, 'label': 'Average'};
    } else {
      return {'grade': 'F', 'color': Colors.red, 'bg': Colors.red.shade50, 'label': 'Needs Work'};
    }
  }

  String _formatDuration(int seconds) {
    final int mins = seconds ~/ 60;
    final int secs = seconds % 60;
    if (mins > 0) {
      return '$mins min $secs sec';
    }
    return '$secs sec';
  }

  String _formatDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _retakeExam() async {
    final examId = _attemptData?['examId']?.toString();
    if (examId == null) return;

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
      final int existingAttempts = canAttemptRes['existingAttempts'] ?? (_attemptData?['attemptNumber'] ?? 1);

      if (!canAttempt) {
        _showBlockedDialog(
          'Maximum Attempts Reached',
          'You have used all $existingAttempts of $maxAttempts allowed attempts for this exam.',
          Icons.block,
          Colors.red,
        );
        return;
      }

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ExamInstructionsScreen(
              examId: examId,
              existingAttempts: existingAttempts,
              maxAttempts: maxAttempts,
            ),
          ),
        );
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
        shape: RoundedRectangleBorder(borderRadius: AppThemeDesign.borderRadiusMedium),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SapienceBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_errorMessage != null) {
      return SapienceBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                const SapienceHeader(title: 'Exam Scorecard'),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 64, color: AppColors.error),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SapienceButton(
                            label: 'Go Back',
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final String examTitle = _attemptData['examTitle'] ?? 'Exam Report';
    final num rawScore = _attemptData['score'] ?? 0;
    final num rawTotal = _attemptData['totalMarks'] ?? 100;
    final num rawPct = _attemptData['percentage'] ?? 0.0;

    final double score = rawScore.toDouble();
    final double totalMarks = rawTotal.toDouble();
    final double pct = rawPct.toDouble();

    final String scoreStr =
        score == score.toInt() ? score.toInt().toString() : score.toStringAsFixed(2);
    final String totalMarksStr = totalMarks == totalMarks.toInt()
        ? totalMarks.toInt().toString()
        : totalMarks.toStringAsFixed(2);

    final bool isPassed = _attemptData['isPassed'] ?? false;
    final int attemptNum = _attemptData['attemptNumber'] ?? 1;
    final int timeSpent = _attemptData['timeSpent'] ?? 0;
    final String dateStr = _attemptData['submittedAt'] ?? '';

    final int correctCount = _attemptData['correctCount'] ??
        _analysis.where((q) => q['status'] == 'correct').length;
    final int incorrectCount = _attemptData['incorrectCount'] ??
        _analysis.where((q) => q['status'] == 'incorrect').length;
    final int unansweredCount = _attemptData['unansweredCount'] ??
        _analysis.where((q) => q['status'] == 'unanswered').length;
    final int totalQuestions = _analysis.length;
    final double accuracy =
        totalQuestions > 0 ? (correctCount / totalQuestions) * 100 : 0.0;

    final gradeInfo = _getGradeInfo(pct);

    // Apply QFilter
    final filteredQuestions = _analysis.where((q) {
      if (_qFilter == 'all') return true;
      return q['status'] == _qFilter;
    }).toList();

    return SapienceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SapienceHeader(
                title: 'Exam Scorecard',
                actions: [
                  if (!isPassed)
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: _retakeExam,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                            boxShadow: const [AppThemeDesign.softShadow],
                          ),
                          child: const Icon(
                            Icons.replay_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(
                        examTitle,
                        isPassed,
                        dateStr,
                        attemptNum,
                        timeSpent,
                        scoreStr,
                        totalMarksStr,
                        pct,
                      ),
                      const SizedBox(height: 16),
                      _buildStatsGrid(
                        scoreStr,
                        totalMarksStr,
                        pct,
                        isPassed,
                        accuracy,
                        correctCount,
                        gradeInfo,
                      ),
                      const SizedBox(height: 16),
                      _buildAnalyticsCard(
                        correctCount,
                        incorrectCount,
                        unansweredCount,
                        totalQuestions,
                        pct,
                        isPassed,
                      ),
                      const SizedBox(height: 16),
                      _buildQuestionReviewSection(filteredQuestions),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    String title,
    bool isPassed,
    String dateStr,
    int attemptNum,
    int timeSpent,
    String scoreStr,
    String totalMarksStr,
    double pct,
  ) {
    return SapienceNavyWaveBanner(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SapienceScoreRing(
                percentage: pct.clamp(0.0, 100.0),
                size: 86,
                strokeWidth: 8,
                trackColor: Colors.white.withOpacity(0.18),
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$scoreStr/$totalMarksStr',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPassed
                            ? const Color(0xFF16B53A).withOpacity(0.28)
                            : const Color(0xFFEB1F1F).withOpacity(0.28),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPassed
                                ? Icons.emoji_events_rounded
                                : Icons.assignment_late_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isPassed ? 'PASSED' : 'NEEDS REVIEW',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Attempt #$attemptNum • ${_formatDate(dateStr)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetaChip('Time', _formatDuration(timeSpent)),
              _buildMetaChip('Attempt', '#$attemptNum'),
              _buildMetaChip('Marks', '$scoreStr / $totalMarksStr'),
            ],
          ),
          if (!isPassed) ...[
            const SizedBox(height: 14),
            SapienceButton(
              label: 'Retake Exam',
              leadingIcon: Icons.replay_rounded,
              variant: SapienceButtonVariant.greenToBlue,
              height: 44,
              onTap: _retakeExam,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Colors.white),
          children: [
            TextSpan(
              text: '${label.toUpperCase()}: ',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 10,
                color: Colors.white.withOpacity(0.78),
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
    String scoreStr,
    String totalMarksStr,
    double pct,
    bool isPassed,
    double accuracy,
    int correctCount,
    Map<String, dynamic> gradeInfo,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatBox(
          'Score',
          '$scoreStr / $totalMarksStr',
          'Points Earned',
          Icons.trending_up_rounded,
          SapienceTileTone.blue,
          AppColors.primary,
        ),
        _buildStatBox(
          'Percentage',
          '${pct.toStringAsFixed(1)}%',
          isPassed ? 'Above cutoff' : 'Below cutoff',
          Icons.insert_chart_outlined_rounded,
          isPassed ? SapienceTileTone.green : SapienceTileTone.pink,
          isPassed ? AppColors.secondary : AppColors.error,
        ),
        _buildStatBox(
          'Accuracy',
          '${accuracy.toStringAsFixed(1)}%',
          '$correctCount Correct',
          Icons.track_changes_rounded,
          SapienceTileTone.orange,
          const Color(0xFFE07A16),
        ),
        _buildStatBox(
          'Grade',
          gradeInfo['grade'],
          gradeInfo['label'],
          Icons.star_rounded,
          SapienceTileTone.purple,
          gradeInfo['color'],
        ),
      ],
    );
  }

  Widget _buildStatBox(
    String title,
    String value,
    String sub,
    IconData icon,
    SapienceTileTone tone,
    Color color,
  ) {
    return SapienceTintedTile(
      tone: tone,
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AppColors.navyInk,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
    int correct,
    int incorrect,
    int unanswered,
    int total,
    double pct,
    bool isPassed,
  ) {
    return SapienceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.analytics_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Performance Breakdown',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                  color: AppColors.navyInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildBreakdownBadge('Correct', correct, AppColors.secondary),
              const SizedBox(width: 8),
              _buildBreakdownBadge('Incorrect', incorrect, AppColors.error),
              const SizedBox(width: 8),
              _buildBreakdownBadge('Skipped', unanswered, AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SCORE PROGRESS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isPassed ? AppColors.secondary : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SapienceProgressBar(
            value: (pct / 100.0).clamp(0.0, 1.0),
            height: 10,
            fillColor: isPassed ? AppColors.secondary : AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownBadge(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionReviewSection(List<dynamic> filtered) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Question Review',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        // Filter tabs selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterTab('all', 'All'),
              const SizedBox(width: 8),
              _buildFilterTab('correct', 'Correct'),
              const SizedBox(width: 8),
              _buildFilterTab('incorrect', 'Incorrect'),
              const SizedBox(width: 8),
              _buildFilterTab('unanswered', 'Skipped'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text('No questions match this filter.', style: TextStyle(color: Colors.grey, fontSize: 14)),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, idx) {
              final item = filtered[idx];
              final status = item['status'] ?? 'unanswered';
              final int qNum = item['questionNumber'] ?? (idx + 1);

              final bool isExpanded = _expandedQuestions.contains(idx);
              Color sideBorderColor = Colors.grey.shade300;
              Color statusBadgeBg = Colors.grey.shade100;
              Color statusBadgeColor = Colors.black54;
              String statusLabel = 'Skipped';
              IconData statusIcon = Icons.error_outline;

              if (status == 'correct') {
                sideBorderColor = Colors.green;
                statusBadgeBg = Colors.green.shade50;
                statusBadgeColor = Colors.green.shade700;
                statusLabel = 'Correct';
                statusIcon = Icons.check_circle;
              } else if (status == 'incorrect') {
                sideBorderColor = Colors.red;
                statusBadgeBg = Colors.red.shade50;
                statusBadgeColor = Colors.red.shade700;
                statusLabel = 'Incorrect';
                statusIcon = Icons.cancel;
              }

              final num earned = item['pointsEarned'] ?? 0;
              final num totalPoints = item['pointsPossible'] ?? 1;

              final String earnedStr = earned == earned.toInt() ? earned.toInt().toString() : earned.toStringAsFixed(1);
              final String totalPointsStr = totalPoints == totalPoints.toInt() ? totalPoints.toInt().toString() : totalPoints.toStringAsFixed(1);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isExpanded ? Colors.white : const Color(0xFFF4F5F8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: sideBorderColor, width: 6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header tap area
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedQuestions.remove(idx);
                              } else {
                                _expandedQuestions.add(idx);
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Q$qNum',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: statusBadgeBg,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(statusIcon, size: 10, color: statusBadgeColor),
                                                const SizedBox(width: 4),
                                                Text(
                                                  statusLabel.toUpperCase(),
                                                  style: TextStyle(color: statusBadgeColor, fontSize: 8, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item['question'] ?? 'Question',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87, height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: earned > 0 ? Colors.green : Colors.grey[700]),
                                        children: [
                                          TextSpan(text: earnedStr),
                                          TextSpan(text: ' / $totalPointsStr pts', style: const TextStyle(color: Colors.black54, fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Icon(
                                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Expanded section
                        if (isExpanded) ...[
                          const Divider(height: 1),
                          Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Comparison Box grid
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // User answer
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: status == 'correct'
                                              ? Colors.green.shade50
                                              : status == 'incorrect'
                                                  ? Colors.red.shade50
                                                  : Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: status == 'correct'
                                                ? Colors.green.withValues(alpha: 0.2)
                                                : status == 'incorrect'
                                                    ? Colors.red.withValues(alpha: 0.2)
                                                    : Colors.grey.shade200,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Your Answer',
                                              style: TextStyle(
                                                color: status == 'correct'
                                                    ? Colors.green.shade700
                                                    : status == 'incorrect'
                                                        ? Colors.red.shade700
                                                        : Colors.grey.shade600,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 8,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              item['selectedAnswerText'] ?? 'Skipped',
                                              style: TextStyle(
                                                color: status == 'correct'
                                                    ? Colors.green.shade900
                                                    : status == 'incorrect'
                                                        ? Colors.red.shade900
                                                        : Colors.black87,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Correct answer
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF4F6FB),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Correct Answer',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 8,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              item['canViewCorrectAnswer'] == true
                                                  ? (item['correctAnswerText'] ?? '—')
                                                  : 'Hidden by Instructor',
                                              style: TextStyle(
                                                color: item['canViewCorrectAnswer'] == true
                                                    ? AppColors.primary
                                                    : Colors.grey,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Solution / Explanation if available
                                if (item['canViewSolution'] == true && item['solutionText'] != null && item['solutionText'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.yellow.shade50.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.yellow.shade200.withValues(alpha: 0.5)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.auto_awesome, size: 16, color: Colors.amber.shade700),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'SOLUTION EXPLANATION',
                                                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                item['solutionText'],
                                                style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.5, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildFilterTab(String key, String label) {
    final bool isSelected = _qFilter == key;
    return InkWell(
      onTap: () {
        setState(() {
          _qFilter = key;
          _expandedQuestions.clear();
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
