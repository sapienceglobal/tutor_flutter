import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../models/course_model.dart';
import '../../models/lesson_model.dart';
import '../../providers/enrollment_provider.dart';
import '../../services/course_service.dart';
import '../../services/payment_service.dart';
import '../../utils/constants.dart';
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
  
  bool _isLoading = true;
  CourseModel? _course;
  List<LessonModel> _lessons = [];
  bool _isEnrolled = false;

  List<dynamic> _exams = [];
  List<Assignment> _assignments = [];
  List<LiveClass> _liveClasses = [];
  bool _isLoadingEnrolledTabs = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    
    _loadCourseData();
  }

  @override
  void dispose() {
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
        setState(() {
          _course = data['course'];
          _lessons = (data['lessons'] as List)
              .map((json) => LessonModel.fromJson(json))
              .toList();
          _isEnrolled = enrolled;
          
          _tabController.dispose();
          _tabController = TabController(
            length: _isEnrolled ? 5 : 3,
            vsync: this,
          );
        });

        if (_isEnrolled) {
          await _loadEnrolledTabData();
        }
      }
    } catch (e) {
      print('Error loading course: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_course == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course Details')),
        body: const Center(child: Text('Course not found')),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: CachedNetworkImage(
                  imageUrl: _course!.thumbnail,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 80),
                  ),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Course Header Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    _course!.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Category & Level
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _course!.category.name,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _course!.level.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Stats
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${_course!.rating.toStringAsFixed(1)} (${_course!.reviewCount})',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.people_outline,
                          color: Colors.grey, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${_course!.enrolledCount} students',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time,
                          color: Colors.grey, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${_course!.duration.toStringAsFixed(0)}h',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tutor Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: CachedNetworkImageProvider(
                          _course!.tutor.user.profileImage,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _course!.tutor.user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_course!.tutor.experience} years experience',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
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

             // Tabs
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                isScrollable: _isEnrolled, // scrollable if 5 tabs
                tabs: _isEnrolled
                    ? const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Curriculum'),
                        Tab(text: 'Live Classes'),
                        Tab(text: 'Assignments'),
                        Tab(text: 'Exams'),
                      ]
                    : const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Curriculum'),
                        Tab(text: 'Reviews'),
                      ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
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
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          const Text(
            'About this course',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _course!.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // What you'll learn
          if (_course!.whatYouWillLearn.isNotEmpty) ...[
            const Text(
              'What you\'ll learn',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._course!.whatYouWillLearn.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 24),
          ],

          // Requirements
          if (_course!.requirements.isNotEmpty) ...[
            const Text(
              'Requirements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._course!.requirements.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.circle,
                        color: Colors.grey,
                        size: 8,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildCurriculumTab() {
    if (_lessons.isEmpty) {
      return const Center(
        child: Text('No lessons available'),
      );
    }

    // Group lessons by module
    Map<String, List<LessonModel>> lessonsByModule = {};
    for (var lesson in _lessons) {
      final moduleId = lesson.moduleId;
      if (!lessonsByModule.containsKey(moduleId)) {
        lessonsByModule[moduleId] = [];
      }
      lessonsByModule[moduleId]!.add(lesson);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _course!.modules.length,
      itemBuilder: (context, index) {
        final module = _course!.modules[index];
        final moduleLessons = lessonsByModule[module.id] ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Text(
              module.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${moduleLessons.length} lessons'),
            children: moduleLessons.map((lesson) {
              final canAccess = _isEnrolled || lesson.isFree;

              return ListTile(
                leading: Icon(
                  lesson.type == 'video'
                      ? Icons.play_circle_outline
                      : lesson.type == 'document'
                          ? Icons.description_outlined
                          : Icons.quiz_outlined,
                  color: canAccess ? AppColors.primary : Colors.grey,
                ),
                title: Text(lesson.title),
                subtitle: Row(
                  children: [
                    if (lesson.content.duration != null) ...[
                      const Icon(Icons.access_time, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${(lesson.content.duration! / 60).toStringAsFixed(0)} min',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                    if (lesson.isFree) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'FREE',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: canAccess
                    ? const Icon(Icons.chevron_right)
                    : const Icon(Icons.lock_outline, color: Colors.grey),
                onTap: canAccess
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LessonPlayerScreen(
                              lesson: lesson,
                              courseId: widget.courseId,
                            ),
                          ),
                        );
                      }
                    : null,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Reviews coming soon',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
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

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _course!.isFree ? 'Free' : '₹${_course!.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                if (!_course!.isFree)
                  Text(
                    'One-time payment',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Consumer<EnrollmentProvider>(
              builder: (context, enrollmentProvider, _) {
                return ElevatedButton(
                  onPressed: _isEnrolled
                      ? null
                      : enrollmentProvider.isLoading
                          ? null
                          : _enrollInCourse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isEnrolled ? Colors.grey : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: enrollmentProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isEnrolled ? 'Enrolled' : 'Enroll Now',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}