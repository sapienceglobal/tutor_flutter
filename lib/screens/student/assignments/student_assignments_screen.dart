import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/assignment_model.dart';
import '../../../services/assignment_service.dart';
import '../../../widgets/shimmer_loader.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_retry.dart';
import '../../../utils/page_transitions.dart';
import 'assignment_details_screen.dart';

class StudentAssignmentsScreen extends StatefulWidget {
  const StudentAssignmentsScreen({Key? key}) : super(key: key);

  @override
  State<StudentAssignmentsScreen> createState() => _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen> with SingleTickerProviderStateMixin {
  final _assignmentService = AssignmentService();
  late TabController _tabController;
  
  List<Assignment> _allAssignments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final assignments = await _assignmentService.fetchAssignments();
      setState(() {
        _allAssignments = assignments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Assignments'),
        ),
        body: const ShimmerListView(itemCount: 5),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Assignments'),
        ),
        body: ErrorRetryWidget(
          message: _errorMessage!,
          onRetry: _loadAssignments,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Submitted'),
            Tab(text: 'Graded'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAssignmentList(_allAssignments),
          _buildAssignmentList(_allAssignments.filterByStatus('pending')),
          _buildAssignmentList(_allAssignments.filterByStatus('submitted')),
          _buildAssignmentList(_allAssignments.filterByStatus('graded')),
        ],
      ),
    );
  }

  Widget _buildAssignmentList(List<Assignment> assignments) {
    if (assignments.isEmpty) {
      return const EmptyAssignmentsState();
    }

    return RefreshIndicator(
      onRefresh: _loadAssignments,
      child: ListView.builder(
        itemCount: assignments.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final a = assignments[index];
          final status = a.mySubmission?.status ?? 'pending';
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(a.courseTitle ?? 'Course', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.blue[300]),
                      const SizedBox(width: 4),
                      Text(
                        a.dueDate != null ? 'Due: ${DateFormat('MMM d').format(a.dueDate!)}' : 'No Due Date',
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.stars, size: 12, color: Colors.orange[300]),
                      const SizedBox(width: 4),
                      Text('${a.totalMarks} pts', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _getStatusBadge(status),
                  if (status == 'graded')
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text('${a.mySubmission?.grade}/${a.totalMarks}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                ],
              ),
              onTap: () async {
                final result = await Navigator.of(context).pushSlideUp(
                  AssignmentDetailsScreen(assignmentId: a.id),
                );
                if (result == true) _loadAssignments();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _getStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'submitted') color = Colors.orange;
    if (status == 'graded') color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

extension AssignmentFilter on List<Assignment> {
  List<Assignment> filterByStatus(String status) {
    if (status == 'pending') {
      return where((a) => a.mySubmission == null).toList();
    }
    return where((a) => a.mySubmission?.status == status).toList();
  }
}
