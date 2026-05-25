import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../../models/assignment_model.dart';
import '../../../services/assignment_service.dart';
import '../../../services/cloudinary_service.dart';
import 'dart:io';

class AssignmentDetailsScreen extends StatefulWidget {
  final String assignmentId;

  const AssignmentDetailsScreen({Key? key, required this.assignmentId}) : super(key: key);

  @override
  State<AssignmentDetailsScreen> createState() => _AssignmentDetailsScreenState();
}

class _AssignmentDetailsScreenState extends State<AssignmentDetailsScreen> {
  final _assignmentService = AssignmentService();
  final _contentController = TextEditingController();
  
  Assignment? _assignment;
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<File> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      final a = await _assignmentService.fetchAssignmentDetails(widget.assignmentId);
      setState(() {
        _assignment = a;
        _isLoading = false;
        if (a.mySubmission?.content != null) {
          _contentController.text = a.mySubmission!.content!;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        _selectedFiles.addAll(result.paths.map((path) => File(path!)).toList());
      });
    }
  }

  void _submit() async {
    if (_assignment == null) return;
    setState(() => _isSubmitting = true);

    try {
      List<Map<String, dynamic>> uploadedAttachments = [];
      
      // Upload new files to Cloudinary first
      for (var file in _selectedFiles) {
        final uploadRes = await CloudinaryService.uploadFile(file);
        if (uploadRes != null) {
          uploadedAttachments.add({
            'name': file.path.split('/').last,
            'url': uploadRes['url'],
            'type': 'file',
          });
        }
      }

      // Add existing attachments if updating
      if (_assignment!.mySubmission != null) {
        uploadedAttachments.addAll(_assignment!.mySubmission!.attachments.cast<Map<String, dynamic>>());
      }

      final success = await _assignmentService.submitAssignment(
        widget.assignmentId,
        content: _contentController.text,
        attachments: uploadedAttachments,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assignment Submitted Successfully!')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_assignment == null) return const Scaffold(body: Center(child: Text('Assignment not found')));

    final sub = _assignment!.mySubmission;
    final isGraded = sub?.status == 'graded';

    return Scaffold(
      appBar: AppBar(title: Text(_assignment!.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 20),
            const Text('Instructions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_assignment!.description ?? 'No instructions provided.', style: const TextStyle(height: 1.5)),
            const SizedBox(height: 24),
            
            if (isGraded) _buildFeedbackSection(),
            
            const Divider(height: 48),
            
            const Text('Your Submission', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (!isGraded) ...[
              TextField(
                controller: _contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Enter your response here...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              _buildFilePicker(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Work'),
                ),
              ),
            ] else ...[
               Text(sub?.content ?? 'No text response provided.', style: const TextStyle(fontStyle: FontStyle.italic)),
               const SizedBox(height: 16),
               if (sub?.attachments.isNotEmpty == true) ...[
                  const Text('Attachments:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...sub!.attachments.map((f) => ListTile(
                    leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
                    title: Text(f['name'] ?? 'File'),
                    dense: true,
                  )).toList(),
               ]
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    final sub = _assignment!.mySubmission;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _assignment!.dueDate != null ? 'Due: ${DateFormat('EEE, MMM d, yyyy').format(_assignment!.dueDate!)}' : 'No Due Date',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Total Points: ${_assignment!.totalMarks}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: sub == null ? Colors.red[50] : Colors.green[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sub == null ? Colors.red : Colors.green),
            ),
            child: Text(
              sub == null ? 'PENDING' : sub.status.toUpperCase(),
              style: TextStyle(color: sub == null ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection() {
    final sub = _assignment!.mySubmission;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green[200]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grade & Feedback', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              Text('${sub?.grade}/${_assignment!.totalMarks}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 8),
          Text(sub?.feedback ?? 'No feedback provided.', style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildFilePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _pickFiles,
          icon: const Icon(Icons.add_link),
          label: const Text('Add Attachments'),
        ),
        const SizedBox(height: 8),
        ..._selectedFiles.map((f) => ListTile(
          leading: const Icon(Icons.insert_drive_file),
          title: Text(f.path.split('/').last),
          trailing: IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _selectedFiles.remove(f))),
          dense: true,
        )).toList(),
      ],
    );
  }
}
