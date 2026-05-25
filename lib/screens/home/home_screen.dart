import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/tutor_provider.dart';
import '../../providers/course_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/category_card.dart';
import '../../widgets/tutor_card.dart';
import '../../widgets/course_card.dart';
import '../categories/categories_screen.dart';
import '../tutors/tutors_screen.dart';
import '../courses/courses_screen.dart';
import '../courses/my_enrollments_screen.dart';
import '../profile/profile_screen.dart';
import '../student/student_learning_screen.dart';
import '../student/ai_buddy/ai_buddy_screen.dart';
import '../student/assignments/student_assignments_screen.dart';
import '../student/live_classes/student_live_classes_screen.dart';
import '../student/certificates/student_certificates_screen.dart';
import '../student/analytics/student_analytics_screen.dart';
import '../student/wishlist/student_wishlist_screen.dart';
import '../student/student_more_hub_screen.dart';
import '../tutor/tutor_dashboard_screen.dart';
import '../admin/subscription/subscription_screen.dart';
import '../../widgets/feature_gate.dart';
import '../../widgets/performance_chart.dart';
import '../../models/dashboard_stats_model.dart';
import '../../services/exam_service.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../student/exam_instructions_screen.dart';
import '../student/student_exam_result_screen.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    final tutorProvider = Provider.of<TutorProvider>(context, listen: false);
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    await Future.wait([
      categoryProvider.fetchCategories(),
      tutorProvider.fetchTutors(),
      courseProvider.fetchCourses(),
    ]);
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
      return TutorDashboardScreen();
    } else {
      return _buildStudentNavigation();
    }
  }

  // 🎓 TUTOR NAVIGATION (Separate Widget)


  // 👨‍🎓 STUDENT NAVIGATION (Separate Widget)
  Widget _buildStudentNavigation() {
    final List<Widget> studentScreens = [
      const StudentHomeContent(),
      const CoursesScreen(),
      const StudentLearningScreen(),
      const AiBuddyScreen(),
      const StudentMoreHubScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: studentScreens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.my_library_books_outlined),
            activeIcon: Icon(Icons.my_library_books),
            label: 'My Learning',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            activeIcon: Icon(Icons.smart_toy),
            label: 'AI Buddy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

// 👨‍🎓 STUDENT HOME CONTENT
class StudentHomeContent extends StatefulWidget {
  const StudentHomeContent({super.key});

  @override
  State<StudentHomeContent> createState() => _StudentHomeContentState();
}

class _StudentHomeContentState extends State<StudentHomeContent> {
  List<dynamic> _exams = [];
  bool _isLoadingExams = true;

  List<dynamic> _myInstitutes = [];
  dynamic _currentInstitute;
  String _activeScope = 'institute';
  bool _isLoadingMembership = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _fetchMembership();
    _refreshDashboardData();
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
          _isLoadingMembership = false;
        });
      }
    } catch (e) {
      print('Error loading membership: $e');
      if (mounted) {
        setState(() {
          _activeScope = 'global';
          _isLoadingMembership = false;
        });
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
      _fetchExams(scope: _activeScope),
    ]);
  }

  Future<void> _fetchExams({String? scope}) async {
    if (!mounted) return;
    setState(() => _isLoadingExams = true);
    try {
      final res = await ExamService.getAllStudentExams(scope: scope);
      if (res['success'] && mounted) {
        setState(() {
          _exams = res['exams'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading exams: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingExams = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
  }

  void _showBlockedDialog(String title, String message, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

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
        ).then((_) => _fetchExams(scope: _activeScope));
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final tutorProvider = Provider.of<TutorProvider>(context);
    final courseProvider = Provider.of<CourseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _activeScope == 'institute' && _currentInstitute != null
                  ? 'Student at ${_currentInstitute['name']}'
                  : 'Independent Learner · Global',
              style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
            Text(
              authProvider.user?.name ?? 'User',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshDashboardData();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Switcher
              if (_myInstitutes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (_activeScope != 'institute') {
                                setState(() {
                                  _activeScope = 'institute';
                                });
                                _refreshDashboardData();
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _activeScope == 'institute'
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'My Institute',
                                style: TextStyle(
                                  color: _activeScope == 'institute'
                                      ? Colors.white
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (_activeScope != 'global') {
                                setState(() {
                                  _activeScope = 'global';
                                });
                                _refreshDashboardData();
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _activeScope == 'global'
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Global',
                                style: TextStyle(
                                  color: _activeScope == 'global'
                                      ? Colors.white
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Search Bar Input Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _searchQuery.isNotEmpty ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search courses, tutors...',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: _searchQuery.isNotEmpty ? AppColors.primary : Colors.grey[600]),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = "";
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (_searchQuery.isNotEmpty)
                _buildSearchResults(context, _searchQuery)
              else ...[
                // Hero Banner
                _buildHeroBanner(context),
                const SizedBox(height: 24),

                // Today's Exams
                _buildTodayExams(context),
                const SizedBox(height: 24),

                // Quick Actions
                _buildQuickActions(context),
                const SizedBox(height: 24),

                // AI Recommendations
                _buildAIRecommendations(context),
                const SizedBox(height: 24),

                // Performance Overview
                _buildPerformanceOverview(context),
                const SizedBox(height: 24),

                // Instructor Announcements
                _buildAnnouncements(context),
                const SizedBox(height: 24),

                // Categories Section
                _buildSectionHeader(
                  context,
                  title: 'Categories',
                  onViewAll: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),

                categoryProvider.isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : categoryProvider.categories.isEmpty
                    ? _buildEmptyState('No categories found', Icons.category)
                    : SizedBox(
                        height: 110,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: categoryProvider.categories.length > 6
                              ? 6
                              : categoryProvider.categories.length,
                          itemBuilder: (context, index) {
                            final category = categoryProvider.categories[index];
                            return CategoryCard(category: category);
                          },
                        ),
                      ),
                const SizedBox(height: 24),

                // ---------------------- POPULAR COURSES ------------------------
                _buildSectionHeader(
                  context,
                  title: 'Popular Courses',
                  onViewAll: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CoursesScreen()),
                    );
                  },
                ),
                const SizedBox(height: 14),

                courseProvider.isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : courseProvider.courses.isEmpty
                    ? _buildEmptyState('No courses found', Icons.school)
                    : SizedBox(
                        height:
                            MediaQuery.of(context).size.height *
                            0.33, // responsive height
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          separatorBuilder: (_, __) => const SizedBox(width: 18),

                          itemCount: courseProvider.courses.length.clamp(0, 5),

                          itemBuilder: (context, index) {
                            final course = courseProvider.courses[index];

                            return TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: Duration(
                                milliseconds: 600 + (index * 120),
                              ),
                              curve: Curves.easeOutExpo,

                              builder: (context, value, child) {
                                final opacity = value.clamp(0.0, 1.0);

                                return Opacity(
                                  opacity: opacity,
                                  child: Transform.translate(
                                    offset: Offset(40 * (1 - value), 0),
                                    child: Transform.scale(
                                      scale: 0.92 + (0.08 * value),
                                      child: child,
                                    ),
                                  ),
                                );
                              },

                              // PREMIUM CARD STYLE
                              child: Container(
                                width: 250,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.85),
                                      Colors.white.withOpacity(0.65),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 18,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                  backgroundBlendMode: BlendMode.overlay,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 10,
                                      sigmaY: 10,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: CourseCard(course: course),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                const SizedBox(height: 24),

                // ---------------------- TOP TUTORS ------------------------
                _buildSectionHeader(
                  context,
                  title: 'Top Tutors',
                  onViewAll: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TutorsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 14),

                tutorProvider.isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : tutorProvider.tutors.isEmpty
                    ? _buildEmptyState('No tutors found', Icons.person)
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tutorProvider.tutors.length.clamp(0, 3),
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final tutor = tutorProvider.tutors[index];
                          return TutorCard(tutor: tutor);
                        },
                      ),

                const SizedBox(height: 34),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, String query) {
    final tutorProvider = Provider.of<TutorProvider>(context);
    final courseProvider = Provider.of<CourseProvider>(context);

    final matchingCourses = courseProvider.courses
        .where((c) =>
            c.title.toLowerCase().contains(query.toLowerCase()) ||
            c.description.toLowerCase().contains(query.toLowerCase()))
        .toList();

    final matchingTutors = tutorProvider.tutors
        .where((t) =>
            t.user.name.toLowerCase().contains(query.toLowerCase()) ||
            t.category.name.toLowerCase().contains(query.toLowerCase()) ||
            (t.bio?.toLowerCase().contains(query.toLowerCase()) ?? false))
        .toList();

    if (matchingCourses.isEmpty && matchingTutors.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_outlined, size: 72, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'No matches found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'We couldn\'t find any courses or tutors for "$query".',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Search Results for "$query"',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            Text(
              '${matchingCourses.length} Courses · ${matchingTutors.length} Tutors',
              style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (matchingCourses.isNotEmpty) ...[
          _buildSearchHeader('🎓 Matching Courses', matchingCourses.length),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: matchingCourses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final course = matchingCourses[index];
              return CourseCard(course: course);
            },
          ),
          const SizedBox(height: 24),
        ],

        if (matchingTutors.isNotEmpty) ...[
          _buildSearchHeader('👨‍🏫 Matching Tutors', matchingTutors.length),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: matchingTutors.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final tutor = matchingTutors[index];
              return TutorCard(tutor: tutor);
            },
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildSearchHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Learn Anything,',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Anytime, Anywhere',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connect with expert tutors and courses',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CoursesScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Explore Now',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.school_outlined, size: 90, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.user?.role ?? 'student';
    final isAdmin = userRole == 'admin' || userRole == 'superadmin';

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: [
        _buildQuickActionCard(
          context,
          icon: Icons.my_library_books_outlined,
          title: 'Courses',
          color: Colors.green,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyEnrollmentsScreen()));
          },
        ),
        _buildQuickActionCard(
          context,
          icon: Icons.emoji_events_outlined,
          title: 'Certs',
          color: Colors.amber,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentCertificatesScreen()));
          },
        ),
        _buildQuickActionCard(
          context,
          icon: Icons.favorite_border,
          title: 'Wishlist',
          color: Colors.pinkAccent,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentWishlistScreen()));
          },
        ),
        _buildQuickActionCard(
          context,
          icon: Icons.video_camera_front,
          title: 'Live Class',
          color: Colors.redAccent,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentLiveClassesScreen()));
          },
        ),
        if (isAdmin)
          _buildQuickActionCard(
            context,
            icon: Icons.workspace_premium,
            title: 'Billing',
            color: const Color(0xFF6B4DF1),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
            },
          )
        else
          _buildQuickActionCard(
            context,
            icon: Icons.assignment_turned_in,
            title: 'Assignments',
            color: Colors.purple,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentAssignmentsScreen()));
            },
          ),
        _buildQuickActionCard(
          context,
          icon: Icons.bar_chart,
          title: 'Reports',
          color: Colors.teal,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentAnalyticsScreen()));
          },
        ),
      ],
    );
  }

  Widget _buildTodayExams(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.flash_on, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 12),
              const Text("Today's Exams", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          _isLoadingExams
              ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : _buildDynamicExamsList(),
        ],
      ),
    );
  }

  Widget _buildDynamicExamsList() {
    final now = DateTime.now();
    final todayExams = _exams.where((exam) {
      final bool isScheduled = exam['isScheduled'] ?? false;
      final int attemptCount = exam['attemptCount'] ?? 0;
      
      // 1. Must be scheduled
      if (!isScheduled) return false;
      
      // 2. Must not be completed
      if (attemptCount > 0) return false;
      
      // 3. Must be currently active (startDate <= now <= endDate)
      final String? startDateStr = exam['startDate'];
      final String? endDateStr = exam['endDate'];
      
      if (startDateStr != null) {
        final start = DateTime.tryParse(startDateStr);
        if (start != null && now.isBefore(start)) return false;
      }
      
      if (endDateStr != null) {
        final end = DateTime.tryParse(endDateStr);
        if (end != null && now.isAfter(end)) return false;
      }
      
      return true;
    }).toList();

    if (todayExams.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white70, size: 36),
            const SizedBox(height: 8),
            const Text("You are all caught up!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            const Text("No pending exams scheduled for today.", style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                if (homeState != null) {
                  homeState._onItemTapped(2); // Go to My Learning tab
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.purple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("View All Exams", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: todayExams.take(2).map((exam) {
        final title = exam['title'] ?? 'Exam';
        final duration = exam['duration'] ?? 60;
        final int attemptCount = exam['attemptCount'] ?? 0;
        final lastAttempt = exam['lastAttempt'];
        final String? lastAttemptId = exam['lastAttemptId'] ?? (lastAttempt != null ? lastAttempt['_id']?.toString() : null);

        final bool hasAttempted = attemptCount > 0 && lastAttemptId != null;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.assignment_outlined, color: Colors.white70),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text("Duration: $duration mins", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (hasAttempted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StudentExamResultScreen(attemptId: lastAttemptId),
                      ),
                    ).then((_) => _fetchExams());
                  } else {
                    _attemptExam(exam);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasAttempted ? Colors.teal : Colors.white,
                  foregroundColor: hasAttempted ? Colors.white : Colors.purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  hasAttempted ? "View Result" : "Take Exam",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAIRecommendations(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            const Text('AI Recommendations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildRecommendationTile(Icons.play_circle_outline, "Continue your enrolled courses"),
                const Divider(),
                _buildRecommendationTile(Icons.article_outlined, "Practice upcoming exam topics"),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                      if (homeState != null) {
                        homeState._onItemTapped(3); // Go to AI Buddy tab
                      }
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text("Start AI Study Plan"),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationTile(IconData icon, String text) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildPerformanceOverview(BuildContext context) {
    // Placeholder data
    final data = [
      ChartDataPoint(label: 'Jan', value: 45),
      ChartDataPoint(label: 'Feb', value: 52),
      ChartDataPoint(label: 'Mar', value: 48),
      ChartDataPoint(label: 'Apr', value: 70),
      ChartDataPoint(label: 'May', value: 85),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Performance Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
          ),
          child: PerformanceChart(data: data),
        ),
      ],
    );
  }

  Widget _buildAnnouncements(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Announcements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 2,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade300)),
                        child: const Text("Mathematics", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                      const Spacer(),
                      const Text("2h ago", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text("New Assignment Posted", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  const Text("The final term practice assignment is now available in your portal.", style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAITools(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Tools',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        FeatureGate(
          featureKey: 'aiAssistant',
          showLockOverlay: true,
          fallback: _buildLockedAICard(context),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AiBuddyScreen()),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: _buildAICard(),
          ),
        ),
      ],
    );
  }

  Widget _buildAICard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.deepPurple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.purple.shade100, shape: BoxShape.circle),
            child: const Icon(Icons.smart_toy, color: Colors.deepPurple),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Buddy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                SizedBox(height: 4),
                Text('Chat with your AI Tutor to solve doubts instantly', style: TextStyle(fontSize: 13, color: Colors.deepPurple)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.deepPurple),
        ],
      ),
    );
  }

  Widget _buildLockedAICard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
            child: Icon(Icons.lock, color: Colors.grey[500]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Buddy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                const SizedBox(height: 4),
                Text('Upgrade your institute plan to unlock AI features', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Text('PRO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple)),
          ),
        ],
      ),
    );
  }


  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required VoidCallback onViewAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton(onPressed: onViewAll, child: const Text('View all')),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
