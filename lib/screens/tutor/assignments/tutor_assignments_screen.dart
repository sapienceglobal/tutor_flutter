import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/api_config.dart';
import '../../../models/course_model.dart';
import '../../../models/assignment_model.dart';
import '../../../providers/course_provider.dart';
import '../../../services/assignment_service.dart';
import '../../../services/batch_service.dart';
import '../../../utils/constants.dart';
import '../../../widgets/sapience_ui.dart';

class TutorAssignmentsScreen extends StatefulWidget {
  const TutorAssignmentsScreen({super.key});

  @override
  State<TutorAssignmentsScreen> createState() => _TutorAssignmentsScreenState();
}

class _TutorAssignmentsScreenState extends State<TutorAssignmentsScreen> {
  final AssignmentService _assignmentService = AssignmentService();
  CourseModel? _selectedCourse;
  List<Assignment> _assignments = [];
  List<dynamic> _batches = [];
  bool _isLoadingAssignments = false;
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _loadCoursesAndData();
      _isInit = false;
    }
  }

  Future<void> _loadCoursesAndData() async {
    final courseProv = Provider.of<CourseProvider>(context, listen: false);
    setState(() => _isLoadingAssignments = true);

    try {
      // Load courses
      await courseProv.fetchMyCourses();
      
      // Load batches
      final batchRes = await BatchService.getAllBatches();
      if (batchRes['success'] == true) {
        _batches = batchRes['batches'] ?? [];
      }

      if (courseProv.myCourses.isNotEmpty) {
        _selectedCourse = courseProv.myCourses.first;
        await _fetchAssignments();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load courses: $e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      setState(() => _isLoadingAssignments = false);
    }
  }

  Future<void> _fetchAssignments() async {
    if (_selectedCourse == null) return;
    setState(() => _isLoadingAssignments = true);
    try {
      final list = await _assignmentService.fetchAssignmentsByCourse(_selectedCourse!.id);
      setState(() {
        _assignments = list;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load assignments: $e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      setState(() => _isLoadingAssignments = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseProv = Provider.of<CourseProvider>(context);

    return SapienceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SapienceHeader(
                title: 'Manage Assignments',
                actions: [
                  if (_selectedCourse != null)
                    Material(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () => _showCreateEditDialog(),
                        borderRadius: BorderRadius.circular(14),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: courseProv.isLoading && _selectedCourse == null
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.primary),
                      )
                    : courseProv.myCourses.isEmpty
                        ? _buildEmptyCoursesState()
                        : Column(
                  children: [
                    // Course Selector Horizontal List
                    Container(
                      height: 60,
                      color: Colors.white,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        itemCount: courseProv.myCourses.length,
                        itemBuilder: (ctx, index) {
                          final course = courseProv.myCourses[index];
                          final isSelected = _selectedCourse?.id == course.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(course.title),
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    _selectedCourse = course;
                                  });
                                  _fetchAssignments();
                                }
                              },
                              selectedColor: AppColors.primary.withValues(alpha: 0.15),
                              checkmarkColor: AppColors.primary,
                              labelStyle: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.primary : Colors.grey.shade700,
                              ),
                              backgroundColor: Colors.grey.shade100,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _isLoadingAssignments
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                          : _assignments.isEmpty
                              ? _buildEmptyAssignmentsState()
                              : RefreshIndicator(
                                  onRefresh: _fetchAssignments,
                                  color: AppColors.primary,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _assignments.length,
                                    itemBuilder: (ctx, i) {
                                      return _buildAssignmentCard(_assignments[i]);
                                    },
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCoursesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No Courses Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'You must be assigned to at least one course to manage assignments.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAssignmentsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No Assignments Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Create tasks, homework, and reports for this course.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showCreateEditDialog(),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Create Assignment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(Assignment assignment) {
    final hasDueDate = assignment.dueDate != null;
    final formattedDate = hasDueDate ? DateFormat('dd MMM yyyy, h:mm a').format(assignment.dueDate!) : 'No Due Date';
    final isDraft = assignment.status == 'draft';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppThemeDesign.borderRadiusMedium,
        boxShadow: const [AppThemeDesign.cardShadow],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: ClipRRect(
        borderRadius: AppThemeDesign.borderRadiusMedium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status bar at top
            Container(
              height: 4,
              color: isDraft ? Colors.orange : AppColors.primary,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDraft ? Colors.orange.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          assignment.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDraft ? Colors.orange.shade800 : Colors.blue.shade800,
                          ),
                        ),
                      ),
                      Text(
                        'Marks: ${assignment.totalMarks}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMain),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    assignment.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain),
                  ),
                  if (assignment.description != null && assignment.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      assignment.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text(
                        'Due: $formattedDate',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () => _navigateToSubmissions(assignment),
                        icon: const Icon(Icons.people_outline, size: 18),
                        label: const Text('Submissions'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(60, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                            onPressed: () => _showCreateEditDialog(assignment: assignment),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            onPressed: () => _confirmDelete(assignment),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSubmissions(Assignment assignment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TutorAssignmentSubmissionsScreen(
          assignment: assignment,
          assignmentService: _assignmentService,
        ),
      ),
    );
  }

  void _confirmDelete(Assignment assignment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: Text('Are you sure you want to delete "${assignment.title}"? This will also remove all student submissions for this assignment.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() => _isLoadingAssignments = true);
              try {
                final success = await _assignmentService.deleteAssignment(assignment.id);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Assignment deleted successfully'), behavior: SnackBarBehavior.floating),
                  );
                  _fetchAssignments();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete: $e'), behavior: SnackBarBehavior.floating),
                );
                setState(() => _isLoadingAssignments = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateEditDialog({Assignment? assignment}) {
    final isEdit = assignment != null;
    final titleCtrl = TextEditingController(text: assignment?.title ?? '');
    final descCtrl = TextEditingController(text: assignment?.description ?? '');
    final marksCtrl = TextEditingController(text: assignment?.totalMarks.toString() ?? '100');
    
    DateTime selectedDate = assignment?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    String? selectedBatchId = assignment?.batchId;
    String status = assignment?.status ?? 'published';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Edit Assignment' : 'Create Assignment',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Assignment Title *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Instructions / Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: marksCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Max Marks *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Status Switcher
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: status,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'published', child: Text('Published')),
                              DropdownMenuItem(value: 'draft', child: Text('Draft')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => status = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Batch Selector (Optional)
                    DropdownButtonFormField<String?>(
                      initialValue: selectedBatchId,
                      decoration: const InputDecoration(
                        labelText: 'Assign to Batch (Optional)',
                        border: OutlineInputBorder(),
                        hintText: 'All Batches',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Enrolled Students (Course-Wide)'),
                        ),
                        ..._batches.map((b) {
                          return DropdownMenuItem<String?>(
                            value: b['_id'],
                            child: Text(b['name'] ?? 'Batch'),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setDialogState(() => selectedBatchId = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    // Due Date Selector
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        );
                        if (pickedDate != null) {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(selectedDate),
                          );
                          if (pickedTime != null) {
                            setDialogState(() {
                              selectedDate = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Due Date: ${DateFormat('dd MMM yyyy, h:mm a').format(selectedDate)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const Icon(Icons.calendar_today, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final title = titleCtrl.text.trim();
                            final desc = descCtrl.text.trim();
                            final marksStr = marksCtrl.text.trim();

                            if (title.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a title'), behavior: SnackBarBehavior.floating),
                              );
                              return;
                            }

                            final marks = int.tryParse(marksStr) ?? 100;

                            Navigator.of(ctx).pop();
                            setState(() => _isLoadingAssignments = true);

                            try {
                              if (isEdit) {
                                await _assignmentService.updateAssignment(
                                  assignment.id,
                                  title: title,
                                  description: desc,
                                  dueDate: selectedDate,
                                  totalMarks: marks,
                                  status: status,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Assignment updated successfully'), behavior: SnackBarBehavior.floating),
                                );
                              } else {
                                await _assignmentService.createAssignment(
                                  courseId: _selectedCourse!.id,
                                  batchId: selectedBatchId,
                                  title: title,
                                  description: desc,
                                  dueDate: selectedDate,
                                  totalMarks: marks,
                                  status: status,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Assignment created successfully'), behavior: SnackBarBehavior.floating),
                                );
                              }
                              _fetchAssignments();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to save assignment: $e'), behavior: SnackBarBehavior.floating),
                              );
                              setState(() => _isLoadingAssignments = false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── SUBMISSIONS LIST SCREEN ───

class TutorAssignmentSubmissionsScreen extends StatefulWidget {
  final Assignment assignment;
  final AssignmentService assignmentService;

  const TutorAssignmentSubmissionsScreen({
    super.key,
    required this.assignment,
    required this.assignmentService,
  });

  @override
  State<TutorAssignmentSubmissionsScreen> createState() => _TutorAssignmentSubmissionsScreenState();
}

class _TutorAssignmentSubmissionsScreenState extends State<TutorAssignmentSubmissionsScreen> {
  List<Map<String, dynamic>> _submissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubmissions();
  }

  Future<void> _fetchSubmissions() async {
    setState(() => _isLoading = true);
    try {
      final list = await widget.assignmentService.getAssignmentSubmissions(widget.assignment.id);
      setState(() {
        _submissions = list;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load submissions: $e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.assignment.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _submissions.isEmpty
              ? _buildEmptySubmissionsState()
              : RefreshIndicator(
                  onRefresh: _fetchSubmissions,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _submissions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      return _buildSubmissionCard(_submissions[i]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptySubmissionsState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No Submissions Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              'When students submit their work, it will appear here for grading.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionCard(Map<String, dynamic> submission) {
    final student = submission['studentId'] ?? {};
    final studentName = student['name'] ?? 'Student';
    final studentEmail = student['email'] ?? '';
    final studentAvatar = student['avatar'] ?? student['profileImage'];
    
    final submittedAtStr = submission['submittedAt'];
    String dateLabel = '';
    if (submittedAtStr != null) {
      dateLabel = DateFormat('dd MMM yyyy, h:mm a').format(DateTime.parse(submittedAtStr).toLocal());
    }

    final status = submission['status'] ?? 'submitted';
    final isGraded = status == 'graded';
    final grade = submission['grade'];
    final feedback = submission['feedback'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppThemeDesign.borderRadiusMedium,
        boxShadow: const [AppThemeDesign.cardShadow],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundImage: studentAvatar != null ? NetworkImage(studentAvatar) : null,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: studentAvatar == null ? const Icon(Icons.person, color: AppColors.primary) : null,
        ),
        title: Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(studentEmail, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isGraded ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isGraded ? Colors.green.shade800 : Colors.orange.shade800,
                    ),
                  ),
                ),
                if (isGraded && grade != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Grade: $grade / ${widget.assignment.totalMarks}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1),
                const SizedBox(height: 12),
                const Text('Submitted Content:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                Text(
                  submission['content'] ?? 'No text content provided.',
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                if (submission['attachments'] != null && (submission['attachments'] as List).isNotEmpty) ...[
                  const Text('Attachments:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  ... (submission['attachments'] as List).map((att) {
                    final name = att['name'] ?? 'File';
                    final url = att['url']?.toString() ?? '';
                    return InkWell(
                      onTap: () async {
                        final resolved = ApiConfig.resolveMediaUrl(url);
                        if (resolved.isEmpty) return;
                        final uri = Uri.tryParse(resolved);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not open attachment URL')),
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.attachment, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: AppColors.primary, decoration: TextDecoration.underline),
                              ),
                            ),
                            const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.primary),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],
                if (feedback.toString().trim().isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEDFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tutor Feedback:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feedback.toString(),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ),
                ],
                Text(
                  'Submitted on: $dateLabel',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _buildGradingSection(submission),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGradingSection(Map<String, dynamic> submission) {
    final status = submission['status'] ?? 'submitted';
    final isGraded = status == 'graded';
    final gradeCtrl = TextEditingController(text: submission['grade']?.toString() ?? '');
    final feedbackCtrl = TextEditingController(text: submission['feedback'] ?? '');

    return StatefulBuilder(
      builder: (ctx, setStateGrading) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isGraded ? 'Update Feedback & Grade' : 'Grade Submission',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: gradeCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Grade (Max ${widget.assignment.totalMarks}) *',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: feedbackCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Feedback / Remarks',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () async {
                  final scoreStr = gradeCtrl.text.trim();
                  final feedback = feedbackCtrl.text.trim();

                  if (scoreStr.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a grade'), behavior: SnackBarBehavior.floating),
                    );
                    return;
                  }

                  final score = double.tryParse(scoreStr);
                  if (score == null || score < 0 || score > widget.assignment.totalMarks) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter a valid grade between 0 and ${widget.assignment.totalMarks}'), behavior: SnackBarBehavior.floating),
                    );
                    return;
                  }

                  try {
                    final success = await widget.assignmentService.gradeSubmission(
                      submission['_id'],
                      grade: score,
                      feedback: feedback,
                    );
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Submission graded successfully'), behavior: SnackBarBehavior.floating),
                      );
                      _fetchSubmissions();
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to grade: $e'), behavior: SnackBarBehavior.floating),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isGraded ? Colors.blue : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: Text(isGraded ? 'Update Grade' : 'Submit Grade'),
              ),
            ),
          ],
        );
      },
    );
  }
}
