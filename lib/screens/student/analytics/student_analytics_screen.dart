import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/api_config.dart';
import '../../../models/dashboard_stats_model.dart';
import '../../../models/enrollment_model.dart';
import '../../../services/dashboard_service.dart';
import '../../../services/enrollment_service.dart';
import '../../../services/report_service.dart';
import '../../../utils/constants.dart';
import '../../../widgets/performance_chart.dart';
import '../../../widgets/sapience_ui.dart';
import '../../courses/course_detail_screen.dart';
import '../../courses/my_enrollments_screen.dart';
import '../certificates/student_certificates_screen.dart';

class StudentAnalyticsScreen extends StatefulWidget {
  const StudentAnalyticsScreen({super.key});

  @override
  State<StudentAnalyticsScreen> createState() => _StudentAnalyticsScreenState();
}

class _StudentAnalyticsScreenState extends State<StudentAnalyticsScreen> {
  final _reportService = ReportService();
  Map<String, dynamic>? _reportData;
  Map<String, dynamic>? _studentStats;
  List<EnrollmentModel> _enrollments = [];
  bool _isLoading = true;
  int _tabIndex = 0; // 0: Overview, 1: Course Progress, 2: Insights

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _reportService.getStudentSummary().catchError((_) => <String, dynamic>{}),
        DashboardService.getStudentStats().catchError((_) => null),
        EnrollmentService.getMyEnrollments().catchError((_) => <EnrollmentModel>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _reportData = results[0] as Map<String, dynamic>?;
        _studentStats = results[1] as Map<String, dynamic>?;
        _enrollments = results[2] as List<EnrollmentModel>;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  double get _overallPct {
    if (_enrollments.isNotEmpty) {
      final sum = _enrollments.fold<double>(0, (s, e) => s + e.progress.percentage);
      return (sum / _enrollments.length).clamp(0, 100);
    }
    return ((_studentStats?['averageExamScore'] ?? 0) as num).toDouble().clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SapienceBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SapienceHeader(title: 'My Learning Progress'),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: SapienceSegmentedTabs(
                  tabs: const ['Overview', 'Course Progress', 'Insights'],
                  currentIndex: _tabIndex,
                  flat: true,
                  onChanged: (i) => setState(() => _tabIndex = i),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadData,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                          children: [
                            if (_tabIndex == 0 || _tabIndex == 1) _buildOverallProgressCard(),
                            if (_tabIndex == 0 || _tabIndex == 1) ...[
                              const SizedBox(height: 18),
                              SapienceSectionHeader(
                                title: 'Course Progress',
                                actionLabel: 'View All',
                                onAction: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const MyEnrollmentsScreen()),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildCourseProgressList(showAll: _tabIndex == 1),
                            ],
                            if (_tabIndex == 0 || _tabIndex == 2) ...[
                              const SizedBox(height: 18),
                              SapienceSectionHeader(
                                title: 'Your Milestones',
                                actionLabel: 'Certificates',
                                onAction: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const StudentCertificatesScreen()),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildAchievementsGrid(),
                              const SizedBox(height: 14),
                              _buildNextGoalCard(),
                            ],
                            if (_tabIndex == 2) ...[
                              const SizedBox(height: 20),
                              const Text(
                                'Exam Score Trend',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildTrendChart(),
                              const SizedBox(height: 20),
                              const Text(
                                'Score Distribution',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildScorePieChart(),
                            ],
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

  Widget _buildOverallProgressCard() {
    final total = _enrollments.isNotEmpty
        ? _enrollments.length
        : (_studentStats?['enrolledCourses'] ?? 0);
    final completed = _enrollments.isNotEmpty
        ? _enrollments.where((e) => e.progress.percentage >= 100 || e.status == 'completed').length
        : (_studentStats?['completedCourses'] ?? 0);
    final inProgress = (total - completed).clamp(0, total);
    final pct = _overallPct;

    return SapienceCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Overall\nProgress',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${pct.round()}%',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pct >= 40 ? AppColors.success : AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_rounded, color: Colors.white, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      pct >= 40 ? 'On Track' : 'Keep Going',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: SapienceScoreRing(
                percentage: pct,
                size: 106,
                strokeWidth: 10,
                center: const Icon(Icons.school_rounded, size: 42, color: AppColors.navy),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(left: 12),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: AppColors.divider, width: 1.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _metricLine(Icons.school_rounded, AppColors.primary, '$total', 'Courses'),
                const SizedBox(height: 10),
                _metricLine(Icons.check_circle_rounded, AppColors.success, '$completed', 'Completed'),
                const SizedBox(height: 10),
                _metricLine(Icons.play_circle_outline_rounded, AppColors.primary, '$inProgress', 'In Progress'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricLine(IconData icon, Color color, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: color, size: 19),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navy),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textBody),
        ),
      ],
    );
  }

  Widget _buildCourseProgressList({required bool showAll}) {
    if (_enrollments.isEmpty) {
      return const SapienceCard(
        padding: EdgeInsets.all(18),
        child: Center(
          child: Text(
            'Enroll in a course to track per-course lesson completion.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final list = showAll ? _enrollments : _enrollments.take(3).toList();
    return Column(
      children: list.map((e) {
        final pct = e.progress.percentage.round().clamp(0, 100);
        final thumb = ApiConfig.resolveMediaUrl(e.course.thumbnail);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SapienceCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CourseDetailScreen(courseId: e.course.id)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: thumb.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: thumb,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _courseBadge(),
                        )
                      : _courseBadge(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.course.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${e.progress.completedLessons.length} Lessons Completed',
                        style: const TextStyle(fontSize: 12, color: AppColors.textBody),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(child: SapienceProgressBar(value: pct / 100, height: 8)),
                          const SizedBox(width: 8),
                          Text(
                            '$pct%',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const SapiencePlayCircle(size: 36),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _courseBadge() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: AppColors.navyWaveGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 24),
    );
  }

  Widget _buildAchievementsGrid() {
    final summary = _reportData?['summary'] ?? {};
    final avgScore = summary['avgScore'] ?? _studentStats?['averageExamScore'] ?? 0;
    final passed = summary['passedExams'] ?? 0;
    final totalCourses = summary['totalCourses'] ?? _enrollments.length;
    final hrs = (_studentStats?['totalLearningHours'] ?? 0).toString();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.85,
      children: [
        _achievementTile(SapienceTileTone.orange, Icons.stars_rounded, AppColors.warning, '$avgScore%', 'Avg\nScore'),
        _achievementTile(SapienceTileTone.purple, Icons.workspace_premium_rounded, AppColors.purple, '$totalCourses', 'Courses\nJoined'),
        _achievementTile(SapienceTileTone.green, Icons.gps_fixed_rounded, AppColors.success, '$passed', 'Exams\nPassed'),
        _achievementTile(SapienceTileTone.blue, Icons.emoji_events_rounded, AppColors.primary, '${hrs}h', 'Study\nTime'),
      ],
    );
  }

  Widget _achievementTile(
    SapienceTileTone tone,
    IconData icon,
    Color color,
    String val,
    String label,
  ) {
    return SapienceTintedTile(
      tone: tone,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            val,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextGoalCard() {
    final incomplete = _enrollments.where((e) => e.progress.percentage < 100).toList();
    final msg = incomplete.isNotEmpty
        ? 'Finish "${incomplete.first.course.title}" to earn your course completion certificate.'
        : 'Great momentum! Keep exploring new courses or take a practice test.';

    return SapienceCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.successSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.track_changes_rounded, color: AppColors.success, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next Goal',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.navy),
                ),
                Text(
                  msg,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textBody, height: 1.25),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SapienceButton(
            label: 'Continue',
            trailingIcon: Icons.arrow_forward_rounded,
            variant: SapienceButtonVariant.blue,
            height: 32,
            fontSize: 12,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyEnrollmentsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    final List attempts = _reportData?['examAttempts'] ?? [];
    if (attempts.isEmpty) {
      return const SapienceCard(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text('Attempt an exam to visualize your score trend.',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    final trendData = attempts.take(6).map((a) {
      return ChartDataPoint(
        label: a['examTitle'].toString().split(' ').first,
        value: (a['pct'] ?? 0).toDouble(),
      );
    }).toList().reversed.toList();

    return SapienceCard(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 200,
        child: PerformanceChart(data: trendData),
      ),
    );
  }

  Widget _buildScorePieChart() {
    final List attempts = _reportData?['examAttempts'] ?? [];
    if (attempts.isEmpty) return const SizedBox();

    final excellent = attempts.where((a) => (a['pct'] ?? 0) >= 90).length;
    final good = attempts.where((a) => (a['pct'] ?? 0) >= 75 && (a['pct'] ?? 0) < 90).length;
    final average = attempts.where((a) => (a['pct'] ?? 0) < 75).length;

    return SapienceCard(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 230,
        child: PieChart(
          PieChartData(
            sections: [
              PieChartSectionData(
                value: excellent.toDouble(),
                color: AppColors.success,
                title: '90%+',
                radius: 50,
                titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              PieChartSectionData(
                value: good.toDouble(),
                color: AppColors.primary,
                title: '75-90%',
                radius: 50,
                titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              PieChartSectionData(
                value: average.toDouble(),
                color: AppColors.warning,
                title: '< 75%',
                radius: 50,
                titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
            centerSpaceRadius: 40,
          ),
        ),
      ),
    );
  }
}
