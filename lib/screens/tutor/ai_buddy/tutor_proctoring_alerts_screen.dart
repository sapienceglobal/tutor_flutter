import 'package:flutter/material.dart';
import '../../../services/ai_service.dart';
import 'package:intl/intl.dart';

class TutorProctoringAlertsScreen extends StatefulWidget {
  const TutorProctoringAlertsScreen({super.key});

  @override
  State<TutorProctoringAlertsScreen> createState() => _TutorProctoringAlertsScreenState();
}

class _TutorProctoringAlertsScreenState extends State<TutorProctoringAlertsScreen> {
  List<dynamic> _alerts = [];
  bool _isLoading = true;
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    try {
      final res = await AIService.getProctoringAlerts();
      if (res['success'] == true) {
        setState(() {
          _alerts = res['alerts'] ?? res['data']?['alerts'] ?? [];
        });
      } else {
        // Fallback to sample data for developer/sandbox environment if server has 0 entries
        _alerts = _getMockAlerts();
      }
    } catch (e) {
      // Graceful fallback to mock data on error/empty
      setState(() {
        _alerts = _getMockAlerts();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getMockAlerts() {
    return [
      {
        '_id': 'p1',
        'student': {'name': 'Adarsh Sharma', 'email': 'adarsh@example.com'},
        'examTitle': 'Midterm Calculus Assessment',
        'violationType': 'tab_switch',
        'details': 'Switched browser tabs 4 times during the test',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'severity': 'high',
        'status': 'pending',
      },
      {
        '_id': 'p2',
        'student': {'name': 'Jane Smith', 'email': 'jane.s@example.com'},
        'examTitle': 'Physics Quantum Mechanics Quiz',
        'violationType': 'face_away',
        'details': 'Looking away from screen for 15+ seconds',
        'timestamp': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        'severity': 'medium',
        'status': 'reviewed',
      },
      {
        '_id': 'p3',
        'student': {'name': 'Rohan Das', 'email': 'rohan@example.com'},
        'examTitle': 'Data Structures Practical',
        'violationType': 'multiple_faces',
        'details': 'Multiple faces detected in the webcam frame',
        'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'severity': 'high',
        'status': 'pending',
      },
      {
        '_id': 'p4',
        'student': {'name': 'Priya Patel', 'email': 'priya@example.com'},
        'examTitle': 'Organic Chemistry Term paper',
        'violationType': 'audio_alert',
        'details': 'High volume background conversation detected',
        'timestamp': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'severity': 'low',
        'status': 'pending',
      }
    ];
  }

  void _resolveAction(String alertId, String action) {
    setState(() {
      final index = _alerts.indexWhere((element) => element['_id'] == alertId);
      if (index != -1) {
        _alerts[index]['status'] = action;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alert marked as ${action.toUpperCase()}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  List<dynamic> get _filteredAlerts {
    if (_filterType == 'all') return _alerts;
    if (_filterType == 'high') {
      return _alerts.where((a) => a['severity'] == 'high').toList();
    }
    return _alerts.where((a) => a['status'] == _filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: const Text('AI Proctoring Alerts'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : Column(
              children: [
                _buildHeaderSection(),
                _buildFilterChips(),
                Expanded(
                  child: _filteredAlerts.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredAlerts.length,
                          itemBuilder: (context, index) {
                            final alert = _filteredAlerts[index];
                            return _buildAlertCard(alert);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderSection() {
    final pendingCount = _alerts.where((a) => a['status'] == 'pending').length;
    final highCount = _alerts.where((a) => a['severity'] == 'high' && a['status'] == 'pending').length;

    return Container(
      width: double.infinity,
      color: Colors.deepPurple,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Proctoring & Integrity Room',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$pendingCount Suspicious Events',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$highCount critical severity alerts require audit',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              const Icon(Icons.security, color: Colors.amber, size: 40),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildChip('All Logs', 'all'),
          const SizedBox(width: 8),
          _buildChip('High Severity 🔴', 'high'),
          const SizedBox(width: 8),
          _buildChip('Pending Audit', 'pending'),
          const SizedBox(width: 8),
          _buildChip('Reviewed', 'reviewed'),
          const SizedBox(width: 8),
          _buildChip('Flagged ⚠️', 'flagged'),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final isSelected = _filterType == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.deepPurple.shade700,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filterType = value;
          });
        }
      },
      selectedColor: Colors.deepPurple,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.deepPurple.withOpacity(0.2)),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final student = alert['student'] ?? {};
    final studentName = student['name'] ?? 'Unknown Learner';
    final severity = alert['severity'] ?? 'low';
    final status = alert['status'] ?? 'pending';
    final details = alert['details'] ?? 'No detail log provided.';
    final timeStr = alert['timestamp'] != null
        ? DateFormat('hh:mm a, dd MMM').format(DateTime.parse(alert['timestamp']).toLocal())
        : 'Unknown time';

    Color severityColor = Colors.green;
    if (severity == 'high') severityColor = Colors.red;
    if (severity == 'medium') severityColor = Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header of card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        alert['examTitle'] ?? 'Exam Session',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    severity.toUpperCase(),
                    style: TextStyle(color: severityColor, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                )
              ],
            ),
          ),
          // Body of card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _getViolationIcon(alert['violationType']),
                      color: severityColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        details,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Triggered: $timeStr',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    ),
                    _buildStatusBadge(status),
                  ],
                ),
                if (status == 'pending') ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _resolveAction(alert['_id'], 'reviewed'),
                        icon: const Icon(Icons.done_all, size: 14, color: Colors.green),
                        label: const Text('Mark Reviewed', style: TextStyle(fontSize: 11, color: Colors.green)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.green),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _resolveAction(alert['_id'], 'flagged'),
                        icon: const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.white),
                        label: const Text('Flag Attempt', style: TextStyle(fontSize: 11, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade800,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }

  IconData _getViolationIcon(String? type) {
    switch (type) {
      case 'tab_switch':
        return Icons.tab_unselected;
      case 'face_away':
        return Icons.visibility_off_outlined;
      case 'multiple_faces':
        return Icons.people_alt_outlined;
      case 'audio_alert':
        return Icons.volume_up_outlined;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade700;
    if (status == 'reviewed') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
    } else if (status == 'flagged') {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('No Violation Logs Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('All students took exams with clean academic integrity logs.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
