import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/attendance_service.dart';
import '../../../utils/constants.dart';

class StudentBatchAttendanceScreen extends StatefulWidget {
  final String batchId;
  final String batchName;

  const StudentBatchAttendanceScreen({
    super.key,
    required this.batchId,
    required this.batchName,
  });

  @override
  State<StudentBatchAttendanceScreen> createState() => _StudentBatchAttendanceScreenState();
}

class _StudentBatchAttendanceScreenState extends State<StudentBatchAttendanceScreen> {
  List<dynamic> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isLoading = true);
    try {
      final res = await AttendanceService.getBatchAttendance(
        token: token,
        batchId: widget.batchId,
      );
      if (res['success'] == true) {
        setState(() {
          _records = res['records'] ?? [];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load attendance: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate stats
    final totalCount = _records.length;
    final presentCount = _records.where((r) => r['status'] == 'Present' || r['status'] == 'Late').length;
    final absentCount = _records.where((r) => r['status'] == 'Absent').length;
    final lateCount = _records.where((r) => r['status'] == 'Late').length;
    final excusedCount = _records.where((r) => r['status'] == 'Excused').length;
    final percentage = totalCount > 0 ? (presentCount / totalCount) * 100 : 0.0;

    Color progressColor = Colors.red;
    if (percentage >= 75) {
      progressColor = Colors.green;
    } else if (percentage >= 50) {
      progressColor = Colors.orange;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.batchName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _records.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_available_outlined, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No attendance logged yet by your tutor',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gauge & stats card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [AppThemeDesign.cardShadow],
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Row(
                          children: [
                            // Gauge
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 90,
                                  height: 90,
                                  child: CircularProgressIndicator(
                                    value: percentage / 100,
                                    strokeWidth: 8,
                                    backgroundColor: Colors.grey.shade100,
                                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${percentage.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: progressColor,
                                      ),
                                    ),
                                    const Text('Attendance', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                            // Stats description
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildStatRow('Total Days Marked', '$totalCount days'),
                                  const SizedBox(height: 6),
                                  _buildStatRow('Present Days', '$presentCount days', color: Colors.green),
                                  const SizedBox(height: 6),
                                  _buildStatRow('Absent Days', '$absentCount days', color: Colors.red),
                                  const SizedBox(height: 6),
                                  if (lateCount > 0)
                                    _buildStatRow('Late Days', '$lateCount days', color: Colors.orange),
                                  if (excusedCount > 0)
                                    _buildStatRow('Excused Days', '$excusedCount days', color: Colors.blue),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Day-by-Day Records',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),

                      // Day lists
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _records.length,
                        itemBuilder: (context, index) {
                          final r = _records[index];
                          final dateStr = r['date'];
                          final date = DateTime.parse(dateStr);
                          final status = r['status'] ?? 'N/A';
                          final remarks = r['remarks'] ?? '';

                          Color statusColor = Colors.grey;
                          if (status == 'Present') statusColor = Colors.green;
                          if (status == 'Absent') statusColor = Colors.red;
                          if (status == 'Late') statusColor = Colors.orange;
                          if (status == 'Excused') statusColor = Colors.blue;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade100),
                              boxShadow: const [AppThemeDesign.softShadow],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat('EEEE, dd MMMM yyyy').format(date),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      if (remarks.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Remark: $remarks',
                                          style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: statusColor.withOpacity(0.4)),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
