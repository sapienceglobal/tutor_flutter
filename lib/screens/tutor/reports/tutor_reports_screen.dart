import 'package:flutter/material.dart';
import '../../../services/report_service.dart';
import '../../../utils/constants.dart';

class TutorReportsScreen extends StatefulWidget {
  const TutorReportsScreen({Key? key}) : super(key: key);

  @override
  State<TutorReportsScreen> createState() => _TutorReportsScreenState();
}

class _TutorReportsScreenState extends State<TutorReportsScreen> {
  final _reportService = ReportService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _reportService.getTutorReportsSummary();
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports Hub')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatCards(),
                  const SizedBox(height: 24),
                  const Text('Course Health', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildCourseReports(),
                  const SizedBox(height: 24),
                  const Text('At-Risk Students', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 12),
                  _buildAtRiskList(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCards() {
    final o = _data?['report']?['overview'] ?? {};
    final s = _data?['report']?['students'] ?? {};

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildReportBox("Total Students", "${o['totalStudents'] ?? 0}", Colors.blue),
        _buildReportBox("At-Risk", "${s['atRiskCount'] ?? 0}", Colors.red),
        _buildReportBox("Avg Progress", "${_data?['report']?['courses']?['averageProgress'] ?? 0}%", Colors.green),
        _buildReportBox("Pass Rate", "${_data?['report']?['exams']?['passRate'] ?? 0}%", Colors.orange),
      ],
    );
  }

  Widget _buildReportBox(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppThemeDesign.borderRadiusMedium,
        boxShadow: const [AppThemeDesign.cardShadow],
        border: Border.all(color: color.withOpacity(0.12), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          const Spacer(),
          Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCourseReports() {
    final List courses = _data?['courseReports'] ?? [];
    if (courses.isEmpty) return const Center(child: Text("No course reports yet"));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final c = courses[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppThemeDesign.borderRadiusMedium,
            boxShadow: const [AppThemeDesign.cardShadow],
            border: Border.all(color: Colors.grey.shade100, width: 1),
          ),
          child: ListTile(
            title: Text(c['title'] ?? 'Untitled Course', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Progress: ${c['averageProgress']}% • Score: ${c['averageExamScore']}%"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCourseReportDetails(c),
          ),
        );
      },
    );
  }

  void _showCourseReportDetails(Map<String, dynamic> c) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    c['title'] ?? 'Course Report',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBadge("Students", "${c['students'] ?? 0}", Icons.people_outline_rounded, Colors.indigo),
                _buildStatBadge("Assignments", "${c['assignmentCount'] ?? 0}", Icons.assignment_outlined, Colors.orange),
                _buildStatBadge("Exams", "${c['examCount'] ?? 0}", Icons.assessment_outlined, Colors.teal),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Performance Metrics',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 14),
            _buildLinearMetricRow("Average Progress", c['averageProgress'] ?? 0, Colors.blue),
            const SizedBox(height: 12),
            _buildLinearMetricRow("Average Exam Score", c['averageExamScore'] ?? 0, Colors.green),
            const SizedBox(height: 12),
            _buildLinearMetricRow("Assignment Submission Rate", c['assignmentSubmissionRate'] ?? 0, Colors.purple),
            const SizedBox(height: 12),
            _buildLinearMetricRow("Class Attendance Rate", c['attendanceRate'] ?? 0, Colors.teal),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildLinearMetricRow(String label, dynamic percentVal, Color color) {
    final double value = (percentVal is num) ? percentVal.toDouble() : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            Text('${value.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value / 100.0,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildAtRiskList() {
    final List students = _data?['atRiskStudents'] ?? [];
    if (students.isEmpty) return const Center(child: Text("All students are performing well!"));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final s = students[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.05),
            borderRadius: AppThemeDesign.borderRadiusMedium,
            border: Border.all(color: Colors.red.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const CircleAvatar(backgroundColor: Colors.red, radius: 4),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(s['email'], style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    const SizedBox(height: 4),
                    Text((s['reasons'] as List).join(' • '), style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Column(
                children: [
                  const Text("Score", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text("${s['riskScore']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
