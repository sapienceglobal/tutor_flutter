import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../models/course_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/tutor_dashboard_provider.dart';
import '../../utils/constants.dart';
import '../../utils/page_transitions.dart';
import '../../widgets/feature_gate.dart';
import '../../widgets/sapience_ui.dart';
import '../common/announcements/announcements_screen.dart';
import '../common/chat/conversations_screen.dart';
import '../common/notifications/notifications_screen.dart';
import '../common/subscription/personal_subscription_screen.dart';
import '../profile/profile_screen.dart';
import 'ai_buddy/tutor_ai_hub_screen.dart';
import 'assignments/tutor_assignments_screen.dart';
import 'attendance/tutor_attendance_screen.dart';
import 'discussions/tutor_discussions_screen.dart';
import 'earnings/tutor_earnings_screen.dart';
import 'institutes/tutor_institutes_screen.dart';
import 'leaves/tutor_leave_requests_screen.dart';
import 'live_classes/tutor_live_classes_screen.dart';
import 'manage_appointments_screen.dart';
import 'manage_batches_screen.dart';
import 'manage_courses_screen.dart';
import 'manage_exam_screen.dart';
import 'manage_lessons_screen.dart';
import 'questions/question_bank_screen.dart';
import 'quizzes/tutor_reevaluation_requests_screen.dart';
import 'reports/tutor_reports_screen.dart';
import 'reviews/tutor_reviews_screen.dart';
import 'students/tutor_student_performance_screen.dart';
import 'taxonomy/tutor_taxonomy_screen.dart';
import 'tutor_students_screen.dart';

class TutorMoreHubScreen extends StatelessWidget {
  final bool embedded;

  const TutorMoreHubScreen({super.key, this.embedded = false});

  String _resolveImageUrl(String? path) {
    final resolved = ApiConfig.resolveMediaUrl(path);
    if (resolved.isEmpty) return '';
    return resolved;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final user = authProvider.user;
    final stats = dashboardProvider.stats;
    final avatarUrl = _resolveImageUrl(user?.profileImage);

    return SapienceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SapienceHeader(
                title: 'Educator Hub',
                onBack: embedded ? () {} : () => Navigator.of(context).pop(),
                leading: embedded ? const SizedBox(width: 4) : null,
                actions: [
                  SapienceBellButton(
                    unreadCount: dashboardProvider.unreadNotifications,
                    onTap: () {
                      Navigator.of(context).pushSlideUp(
                        const NotificationsScreen(),
                      );
                    },
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Navy Wave Educator Profile Banner
                      SapienceNavyWaveBanner(
                        borderRadius: 24,
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).pushSlideUp(
                                const ProfileScreen(),
                              ),
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.18),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
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
                                        color: Colors.white,
                                        size: 30,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.name ?? 'Educator',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    user?.email ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.84),
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1ED066)
                                          .withOpacity(0.24),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Verified Educator',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.of(context)
                                  .pushSlideUp(const ProfileScreen()),
                            ),
                          ],
                        ),
                      ),
                      if (stats != null) ...[
                        const SizedBox(height: 12),
                        SapienceStatsRow(
                          items: [
                            SapienceStatItem(
                              icon: const Icon(Icons.menu_book_rounded,
                                  size: 16, color: AppColors.primary),
                              value: '${stats.courses.total}',
                              label: 'Courses',
                            ),
                            SapienceStatItem(
                              icon: const Icon(Icons.groups_rounded,
                                  size: 16, color: AppColors.secondary),
                              value: '${stats.students.total}',
                              label: 'Students',
                            ),
                            SapienceStatItem(
                              icon: const Icon(Icons.star_rounded,
                                  size: 16, color: Color(0xFFE07A16)),
                              value: stats.rating.average.toStringAsFixed(1),
                              label: 'Rating',
                            ),
                            SapienceStatItem(
                              icon: const Icon(Icons.currency_rupee_rounded,
                                  size: 16, color: Color(0xFF7B3DF5)),
                              value: '₹${stats.revenue.total.toStringAsFixed(0)}',
                              label: 'Revenue',
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 22),

                      const SapienceSectionHeader(
                        title: 'Academic & Content Management',
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.48,
                        children: [
                          _buildHubTile(
                            context,
                            title: 'My Courses',
                            subtitle: 'Manage curriculum',
                            icon: Icons.menu_book_rounded,
                            color: AppColors.primary,
                            tone: SapienceTileTone.blue,
                            targetScreen: const ManageCoursesScreen(),
                          ),
                          _buildHubTile(
                            context,
                            title: 'Lessons & Units',
                            subtitle: 'Video & PDF lessons',
                            icon: Icons.play_lesson_outlined,
                            color: const Color(0xFFE07A16),
                            tone: SapienceTileTone.orange,
                            onTap: () => _selectCourseAndNavigate(
                              context,
                              (course) => ManageLessonsScreen(course: course),
                            ),
                          ),
                          _buildHubTile(
                            context,
                            title: 'Exams & Quizzes',
                            subtitle: 'Design assessments',
                            icon: Icons.assignment_outlined,
                            color: AppColors.secondary,
                            tone: SapienceTileTone.green,
                            onTap: () => _selectCourseAndNavigate(
                              context,
                              (course) => ManageExamsScreen(course: course),
                            ),
                          ),
                          _buildHubTile(
                            context,
                            title: 'Batches & Slots',
                            subtitle: 'Manage student batches',
                            icon: Icons.groups_outlined,
                            color: const Color(0xFF7B3DF5),
                            tone: SapienceTileTone.purple,
                            targetScreen: const ManageBatchesScreen(),
                          ),
                          _buildHubTile(
                            context,
                            title: 'Question Bank',
                            subtitle: 'Question repository',
                            icon: Icons.inventory_2_outlined,
                            color: AppColors.primary,
                            tone: SapienceTileTone.blue,
                            targetScreen: const QuestionBankScreen(),
                          ),
                          _buildHubTile(
                            context,
                            title: 'Taxonomy',
                            subtitle: 'Topics & Skills tags',
                            icon: Icons.label_outlined,
                            color: const Color(0xFF7B3DF5),
                            tone: SapienceTileTone.purple,
                            targetScreen: const TutorTaxonomyScreen(),
                          ),
                          _buildHubTile(
                            context,
                            title: 'Re-evaluations',
                            subtitle: 'Grade review queue',
                            icon: Icons.assignment_turned_in_outlined,
                            color: AppColors.error,
                            tone: SapienceTileTone.pink,
                            targetScreen:
                                const TutorReevaluationRequestsScreen(),
                          ),
                          _buildHubTile(
                            context,
                            title: 'Assignments',
                            subtitle: 'Homework & grading',
                            icon: Icons.task_alt_rounded,
                            color: AppColors.secondary,
                            tone: SapienceTileTone.green,
                            targetScreen: const TutorAssignmentsScreen(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      const SapienceSectionHeader(
                        title: 'Engagement & Workspace',
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.48,
                        children: [
                          _buildHubTile(
                            context,
                            title: 'Live Classes',
                            subtitle: 'Interactive lectures',
                            icon: Icons.videocam_outlined,
                            color: AppColors.error,
                            tone: SapienceTileTone.pink,
                            targetScreen: const TutorLiveClassesScreen(),
                          ),
                          _buildHubTile(
                            context,
                            title: 'My Students',
                            subtitle: 'Enrolled profiles',
                            icon: Icons.people_outline_rounded,
                            color: AppColors.secondary,
                            tone: SapienceTileTone.green,
                            targetScreen: const TutorStudentsScreen(),
                          ),
                          _buildHubTile(
                            context,
                            title: 'Appointments',
                            subtitle: '1-on-1 consultations',
                            icon: Icons.calendar_today_outlined,
                            color: const Color(0xFFE07A16),
                            tone: SapienceTileTone.orange,
                            targetScreen: const ManageAppointmentsScreen(),
                          ),
                          _buildHubTile(
                            context,
                            title: 'Performance Reports',
                            subtitle: 'Batch level insights',
                            icon: Icons.bar_chart_outlined,
                            color: const Color(0xFF7B3DF5),
                            tone: SapienceTileTone.purple,
                            targetScreen: const TutorReportsScreen(),
                          ),
                          _buildHubTile(
                            context,
                            title: 'Discussions',
                            subtitle: 'Moderate comments',
                            icon: Icons.forum_outlined,
                            color: AppColors.primary,
                            tone: SapienceTileTone.blue,
                            targetScreen: const TutorDiscussionsScreen(),
                          ),
                          _buildHubTile(
                            context,
                            title: 'Student Grades',
                            subtitle: 'Performance report',
                            icon: Icons.analytics_outlined,
                            color: AppColors.secondary,
                            tone: SapienceTileTone.green,
                            targetScreen:
                                const TutorStudentPerformanceScreen(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      const SapienceSectionHeader(title: 'Smart Tools & Finance'),
                      const SizedBox(height: 10),
                      FeatureGate(
                        featureKey: 'aiAssistant',
                        showLockOverlay: true,
                        child: _buildListTile(
                          context,
                          title: 'AI Co-Pilot & Analytics Buddy',
                          subtitle:
                              'Automated study insights, grading assistance & templates',
                          icon: Icons.smart_toy_outlined,
                          color: const Color(0xFF7B3DF5),
                          targetScreen: const TutorAiHubScreen(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildListTile(
                        context,
                        title: 'Earnings & Finance Console',
                        subtitle:
                            'Monitor enrollments revenue share & withdraw funds',
                        icon: Icons.account_balance_wallet_outlined,
                        color: AppColors.secondary,
                        targetScreen: const TutorEarningsScreen(),
                      ),
                      const SizedBox(height: 22),

                      const SapienceSectionHeader(
                        title: 'Settings & Administration',
                      ),
                      const SizedBox(height: 10),
                      _buildListTile(
                        context,
                        title: 'Notifications Center',
                        subtitle:
                            'Real-time student enrollments, submissions & class alerts',
                        icon: Icons.notifications_active_outlined,
                        color: AppColors.primary,
                        targetScreen: const NotificationsScreen(),
                      ),
                      const SizedBox(height: 10),
                      _buildListTile(
                        context,
                        title: 'Instructor Profile & Account',
                        subtitle:
                            'Update bio, photo, theme, language & security settings',
                        icon: Icons.badge_outlined,
                        color: AppColors.navyInk,
                        targetScreen: const ProfileScreen(),
                      ),
                      const SizedBox(height: 10),
                      _buildListTile(
                        context,
                        title: 'Manage Institutes',
                        subtitle: 'Switch active institute & invite links',
                        icon: Icons.business_outlined,
                        color: AppColors.primary,
                        targetScreen: const TutorInstitutesScreen(),
                      ),
                      const SizedBox(height: 10),
                      _buildListTile(
                        context,
                        title: 'Personal Subscription',
                        subtitle:
                            'Upgrade membership to unlock smart AI features',
                        icon: Icons.stars_rounded,
                        color: const Color(0xFFE07A16),
                        targetScreen: const PersonalSubscriptionScreen(),
                      ),
                      const SizedBox(height: 10),
                      _buildListTile(
                        context,
                        title: 'Student Reviews',
                        subtitle: 'View and reply to feedback from your students',
                        icon: Icons.star_outline_rounded,
                        color: const Color(0xFFE07A16),
                        targetScreen: const TutorReviewsScreen(),
                      ),
                      const SizedBox(height: 10),
                      _buildListTile(
                        context,
                        title: 'Attendance Register',
                        subtitle:
                            'Mark and view student attendance sheets for your batches',
                        icon: Icons.fact_check_rounded,
                        color: AppColors.secondary,
                        targetScreen: const TutorAttendanceScreen(),
                      ),
                      const SizedBox(height: 10),
                      _buildListTile(
                        context,
                        title: 'Leave Requests',
                        subtitle: 'Apply for leave and view status tracking',
                        icon: Icons.event_note_rounded,
                        color: const Color(0xFFE07A16),
                        targetScreen: const TutorLeaveRequestsScreen(),
                      ),
                      const SizedBox(height: 10),
                      _buildListTile(
                        context,
                        title: 'Notice Board / Announcements',
                        subtitle:
                            'Broadcast announcements to courses/batches and manage notices',
                        icon: Icons.campaign_outlined,
                        color: AppColors.error,
                        targetScreen: const AnnouncementsScreen(isTutor: true),
                      ),
                      const SizedBox(height: 10),
                      _buildListTile(
                        context,
                        title: 'Inbox / Messages',
                        subtitle: 'Chat with students and manage inquiries',
                        icon: Icons.forum_outlined,
                        color: AppColors.primary,
                        targetScreen: const ConversationsScreen(),
                      ),
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
      if (!context.mounted) return;
      Navigator.of(context).pop();

      final courses = courseProvider.myCourses;
      if (courses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please create a course first!')),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        backgroundColor: Colors.white,
        builder: (context) => Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Associated Course',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyInk,
                ),
              ),
              const SizedBox(height: 12),
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
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(course.thumbnail),
                        backgroundColor: AppColors.primaryTint,
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
                        '${course.enrolledCount} Students • Grade ${course.level}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushSlideUp(
                          screenBuilder(course),
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
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading courses: $e')),
      );
    }
  }

  Widget _buildHubTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required SapienceTileTone tone,
    Widget? targetScreen,
    VoidCallback? onTap,
  }) {
    return SapienceTintedTile(
      tone: tone,
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      onTap: () {
        if (onTap != null) {
          onTap();
        } else if (targetScreen != null) {
          Navigator.of(context).pushSlideUp(targetScreen);
        }
      },
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
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    Widget? targetScreen,
    VoidCallback? onTap,
  }) {
    return SapienceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      borderRadius: 18,
      onTap: () {
        if (onTap != null) {
          onTap();
        } else if (targetScreen != null) {
          Navigator.of(context).pushSlideUp(targetScreen);
        }
      },
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyInk,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
