import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/api_config.dart';
import '../../models/course_model.dart';
import '../../models/enrollment_model.dart';
import '../../models/live_class_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/tutor_provider.dart';
import '../../services/announcement_service.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/enrollment_service.dart';
import '../../services/exam_service.dart';
import '../../services/live_class_service.dart';
import '../../services/notification_service.dart';
import '../../utils/constants.dart';
import '../../widgets/sapience_ui.dart';
import '../common/announcements/announcements_screen.dart';
import '../common/chat/conversations_screen.dart';
import '../common/live_meeting_screen.dart';
import '../common/notifications/notifications_screen.dart';
import '../courses/course_detail_screen.dart';
import '../courses/courses_screen.dart';
import '../courses/my_enrollments_screen.dart';
import '../profile/profile_screen.dart';
import '../student/ai_buddy/student_ai_hub_screen.dart';
import '../student/analytics/student_analytics_screen.dart';
import '../student/assignments/student_assignments_screen.dart';
import '../student/certificates/student_certificates_screen.dart';
import '../student/exam_instructions_screen.dart';
import '../student/live_classes/student_live_classes_screen.dart';
import '../student/payments/student_payments_screen.dart';
import '../student/student_batches_screen.dart';
import '../student/student_exam_result_screen.dart';
import '../student/student_exams_screen.dart';
import '../student/student_practice_sets_screen.dart';
import '../tutor/tutor_dashboard_screen.dart';
import '../tutors/tutor_detail_screen.dart';
import '../tutors/tutors_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final tutorProvider = Provider.of<TutorProvider>(context, listen: false);
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    final results = await Future.wait<dynamic>([
      categoryProvider.fetchCategories(),
      tutorProvider.fetchTutors(),
      courseProvider.fetchCourses(),
      NotificationService.getUnreadCount(),
    ]);

    if (mounted) {
      final unread = results[3];
      if (unread is int) {
        setState(() => _unreadCount = unread);
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?.role ?? 'student';

    if (userRole == 'tutor') {
      return const TutorDashboardScreen();
    }
    return _buildStudentNavigation();
  }

  Widget _buildStudentNavigation() {
    final List<Widget> studentScreens = [
      StudentHomeContent(
        onSwitchTab: _onItemTapped,
        onUnreadChanged: (count) {
          if (mounted && count != _unreadCount) {
            setState(() => _unreadCount = count);
          }
        },
      ),
      const CoursesScreen(embedded: true),
      const StudentExamsScreen(embedded: true),
      const StudentAiHubScreen(embedded: true),
      const ProfileScreen(embedded: true),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _selectedIndex, children: studentScreens),
      bottomNavigationBar: SapienceBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          const SapienceNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
          ),
          const SapienceNavItem(
            icon: Icons.ondemand_video_outlined,
            activeIcon: Icons.ondemand_video_rounded,
            label: 'Courses',
          ),
          const SapienceNavItem(
            icon: Icons.assignment_turned_in_outlined,
            activeIcon: Icons.assignment_turned_in_rounded,
            label: 'Tests',
          ),
          const SapienceNavItem(
            icon: Icons.auto_awesome_outlined,
            activeIcon: Icons.auto_awesome,
            label: 'AI Tutor',
          ),
          SapienceNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
            showDot: _unreadCount > 0,
          ),
        ],
      ),
    );
  }
}

class StudentHomeContent extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;
  final ValueChanged<int>? onUnreadChanged;

  const StudentHomeContent({
    super.key,
    this.onSwitchTab,
    this.onUnreadChanged,
  });

  @override
  State<StudentHomeContent> createState() => _StudentHomeContentState();
}

class _StudentHomeContentState extends State<StudentHomeContent> {
  final LiveClassService _liveClassService = LiveClassService();
  final PageController _heroPageController = PageController();
  final TextEditingController _searchController = TextEditingController();

  int _heroPage = 0;
  bool _showSearchBar = false;
  String _searchQuery = '';

  List<dynamic> _myInstitutes = [];
  dynamic _currentInstitute;
  String _activeScope = 'institute';

  List<EnrollmentModel> _enrollments = [];
  List<LiveClass> _liveClasses = [];
  List<dynamic> _exams = [];
  List<dynamic> _announcements = [];
  Map<String, dynamic>? _studentStats;
  List<Map<String, dynamic>> _studentActivity = [];
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _heroPageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _fetchMembership();
    await _refreshDashboardData();
  }

  Future<void> _fetchMembership() async {
    try {
      final token = await AuthService.getToken();
      final res = await ApiService.get('/membership/my-institutes', token: token);
      if (res['success'] == true && mounted) {
        setState(() {
          _myInstitutes = res['institutes'] ?? [];
          _currentInstitute = res['currentInstitute'];
          if (_currentInstitute == null) {
            _activeScope = 'global';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _activeScope = 'global');
      }
    }
  }

  Future<void> _refreshDashboardData() async {
    if (!mounted) return;
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final tutorProvider = Provider.of<TutorProvider>(context, listen: false);
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    await Future.wait([
      categoryProvider.fetchCategories(),
      tutorProvider.fetchTutors(scope: _activeScope),
      courseProvider.fetchCourses(scope: _activeScope),
      _fetchEnrollments(),
      _fetchLiveClasses(),
      _fetchExams(scope: _activeScope),
      _fetchAnnouncements(),
      _fetchStudentStatsAndActivity(),
      _fetchUnreadNotifications(),
    ]);
  }

  Future<void> _fetchEnrollments() async {
    try {
      final list = await EnrollmentService.getMyEnrollments();
      if (mounted) setState(() => _enrollments = list);
    } catch (_) {}
  }

  Future<void> _fetchLiveClasses() async {
    try {
      final classes = await _liveClassService.fetchLiveClasses();
      if (mounted) setState(() => _liveClasses = classes);
    } catch (_) {}
  }

  Future<void> _fetchExams({String? scope}) async {
    try {
      final res = await ExamService.getAllStudentExams(scope: scope);
      if (res['success'] == true && mounted) {
        setState(() => _exams = res['exams'] ?? []);
      }
    } catch (_) {}
  }

  Future<void> _fetchAnnouncements() async {
    try {
      final list = await AnnouncementService.fetchStudentAnnouncements();
      if (mounted) setState(() => _announcements = list);
    } catch (_) {}
  }

  Future<void> _fetchStudentStatsAndActivity() async {
    try {
      final results = await Future.wait<dynamic>([
        DashboardService.getStudentStats(scope: _activeScope),
        DashboardService.getStudentActivity(scope: _activeScope),
      ]);
      if (!mounted) return;
      setState(() {
        _studentStats = results[0] as Map<String, dynamic>?;
        _studentActivity = results[1] as List<Map<String, dynamic>>;
      });
    } catch (_) {}
  }

  Future<void> _fetchUnreadNotifications() async {
    final count = await NotificationService.getUnreadCount();
    if (!mounted) return;
    setState(() => _unreadNotifications = count);
    widget.onUnreadChanged?.call(count);
  }

  Future<void> _joinLiveClass(LiveClass liveClass) async {
    if (liveClass.status == 'completed' || liveClass.status == 'cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This class has already ended.')),
      );
      return;
    }
    try {
      final config = await _liveClassService.getJoinConfig(liveClass.id);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveMeetingScreen(classId: liveClass.id, config: config),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to join: $e')),
        );
      }
    }
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
          _showInfoDialog(
            'Exam Not Available Yet',
            'Starts on ${DateFormat('MMM dd, yyyy • hh:mm a').format(start)}.',
            Icons.schedule_rounded,
            AppColors.warning,
          );
          return;
        }
      }
      if (endDateStr != null) {
        final end = DateTime.tryParse(endDateStr);
        if (end != null && now.isAfter(end)) {
          _showInfoDialog(
            'Exam Expired',
            'Ended on ${DateFormat('MMM dd, yyyy • hh:mm a').format(end)}.',
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
        _showInfoDialog(
          'Unavailable',
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
        _showInfoDialog(
          'Maximum Attempts Reached',
          'You have used all $existingAttempts of $maxAttempts allowed attempts.',
          Icons.block_rounded,
          AppColors.error,
        );
        return;
      }

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ExamInstructionsScreen(
            examId: examId,
            existingAttempts: existingAttempts,
            maxAttempts: maxAttempts,
          ),
        ),
      ).then((_) => _fetchExams(scope: _activeScope));
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showInfoDialog(String title, String message, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(color: AppColors.textBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  LiveClass? get _featuredLiveClass {
    if (_liveClasses.isEmpty) return null;
    final ongoing = _liveClasses.where((c) => c.status == 'ongoing').toList();
    if (ongoing.isNotEmpty) return ongoing.first;
    final upcoming = _liveClasses
        .where((c) => c.status == 'scheduled' && c.dateTime.isAfter(DateTime.now().subtract(const Duration(minutes: 15))))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    if (upcoming.isNotEmpty) return upcoming.first;
    return _liveClasses.first;
  }

  double get _overallProgressPercent {
    if (_enrollments.isEmpty) {
      return ((_studentStats?['averageExamScore'] ?? 0) as num).toDouble();
    }
    final total = _enrollments.fold<double>(0, (sum, e) => sum + e.progress.percentage);
    return (total / _enrollments.length).clamp(0, 100);
  }

  String get _activityTrendLabel {
    if (_studentActivity.length < 2) {
      final hrs = (_studentStats?['totalLearningHours'] ?? 0).toString();
      return '${hrs}h';
    }
    final mid = _studentActivity.length ~/ 2;
    final firstHalf = _studentActivity.sublist(0, mid);
    final secondHalf = _studentActivity.sublist(mid);
    double avg(List<Map<String, dynamic>> items) {
      if (items.isEmpty) return 0;
      return items.fold<double>(0, (s, e) => s + ((e['score'] ?? 0) as num).toDouble()) / items.length;
    }

    final diff = (avg(secondHalf) - avg(firstHalf)).round();
    if (diff == 0) {
      final hrs = (_studentStats?['totalLearningHours'] ?? 0).toString();
      return '${hrs}h';
    }
    return diff > 0 ? '+$diff%' : '$diff%';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final courseProvider = Provider.of<CourseProvider>(context);
    final tutorProvider = Provider.of<TutorProvider>(context);
    final avatarUrl = ApiConfig.resolveMediaUrl(authProvider.user?.profileImage);

    return Scaffold(
      body: SapienceBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refreshDashboardData,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
              children: [
                _buildTopBar(avatarUrl),
                if (_showSearchBar) ...[
                  const SizedBox(height: 8),
                  _buildInlineSearchBar(),
                ],
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSearchResults(courseProvider.courses, tutorProvider.tutors),
                ] else ...[
                  if (_myInstitutes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildScopeSwitcher(),
                  ],
                  const SizedBox(height: 10),
                  _buildHeroCarousel(authProvider.user?.name ?? 'Learner'),
                  const SizedBox(height: 14),
                  _buildQuickActionsGrid(),
                  const SizedBox(height: 12),
                  _buildCampusToolsStrip(),
                  const SizedBox(height: 18),
                  SapienceSectionHeader(
                    title: 'Continue Learning',
                    actionLabel: 'View All',
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyEnrollmentsScreen()),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildContinueLearningCard(courseProvider.courses),
                  const SizedBox(height: 18),
                  SapienceSectionHeader(
                    title: 'Upcoming Live Class',
                    actionLabel: 'View All',
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentLiveClassesScreen()),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildUpcomingLiveClassCard(),
                  const SizedBox(height: 18),
                  SapienceSectionHeader(
                    title: 'Your Performance',
                    actionLabel: 'View Report',
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentAnalyticsScreen()),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildPerformanceGrid(),
                  if (_announcements.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    SapienceSectionHeader(
                      title: 'Latest Notice',
                      actionLabel: 'View All',
                      onAction: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const AnnouncementsScreen(isTutor: false)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildLatestAnnouncementCard(),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(String avatarUrl) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF16B53A), Color(0xFF0B5CFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [AppThemeDesign.softShadow],
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sapience LMS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: -0.5,
                    height: 1.05,
                  ),
                ),
                if (_activeScope == 'institute' && _currentInstitute != null)
                  Text(
                    '${_currentInstitute['name']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
                if (!_showSearchBar) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
            icon: Icon(
              _showSearchBar ? Icons.close_rounded : Icons.search_rounded,
              color: AppColors.navy,
              size: 26,
            ),
            splashRadius: 20,
          ),
          SapienceBellButton(
            unreadCount: _unreadNotifications,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
              _fetchUnreadNotifications();
            },
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => widget.onSwitchTab?.call(4),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [AppThemeDesign.softShadow],
              ),
              child: ClipOval(
                child: avatarUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _avatarFallback(),
                      )
                    : _avatarFallback(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: AppColors.primarySoft,
      child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 22),
    );
  }

  Widget _buildInlineSearchBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE3EAF6)),
        boxShadow: const [AppThemeDesign.softShadow],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              style: const TextStyle(color: AppColors.navy, fontSize: 14.5),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintText: 'Search courses, tutors, or exams...',
                hintStyle: TextStyle(color: AppColors.textSubtle, fontSize: 14),
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeSwitcher() {
    return SapienceSegmentedTabs(
      tabs: [
        _currentInstitute != null
            ? '${_currentInstitute['name']}'
            : 'My Institute',
        'Global Campus',
      ],
      currentIndex: _activeScope == 'institute' ? 0 : 1,
      onChanged: (idx) {
        final next = idx == 0 ? 'institute' : 'global';
        if (_activeScope != next) {
          setState(() => _activeScope = next);
          _refreshDashboardData();
        }
      },
    );
  }

  Widget _buildHeroCarousel(String userName) {
    final enrolled = _studentStats?['enrolledCourses'] ?? _enrollments.length;
    final avgScore = _studentStats?['averageExamScore'] ?? 0;

    return Column(
      children: [
        SizedBox(
          height: 176,
          child: PageView(
            controller: _heroPageController,
            onPageChanged: (i) => setState(() => _heroPage = i),
            children: [
              // Slide 1: Exact match to Sapience LMS Dashboard UI.png
              _buildHeroSlideOne(),
              // Slide 2: Real Personal Progress Summary Hero
              SapienceNavyWaveBanner(
                borderRadius: 22,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Hi, ${userName.split(' ').first}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$enrolled Active Courses\n$avgScore% Exam Average',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SapienceButton(
                            label: 'View Progress',
                            trailingIcon: Icons.arrow_forward_rounded,
                            variant: SapienceButtonVariant.green,
                            height: 34,
                            fontSize: 13,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const StudentAnalyticsScreen()),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SapienceScoreRing(
                      percentage: _overallProgressPercent,
                      size: 92,
                      strokeWidth: 9,
                      trackColor: Colors.white.withValues(alpha: 0.2),
                      center: Text(
                        '${_overallProgressPercent.round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Slide 3: Real AI Tutor Spotlight
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF3EEFF), Color(0xFFE7F0FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '24x7 Personal\nAI Tutor Ready',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                              height: 1.12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Instant doubt solving, weak-topic insights & study plans.',
                            style: TextStyle(fontSize: 12, color: AppColors.textBody),
                          ),
                          const SizedBox(height: 10),
                          SapienceButton(
                            label: 'Ask AI Tutor',
                            trailingIcon: Icons.auto_awesome,
                            variant: SapienceButtonVariant.blue,
                            height: 34,
                            fontSize: 13,
                            onTap: () => widget.onSwitchTab?.call(3),
                          ),
                        ],
                      ),
                    ),
                    Image.asset(
                      'assets/images/ai-robot.png',
                      width: 118,
                      height: 118,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final active = i == _heroPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 8 : 7,
              height: active ? 8 : 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? AppColors.primary : const Color(0xFFC6D2E8),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHeroSlideOne() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF6F9FF), Color(0xFFEDF3FF), Color(0xFFE7F0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [AppThemeDesign.cardShadow],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -6,
            top: 0,
            bottom: 0,
            width: 175,
            child: Image.asset(
              'assets/images/hero-student.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          // Soft readability fade under text on smaller screens
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF6F9FF),
                    const Color(0xFFF1F6FF).withValues(alpha: 0.92),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.50, 0.78],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 150, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      height: 1.08,
                      letterSpacing: -0.5,
                    ),
                    children: [
                      TextSpan(text: 'Learn Smarter\nwith '),
                      TextSpan(
                        text: 'AI-Powered\n',
                        style: TextStyle(color: AppColors.success),
                      ),
                      TextSpan(text: 'LMS'),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Courses • Tests • Live Classes • Assignments',
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textBody,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                SapienceButton(
                  label: 'Explore Courses',
                  trailingIcon: Icons.arrow_forward_rounded,
                  variant: SapienceButtonVariant.green,
                  height: 32,
                  fontSize: 12.5,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  onTap: () => widget.onSwitchTab?.call(1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = [
      (
        icon: Icons.school_rounded,
        color: AppColors.primary,
        label: 'My Courses',
        tone: SapienceTileTone.blue,
        badge: null,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyEnrollmentsScreen())),
      ),
      (
        icon: Icons.assignment_turned_in_rounded,
        color: AppColors.success,
        label: 'Tests & Exams',
        tone: SapienceTileTone.green,
        badge: null,
        onTap: () => widget.onSwitchTab?.call(2),
      ),
      (
        icon: Icons.auto_awesome,
        color: AppColors.purple,
        label: 'AI Tutor',
        tone: SapienceTileTone.purple,
        badge: 'New',
        onTap: () => widget.onSwitchTab?.call(3),
      ),
      (
        icon: Icons.videocam_rounded,
        color: AppColors.primary,
        label: 'Live Classes',
        tone: SapienceTileTone.blue,
        badge: null,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentLiveClassesScreen())),
      ),
      (
        icon: Icons.description_rounded,
        color: AppColors.warning,
        label: 'Assignments',
        tone: SapienceTileTone.orange,
        badge: null,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentAssignmentsScreen())),
      ),
      (
        icon: Icons.event_note_rounded,
        color: AppColors.primary,
        label: 'Upcoming\nExams',
        tone: SapienceTileTone.blue,
        badge: null,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentExamsScreen())),
      ),
      (
        icon: Icons.credit_card_rounded,
        color: AppColors.purple,
        label: 'Payments',
        tone: SapienceTileTone.purple,
        badge: null,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentPaymentsScreen())),
      ),
      (
        icon: Icons.workspace_premium_rounded,
        color: AppColors.primary,
        label: 'Certificates',
        tone: SapienceTileTone.blue,
        badge: null,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentCertificatesScreen())),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      clipBehavior: Clip.none,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 8,
        childAspectRatio: 1.05,
      ),
      itemCount: actions.length,
      itemBuilder: (context, i) {
        final item = actions[i];
        return SapienceTintedTile(
          tone: item.tone,
          badgeText: item.badge,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          onTap: item.onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: item.color, size: 26),
              const SizedBox(height: 5),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textBody,
                  height: 1.12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCampusToolsStrip() {
    final tools = [
      ('Batches', Icons.groups_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentBatchesScreen()))),
      ('Practice Sets', Icons.quiz_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentPracticeSetsScreen()))),
      ('Attendance', Icons.fact_check_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentBatchesScreen()))),
      ('Tutors', Icons.person_search_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorsScreen()))),
      ('Messages', Icons.chat_bubble_outline_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConversationsScreen()))),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tools.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (label, icon, onTap) = tools[i];
          return GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 15, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContinueLearningCard(List<CourseModel> catalogCourses) {
    if (_enrollments.isNotEmpty) {
      final active = List<EnrollmentModel>.from(_enrollments)
        ..sort((a, b) => b.lastAccessed.compareTo(a.lastAccessed));
      final top = active.first;
      final course = top.course;
      final pct = top.progress.percentage.round().clamp(0, 100);
      final thumb = ApiConfig.resolveMediaUrl(course.thumbnail);

      return SapienceCard(
        borderRadius: 18,
        padding: const EdgeInsets.all(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CourseDetailScreen(courseId: course.id)),
        ),
        child: Row(
          children: [
            _buildCourseThumb(thumb, size: 62),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${top.progress.completedLessons.length} lessons completed • ${course.level.toUpperCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textBody),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(child: SapienceProgressBar(value: pct / 100)),
                      const SizedBox(width: 10),
                      Text(
                        '$pct%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SapiencePlayCircle(
              size: 40,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CourseDetailScreen(courseId: course.id)),
              ),
            ),
          ],
        ),
      );
    }

    if (catalogCourses.isNotEmpty) {
      final course = catalogCourses.first;
      final thumb = ApiConfig.resolveMediaUrl(course.thumbnail);
      return SapienceCard(
        borderRadius: 18,
        padding: const EdgeInsets.all(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CourseDetailScreen(courseId: course.id)),
        ),
        child: Row(
          children: [
            _buildCourseThumb(thumb, size: 62),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${course.category.name} • ${course.isFree ? 'Free' : '₹${course.price.toStringAsFixed(0)}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textBody),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Recommended for you • Tap to start',
                    style: TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const SapiencePlayCircle(size: 40),
          ],
        ),
      );
    }

    return SapienceCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No active courses yet. Explore the catalog to begin learning!',
              style: TextStyle(fontSize: 13, color: AppColors.textBody),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseThumb(String url, {double size = 60}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: url.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _thumbPlaceholder(size),
            )
          : _thumbPlaceholder(size),
    );
  }

  Widget _thumbPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.navyWaveGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.play_lesson_rounded, color: Colors.white, size: 28),
    );
  }

  Widget _buildUpcomingLiveClassCard() {
    final lc = _featuredLiveClass;
    if (lc == null) {
      return SapienceCard(
        borderRadius: 18,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Image.asset('assets/images/live-laptop.png', width: 58, height: 52, fit: BoxFit.contain),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No live classes scheduled right now. Pull down to refresh.',
                style: TextStyle(fontSize: 13, color: AppColors.textBody),
              ),
            ),
          ],
        ),
      );
    }

    final isLiveNow = lc.status == 'ongoing' ||
        (lc.status == 'scheduled' &&
            lc.dateTime.isBefore(DateTime.now().add(const Duration(minutes: 15))));
    final endDt = lc.dateTime.add(Duration(minutes: lc.duration));
    final timeStr =
        '${DateFormat('dd MMM').format(lc.dateTime)}, ${DateFormat('h:mm a').format(lc.dateTime)} – ${DateFormat('h:mm a').format(endDt)}';
    final tutorAvatar = ApiConfig.resolveMediaUrl(lc.tutorImage);

    return SapienceCard(
      borderRadius: 18,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isLiveNow)
                      const SapienceLiveBadge()
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'UPCOMING',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lc.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 13.5, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        timeStr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textBody),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primarySoft,
                      backgroundImage:
                          tutorAvatar.isNotEmpty ? NetworkImage(tutorAvatar) : null,
                      child: tutorAvatar.isEmpty
                          ? const Icon(Icons.person, size: 13, color: AppColors.primary)
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'By ${lc.tutorName ?? 'Instructor'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textBody, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Image.asset(
                'assets/images/live-laptop.png',
                width: 68,
                height: 46,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 4),
              SapienceButton(
                label: 'Join Now',
                variant: SapienceButtonVariant.blue,
                height: 30,
                fontSize: 12,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                onTap: () => _joinLiveClass(lc),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceGrid() {
    final avgExam = (_studentStats?['averageExamScore'] ?? 0).toString();
    final completed = (_studentStats?['completedCourses'] ?? 0).toString();
    final examsSubmitted = (_studentStats?['examsSubmitted'] ?? 0).toString();
    final ringVal = _overallProgressPercent;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.88,
      children: [
        SapienceTintedTile(
          tone: SapienceTileTone.white,
          padding: const EdgeInsets.all(4),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentAnalyticsScreen())),
          child: Center(
            child: SapienceScoreRing(
              percentage: ringVal,
              size: 68,
              strokeWidth: 6.5,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${ringVal.round()}%',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      height: 1.0,
                    ),
                  ),
                  const Text(
                    'Score',
                    style: TextStyle(fontSize: 10, color: AppColors.textBody),
                  ),
                ],
              ),
            ),
          ),
        ),
        SapienceTintedTile(
          tone: SapienceTileTone.orange,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyEnrollmentsScreen())),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events_rounded, color: AppColors.warning, size: 24),
              const SizedBox(height: 3),
              Text(
                completed,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const Text(
                'Completed',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: AppColors.textBody),
              ),
            ],
          ),
        ),
        SapienceTintedTile(
          tone: SapienceTileTone.blue,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          onTap: () => widget.onSwitchTab?.call(2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bar_chart_rounded, color: AppColors.purple, size: 24),
              const SizedBox(height: 3),
              Text(
                '$avgExam%',
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const Text(
                'Test Avg.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: AppColors.textBody),
              ),
            ],
          ),
        ),
        SapienceTintedTile(
          tone: SapienceTileTone.green,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentAnalyticsScreen())),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.trending_up_rounded, color: AppColors.success, size: 24),
              const SizedBox(height: 3),
              Text(
                _activityTrendLabel,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              Text(
                '$examsSubmitted Tests',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, color: AppColors.textBody),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLatestAnnouncementCard() {
    final ann = _announcements.first;
    final title = ann['title']?.toString() ?? 'Announcement';
    final msg = ann['message']?.toString() ?? ann['content']?.toString() ?? '';
    return SapienceCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const AnnouncementsScreen(isTutor: false)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.campaign_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                if (msg.isNotEmpty)
                  Text(
                    msg,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textBody),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<CourseModel> courses, List<dynamic> tutors) {
    final q = _searchQuery;
    final matchedCourses = courses
        .where((c) =>
            c.title.toLowerCase().contains(q) ||
            c.category.name.toLowerCase().contains(q) ||
            c.tutor.user.name.toLowerCase().contains(q))
        .toList();
    final matchedExams = _exams
        .where((e) => (e['title'] ?? '').toString().toLowerCase().contains(q))
        .toList();
    final matchedTutors = tutors
        .where((t) => t.user.name.toLowerCase().contains(q))
        .toList();

    if (matchedCourses.isEmpty && matchedExams.isEmpty && matchedTutors.isEmpty) {
      return SapienceCard(
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Text(
            'No matching courses, exams, or tutors found.',
            style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (matchedCourses.isNotEmpty) ...[
          SapienceSectionHeader(title: 'Courses (${matchedCourses.length})'),
          const SizedBox(height: 8),
          ...matchedCourses.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SapienceCard(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CourseDetailScreen(courseId: c.id)),
                  ),
                  child: Row(
                    children: [
                      _buildCourseThumb(ApiConfig.resolveMediaUrl(c.thumbnail), size: 54),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
                            ),
                            Text(
                              '${c.category.name} • ${c.isFree ? 'Free' : '₹${c.price.toStringAsFixed(0)}'}',
                              style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SapiencePlayCircle(solid: true, size: 34),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 10),
        ],
        if (matchedExams.isNotEmpty) ...[
          SapienceSectionHeader(title: 'Tests & Exams (${matchedExams.length})'),
          const SizedBox(height: 8),
          ...matchedExams.map((e) {
            final lastAttemptId = (e['lastAttemptId'] ?? e['lastAttempt']?['_id'] ?? '').toString();
            final isCompleted = (e['attemptCount'] ?? 0) > 0 && lastAttemptId.isNotEmpty;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SapienceCard(
                onTap: () => isCompleted
                    ? Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => StudentExamResultScreen(attemptId: lastAttemptId)),
                      )
                    : _attemptExam(e),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.successSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.assignment_rounded, color: AppColors.success),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e['title'] ?? 'Exam',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
                          ),
                          Text(
                            '${e['totalQuestions'] ?? 0} Questions • ${e['duration'] ?? 30} Mins',
                            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    SapienceButton(
                      label: isCompleted ? 'Result' : 'Start',
                      variant: isCompleted ? SapienceButtonVariant.green : SapienceButtonVariant.blue,
                      height: 32,
                      fontSize: 12.5,
                      onTap: () => isCompleted
                          ? Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => StudentExamResultScreen(attemptId: lastAttemptId)),
                            )
                          : _attemptExam(e),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
        if (matchedTutors.isNotEmpty) ...[
          SapienceSectionHeader(title: 'Instructors (${matchedTutors.length})'),
          const SizedBox(height: 8),
          ...matchedTutors.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SapienceCard(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TutorDetailScreen(tutor: t)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primarySoft,
                        child: Icon(Icons.person_rounded, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.name ?? 'Tutor',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    ],
                  ),
                ),
              )),
        ],
      ],
    );
  }
}
