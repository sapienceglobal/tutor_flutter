import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/live_class_service.dart';
import '../../../services/course_service.dart';
import '../../../services/batch_service.dart';
import '../../../models/course_model.dart';

class ScheduleLiveClassScreen extends StatefulWidget {
  const ScheduleLiveClassScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleLiveClassScreen> createState() => _ScheduleLiveClassScreenState();
}

class _ScheduleLiveClassScreenState extends State<ScheduleLiveClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _liveClassService = LiveClassService();

  String _title = '';
  String _description = '';
  String? _selectedCourseId;
  String? _selectedBatchId;
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  int _duration = 60;
  bool _isLoading = false;
  List<CourseModel> _courses = [];
  List<dynamic> _batches = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final courses = await CourseService.getMyCourses();
      final batchRes = await BatchService.getAllBatches();
      setState(() {
        _courses = courses;
        _batches = batchRes['batches'] ?? [];
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      final success = await _liveClassService.createLiveClass({
        'title': _title,
        'description': _description,
        'courseId': _selectedCourseId,
        'batchId': _selectedBatchId,
        'dateTime': _selectedDateTime.toIso8601String(),
        'duration': _duration,
        'platform': 'jitsi',
        'autoCreate': true,
      });

      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Live Class')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                      validator: (val) => val!.isEmpty ? 'Enter title' : null,
                      onSaved: (val) => _title = val!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                      maxLines: 3,
                      onSaved: (val) => _description = val!,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Course', border: OutlineInputBorder()),
                      initialValue: _selectedCourseId,
                      items: _courses.map((c) => DropdownMenuItem<String>(value: c.id, child: Text(c.title))).toList(),
                      onChanged: (val) => setState(() => _selectedCourseId = val),
                      validator: (val) => val == null ? 'Select course' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Batch (Optional)', border: OutlineInputBorder()),
                      initialValue: _selectedBatchId,
                      items: _batches.map((b) => DropdownMenuItem<String>(value: b['_id'] as String, child: Text(b['name'] as String))).toList(),
                      onChanged: (val) => setState(() => _selectedBatchId = val),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Date & Time'),
                      subtitle: Text(DateFormat('MMM d, yyyy - hh:mm a').format(_selectedDateTime)),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: _pickDateTime,
                      shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: '60',
                      decoration: const InputDecoration(labelText: 'Duration (minutes)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onSaved: (val) => _duration = int.parse(val!),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                        child: const Text('Schedule Now'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
