import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/course_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../services/enrollment_service.dart';
import '../../services/tutor_link_service.dart';
import '../../utils/constants.dart';
import '../../widgets/sapience_ui.dart';
import '../../widgets/workspace_switcher.dart';

class TutorStudentsScreen extends StatefulWidget {
  const TutorStudentsScreen({super.key});

  @override
  State<TutorStudentsScreen> createState() => _TutorStudentsScreenState();
}

class _TutorStudentsScreenState extends State<TutorStudentsScreen> {
  int _selectedTab = 0; // 0: Enrolled, 1: Private Requests, 2: Offline Fees
  String? _lastWorkspaceSignature;

  String? _selectedCourseId;
  List<StudentEnrollment> _students = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> _privateLinks = [];
  Map<String, dynamic>? _privateQuota;
  bool _isLoadingRequests = false;

  List<Map<String, dynamic>> _offlinePending = [];
  bool _isLoadingOffline = false;
  String? _processingActionId;

  @override
  void initState() {
    super.initState();
    _reloadForWorkspace();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ws = Provider.of<WorkspaceProvider>(context);
    final signature = '${ws.workspaceType}|${ws.activeInstituteId ?? ''}';
    if (_lastWorkspaceSignature == null) {
      _lastWorkspaceSignature = signature;
      return;
    }
    if (_lastWorkspaceSignature != signature) {
      _lastWorkspaceSignature = signature;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedCourseId = null;
          _students = [];
        });
        _reloadForWorkspace();
      });
    }
  }

  Future<void> _reloadForWorkspace() async {
    await Future.wait([
      _loadCourses(),
      _loadPrivateRequests(),
      _loadOfflinePending(),
    ]);
  }

  Future<void> _loadCourses() async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    await courseProvider.fetchMyCourses();
  }

  Future<void> _loadPrivateRequests() async {
    if (mounted) setState(() => _isLoadingRequests = true);
    try {
      final res = await TutorLinkService.getTutorStudentRequests(status: 'all');
      if (!mounted) return;
      final rawLinks = res['links'] as List? ?? const [];
      setState(() {
        _privateLinks = rawLinks
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _privateQuota = res['quota'] is Map
            ? Map<String, dynamic>.from(res['quota'])
            : null;
        _isLoadingRequests = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingRequests = false);
    }
  }

  Future<void> _loadOfflinePending() async {
    if (mounted) setState(() => _isLoadingOffline = true);
    try {
      final list = await EnrollmentService.getOfflinePendingEnrollments();
      if (!mounted) return;
      setState(() {
        _offlinePending = list;
        _isLoadingOffline = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingOffline = false);
    }
  }

  Future<void> _loadStudents(String courseId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await EnrollmentService.getCourseStudents(courseId);

      // Parse the response
      List<StudentEnrollment> students = [];
      for (var item in result) {
        students.add(StudentEnrollment.fromJson(item));
      }

      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading students: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    final myCourses = courseProvider.myCourses;
    final pendingRequestCount =
        _privateLinks.where((l) => l['status'] == 'pending').length;

    return SapienceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SapienceHeader(
                title: 'My Students',
                actions: [
                  Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: _showAddPrivateStudentDialog,
                      borderRadius: BorderRadius.circular(14),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.person_add_alt_1_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                child: WorkspaceSwitcherBar(
                  compact: true,
                  onWorkspaceChanged: _reloadForWorkspace,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                child: SapienceSegmentedTabs(
                  tabs: [
                    'Enrolled',
                    'Private ($pendingRequestCount)',
                    'Offline (${_offlinePending.length})',
                  ],
                  currentIndex: _selectedTab,
                  onChanged: (idx) => setState(() => _selectedTab = idx),
                ),
              ),
              Expanded(
                child: _selectedTab == 0
                    ? Column(
                        children: [
                          // Course Filter
                          if (myCourses.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedCourseId,
                                decoration: InputDecoration(
                                  labelText: 'Filter by Course',
                                  prefixIcon: const Icon(Icons.school),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        AppThemeDesign.borderRadiusMedium,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                hint: const Text('Select a course'),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('All Courses'),
                                  ),
                                  ...myCourses.map((course) {
                                    return DropdownMenuItem(
                                      value: course.id,
                                      child: Text(
                                        course.title,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCourseId = value;
                                    _students = [];
                                  });
                                  if (value != null) {
                                    _loadStudents(value);
                                  }
                                },
                              ),
                            ),

                          // Stats Summary
                          if (_selectedCourseId != null && _students.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: AppThemeDesign.borderRadiusMedium,
                                boxShadow: const [AppThemeDesign.cardShadow],
                                border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.12),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem(
                                    icon: Icons.people,
                                    label: 'Students',
                                    value: _students.length.toString(),
                                  ),
                                  _buildStatItem(
                                    icon: Icons.trending_up,
                                    label: 'Active',
                                    value: _students
                                        .where((s) => s.status == 'active')
                                        .length
                                        .toString(),
                                  ),
                                  _buildStatItem(
                                    icon: Icons.check_circle,
                                    label: 'Completed',
                                    value: _students
                                        .where((s) => s.status == 'completed')
                                        .length
                                        .toString(),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 12),

                          // Students List
                          Expanded(child: _buildStudentsList()),
                        ],
                      )
                    : _selectedTab == 1
                        ? _buildPrivateRequestsTab()
                        : _buildOfflineFeesTab(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildStudentsList() {
    // Show message if no course selected
    if (_selectedCourseId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Select a course to view students',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Show loading
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show empty state if no students
    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No students enrolled yet',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Students will appear here once they enroll',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Show real students list from API
    return RefreshIndicator(
      onRefresh: () => _loadStudents(_selectedCourseId!),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _students.length,
        itemBuilder: (context, index) {
          final student = _students[index];
          return _buildStudentCard(student);
        },
      ),
    );
  }

  Widget _buildStudentCard(StudentEnrollment student) {
    Color statusColor = student.status == 'completed'
        ? Colors.green
        : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              // Avatar with Profile Image
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: student.profileImage,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.primary.withOpacity(0.1),
                    child: Center(
                      child: Text(
                        student.name[0].toUpperCase(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.primary.withOpacity(0.1),
                    child: Center(
                      child: Text(
                        student.name[0].toUpperCase(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Student Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student.email,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (student.phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        student.phone,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  student.status == 'completed' ? 'Completed' : 'Active',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Course Progress',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    '${student.progressPercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: student.progressPercentage / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Footer Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Enrolled Date
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Enrolled: ${DateFormat('dd/MM/yyyy').format(student.enrolledAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),

              // Last Accessed
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    _getTimeAgo(student.lastAccessed),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildPrivateRequestsTab() {
    if (_isLoadingRequests && _privateLinks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final pending =
        _privateLinks.where((l) => l['status'] == 'pending').toList();
    final active = _privateLinks.where((l) => l['status'] == 'active').toList();
    final inactive = _privateLinks
        .where((l) => l['status'] == 'suspended' || l['status'] == 'rejected')
        .toList();

    final used = _privateQuota?['used'] ?? active.length;
    final limit = _privateQuota?['limit'];
    final planName = (_privateQuota?['planName'] ?? 'free').toString();

    return RefreshIndicator(
      onRefresh: _loadPrivateRequests,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppThemeDesign.borderRadiusMedium,
              boxShadow: const [AppThemeDesign.softShadow],
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Private Tuition Studio Roster',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Active: $used / ${limit == null ? 'Unlimited' : limit} • Plan: ${planName.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddPrivateStudentDialog,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
                  label: const Text('Add'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (pending.isNotEmpty) ...[
            Text(
              'Pending Join Requests (${pending.length})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.navyInk,
              ),
            ),
            const SizedBox(height: 8),
            ...pending.map((link) => _buildPrivateLinkCard(link, isPending: true)),
            const SizedBox(height: 16),
          ],
          Text(
            'Active Private Students (${active.length})',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.navyInk,
            ),
          ),
          const SizedBox(height: 8),
          if (active.isEmpty && pending.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppThemeDesign.borderRadiusMedium,
              ),
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 54, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  Text(
                    'No private students linked yet',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Students can request to join your Private Studio or you can add them directly by email.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          else
            ...active.map((link) => _buildPrivateLinkCard(link)),
          if (inactive.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Suspended / Rejected (${inactive.length})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            ...inactive.map((link) => _buildPrivateLinkCard(link)),
          ],
        ],
      ),
    );
  }

  Widget _buildPrivateLinkCard(
    Map<String, dynamic> link, {
    bool isPending = false,
  }) {
    final linkId = (link['_id'] ?? '').toString();
    final student = link['studentId'] is Map
        ? Map<String, dynamic>.from(link['studentId'])
        : <String, dynamic>{};
    final name = (student['name'] ?? 'Student').toString();
    final email = (student['email'] ?? '').toString();
    final phone = (student['phone'] ?? '').toString();
    final status = (link['status'] ?? 'pending').toString();
    final message = (link['requestMessage'] ?? '').toString();
    final subjects = (link['subjects'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];
    final busy = _processingActionId == linkId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppThemeDesign.borderRadiusMedium,
        boxShadow: const [AppThemeDesign.softShadow],
        border: Border.all(
          color: isPending
              ? Colors.orange.withValues(alpha: 0.35)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryTint,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    if (phone.isNotEmpty)
                      Text(
                        phone,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (status == 'active'
                          ? AppColors.success
                          : status == 'pending'
                              ? Colors.orange
                              : AppColors.error)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: status == 'active'
                        ? AppColors.success
                        : status == 'pending'
                            ? Colors.orange
                            : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          if (subjects.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: subjects
                  .map(
                    (s) => Chip(
                      label: Text(s, style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: AppColors.primaryTint,
                    ),
                  )
                  .toList(),
            ),
          ],
          if (message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '"$message"',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (status == 'pending' || status == 'active') ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'pending') ...[
                  OutlinedButton(
                    onPressed: busy ? null : () => _rejectPrivateLink(linkId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: busy ? null : () => _approvePrivateLink(linkId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(busy ? 'Saving...' : 'Approve'),
                  ),
                ] else
                  TextButton(
                    onPressed: busy ? null : () => _suspendPrivateLink(linkId),
                    style: TextButton.styleFrom(foregroundColor: AppColors.error),
                    child: Text(busy ? 'Updating...' : 'Suspend Student'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOfflineFeesTab() {
    if (_isLoadingOffline && _offlinePending.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_offlinePending.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadOfflinePending,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 48),
            Icon(Icons.receipt_long_outlined, size: 68, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text(
              'No Offline Fee Submissions Pending',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'When students submit manual/offline tuition fee receipts or UTR references for courses in this workspace, they appear here for verification.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOfflinePending,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _offlinePending.length,
        itemBuilder: (context, index) {
          final item = _offlinePending[index];
          final id = (item['_id'] ?? '').toString();
          final student = item['studentId'] is Map
              ? Map<String, dynamic>.from(item['studentId'])
              : <String, dynamic>{};
          final course = item['courseId'] is Map
              ? Map<String, dynamic>.from(item['courseId'])
              : <String, dynamic>{};
          final offline = item['offlinePayment'] is Map
              ? Map<String, dynamic>.from(item['offlinePayment'])
              : <String, dynamic>{};

          final studentName = (student['name'] ?? 'Student').toString();
          final studentEmail = (student['email'] ?? '').toString();
          final courseTitle = (course['title'] ?? 'Course').toString();
          final declaredAmount =
              offline['declaredAmount'] ?? course['price'] ?? 0;
          final txRef = (offline['transactionRef'] ?? '').toString();
          final note = (offline['note'] ?? '').toString();
          final busy = _processingActionId == id;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppThemeDesign.borderRadiusMedium,
              boxShadow: const [AppThemeDesign.softShadow],
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            courseTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.navyInk,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$studentName${studentEmail.isNotEmpty ? ' • $studentEmail' : ''}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '₹$declaredAmount',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                if (txRef.isNotEmpty || note.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (txRef.isNotEmpty)
                          Text(
                            'UTR / Receipt Ref: $txRef',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        if (note.isNotEmpty) ...[
                          if (txRef.isNotEmpty) const SizedBox(height: 3),
                          Text(
                            'Note: $note',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: busy ? null : () => _rejectOfflineFee(id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: busy ? null : () => _confirmOfflineFee(id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 17),
                      label: Text(busy ? 'Confirming...' : 'Confirm Fee'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _approvePrivateLink(String linkId) async {
    setState(() => _processingActionId = linkId);
    try {
      await TutorLinkService.approveStudentLink(linkId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Private student approved!'),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadPrivateRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _processingActionId = null);
    }
  }

  Future<void> _rejectPrivateLink(String linkId) async {
    String reason = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Join Request'),
        content: TextFormField(
          onChanged: (v) => reason = v,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _processingActionId = linkId);
    try {
      await TutorLinkService.rejectStudentLink(
        linkId,
        rejectionReason: reason.trim().isNotEmpty ? reason.trim() : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected.')),
      );
      await _loadPrivateRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _processingActionId = null);
    }
  }

  Future<void> _suspendPrivateLink(String linkId) async {
    setState(() => _processingActionId = linkId);
    try {
      await TutorLinkService.suspendStudentLink(linkId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student suspended from Private Studio.')),
      );
      await _loadPrivateRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _processingActionId = null);
    }
  }

  void _showAddPrivateStudentDialog() {
    String email = '';
    String subjectsRaw = '';
    bool isSaving = false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Private Student by Email'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  onChanged: (v) => email = v,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v == null || !v.contains('@') ? 'Enter a valid student email' : null,
                  decoration: const InputDecoration(
                    labelText: 'Registered Student Email',
                    hintText: 'student@example.com',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  onChanged: (v) => subjectsRaw = v,
                  decoration: const InputDecoration(
                    labelText: 'Subjects (optional, comma separated)',
                    hintText: 'Physics, Maths',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setDialogState(() => isSaving = true);
                      try {
                        final subjects = subjectsRaw
                            .split(',')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList();
                        await TutorLinkService.addPrivateStudentByEmail(
                          email: email,
                          subjects: subjects.isNotEmpty ? subjects : null,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Student linked to your Private Studio!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          _loadPrivateRequests();
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Failed to add student: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(isSaving ? 'Adding...' : 'Add Student'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmOfflineFee(String enrollmentId) async {
    setState(() => _processingActionId = enrollmentId);
    try {
      await EnrollmentService.approveOfflineEnrollment(enrollmentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offline fee confirmed! Student is now enrolled.'),
          backgroundColor: AppColors.success,
        ),
      );
      await Future.wait([
        _loadOfflinePending(),
        if (_selectedCourseId != null) _loadStudents(_selectedCourseId!),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Confirmation failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _processingActionId = null);
    }
  }

  Future<void> _rejectOfflineFee(String enrollmentId) async {
    setState(() => _processingActionId = enrollmentId);
    try {
      await EnrollmentService.rejectEnrollment(enrollmentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline fee request rejected.')),
      );
      await _loadOfflinePending();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reject failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _processingActionId = null);
    }
  }
}

// ✅ Student Enrollment Model
class StudentEnrollment {
  final String enrollmentId;
  final String name;
  final String email;
  final String phone;
  final String profileImage;
  final DateTime enrolledAt;
  final DateTime lastAccessed;
  final String status;
  final double progressPercentage;
  final int completedLessons;
  final DateTime? completedAt;

  StudentEnrollment({
    required this.enrollmentId,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImage,
    required this.enrolledAt,
    required this.lastAccessed,
    required this.status,
    required this.progressPercentage,
    required this.completedLessons,
    this.completedAt,
  });

  factory StudentEnrollment.fromJson(Map<String, dynamic> json) {
    final studentData = json['studentId'] ?? {};
    final progressData = json['progress'] ?? {};

    return StudentEnrollment(
      enrollmentId: json['_id'] ?? '',
      name: studentData['name'] ?? 'Unknown',
      email: studentData['email'] ?? '',
      phone: studentData['phone'] ?? '',
      profileImage:
          studentData['profileImage'] ?? 'https://via.placeholder.com/150',
      enrolledAt: json['enrolledAt'] != null
          ? DateTime.parse(json['enrolledAt'])
          : DateTime.now(),
      lastAccessed: json['lastAccessed'] != null
          ? DateTime.parse(json['lastAccessed'])
          : DateTime.now(),
      status: json['status'] ?? 'active',
      progressPercentage: (progressData['percentage'] ?? 0).toDouble(),
      completedLessons:
          (progressData['completedLessons'] as List?)?.length ?? 0,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }
}
