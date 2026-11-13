import 'package:flutter/material.dart';
import 'package:my_app/widgets/create_exam_screen.dart';
import '../../../models/course_model.dart';
import '../../../models/exam_model.dart';
import '../../../services/exam_service.dart';
import '../../../utils/constants.dart';
import '../../../widgets/sapience_ui.dart';


class ManageExamsScreen extends StatefulWidget {
  final CourseModel course;

  const ManageExamsScreen({super.key, required this.course});

  @override
  State<ManageExamsScreen> createState() => _ManageExamsScreenState();
}

class _ManageExamsScreenState extends State<ManageExamsScreen> {
  List<ExamModel> _exams = [];
  bool _isLoading = false;
  String _filterStatus = 'all'; // all, draft, published, archived

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() => _isLoading = true);

    try {
      final result = await ExamService.getExamsByCourse(widget.course.id);

      if (result['success']) {
        setState(() => _exams = result['exams'] as List<ExamModel>);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<ExamModel> get _filteredExams {
    if (_filterStatus == 'all') return _exams;
    return _exams.where((exam) => exam.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    const statuses = ['all', 'draft', 'published', 'archived'];
    final currentTab = statuses.indexOf(_filterStatus).clamp(0, 3);

    return SapienceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SapienceHeader(
                title: 'Manage Exams',
                actions: [
                  Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CreateExamScreen(course: widget.course),
                          ),
                        );
                        if (result == true) _loadExams();
                      },
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: SapienceSegmentedTabs(
                  tabs: const ['All', 'Draft', 'Published', 'Archived'],
                  currentIndex: currentTab,
                  onChanged: (idx) =>
                      setState(() => _filterStatus = statuses[idx]),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredExams.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: _loadExams,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                              itemCount: _filteredExams.length,
                              itemBuilder: (context, index) {
                                return _buildExamCard(_filteredExams[index]);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _filterStatus == 'all'
                ? 'No exams created yet'
                : 'No ${_filterStatus} exams',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateExamScreen(course: widget.course),
                ),
              );
              if (result == true) _loadExams();
            },
            icon: const Icon(Icons.add),
            label: const Text('Create First Exam'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(ExamModel exam) {
    final statusColor = _getStatusColor(exam.status);
    final typeIcon = _getTypeIcon(exam.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppThemeDesign.borderRadiusMedium,
        boxShadow: const [AppThemeDesign.cardShadow],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: InkWell(
        borderRadius: AppThemeDesign.borderRadiusMedium,
        onTap: () => _viewExamDetails(exam),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(typeIcon, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                exam.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (exam.isAIGenerated)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.auto_awesome, size: 10, color: Colors.purple),
                                    SizedBox(width: 4),
                                    Text(
                                      'AI',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple,
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
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editExam(exam);
                      } else if (value == 'publish') {
                        _togglePublish(exam);
                      } else if (value == 'delete') {
                        _confirmDeleteExam(exam);
                      } else if (value == 'attempts') {
                        _viewAttempts(exam);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'publish',
                        child: Row(
                          children: [
                            Icon(
                              exam.isPublished ? Icons.unpublished : Icons.publish,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(exam.isPublished ? 'Unpublish' : 'Publish'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'attempts',
                        child: Row(
                          children: [
                            Icon(Icons.bar_chart, size: 20),
                            SizedBox(width: 8),
                            Text('View Attempts'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (exam.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  exam.description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(Icons.question_answer, '${exam.totalQuestions} Qs'),
                  const SizedBox(width: 12),
                  _buildInfoChip(Icons.timer, '${exam.duration} min'),
                  const SizedBox(width: 12),
                  _buildInfoChip(Icons.trending_up, '${exam.passingPercentage}%'),
                  const Spacer(),
                  if (exam.attemptCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${exam.attemptCount} attempts',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'published':
        return Colors.green;
      case 'draft':
        return Colors.orange;
      case 'archived':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'midterm':
        return Icons.description;
      case 'final':
        return Icons.assignment_turned_in;
      case 'quiz':
        return Icons.quiz;
      case 'practice':
        return Icons.school;
      default:
        return Icons.assignment;
    }
  }

  void _viewExamDetails(ExamModel exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppThemeDesign.borderRadiusMedium),
        title: Text(exam.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Type', exam.type.toUpperCase()),
              _buildDetailRow('Questions', '${exam.totalQuestions}'),
              _buildDetailRow('Duration', '${exam.duration} minutes'),
              _buildDetailRow('Total Marks', '${exam.totalMarks}'),
              _buildDetailRow('Passing Marks', '${exam.passingMarks} (${exam.passingPercentage}%)'),
              _buildDetailRow('Status', exam.status.toUpperCase()),
              _buildDetailRow('Attempts', '${exam.attemptCount}'),
              if (exam.attemptCount > 0)
                _buildDetailRow('Average Score', exam.averageScore.toStringAsFixed(1)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editExam(exam);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _editExam(ExamModel exam) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateExamScreen(
          course: widget.course,
          existingExam: exam,
        ),
      ),
    );
    if (result == true) _loadExams();
  }

  Future<void> _togglePublish(ExamModel exam) async {
    try {
      final response = await ExamService.updateExam(
        id: exam.id,
        updates: {
          'isPublished': !exam.isPublished,
          'status': exam.isPublished ? 'draft' : 'published',
        },
      );

      if (response['success'] && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(exam.isPublished ? 'Exam unpublished' : 'Exam published!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadExams();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDeleteExam(ExamModel exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppThemeDesign.borderRadiusMedium),
        title: const Text('Delete Exam'),
        content: Text('Delete "${exam.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final response = await ExamService.deleteExam(exam.id);
        if (response['success'] && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exam deleted!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadExams();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _viewAttempts(ExamModel exam) {
    // Navigate to attempts screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('View attempts feature coming soon')),
    );
  }
}