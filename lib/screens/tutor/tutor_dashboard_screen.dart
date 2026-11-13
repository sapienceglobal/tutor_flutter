import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../models/course_model.dart';
import '../../models/dashboard_stats_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/tutor_dashboard_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/create_exam_screen.dart';
import '../../widgets/performance_chart.dart';
import '../../widgets/sapience_ui.dart';
import '../common/chat/conversations_screen.dart';
import '../common/notifications/notifications_screen.dart';
import 'ai_buddy/tutor_ai_hub_screen.dart';
import 'assignments/tutor_assignments_screen.dart';
import 'attendance/tutor_attendance_screen.dart';
import 'create_course_screen.dart';
import 'live_classes/schedule_live_class_screen.dart';
import 'live_classes/tutor_live_classes_screen.dart';
import 'manage_appointments_screen.dart';
import 'manage_batches_screen.dart';
import 'manage_courses_screen.dart';
import 'manage_exam_screen.dart';
import 'manage_lessons_screen.dart';
import 'questions/ai_bulk_generator_screen.dart';
import 'questions/comprehension_management_screen.dart';
import 'questions/question_bank_screen.dart';
import 'quizzes/tutor_reevaluation_requests_screen.dart';
import 'reports/tutor_reports_screen.dart';
import 'tutor_more_hub_screen.dart';
import 'tutor_students_screen.dart';

class TutorDashboardScreen extends StatefulWidget {
  const TutorDashboardScreen({super.key});

  @override
  State<TutorDashboardScreen> createState() => _TutorDashboardScreenState();
}

class _TutorDashboardScreenState extends State<TutorDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    await Future.wait([
      dashboardProvider.fetchStats(),
      courseProvider.fetchMyCourses(),
    ]);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const TutorHomeContent(),
      const ManageCoursesScreen(embedded: true),
      const TutorLiveClassesScreen(embedded: true),
      const TutorTestsTab(),
      const TutorMoreHubScreen(embedded: true),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: screens[_selectedIndex],
      bottomNavigationBar: SapienceBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          SapienceNavItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
            label: 'Dashboard',
          ),
          SapienceNavItem(
            icon: Icons.menu_book_outlined,
            activeIcon: Icons.menu_book_rounded,
            label: 'Courses',
          ),
          SapienceNavItem(
            icon: Icons.videocam_outlined,
            activeIcon: Icons.videocam_rounded,
            label: 'Live',
          ),
          SapienceNavItem(
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment_rounded,
            label: 'Tests',
          ),
          SapienceNavItem(
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view_rounded,
            label: 'Hub',
          ),
        ],
      ),
    );
  }
}

class TutorHomeContent extends StatelessWidget {
  const TutorHomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final courseProvider = Provider.of<CourseProvider>(context);

    final stats = dashboardProvider.stats;
    final unreadCount = dashboardProvider.unreadNotifications;
    final avatarUrl =
        ApiConfig.resolveMediaUrl(authProvider.user?.profileImage);

    return SapienceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top App Header matching Student Dashboard
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: const [AppThemeDesign.softShadow],
                        image: avatarUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(avatarUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: avatarUrl.isEmpty
                          ? const Icon(
                              Icons.person_rounded,
                              color: AppColors.primary,
                              size: 22,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EDUCATOR WORKSPACE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 0.7,
                            ),
                          ),
                          Text(
                            authProvider.user?.name ?? 'Instructor',
                            style: const TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navyInk,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ConversationsScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                            boxShadow: const [AppThemeDesign.softShadow],
                          ),
                          child: const Icon(
                            Icons.mail_outline_rounded,
                            size: 20,
                            color: AppColors.navyInk,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SapienceBellButton(
                      unreadCount: unreadCount,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );
                        dashboardProvider.fetchStats();
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    await Future.wait([
                      dashboardProvider.fetchStats(),
                      courseProvider.fetchMyCourses(),
                    ]);
                  },
                  child: dashboardProvider.isLoading && stats == null
                      ? const Center(
                          child:
                              CircularProgressIndicator(color: AppColors.primary),
                        )
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Navy Wave Revenue & Courses Hero Card
                              SapienceNavyWaveBanner(
                                borderRadius: 24,
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1ED066)
                                                  .withOpacity(0.24),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              stats != null
                                                  ? '${stats.content.quizzes} Quizzes • ${stats.content.questions} Qs'
                                                  : 'Live Teaching Console',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          const Text(
                                            'Total Course Revenue',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            stats != null
                                                ? '₹${stats.revenue.total.toStringAsFixed(0)}'
                                                : '₹0',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              SapienceButton(
                                                label: 'New Course',
                                                leadingIcon: Icons.add_rounded,
                                                variant:
                                                    SapienceButtonVariant.green,
                                                height: 36,
                                                fontSize: 12,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                ),
                                                onTap: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          const CreateCourseScreen(),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Image.asset(
                                      'assets/images/hero-student.png',
                                      width: 96,
                                      height: 108,
                                      fit: BoxFit.contain,
                                    ),
                                  ],
                                ),
                              ),

                              if (stats != null) ...[
                                const SizedBox(height: 14),
                                SapienceStatsRow(
                                  items: [
                                    SapienceStatItem(
                                      icon: const Icon(Icons.menu_book_rounded,
                                          size: 16, color: AppColors.primary),
                                      value: '${stats.courses.total}',
                                      label:
                                          '${stats.courses.published} Live',
                                    ),
                                    SapienceStatItem(
                                      icon: const Icon(Icons.groups_rounded,
                                          size: 16, color: AppColors.secondary),
                                      value: '${stats.students.total}',
                                      label:
                                          '+${stats.students.recentEnrollments} wk',
                                    ),
                                    SapienceStatItem(
                                      icon: const Icon(
                                          Icons.event_available_rounded,
                                          size: 16,
                                          color: Color(0xFF7B3DF5)),
                                      value: '${stats.appointments.upcoming}',
                                      label: 'Sessions',
                                    ),
                                    SapienceStatItem(
                                      icon: const Icon(Icons.star_rounded,
                                          size: 16, color: Color(0xFFE07A16)),
                                      value:
                                          stats.rating.average.toStringAsFixed(1),
                                      label:
                                          '${stats.rating.totalReviews} rev',
                                    ),
                                  ],
                                ),
                              ],

                              const SizedBox(height: 18),

                              // 4x2 Quick Action Grid
                              _buildQuickActionsGrid(context),
                              const SizedBox(height: 18),

                              // Action Queue
                              _buildActionQueue(context),
                              const SizedBox(height: 18),

                              // Performance Chart
                              _buildPerformanceChart(
                                  context, dashboardProvider, courseProvider),
                              const SizedBox(height: 18),

                              // Recent Student Activity
                              _buildRecentActivity(context, dashboardProvider),
                              const SizedBox(height: 18),

                              // Recent Courses
                              SapienceSectionHeader(
                                title: 'Recent Courses',
                                actionLabel: 'Manage All',
                                onAction: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ManageCoursesScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              courseProvider.isLoading
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(20),
                                        child: CircularProgressIndicator(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    )
                                  : courseProvider.myCourses.isEmpty
                                      ? _buildEmptyState(
                                          icon: Icons.menu_book_outlined,
                                          message: 'No courses created yet',
                                          actionText: 'Create your first course',
                                          onAction: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const CreateCourseScreen(),
                                              ),
                                            );
                                          },
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount:
                                              courseProvider.myCourses.length > 3
                                                  ? 3
                                                  : courseProvider
                                                      .myCourses.length,
                                          itemBuilder: (context, index) {
                                            final course =
                                                courseProvider.myCourses[index];
                                            return _buildCourseItem(
                                                context, course);
                                          },
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

  Widget _buildQuickActionsGrid(BuildContext context) {
    final dashboardState =
        context.findAncestorStateOfType<_TutorDashboardScreenState>();

    final tiles = [
      (
        title: 'Create Course',
        icon: Icons.add_box_rounded,
        color: AppColors.primary,
        tone: SapienceTileTone.blue,
        badge: null,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateCourseScreen()),
        ),
      ),
      (
        title: 'Schedule Live',
        icon: Icons.videocam_rounded,
        color: AppColors.error,
        tone: SapienceTileTone.pink,
        badge: null,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ScheduleLiveClassScreen()),
        ),
      ),
      (
        title: 'Add Exam',
        icon: Icons.assignment_rounded,
        color: AppColors.secondary,
        tone: SapienceTileTone.green,
        badge: null,
        onTap: () => _selectCourseAndNavigate(
          context,
          (course) => CreateExamScreen(course: course),
        ),
      ),
      (
        title: 'Batches',
        icon: Icons.groups_rounded,
        color: const Color(0xFF7B3DF5),
        tone: SapienceTileTone.purple,
        badge: null,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ManageBatchesScreen()),
        ),
      ),
      (
        title: 'Question Bank',
        icon: Icons.inventory_2_rounded,
        color: const Color(0xFFE07A16),
        tone: SapienceTileTone.orange,
        badge: null,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const QuestionBankScreen()),
        ),
      ),
      (
        title: 'Assignments',
        icon: Icons.task_alt_rounded,
        color: AppColors.primary,
        tone: SapienceTileTone.blue,
        badge: null,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TutorAssignmentsScreen()),
        ),
      ),
      (
        title: 'Reports',
        icon: Icons.bar_chart_rounded,
        color: AppColors.secondary,
        tone: SapienceTileTone.green,
        badge: null,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TutorReportsScreen()),
        ),
      ),
      (
        title: 'AI Co-Pilot',
        icon: Icons.smart_toy_rounded,
        color: const Color(0xFF7B3DF5),
        tone: SapienceTileTone.purple,
        badge: 'New',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TutorAiHubScreen()),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SapienceSectionHeader(
          title: 'Educator Toolkit',
          actionLabel: 'All Tools',
          onAction: () => dashboardState?._onItemTapped(4),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.92,
          ),
          itemCount: tiles.length,
          itemBuilder: (context, index) {
            final item = tiles[index];
            return SapienceTintedTile(
              tone: item.tone,
              badgeText: item.badge,
              borderRadius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              onTap: item.onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [AppThemeDesign.softShadow],
                    ),
                    child: Icon(item.icon, color: item.color, size: 20),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.8,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyInk,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _selectCourseAndNavigate(
    BuildContext context,
    Widget Function(CourseModel) screenBuilder,
  ) async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      await courseProvider.fetchMyCourses();
      if (context.mounted) Navigator.of(context).pop();

      final courses = courseProvider.myCourses;
      if (courses.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please create a course first!')),
          );
        }
        return;
      }

      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          builder: (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Course',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyInk,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: courses.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTint,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          course.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.navyInk,
                          ),
                        ),
                        subtitle: Text(
                          '${course.enrolledCount} students enrolled',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => screenBuilder(course),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildActionQueue(BuildContext context) {
    final dashboardState =
        context.findAncestorStateOfType<_TutorDashboardScreenState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SapienceSectionHeader(title: 'Action Queue'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildQueueCard(
                Icons.fact_check_rounded,
                'Attendance',
                'Batch registers',
                AppColors.primary,
                SapienceTileTone.blue,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TutorAttendanceScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQueueCard(
                Icons.calendar_today_rounded,
                'Appointments',
                '1-on-1 requests',
                AppColors.secondary,
                SapienceTileTone.green,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ManageAppointmentsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildQueueCard(
                Icons.assignment_turned_in_rounded,
                'Assignments',
                'Review submissions',
                const Color(0xFF7B3DF5),
                SapienceTileTone.purple,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TutorAssignmentsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQueueCard(
                Icons.videocam_rounded,
                'Live Sessions',
                'Manage schedule',
                const Color(0xFFE07A16),
                SapienceTileTone.orange,
                () => dashboardState?._onItemTapped(2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQueueCard(
    IconData icon,
    String title,
    String subtitle,
    Color accent,
    SapienceTileTone tone,
    VoidCallback onTap,
  ) {
    return SapienceTintedTile(
      tone: tone,
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [AppThemeDesign.softShadow],
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: AppColors.navyInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart(
    BuildContext context,
    DashboardProvider dashboardProvider,
    CourseProvider courseProvider,
  ) {
    List<ChartDataPoint> data = [];

    if (dashboardProvider.monthlyEarnings.isNotEmpty) {
      data = dashboardProvider.monthlyEarnings.map((m) {
        final label = (m['name'] ?? '').toString();
        final revenue = (m['revenue'] as num?)?.toDouble() ?? 0.0;
        return ChartDataPoint(
          label: label.isEmpty ? 'Mo' : label,
          value: revenue,
          secondaryValue: revenue > 0 ? (revenue * 0.75) : 0,
        );
      }).toList();
    } else if (courseProvider.myCourses.isNotEmpty) {
      data = courseProvider.myCourses.take(5).map((c) {
        final shortLabel =
            c.title.length > 5 ? c.title.substring(0, 5) : c.title;
        return ChartDataPoint(
          label: shortLabel,
          value: c.enrolledCount.toDouble(),
          secondaryValue: c.rating * 10,
        );
      }).toList();
    } else {
      data = [
        ChartDataPoint(label: 'Jan', value: 0, secondaryValue: 0),
        ChartDataPoint(label: 'Feb', value: 0, secondaryValue: 0),
        ChartDataPoint(label: 'Mar', value: 0, secondaryValue: 0),
        ChartDataPoint(label: 'Apr', value: 0, secondaryValue: 0),
        ChartDataPoint(label: 'May', value: 0, secondaryValue: 0),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Performance & Growth',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.navyInk,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '6-Month Sync',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SapienceCard(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 185,
            child: PerformanceChart(data: data, isTutor: true),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(
    BuildContext context,
    DashboardProvider dashboardProvider,
  ) {
    final enrollments = dashboardProvider.recentEnrollments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SapienceSectionHeader(
          title: 'Recent Student Activity',
          actionLabel: 'All Students',
          onAction: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TutorStudentsScreen()),
            );
          },
        ),
        const SizedBox(height: 8),
        SapienceCard(
          padding: enrollments.isEmpty
              ? const EdgeInsets.all(22)
              : const EdgeInsets.symmetric(vertical: 4),
          child: enrollments.isEmpty
              ? const Center(
                  child: Text(
                    'No recent student enrollments recorded yet.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: enrollments.length > 5 ? 5 : enrollments.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final item = enrollments[index];
                    final student = item['studentId'] is Map
                        ? Map<String, dynamic>.from(item['studentId'])
                        : <String, dynamic>{};
                    final course = item['courseId'] is Map
                        ? Map<String, dynamic>.from(item['courseId'])
                        : <String, dynamic>{};
                    final progressMap = item['progress'] is Map
                        ? Map<String, dynamic>.from(item['progress'])
                        : <String, dynamic>{};

                    final studentName =
                        student['name']?.toString() ?? 'Student';
                    final avatarUrl = ApiConfig.resolveMediaUrl(
                        student['profileImage']?.toString());
                    final courseTitle =
                        course['title']?.toString() ?? 'Enrolled Course';
                    final pct =
                        (progressMap['percentage'] as num?)?.toInt() ?? 0;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        radius: 19,
                        backgroundColor: AppColors.primaryTint,
                        backgroundImage:
                            avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl.isEmpty
                            ? Text(
                                studentName.isNotEmpty
                                    ? studentName[0].toUpperCase()
                                    : 'S',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.navyInk,
                        ),
                      ),
                      subtitle: Text(
                        courseTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: pct >= 50
                              ? AppColors.secondary.withOpacity(0.14)
                              : AppColors.primaryTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$pct%',
                          style: TextStyle(
                            color: pct >= 50
                                ? AppColors.secondary
                                : AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCourseItem(BuildContext context, CourseModel course) {
    final resolvedThumb = ApiConfig.resolveMediaUrl(course.thumbnail);

    return SapienceCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      borderRadius: 18,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ManageLessonsScreen(course: course),
          ),
        );
      },
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              resolvedThumb,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 60,
                height: 60,
                color: AppColors.primaryTint,
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: AppColors.navyInk,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.people_outline_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${course.enrolledCount} students',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      course.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyInk,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: course.status == 'published'
                        ? AppColors.secondary.withOpacity(0.14)
                        : AppColors.warningSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    course.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: course.status == 'published'
                          ? AppColors.secondary
                          : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SapiencePlayCircle(size: 32, solid: false),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return SapienceCard(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.navyInk,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            SapienceButton(
              label: actionText,
              leadingIcon: Icons.add_rounded,
              variant: SapienceButtonVariant.greenToBlue,
              onTap: onAction,
            ),
          ],
        ),
      ),
    );
  }
}

/// Embedded Exams & Question Bank tab inside Tutor 5-tab navigation.
class TutorTestsTab extends StatelessWidget {
  const TutorTestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    final courses = courseProvider.myCourses;

    return SapienceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SapienceHeader(
                title: 'Tests & Question Bank',
                onBack: () {},
                leading: const SizedBox(width: 4),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => courseProvider.fetchMyCourses(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.5,
                          children: [
                            _testToolTile(
                              context,
                              title: 'Question Bank',
                              subtitle: 'Central MCQs & items',
                              icon: Icons.inventory_2_rounded,
                              color: AppColors.primary,
                              tone: SapienceTileTone.blue,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const QuestionBankScreen(),
                                ),
                              ),
                            ),
                            _testToolTile(
                              context,
                              title: 'AI Question Gen',
                              subtitle: 'Bulk generate questions',
                              icon: Icons.auto_awesome_rounded,
                              color: const Color(0xFF7B3DF5),
                              tone: SapienceTileTone.purple,
                              badge: 'AI',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AiBulkGeneratorScreen(),
                                ),
                              ),
                            ),
                            _testToolTile(
                              context,
                              title: 'Comprehensions',
                              subtitle: 'Passage-based sets',
                              icon: Icons.menu_book_rounded,
                              color: AppColors.secondary,
                              tone: SapienceTileTone.green,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ComprehensionManagementScreen(),
                                ),
                              ),
                            ),
                            _testToolTile(
                              context,
                              title: 'Re-evaluations',
                              subtitle: 'Grade review queue',
                              icon: Icons.assignment_turned_in_rounded,
                              color: const Color(0xFFE07A16),
                              tone: SapienceTileTone.orange,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const TutorReevaluationRequestsScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const SapienceSectionHeader(
                          title: 'Course Exams & Assessments',
                        ),
                        const SizedBox(height: 10),
                        if (courseProvider.isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (courses.isEmpty)
                          SapienceCard(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                const Text(
                                  'Create a course first to publish exams & quizzes.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navyInk,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SapienceButton(
                                  label: 'Create Course',
                                  variant: SapienceButtonVariant.greenToBlue,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const CreateCourseScreen(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...courses.map(
                            (course) => SapienceCard(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryTint,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.assignment_rounded,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          course.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.navyInk,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${course.enrolledCount} enrolled • ${course.category.name}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SapienceButton(
                                    label: 'Manage',
                                    variant: SapienceButtonVariant.blue,
                                    height: 36,
                                    fontSize: 12,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ManageExamsScreen(
                                            course: course,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
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

  Widget _testToolTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required SapienceTileTone tone,
    required VoidCallback onTap,
    String? badge,
  }) {
    return SapienceTintedTile(
      tone: tone,
      badgeText: badge,
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
              boxShadow: const [AppThemeDesign.softShadow],
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyInk,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
