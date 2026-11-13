import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../models/course_model.dart';
import '../../models/lesson_model.dart';
import '../../providers/enrollment_provider.dart';
import '../../services/course_service.dart';
import '../../services/payment_service.dart';
import '../../services/wishlist_service.dart';
import '../../utils/constants.dart';
import '../../widgets/sapience_ui.dart';
import 'lesson_player_screen.dart';

import '../../services/exam_service.dart';
import '../../services/live_class_service.dart';
import '../../services/assignment_service.dart';
import '../../models/live_class_model.dart';
import '../../models/assignment_model.dart';
import '../student/student_exam_result_screen.dart';
import '../student/exam_instructions_screen.dart';
import '../student/assignments/assignment_details_screen.dart';
import '../common/live_meeting_screen.dart';
import '../../services/review_service.dart';
import '../../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late Razorpay _razorpay;
  final _paymentService = PaymentService();
  final _wishlistService = WishlistService();

  bool _isLoading = true;
  CourseModel? _course;
  List<LessonModel> _lessons = [];
  bool _isEnrolled = false;
  bool _isWishlisted = false;
  bool _isTogglingWishlist = false;
  int _selectedTabIndex = 0;
  double _courseProgress = 0.0;

  List<dynamic> _exams = [];
  List<Assignment> _assignments = [];
  List<LiveClass> _liveClasses = [];
  bool _isLoadingEnrolledTabs = false;

  // Review states
  bool _isLoadingReview = false;
  Map<String, dynamic>? _myReview;
  bool _hasReviewed = false;
  List<dynamic> _publicReviews = [];
  bool _isLoadingPublicReviews = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _loadCourseData();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && mounted) {
      if (_selectedTabIndex != _tabController.index) {
        setState(() => _selectedTabIndex = _tabController.index);
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await _paymentService.verifyPayment({
        'razorpayOrderId': response.orderId,
        'razorpayPaymentId': response.paymentId,
        'razorpaySignature': response.signature,
      });

      if (mounted) Navigator.pop(context);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Successful! Enrolling you now...'), backgroundColor: Colors.green),
        );
        _loadCourseData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment verification failed.')));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification Error: $e')));
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}'), backgroundColor: Colors.red),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  Future<void> _loadCourseData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await CourseService.getCourseById(widget.courseId);
      if (data != null) {
        final enrolled = data['isEnrolled'] ?? false;
        _tabController.removeListener(_onTabChanged);
        _tabController.dispose();
        final newController = TabController(
          length: enrolled ? 5 : 3,
          vsync: this,
        )..addListener(_onTabChanged);

        setState(() {
          _course = data['course'];
          _lessons = (data['lessons'] as List)
              .map((json) => LessonModel.fromJson(json))
              .toList();
          _isEnrolled = enrolled;
          _selectedTabIndex = 0;
          _tabController = newController;
        });

        _loadWishlistState();

        if (_isEnrolled) {
          _syncEnrollmentProgress();
          await _loadEnrolledTabData();
          _fetchMyReview();
        } else {
          _fetchPublicReviews();
        }
      }
    } catch (e) {
      print('Error loading course: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadWishlistState() async {
    try {
      final wishlist = await _wishlistService.getWishlist();
      if (!mounted) return;
      setState(() {
        _isWishlisted = wishlist.any((c) => c.id == widget.courseId);
      });
    } catch (_) {}
  }

  Future<void> _syncEnrollmentProgress() async {
    try {
      final provider = Provider.of<EnrollmentProvider>(context, listen: false);
      if (provider.enrollments.isEmpty) {
        await provider.fetchMyEnrollments();
      }
      if (!mounted) return;
      for (final enr in provider.enrollments) {
        if (enr.course.id == widget.courseId) {
          setState(() {
            _courseProgress = enr.progress.percentage.clamp(0.0, 100.0);
          });
          break;
        }
      }
    } catch (_) {}
  }

  Future<void> _toggleWishlist() async {
    if (_isTogglingWishlist) return;
    setState(() => _isTogglingWishlist = true);
    try {
      final ok = _isWishlisted
          ? await _wishlistService.removeFromWishlist(widget.courseId)
          : await _wishlistService.addToWishlist(widget.courseId);
      if (!mounted) return;
      if (ok) {
        setState(() => _isWishlisted = !_isWishlisted);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isWishlisted ? 'Saved to your wishlist' : 'Removed from wishlist',
            ),
            backgroundColor:
                _isWishlisted ? AppColors.secondary : AppColors.navyInk,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update wishlist: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTogglingWishlist = false);
    }
  }

  void _openContinueLearning() {
    if (_lessons.isEmpty) {
      setState(() {
        _selectedTabIndex = 1;
        _tabController.animateTo(1);
      });
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonPlayerScreen(
          lesson: _lessons.first,
          courseId: widget.courseId,
        ),
      ),
    ).then((_) => _syncEnrollmentProgress());
  }

  Future<void> _loadEnrolledTabData() async {
    setState(() => _isLoadingEnrolledTabs = true);
    try {
      // 1. Fetch Exams
      final allExamsRes = await ExamService.getAllStudentExams();
      List<dynamic> courseExams = [];
      if (allExamsRes['success'] == true) {
        final List examsList = allExamsRes['exams'] ?? [];
        courseExams = examsList.where((ex) {
          final cid = ex['courseId'];
          return cid != null && cid.toString() == widget.courseId;
        }).toList();
      }

      // 2. Fetch Live Classes
      final liveClassesService = LiveClassService();
      final lClasses = await liveClassesService.fetchLiveClasses(courseId: widget.courseId);

      // 3. Fetch Assignments
      final assignmentsService = AssignmentService();
      final asgns = await assignmentsService.fetchAssignmentsByCourse(widget.courseId);

      setState(() {
        _exams = courseExams;
        _liveClasses = lClasses;
        _assignments = asgns;
      });
    } catch (e) {
      print('Error loading enrolled course tabs: $e');
    } finally {
      setState(() => _isLoadingEnrolledTabs = false);
    }
  }

  Future<void> _fetchMyReview() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    setState(() => _isLoadingReview = true);
    try {
      final res = await ReviewService.getMyReview(token: token, courseId: widget.courseId);
      if (res['success'] == true) {
        setState(() {
          _myReview = res['review'];
          _hasReviewed = res['hasReviewed'] ?? false;
        });
      }
    } catch (e) {
      print('Error fetching my review: $e');
    } finally {
      setState(() => _isLoadingReview = false);
    }
  }

  Future<void> _fetchPublicReviews() async {
    setState(() => _isLoadingPublicReviews = true);
    try {
      final res = await ReviewService.getCourseReviews(courseId: widget.courseId);
      if (res['success'] == true) {
        setState(() {
          _publicReviews = res['reviews'] ?? [];
        });
      }
    } catch (e) {
      print('Error fetching public reviews: $e');
    } finally {
      setState(() => _isLoadingPublicReviews = false);
    }
  }

  Future<void> _submitReview(int rating, String comment) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await ReviewService.createReview(
        token: token,
        courseId: widget.courseId,
        rating: rating,
        comment: comment,
      );

      if (mounted) Navigator.pop(context); // Dismiss loader

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!'), backgroundColor: Colors.green),
        );
        _fetchMyReview();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to submit review')),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Dismiss loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _updateReview(String reviewId, int rating, String comment) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await ReviewService.updateReview(
        token: token,
        reviewId: reviewId,
        rating: rating,
        comment: comment,
      );

      if (mounted) Navigator.pop(context); // Dismiss loader

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review updated successfully!'), backgroundColor: Colors.green),
        );
        _fetchMyReview();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to update review')),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Dismiss loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _enrollInCourse() async {
    if (_course == null) return;

    // Handle Paid Course Flow
    if (!_course!.isFree && _course!.price > 0) {
      try {
        final orderData = await _paymentService.createCourseOrder(_course!.id);
        
        var options = {
          'key': orderData['key'],
          'amount': orderData['order']['amount'],
          'name': 'Sapience LMS',
          'description': 'Purchase: ${_course!.title}',
          'order_id': orderData['order']['id'],
          'theme': {'color': '#6B4DF1'}
        };

        _razorpay.open(options);
        return;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Init Error: $e')));
        return;
      }
    }

    // Handle Free Course Flow (existing)
    final enrollmentProvider =
        Provider.of<EnrollmentProvider>(context, listen: false);

    final success = await enrollmentProvider.enrollInCourse(widget.courseId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enrolled successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadCourseData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              enrollmentProvider.error ?? 'Failed to enroll in course'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

    if (_course == null) {
      return SapienceBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: const [
                SapienceHeader(title: 'Course Details'),
                Expanded(child: Center(child: Text('Course not found'))),
              ],
            ),
          ),
        ),
      );
    }

    final tabs = _isEnrolled
        ? const ['Overview', 'Curriculum', 'Live', 'Tasks', 'Exams']
        : const ['Overview', 'Curriculum', 'Reviews'];

    return SapienceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SapienceHeader(
                title: _course!.title,
                actions: [
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: _toggleWishlist,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                          boxShadow: const [AppThemeDesign.softShadow],
                        ),
                        child: Icon(
                          _isWishlisted
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: _isWishlisted
                              ? AppColors.primary
                              : AppColors.navyInk,
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                          child: Column(
                            children: [
                              _buildHeroCourseBanner(),
                              const SizedBox(height: 12),
                              SapienceStatsRow(
                                items: [
                                  SapienceStatItem(
                                    icon: const Icon(
                                      Icons.schedule_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    value:
                                        '${_course!.duration.toStringAsFixed(0)}h',
                                    label: 'Duration',
                                  ),
                                  SapienceStatItem(
                                    icon: const Icon(
                                      Icons.play_lesson_rounded,
                                      size: 16,
                                      color: AppColors.secondary,
                                    ),
                                    value: '${_lessons.length}',
                                    label: 'Lessons',
                                  ),
                                  SapienceStatItem(
                                    icon: const Icon(
                                      Icons.people_alt_rounded,
                                      size: 16,
                                      color: Color(0xFF7B3DF5),
                                    ),
                                    value: '${_course!.enrolledCount}',
                                    label: 'Students',
                                  ),
                                  SapienceStatItem(
                                    icon: const Icon(
                                      Icons.bar_chart_rounded,
                                      size: 16,
                                      color: Color(0xFFE07A16),
                                    ),
                                    value: _course!.level.isNotEmpty
                                        ? _course!.level[0].toUpperCase() +
                                            _course!.level.substring(1)
                                        : 'All',
                                    label: 'Level',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SapienceSegmentedTabs(
                                tabs: tabs,
                                currentIndex: _selectedTabIndex.clamp(
                                  0,
                                  tabs.length - 1,
                                ),
                                onChanged: (index) {
                                  setState(() => _selectedTabIndex = index);
                                  _tabController.animateTo(index);
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: _isEnrolled
                        ? [
                            _buildOverviewTab(),
                            _buildCurriculumTab(),
                            _buildLiveClassesTab(),
                            _buildAssignmentsTab(),
                            _buildExamsTab(),
                          ]
                        : [
                            _buildOverviewTab(),
                            _buildCurriculumTab(),
                            _buildReviewsTab(),
                          ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildHeroCourseBanner() {
    return SapienceNavyWaveBanner(
      borderRadius: 24,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _course!.category.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1ED066).withOpacity(0.24),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFCA28),
                            size: 13,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${_course!.rating.toStringAsFixed(1)} (${_course!.reviewCount})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _course!.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'By ${_course!.tutor.user.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.84),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_isEnrolled) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_courseProgress.toStringAsFixed(0)}% Completed',
                        style: const TextStyle(
                          color: Color(0xFF7AF29B),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${_lessons.length} lessons',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (_courseProgress / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: Colors.white.withOpacity(0.18),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF1ED066),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 96,
              height: 112,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.22),
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: _course!.thumbnail.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: _course!.thumbnail,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Image.asset(
                        'assets/images/cd-illustration.png',
                        fit: BoxFit.cover,
                      ),
                      errorWidget: (_, __, ___) => Image.asset(
                        'assets/images/cd-illustration.png',
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      'assets/images/cd-illustration.png',
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About Course Card
          SapienceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About This Course',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyInk,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _course!.description,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // What you'll learn
          if (_course!.whatYouWillLearn.isNotEmpty) ...[
            SapienceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/cd-illustration.png',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'What You\'ll Learn',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navyInk,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ..._course!.whatYouWillLearn.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SapienceCheckBadge(size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: AppColors.navyInk,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Requirements
          if (_course!.requirements.isNotEmpty) ...[
            SapienceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Requirements',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyInk,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._course!.requirements.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: AppColors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Course Instructor Card
          SapienceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Course Instructor',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyInk,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: _course!.tutor.user.profileImage,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 52,
                          height: 52,
                          color: AppColors.primaryTint,
                          child: const Icon(Icons.person_rounded,
                              color: AppColors.primary),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 52,
                          height: 52,
                          color: AppColors.primaryTint,
                          child: const Icon(Icons.person_rounded,
                              color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _course!.tutor.user.name,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navyInk,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_course!.tutor.experience} years experience • ${_course!.tutor.rating.toStringAsFixed(1)} ★',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_isEnrolled) ...[
            const SizedBox(height: 14),
            _buildMyReviewSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildMyReviewSection() {
    if (_isLoadingReview) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasReviewed && _myReview != null) {
      final rating = _myReview!['rating'] ?? 5;
      final comment = _myReview!['comment'] ?? '';
      final reviewId = _myReview!['_id'];
      final tutorResponse = _myReview!['tutorResponse'];

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.shade50.withOpacity(0.4),
          borderRadius: AppThemeDesign.borderRadiusMedium,
          border: Border.all(color: Colors.amber.shade200, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Review',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                TextButton.icon(
                  onPressed: () {
                    _showReviewForm(
                      initialRating: rating,
                      initialComment: comment,
                      reviewId: reviewId,
                    );
                  },
                  icon: const Icon(Icons.edit, size: 16, color: AppColors.primary),
                  label: const Text(
                    'Edit',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (starIndex) {
                return Icon(
                  starIndex < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              comment,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            if (tutorResponse != null && tutorResponse['comment'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.reply, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        const Text(
                          'Tutor Response',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tutorResponse['comment'],
                      style: TextStyle(fontSize: 13, color: Colors.grey[700], fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: AppThemeDesign.borderRadiusMedium,
        border: Border.all(color: AppColors.primary.withOpacity(0.12), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rate this course',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          const Text(
            'Share your thoughts to help other students.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(5, (index) {
                  return InkWell(
                    onTap: () {
                      _showReviewForm(initialRating: index + 1);
                    },
                    child: const Icon(
                      Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () {
                  _showReviewForm();
                },
                child: const Text('Write Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReviewForm({int? initialRating, String? initialComment, String? reviewId}) {
    int rating = initialRating ?? 5;
    final controller = TextEditingController(text: initialComment);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reviewId == null ? 'Write a Review' : 'Edit Your Review',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starVal = index + 1;
                      return IconButton(
                        icon: Icon(
                          starVal <= rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () {
                          setModalState(() {
                            rating = starVal;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Share your thoughts about this course...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final comment = controller.text.trim();
                        if (comment.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a comment')),
                          );
                          return;
                        }
                        if (comment.length < 10) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Comment must be at least 10 characters')),
                          );
                          return;
                        }
                        Navigator.pop(context); // close bottom sheet
                        if (reviewId == null) {
                          _submitReview(rating, comment);
                        } else {
                          _updateReview(reviewId, rating, comment);
                        }
                      },
                      child: Text(
                        reviewId == null ? 'Submit Review' : 'Update Review',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCurriculumTab() {
    if (_lessons.isEmpty) {
      return Center(
        child: SapienceCard(
          margin: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.menu_book_rounded, size: 42, color: AppColors.primary),
              SizedBox(height: 10),
              Text(
                'No lessons available yet',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyInk,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group lessons by module
    final Map<String, List<LessonModel>> lessonsByModule = {};
    for (final lesson in _lessons) {
      lessonsByModule.putIfAbsent(lesson.moduleId, () => []).add(lesson);
    }

    const tones = [
      SapienceTileTone.blue,
      SapienceTileTone.green,
      SapienceTileTone.purple,
      SapienceTileTone.orange,
    ];
    final toneColors = [
      AppColors.primary,
      AppColors.secondary,
      const Color(0xFF7B3DF5),
      const Color(0xFFE07A16),
    ];

    if (_course!.modules.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _lessons.length,
        itemBuilder: (context, index) {
          final lesson = _lessons[index];
          return _buildLessonRowCard(
            lesson,
            tones[index % tones.length],
            toneColors[index % toneColors.length],
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _course!.modules.length,
      itemBuilder: (context, index) {
        final module = _course!.modules[index];
        final moduleLessons = lessonsByModule[module.id] ?? [];
        final accent = toneColors[index % toneColors.length];

        return SapienceCard(
          margin: const EdgeInsets.only(bottom: 14),
          padding: EdgeInsets.zero,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: index == 0,
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  (index + 1).toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: accent,
                  ),
                ),
              ),
              title: Text(
                module.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.navyInk,
                ),
              ),
              subtitle: Text(
                '${moduleLessons.length} ${moduleLessons.length == 1 ? 'lesson' : 'lessons'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              children: moduleLessons.asMap().entries.map((entry) {
                final lIdx = entry.key;
                return _buildLessonRowCard(
                  entry.value,
                  tones[(index + lIdx) % tones.length],
                  toneColors[(index + lIdx) % toneColors.length],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLessonRowCard(
    LessonModel lesson,
    SapienceTileTone tone,
    Color accentColor,
  ) {
    final canAccess = _isEnrolled || lesson.isFree;
    final iconData = lesson.type == 'video'
        ? Icons.play_circle_outline_rounded
        : lesson.type == 'document'
            ? Icons.description_outlined
            : Icons.quiz_outlined;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SapienceTintedTile(
        tone: tone,
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onTap: canAccess
            ? () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (_) => LessonPlayerScreen(
                          lesson: lesson,
                          courseId: widget.courseId,
                        ),
                      ),
                    )
                    .then((_) => _syncEnrollmentProgress());
              }
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enroll in this course to unlock this lesson'),
                  ),
                );
              },
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
              child: Icon(
                iconData,
                color: canAccess ? accentColor : AppColors.textMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyInk,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (lesson.content.duration != null) ...[
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(lesson.content.duration! / 60).ceil()} min',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else
                        Text(
                          lesson.type.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (lesson.isFree) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'FREE',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SapiencePlayCircle(
              solid: canAccess,
              locked: !canAccess,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    if (_isLoadingPublicReviews) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_publicReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No reviews yet for this course',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _publicReviews.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final review = _publicReviews[index];
        final student = review['studentId'];
        final studentName = student != null ? student['name'] : 'Student';
        final studentImg = student != null ? student['profileImage'] : null;
        final rating = review['rating'] ?? 5;
        final comment = review['comment'] ?? '';
        final tutorResponse = review['tutorResponse'];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppThemeDesign.borderRadiusMedium,
            boxShadow: const [AppThemeDesign.cardShadow],
            border: Border.all(color: Colors.grey.shade100, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: studentImg != null ? CachedNetworkImageProvider(studentImg) : null,
                    child: studentImg == null ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              starIndex < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                comment,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              if (tutorResponse != null && tutorResponse['comment'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.reply, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          const Text(
                            'Tutor Response',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tutorResponse['comment'],
                        style: TextStyle(fontSize: 13, color: Colors.grey[700], fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveClassesTab() {
    if (_isLoadingEnrolledTabs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_liveClasses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_camera_back_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'No live classes scheduled for this course.',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _liveClasses.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final liveClass = _liveClasses[index];
        final bool isLive = liveClass.status == 'ongoing' ||
            (liveClass.status == 'scheduled' &&
                liveClass.dateTime.isBefore(DateTime.now().add(const Duration(minutes: 5))));

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppThemeDesign.borderRadiusMedium,
            boxShadow: const [AppThemeDesign.cardShadow],
            border: Border.all(color: Colors.grey.shade100, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        liveClass.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLive ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isLive ? 'LIVE' : liveClass.status.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.blueAccent),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('EEE, MMM d, yyyy').format(liveClass.dateTime),
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 14, color: Colors.blueAccent),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('hh:mm a').format(liveClass.dateTime),
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLive ? () => _joinClass(liveClass) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(borderRadius: AppThemeDesign.borderRadiusMedium),
                    ),
                    child: const Text('Join Class', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssignmentsTab() {
    if (_isLoadingEnrolledTabs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'No assignments posted for this course.',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _assignments.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final assignment = _assignments[index];
        final formattedDueDate = assignment.dueDate != null
            ? DateFormat('MMM d, yyyy (hh:mm a)').format(assignment.dueDate!)
            : 'No due date';

        final isSubmitted = assignment.mySubmission != null;
        final isGraded = assignment.mySubmission?.status == 'graded';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppThemeDesign.borderRadiusMedium,
            boxShadow: const [AppThemeDesign.cardShadow],
            border: Border.all(color: Colors.grey.shade100, width: 1),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AssignmentDetailsScreen(assignmentId: assignment.id),
                ),
              ).then((_) => _loadEnrolledTabData());
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          assignment.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isGraded
                              ? Colors.green.withOpacity(0.1)
                              : isSubmitted
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isGraded
                              ? 'GRADED'
                              : isSubmitted
                                  ? 'SUBMITTED'
                                  : 'PENDING',
                          style: TextStyle(
                            color: isGraded
                                ? Colors.green
                                : isSubmitted
                                    ? Colors.blue
                                    : Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (assignment.description != null && assignment.description!.isNotEmpty) ...[
                    Text(
                      assignment.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      const Icon(Icons.event_note, size: 14, color: Colors.orangeAccent),
                      const SizedBox(width: 4),
                      Text(
                        'Due: $formattedDueDate',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const Spacer(),
                      const Icon(Icons.bookmark_outline, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Marks: ${assignment.totalMarks}',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExamsTab() {
    if (_isLoadingEnrolledTabs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'No exams scheduled for this course.',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _exams.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final exam = _exams[index];
        final int attemptCount = exam['attemptCount'] ?? 0;
        final bool isCompletedState = attemptCount > 0;
        
        final lastAttempt = exam['lastAttempt'];
        final bool? isPassed = lastAttempt != null ? lastAttempt['isPassed'] : null;

        Color statusColor = Colors.orange;
        String statusText = 'Available';

        if (isCompletedState) {
          if (isPassed == true) {
            statusColor = Colors.green;
            statusText = 'Passed';
          } else if (isPassed == false) {
            statusColor = Colors.red;
            statusText = 'Failed';
          } else {
            statusColor = Colors.blue;
            statusText = 'Attempted';
          }
        }

        final buttonText = isCompletedState ? 'View Result' : 'Take Exam';
        final buttonColor = isCompletedState ? Colors.teal : AppColors.primary;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppThemeDesign.borderRadiusMedium,
            boxShadow: const [AppThemeDesign.cardShadow],
            border: Border.all(color: Colors.grey.shade100, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        exam['title'] ?? 'Exam',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
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
                    onPressed: () {
                      if (isCompletedState) {
                        final String? attemptId = lastAttempt != null ? lastAttempt['_id']?.toString() : null;
                        if (attemptId != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StudentExamResultScreen(attemptId: attemptId),
                            ),
                          ).then((_) => _loadEnrolledTabData());
                        } else {
                          _attemptExam(exam);
                        }
                      } else {
                        _attemptExam(exam);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: AppThemeDesign.borderRadiusMedium),
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
      ],
    );
  }

  void _joinClass(LiveClass liveClass) async {
    if (liveClass.status == 'completed' || liveClass.status == 'cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This class has ended or been cancelled')),
      );
      return;
    }

    try {
      final liveClassService = LiveClassService();
      final config = await liveClassService.getJoinConfig(liveClass.id);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LiveMeetingScreen(
              classId: liveClass.id,
              config: config,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Join Error: $e')),
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
        ).then((_) => _loadEnrolledTabData());
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

  Widget _buildBottomBar() {
    if (_course == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0E2960).withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: _isEnrolled
                  ? SapienceButton(
                      label: _isWishlisted ? 'Saved' : 'Save Course',
                      leadingIcon: _isWishlisted
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      variant: SapienceButtonVariant.outlinedNavy,
                      height: 48,
                      fontSize: 13.5,
                      onTap: _toggleWishlist,
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _course!.isFree
                              ? 'Free Course'
                              : '₹${_course!.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navyInk,
                          ),
                        ),
                        Text(
                          _course!.isFree
                              ? 'Instant full access'
                              : 'One-time enrollment',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: _isEnrolled
                  ? SapienceButton(
                      label: 'Continue Learning',
                      trailingIcon: Icons.arrow_forward_rounded,
                      variant: SapienceButtonVariant.greenToBlue,
                      height: 48,
                      fontSize: 14,
                      onTap: _openContinueLearning,
                    )
                  : Consumer<EnrollmentProvider>(
                      builder: (context, enrollmentProvider, _) {
                        if (enrollmentProvider.isLoading) {
                          return Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppThemeDesign.greenToBlueGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.2,
                              ),
                            ),
                          );
                        }
                        return SapienceButton(
                          label: _course!.isFree
                              ? 'Enroll Free'
                              : 'Enroll Now • ₹${_course!.price.toStringAsFixed(0)}',
                          trailingIcon: Icons.arrow_forward_rounded,
                          variant: SapienceButtonVariant.greenToBlue,
                          height: 48,
                          fontSize: 14,
                          onTap: _enrollInCourse,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}