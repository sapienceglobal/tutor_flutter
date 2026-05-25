import 'package:flutter/material.dart';
import '../../../services/report_service.dart';

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
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
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
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(c['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Progress: ${c['averageProgress']}% • Score: ${c['averageExamScore']}%"),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
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
            borderRadius: BorderRadius.circular(12),
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
