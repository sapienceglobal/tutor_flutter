import 'package:flutter/material.dart';
import '../../../services/ai_service.dart';

class TutorWeakTopicsScreen extends StatefulWidget {
  const TutorWeakTopicsScreen({super.key});

  @override
  State<TutorWeakTopicsScreen> createState() => _TutorWeakTopicsScreenState();
}

class _TutorWeakTopicsScreenState extends State<TutorWeakTopicsScreen> {
  List<dynamic> _topics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeakTopics();
  }

  Future<void> _loadWeakTopics() async {
    setState(() => _isLoading = true);
    try {
      final res = await AIService.getWeakTopics();
      if (res['success'] == true) {
        setState(() {
          _topics = res['weakTopics'] ?? res['data']?['weakTopics'] ?? [];
        });
      } else {
        _topics = _getMockWeakTopics();
      }
    } catch (e) {
      setState(() {
        _topics = _getMockWeakTopics();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getMockWeakTopics() {
    return [
      {
        'topic': 'Trigonometric Identities & Functions',
        'course': 'Advanced Math Grade 12',
        'averageScore': 42, // Percentage
        'studentsStruggling': 8,
        'difficulty': 'Hard',
        'reasons': [
          'Frequent errors in formula application in Exam 1',
          'Low homework completion rates on trigonometry worksheets',
        ],
        'actionPlan': 'Generate targeted Trigonometry practice sets using AI and broadcast a doubt-solving session announcement.',
      },
      {
        'topic': 'Projectile Motion Calculations',
        'course': 'Physics Foundation Batch A',
        'averageScore': 51,
        'studentsStruggling': 5,
        'difficulty': 'Medium',
        'reasons': [
          'Struggling with vector decomposition in quiz responses',
        ],
        'actionPlan': 'Draft simplified notes explaining vector angles and share with the batch.',
      },
      {
        'topic': 'Object-Oriented Programming Abstraction',
        'course': 'Java Basics Core',
        'averageScore': 58,
        'studentsStruggling': 4,
        'difficulty': 'Hard',
        'reasons': [
          'Errors in polymorphism implementation logs',
        ],
        'actionPlan': 'Host an interactive coding lab during upcoming live webinar.',
      }
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBEB), // Light amber/yellow background
      appBar: AppBar(
        title: const Text('AI Curriculum Insights'),
        backgroundColor: Colors.amber.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.amber.shade800))
          : Column(
              children: [
                _buildOverviewCard(),
                Expanded(
                  child: _topics.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _topics.length,
                          itemBuilder: (context, index) {
                            return _buildWeakTopicCard(_topics[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildOverviewCard() {
    final hardTopics = _topics.where((t) => t['difficulty'] == 'Hard').length;
    final totalStruggling = _topics.fold<int>(0, (sum, item) => sum + ((item['studentsStruggling'] as int?) ?? 0));

    return Container(
      width: double.infinity,
      color: Colors.amber.shade800,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Batch-level Concept Mastery Analyzer',
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
                    '${_topics.length} Weak Topics Detected',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Affecting $totalStruggling students. $hardTopics concepts flagged as Hard.',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              const Icon(Icons.analytics_outlined, color: Colors.indigoAccent, size: 40),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildWeakTopicCard(Map<String, dynamic> item) {
    final topic = item['topic'] ?? 'Topic Concept';
    final course = item['course'] ?? 'Course';
    final avgScore = item['averageScore'] ?? 0;
    final studentsCount = item['studentsStruggling'] ?? 0;
    final difficulty = item['difficulty'] ?? 'Medium';
    final reasons = item['reasons'] as List? ?? [];
    final actionPlan = item['actionPlan'] ?? '';

    Color scoreColor = Colors.green;
    if (avgScore < 50) scoreColor = Colors.red;
    else if (avgScore < 70) scoreColor = Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(topic, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(course, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    difficulty.toUpperCase(),
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Scores summary row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$avgScore%', style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 18)),
                      const Text('Average Concept Score', style: TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$studentsCount Students', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                      const Text('Struggling with Concept', style: TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Diagnostic bullet points
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Diagnostic Findings:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                ...reasons.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.analytics, size: 12, color: Colors.amber),
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
          // Remedial AI Playbook Action plan
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.healing_rounded, size: 16, color: Colors.indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: 'Remedial Action Plan: ',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 11),
                      children: [
                        TextSpan(
                          text: actionPlan,
                          style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black87),
                        )
                      ],
                    ),
                  ),
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
          Icon(Icons.verified_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('Concept Mastery Met', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Your class has successfully cleared the minimum mastery parameters.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
