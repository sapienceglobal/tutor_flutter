import 'package:flutter/material.dart';
import '../services/batch_service.dart';
import '../services/enrollment_service.dart';
import '../utils/constants.dart';

class AudienceSelector extends StatefulWidget {
  final String initialScope;
  final List<String> initialBatchIds;
  final List<String> initialStudentIds;
  final String? courseId;
  final Function(String scope, List<String> batchIds, List<String> studentIds) onChanged;

  const AudienceSelector({
    super.key,
    required this.initialScope,
    required this.initialBatchIds,
    required this.initialStudentIds,
    this.courseId,
    required this.onChanged,
  });

  @override
  State<AudienceSelector> createState() => _AudienceSelectorState();
}

class _AudienceSelectorState extends State<AudienceSelector> {
  late String _scope;
  late List<String> _batchIds;
  late List<String> _studentIds;

  List<dynamic> _availableBatches = [];
  List<dynamic> _availableStudents = [];
  bool _isLoadingBatches = false;
  bool _isLoadingStudents = false;

  @override
  void initState() {
    super.initState();
    _scope = widget.initialScope;
    _batchIds = List.from(widget.initialBatchIds);
    _studentIds = List.from(widget.initialStudentIds);

    _loadBatches();
    if (widget.courseId != null) {
      _loadStudents(widget.courseId!);
    }
  }

  @override
  void didUpdateWidget(AudienceSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.courseId != oldWidget.courseId && widget.courseId != null) {
      _loadStudents(widget.courseId!);
    }
  }

  Future<void> _loadBatches() async {
    setState(() => _isLoadingBatches = true);
    try {
      final res = await BatchService.getAllBatches(courseId: widget.courseId);
      if (mounted) {
        setState(() {
          _availableBatches = res['batches'] ?? [];
          _isLoadingBatches = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching batches: $e');
      if (mounted) setState(() => _isLoadingBatches = false);
    }
  }

  Future<void> _loadStudents(String courseId) async {
    setState(() => _isLoadingStudents = true);
    try {
      final students = await EnrollmentService.getCourseStudents(courseId);
      if (mounted) {
        setState(() {
          _availableStudents = students;
          _isLoadingStudents = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching students: $e');
      if (mounted) setState(() => _isLoadingStudents = false);
    }
  }

  void _triggerChange() {
    widget.onChanged(_scope, _batchIds, _studentIds);
  }

  void _toggleBatch(String id) {
    setState(() {
      if (_batchIds.contains(id)) {
        _batchIds.remove(id);
      } else {
        _batchIds.add(id);
      }
    });
    _triggerChange();
  }

  void _toggleStudent(String id) {
    setState(() {
      if (_studentIds.contains(id)) {
        _studentIds.remove(id);
      } else {
        _studentIds.add(id);
      }
    });
    _triggerChange();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EFFD), // matching the outerCard shade (#EAE8FA / #F1EFFD)
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Audience Scope',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _scope,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              fillColor: const Color(0xFFE8E5FB), // Inner box color
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'global', child: Text('Global (All Learners)')),
              DropdownMenuItem(value: 'institute', child: Text('Institute Only')),
              DropdownMenuItem(value: 'batch', child: Text('Specific Batches')),
              DropdownMenuItem(value: 'private', child: Text('Private (Target Students)')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _scope = value;
                });
                _triggerChange();
              }
            },
          ),
          if (_scope == 'batch') ...[
            const SizedBox(height: 16),
            const Text(
              'Target Batches',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            _isLoadingBatches
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : _availableBatches.isEmpty
                    ? Text(
                        'No batches found. Create a batch first.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                      )
                    : Column(
                        children: _availableBatches.map((batch) {
                          final batchId = batch['_id'] as String;
                          final isSelected = _batchIds.contains(batchId);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : const Color(0xFFE8E5FB).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: CheckboxListTile(
                              dense: true,
                              title: Text(
                                batch['name'] ?? 'Batch',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              subtitle: batch['code'] != null
                                  ? Text(
                                      'Code: ${batch['code']}',
                                      style: const TextStyle(fontSize: 11),
                                    )
                                  : null,
                              value: isSelected,
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              onChanged: (_) => _toggleBatch(batchId),
                            ),
                          );
                        }).toList(),
                      ),
          ],
          if (_scope == 'private') ...[
            const SizedBox(height: 16),
            const Text(
              'Target Students',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            widget.courseId == null
                ? Text(
                    'Select a course first to assign students.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                  )
                : _isLoadingStudents
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : _availableStudents.isEmpty
                        ? Text(
                            'No enrolled students found in this course.',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                          )
                        : Column(
                            children: _availableStudents.map((enrollment) {
                              final student = enrollment['studentId'] ?? {};
                              final studentId = student['_id'] as String? ?? '';
                              if (studentId.isEmpty) return const SizedBox.shrink();
                              final isSelected = _studentIds.contains(studentId);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : const Color(0xFFE8E5FB).withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: CheckboxListTile(
                                  dense: true,
                                  title: Text(
                                    student['name'] ?? 'Student',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  subtitle: Text(
                                    student['email'] ?? '',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  secondary: CircleAvatar(
                                    radius: 16,
                                    backgroundImage: student['profileImage'] != null
                                        ? NetworkImage(student['profileImage'])
                                        : null,
                                    child: student['profileImage'] == null
                                        ? Text(
                                            (student['name'] ?? 'S')[0].toUpperCase(),
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          )
                                        : null,
                                  ),
                                  value: isSelected,
                                  activeColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  onChanged: (_) => _toggleStudent(studentId),
                                ),
                              );
                            }).toList(),
                          ),
          ],
        ],
      ),
    );
  }
}
