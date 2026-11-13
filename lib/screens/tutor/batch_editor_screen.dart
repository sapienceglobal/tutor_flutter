import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/course_provider.dart';
import '../../services/batch_service.dart';
import '../../services/enrollment_service.dart';
import '../../utils/constants.dart';

class BatchEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? batch; // If null, we are in "Create Batch" mode

  const BatchEditorScreen({super.key, this.batch});

  @override
  State<BatchEditorScreen> createState() => _BatchEditorScreenState();
}

class _BatchEditorScreenState extends State<BatchEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _capacityController;
  late TextEditingController _scheduleController;

  String? _selectedCourseId;
  String _selectedGrade = 'Class 10';
  DateTime? _startDate;
  DateTime? _endDate;

  List<dynamic> _availableStudents = [];
  List<String> _selectedStudentIds = [];
  bool _isLoadingStudents = false;

  final List<String> _grades = [
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
    'Class 11', 'Class 12', 'Intermediate', 'Undergraduate', 'Postgraduate', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.batch?['name'] ?? '');
    _capacityController = TextEditingController(text: (widget.batch?['capacity'] ?? 50).toString());
    _scheduleController = TextEditingController(text: widget.batch?['schedule'] ?? '');

    if (widget.batch != null && widget.batch!['courseId'] != null) {
      if (widget.batch!['courseId'] is Map) {
        _selectedCourseId = widget.batch!['courseId']['_id'];
      } else {
        _selectedCourseId = widget.batch!['courseId'];
      }
    }

    _selectedGrade = widget.batch?['grade'] ?? 'Class 10';

    if (widget.batch?['startDate'] != null) {
      _startDate = DateTime.tryParse(widget.batch!['startDate']);
    }
    if (widget.batch?['endDate'] != null) {
      _endDate = DateTime.tryParse(widget.batch!['endDate']);
    }

    if (widget.batch?['students'] != null && widget.batch?['students'] is List) {
      for (var s in widget.batch?['students']) {
        if (s is Map && s['_id'] != null) {
          _selectedStudentIds.add(s['_id']);
        } else if (s is String) {
          _selectedStudentIds.add(s);
        }
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      await courseProvider.fetchMyCourses();

      if (_selectedCourseId != null) {
        _loadCourseStudents(_selectedCourseId!);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _scheduleController.dispose();
    super.dispose();
  }

  Future<void> _loadCourseStudents(String courseId) async {
    setState(() {
      _isLoadingStudents = true;
      _availableStudents = [];
    });
    try {
      final res = await EnrollmentService.getCourseStudents(courseId);
      setState(() {
        _availableStudents = res;
      });
    } catch (e) {
      print('⚠️ Error loading students for course: $e');
    } finally {
      setState(() {
        _isLoadingStudents = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveBatch() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a course for this batch.')),
      );
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end dates.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final payload = {
      'name': _nameController.text.trim(),
      'courseId': _selectedCourseId,
      'grade': _selectedGrade,
      'capacity': int.tryParse(_capacityController.text.trim()) ?? 50,
      'schedule': _scheduleController.text.trim(),
      'startDate': _startDate!.toIso8601String(),
      'endDate': _endDate!.toIso8601String(),
      'students': _selectedStudentIds,
    };

    try {
      final bool isEdit = widget.batch != null;
      final Map<String, dynamic> res = isEdit
          ? await BatchService.updateBatch(widget.batch!['_id'], payload)
          : await BatchService.createBatch(payload);

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Batch updated successfully!' : 'Batch created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to save batch.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    final myCourses = courseProvider.myCourses;
    final bool isEdit = widget.batch != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Batch' : 'Create Batch',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else
            TextButton(
              onPressed: _saveBatch,
              child: const Text(
                'SAVE',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Form Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    // Batch Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Batch Name *',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter batch name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Course Picker
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCourseId,
                      decoration: InputDecoration(
                        labelText: 'Associated Course *',
                        prefixIcon: const Icon(Icons.school_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      hint: const Text('Select a course'),
                      items: myCourses.map((c) {
                        return DropdownMenuItem(value: c.id, child: Text(c.title));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCourseId = val;
                            _selectedStudentIds.clear();
                          });
                          _loadCourseStudents(val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Grade & Capacity
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedGrade,
                            decoration: InputDecoration(
                              labelText: 'Target Grade *',
                              prefixIcon: const Icon(Icons.grade_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: _grades.map((g) {
                              return DropdownMenuItem(value: g, child: Text(g));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedGrade = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _capacityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Capacity *',
                              prefixIcon: const Icon(Icons.people_outline),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (value) {
                              if (value == null || int.tryParse(value) == null) {
                                return 'Enter capacity';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Schedule & Dates Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Schedule & Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),

                    // Schedule description
                    TextFormField(
                      controller: _scheduleController,
                      decoration: InputDecoration(
                        labelText: 'Weekly Schedule (e.g. Mon, Wed 4pm)',
                        prefixIcon: const Icon(Icons.schedule_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date Selectors
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.calendar_today_outlined, size: 18),
                            label: Text(
                              _startDate == null ? 'Start Date *' : DateFormat('dd/MM/yyyy').format(_startDate!),
                            ),
                            onPressed: () => _selectDate(context, true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.calendar_today_outlined, size: 18),
                            label: Text(
                              _endDate == null ? 'End Date *' : DateFormat('dd/MM/yyyy').format(_endDate!),
                            ),
                            onPressed: () => _selectDate(context, false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Student Selection Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Enroll Students',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${_selectedStudentIds.length} Selected',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_selectedCourseId == null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Please select a course to view enrolled students.',
                            style: TextStyle(color: Colors.grey[500], fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else if (_isLoadingStudents)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (_availableStudents.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'No students enrolled in this course yet.',
                            style: TextStyle(color: Colors.grey[500], fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _availableStudents.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _availableStudents[index];
                          final studentInfo = item['studentId'] ?? {};
                          final String studentId = studentInfo['_id'] ?? '';
                          final String name = studentInfo['name'] ?? 'Unknown Student';
                          final String email = studentInfo['email'] ?? '';
                          final String avatar = studentInfo['profileImage'] ?? 'https://via.placeholder.com/150';
                          final bool isSelected = _selectedStudentIds.contains(studentId);

                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: NetworkImage(avatar),
                                  backgroundColor: Colors.grey[200],
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                      Text(email, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            value: isSelected,
                            activeColor: AppColors.primary,
                            onChanged: (bool? val) {
                              setState(() {
                                if (val == true) {
                                  _selectedStudentIds.add(studentId);
                                } else {
                                  _selectedStudentIds.remove(studentId);
                                }
                              });
                            },
                          );
                        },
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
}
