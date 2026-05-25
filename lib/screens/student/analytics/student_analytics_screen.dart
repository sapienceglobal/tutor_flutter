import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/report_service.dart';
import '../../../widgets/performance_chart.dart';
import '../../../models/dashboard_stats_model.dart';

class StudentAnalyticsScreen extends StatefulWidget {
  const StudentAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<StudentAnalyticsScreen> createState() => _StudentAnalyticsScreenState();
}

class _StudentAnalyticsScreenState extends State<StudentAnalyticsScreen> {
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
      final data = await _reportService.getStudentSummary();
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
      appBar: AppBar(title: const Text('Reports & Analytics')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryGrid(),
                  const SizedBox(height: 24),
                  const Text('Performance Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildTrendChart(),
                  const SizedBox(height: 24),
                  const Text('Score Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildScorePieChart(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryGrid() {
    final s = _data?['summary'] ?? {};
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatBox("Avg Score", "${s['avgScore']}%", Colors.blue),
        _buildStatBox("Passed", "${s['passedExams']}", Colors.green),
        _buildStatBox("Total Exams", "${s['totalExams']}", Colors.orange),
        _buildStatBox("Courses", "${s['totalCourses']}", Colors.purple),
      ],
    );
  }

  Widget _buildStatBox(String label, String val, Color color) {
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

  Widget _buildTrendChart() {
    // Transforming data for the PerformanceChart widget
    final List attempts = _data?['examAttempts'] ?? [];
    if (attempts.isEmpty) return const Center(child: Text("No exam data yet"));

    // Grouping by date/month for trend (simplified for mobile)
    final trendData = attempts.take(5).map((a) {
      return ChartDataPoint(label: a['examTitle'].toString().split(' ').first, value: (a['pct'] ?? 0).toDouble());
    }).toList().reversed.toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: PerformanceChart(data: trendData),
    );
  }

  Widget _buildScorePieChart() {
    final List attempts = _data?['examAttempts'] ?? [];
    if (attempts.isEmpty) return const SizedBox();

    int excellent = attempts.where((a) => (a['pct'] ?? 0) >= 90).length;
    int good = attempts.where((a) => (a['pct'] ?? 0) >= 75 && (a['pct'] ?? 0) < 90).length;
    int average = attempts.where((a) => (a['pct'] ?? 0) < 75).length;

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(value: excellent.toDouble(), color: Colors.green, title: '90%+', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            PieChartSectionData(value: good.toDouble(), color: Colors.blue, title: '75-90%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            PieChartSectionData(value: average.toDouble(), color: Colors.orange, title: '< 75%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
          centerSpaceRadius: 40,
        ),
      ),
    );
  }
}
