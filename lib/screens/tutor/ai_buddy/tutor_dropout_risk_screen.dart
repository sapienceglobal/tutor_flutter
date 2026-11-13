import 'package:flutter/material.dart';
import '../../../services/ai_service.dart';
import '../../common/chat/chat_detail_screen.dart';

class TutorDropoutRiskScreen extends StatefulWidget {
  const TutorDropoutRiskScreen({super.key});

  @override
  State<TutorDropoutRiskScreen> createState() => _TutorDropoutRiskScreenState();
}

class _TutorDropoutRiskScreenState extends State<TutorDropoutRiskScreen> {
  List<dynamic> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDropoutRisk();
  }

  Future<void> _loadDropoutRisk() async {
    setState(() => _isLoading = true);
    try {
      final res = await AIService.getDropoutRisk();
      if (res['success'] == true) {
        setState(() {
          _students = res['students'] ?? res['data']?['students'] ?? [];
        });
      } else {
        _students = _getMockDropoutData();
      }
    } catch (e) {
      setState(() {
        _students = _getMockDropoutData();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getMockDropoutData() {
    return [
      {
        'studentId': 's1',
        'name': 'Rohan Das',
        'email': 'rohan@example.com',
        'riskScore': 87, // Percentage
        'status': 'High Risk',
        'profileImage': null,
        'reasons': [
          'Unsubmitted work for 2 consecutive assignments',
          'Exam failure in Calculus Assessment (Score: 28%)',
          'Zero video lessons watched in the last 14 days',
        ],
        'recommendation': 'Send a friendly check-in message and assign a remedial practice set.',
      },
      {
        'studentId': 's2',
        'name': 'Siddharth Roy',
        'email': 'sid@example.com',
        'riskScore': 68,
        'status': 'Medium Risk',
        'profileImage': null,
        'reasons': [
          'Attendance dropped to 52% (Threshold: 75%)',
          'Low engagement in practice quizzes',
        ],
        'recommendation': 'Draft batch shifting alert or request one-on-one session.',
      },
      {
        'studentId': 's3',
        'name': 'Anjali Gupta',
        'email': 'anjali@example.com',
        'riskScore': 42,
        'status': 'Low Risk',
        'profileImage': null,
        'reasons': [
          'Missed the latest live class session',
        ],
        'recommendation': 'No critical action. Keep monitoring.',
      }
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF2F2), // Light red/pink background
      appBar: AppBar(
        title: const Text('AI Dropout Predictor'),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.red.shade800))
          : Column(
              children: [
                _buildOverviewCard(),
                Expanded(
                  child: _students.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            return _buildStudentRiskCard(_students[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildOverviewCard() {
    final highCount = _students.where((s) => (s['riskScore'] ?? 0) >= 70).length;
    final totalAtRisk = _students.where((s) => (s['riskScore'] ?? 0) >= 50).length;

    return Container(
      width: double.infinity,
      color: Colors.red.shade800,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LMS Engagement & Retention Engine',
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
                    '$totalAtRisk Active Risk Cases',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$highCount students have severe dropout risk (>70%)',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              const Icon(Icons.trending_down_rounded, color: Colors.amberAccent, size: 40),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStudentRiskCard(Map<String, dynamic> item) {
    final name = item['name'] ?? 'Learner';
    final email = item['email'] ?? '';
    final riskScore = item['riskScore'] ?? 0;
    final reasons = item['reasons'] as List? ?? [];
    final recommendation = item['recommendation'] ?? 'Monitor weekly metrics.';

    Color progressColor = Colors.green;
    if (riskScore >= 70) progressColor = Colors.red;
    else if (riskScore >= 50) progressColor = Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: progressColor.withOpacity(0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: TextStyle(color: progressColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(email, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$riskScore%',
                      style: TextStyle(color: progressColor, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Text('Dropout Risk', style: TextStyle(color: Colors.grey, fontSize: 9)),
                  ],
                )
              ],
            ),
          ),
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: riskScore / 100.0,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation(progressColor),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // AI Reasons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Risk Trigger Indicators:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                ...reasons.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.circle, size: 6, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
          // Action Panel
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.psychology, size: 16, color: Colors.indigo),
                    const SizedBox(width: 6),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          text: 'AI Playbook Tip: ',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 11),
                          children: [
                            TextSpan(
                              text: recommendation,
                              style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black87),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              partnerId: item['studentId'] ?? '',
                              partnerName: name,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                      label: const Text('Contact Student', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.thumb_up_alt_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('Class Performance High', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('All students are actively participating and meeting expectations.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
