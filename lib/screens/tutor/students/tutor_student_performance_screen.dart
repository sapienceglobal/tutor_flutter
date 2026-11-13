import 'package:flutter/material.dart';
import '../../../services/tutor_dashboard_service.dart';
import '../../../utils/constants.dart';

class TutorStudentPerformanceScreen extends StatefulWidget {
  const TutorStudentPerformanceScreen({super.key});

  @override
  State<TutorStudentPerformanceScreen> createState() => _TutorStudentPerformanceScreenState();
}

class _TutorStudentPerformanceScreenState extends State<TutorStudentPerformanceScreen> {
  bool _isLoading = true;
  List<dynamic> _students = [];
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _report;

  String _searchQuery = '';
  String _batchFilter = 'all';
  String _courseFilter = 'all';
  String _sortBy = 'score'; // score, progress, name

  List<String> _batches = ['all'];
  List<String> _courses = ['all'];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final res = await DashboardService.getStudentPerformanceReport();
      if (res['success'] == true && mounted) {
        final List studentsList = res['students'] ?? [];
        
        // Extract unique batches and courses for filtering
        final tempBatches = <String>{'all'};
        final tempCourses = <String>{'all'};
        for (final s in studentsList) {
          if (s['batch'] != null) tempBatches.add(s['batch'].toString());
          if (s['courses'] != null && s['courses'] is List) {
            for (final c in s['courses']) {
              tempCourses.add(c.toString());
            }
          }
        }

        setState(() {
          _students = studentsList;
          _summary = res['summary'];
          _report = res['report'];
          _batches = tempBatches.toList();
          _courses = tempCourses.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load performance report: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Load failed: $e')),
        );
      }
    }
  }

  Map<String, dynamic> _getGrade(double score) {
    if (score >= 90) return {'letter': 'A', 'color': Colors.green};
    if (score >= 70) return {'letter': 'B', 'color': Colors.blue};
    if (score >= 50) return {'letter': 'C', 'color': Colors.orange};
    return {'letter': 'F', 'color': Colors.red};
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _students.where((s) {
      final name = (s['name'] ?? '').toString().toLowerCase();
      final studentId = (s['studentId'] ?? '').toString().toLowerCase();
      final matchesSearch = name.contains(_searchQuery.toLowerCase()) || studentId.contains(_searchQuery.toLowerCase());
      final matchesBatch = _batchFilter == 'all' || s['batch']?.toString() == _batchFilter;
      
      bool matchesCourse = _courseFilter == 'all';
      if (_courseFilter != 'all' && s['courses'] != null && s['courses'] is List) {
        matchesCourse = (s['courses'] as List).map((c) => c.toString()).contains(_courseFilter);
      }

      return matchesSearch && matchesBatch && matchesCourse;
    }).toList();

    // Sorting
    filtered.sort((a, b) {
      final indicatorsA = a['indicators'] ?? {};
      final indicatorsB = b['indicators'] ?? {};
      if (_sortBy == 'score') {
        final double scoreA = (indicatorsA['examAverage'] ?? 0).toDouble();
        final double scoreB = (indicatorsB['examAverage'] ?? 0).toDouble();
        return scoreB.compareTo(scoreA);
      } else if (_sortBy == 'progress') {
        final double progA = (indicatorsA['progress'] ?? 0).toDouble();
        final double progB = (indicatorsB['progress'] ?? 0).toDouble();
        return progB.compareTo(progA);
      } else {
        final String nameA = (a['name'] ?? '').toString();
        final String nameB = (b['name'] ?? '').toString();
        return nameA.compareTo(nameB);
      }
    });

    final int totalCount = _summary?['totalStudents'] ?? _students.length;
    final double classAvg = (_summary?['classAverage'] ?? 72.5).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Student Performance', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // --- Top Statistics row ---
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Class Average',
                          value: '${classAvg.toStringAsFixed(1)}%',
                          subtitle: 'Exam mean score',
                          color: AppColors.primary,
                          icon: Icons.star_purple500_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Enrolled List',
                          value: '$totalCount',
                          subtitle: 'Active profiles',
                          color: Colors.green,
                          icon: Icons.people_outline,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- Filters Row ---
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _batchFilter,
                                  isExpanded: true,
                                  style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
                                  items: _batches
                                      .map((b) => DropdownMenuItem(
                                            value: b,
                                            child: Text(b == 'all' ? 'All Batches' : b),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setState(() => _batchFilter = v!),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _courseFilter,
                                  isExpanded: true,
                                  style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
                                  items: _courses
                                      .map((c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(c == 'all' ? 'All Courses' : c, overflow: TextOverflow.ellipsis),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setState(() => _courseFilter = v!),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Sort By: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(width: 8),
                          _buildSortChip('score', 'Exam Score'),
                          const SizedBox(width: 6),
                          _buildSortChip('progress', 'Progress'),
                          const SizedBox(width: 6),
                          _buildSortChip('name', 'Name'),
                        ],
                      ),
                    ],
                  ),
                ),

                // --- Search Bar ---
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search students...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),

                // --- Student list ---
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                'No student records found',
                                style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final student = filtered[index];
                            final name = student['name'] ?? 'Student';
                            final indicators = student['indicators'] ?? {};
                            final double score = (indicators['examAverage'] ?? 0).toDouble();
                            final double progress = (indicators['progress'] ?? 0).toDouble();
                            final gradeMeta = _getGrade(score);

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.primary.withOpacity(0.08),
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                'Avg Exam: ${score.toStringAsFixed(1)}%',
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Progress: ${progress.toStringAsFixed(0)}%',
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (gradeMeta['color'] as Color).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        gradeMeta['letter'] as String,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: gradeMeta['color'] as Color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String value, String label) {
    final bool isSelected = _sortBy == value;
    return InkWell(
      onTap: () => setState(() => _sortBy = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary.withOpacity(0.3) : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
