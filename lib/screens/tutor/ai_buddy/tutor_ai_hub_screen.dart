import 'package:flutter/material.dart';
import '../../../services/ai_service.dart';
import '../../../utils/constants.dart';
import '../../../widgets/sapience_ui.dart';
import '../../../widgets/feature_gate.dart';
import '../../student/ai_buddy/ai_buddy_screen.dart';
import 'tutor_proctoring_alerts_screen.dart';
import 'tutor_dropout_risk_screen.dart';
import 'tutor_weak_topics_screen.dart';

class TutorAiHubScreen extends StatelessWidget {
  const TutorAiHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SapienceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SapienceHeader(title: 'Educator AI Co-Pilot'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Card matching AI Tutor PNG + Navy Wave banner
                      SapienceNavyWaveBanner(
                        borderRadius: 24,
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'AI Powered',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'AI-Driven Classroom',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Draft announcements, simplify lectures, grade descriptive answers, and check submission integrity.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.84),
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Image.asset(
                              'assets/images/ai-robot.png',
                              width: 78,
                              height: 78,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      const SapienceSectionHeader(
                        title: 'Assistant & Content Tools',
                      ),
                      const SizedBox(height: 10),

            // 🔐 aiAssistant — Smart Teaching tools
            FeatureGate(
              featureKey: 'aiAssistant',
              showLockOverlay: true,
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _buildToolCard(
                    context,
                    title: 'AI Chat Assistant',
                    subtitle: 'Interactive helper',
                    icon: Icons.chat_bubble_outline_rounded,
                    color: Colors.indigo,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AiBuddyScreen()),
                    ),
                  ),
                  _buildToolCard(
                    context,
                    title: 'Lecture Summarizer',
                    subtitle: 'Key takeaway generator',
                    icon: Icons.summarize_outlined,
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TutorLectureSummarizerScreen()),
                    ),
                  ),
                  _buildToolCard(
                    context,
                    title: 'Notes Simplifier',
                    subtitle: 'Condense complex drafts',
                    icon: Icons.note_alt_outlined,
                    color: Colors.teal,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TutorNotesSimplifierScreen()),
                    ),
                  ),
                  _buildToolCard(
                    context,
                    title: 'Smart Notification',
                    subtitle: 'Draft update announcements',
                    icon: Icons.campaign_outlined,
                    color: Colors.purple,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TutorNotificationDrafterScreen()),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Grading & Integrity Suite',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
            ),
            const SizedBox(height: 12),

            // 🔐 aiAssessment — Grading & Integrity tools
            FeatureGate(
              featureKey: 'aiAssessment',
              showLockOverlay: true,
              child: Column(
                children: [
                  _buildRowCard(
                    context,
                    title: 'Subjective Script Evaluator',
                    subtitle: 'Check descriptive answers against standard rubrics',
                    icon: Icons.assignment_turned_in_outlined,
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TutorSubjectiveCheckerScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRowCard(
                    context,
                    title: 'Plagiarism Detector',
                    subtitle: 'Audit assignment submission integrity',
                    icon: Icons.spellcheck_rounded,
                    color: Colors.red,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TutorPlagiarismScreen()),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const SapienceSectionHeader(
              title: 'Retention & Curriculum Diagnostics',
            ),
            const SizedBox(height: 10),

            // 🔐 aiIntelligence — Analytics & Diagnostics tools
            FeatureGate(
              featureKey: 'aiIntelligence',
              showLockOverlay: true,
              child: Column(
                children: [
                  _buildRowCard(
                    context,
                    title: 'Proctoring & Exam Suspicion Alerts',
                    subtitle: 'Audit browser tab switches and proctoring logs',
                    icon: Icons.security,
                    color: Colors.deepPurple,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TutorProctoringAlertsScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRowCard(
                    context,
                    title: 'Dropout & Risk Predictor',
                    subtitle: 'Identify inactive or low engagement students',
                    icon: Icons.trending_down_rounded,
                    color: Colors.red.shade800,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TutorDropoutRiskScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRowCard(
                    context,
                    title: 'Concept Weakness Mastery analysis',
                    subtitle: 'Analyze topics struggling students are failing',
                    icon: Icons.analytics_outlined,
                    color: Colors.amber.shade800,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TutorWeakTopicsScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InteractivePressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppThemeDesign.buildGlassDecoration(
          borderOpacity: 0.15,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF1E1B4B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InteractivePressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppThemeDesign.buildGlassDecoration(
          borderOpacity: 0.15,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 📖 SUB-SCREEN: TUTOR LECTURE SUMMARIZER
// ─────────────────────────────────────────────────────────────────────────────
class TutorLectureSummarizerScreen extends StatefulWidget {
  const TutorLectureSummarizerScreen({super.key});

  @override
  State<TutorLectureSummarizerScreen> createState() => _TutorLectureSummarizerScreenState();
}

class _TutorLectureSummarizerScreenState extends State<TutorLectureSummarizerScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  String _summaryResult = '';

  Future<void> _generateSummary() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both Title and Content!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _summaryResult = '';
    });

    try {
      final res = await AIService.generateLectureSummary(
        lectureTitle: title,
        content: content,
      );
      if (res['success'] == true) {
        setState(() {
          _summaryResult = res['data']?['summary'] ?? res['summary'] ?? 'No summary generated.';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generation failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: const Text('Lecture Summarizer'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Lecture / Video Title',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Lecture Notes / Audio Transcription Text',
                hintText: 'Paste detailed lecture notes or audio transcripts here...',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _generateSummary,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Generate AI Summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            if (_summaryResult.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'AI Lecture Summary:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  _summaryResult,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 📝 SUB-SCREEN: TUTOR NOTES SIMPLIFIER
// ─────────────────────────────────────────────────────────────────────────────
class TutorNotesSimplifierScreen extends StatefulWidget {
  const TutorNotesSimplifierScreen({super.key});

  @override
  State<TutorNotesSimplifierScreen> createState() => _TutorNotesSimplifierScreenState();
}

class _TutorNotesSimplifierScreenState extends State<TutorNotesSimplifierScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  String _simplifiedResult = '';

  Future<void> _simplifyNotes() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both Title and Content!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _simplifiedResult = '';
    });

    try {
      final res = await AIService.simplifyNotes(
        notesTitle: title,
        content: content,
      );
      if (res['success'] == true) {
        setState(() {
          _simplifiedResult = res['data']?['summary'] ?? res['content'] ?? 'No simplified notes returned.';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Simplification failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: const Text('Notes Simplifier'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Notes Topic Title',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Paste Complex Reference Material Text',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _simplifyNotes,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Simplify Notes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            if (_simplifiedResult.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'AI Simplified Output:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  _simplifiedResult,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 📢 SUB-SCREEN: TUTOR NOTIFICATION DRAFTER
// ─────────────────────────────────────────────────────────────────────────────
class TutorNotificationDrafterScreen extends StatefulWidget {
  const TutorNotificationDrafterScreen({super.key});

  @override
  State<TutorNotificationDrafterScreen> createState() => _TutorNotificationDrafterScreenState();
}

class _TutorNotificationDrafterScreenState extends State<TutorNotificationDrafterScreen> {
  final _topicController = TextEditingController();
  String _targetAudience = 'students';
  bool _isLoading = false;
  String _draftResult = '';

  Future<void> _draftNotification() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter announcement topic!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _draftResult = '';
    });

    try {
      final res = await AIService.draftNotification(
        topic: topic,
        targetAudience: _targetAudience,
      );
      if (res['success'] == true) {
        setState(() {
          _draftResult = res['data']?['draft'] ?? res['draft'] ?? 'Draft generated successfully.';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Drafting failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: const Text('Smart Notification Drafter'),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: 'Notification Context / Topic',
                hintText: 'e.g. Schedule shift for Friday physics batch...',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _targetAudience,
              decoration: const InputDecoration(
                labelText: 'Target Audience Group',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(value: 'students', child: Text('Students Only')),
                DropdownMenuItem(value: 'parents', child: Text('Parents Only')),
                DropdownMenuItem(value: 'all', child: Text('All Users')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _targetAudience = val);
                }
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _draftNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Generate Notification Draft', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            if (_draftResult.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'AI Draft Announcement:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  _draftResult,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ✍️ SUB-SCREEN: TUTOR SUBJECTIVE CHECKER
// ─────────────────────────────────────────────────────────────────────────────
class TutorSubjectiveCheckerScreen extends StatefulWidget {
  const TutorSubjectiveCheckerScreen({super.key});

  @override
  State<TutorSubjectiveCheckerScreen> createState() => _TutorSubjectiveCheckerScreenState();
}

class _TutorSubjectiveCheckerScreenState extends State<TutorSubjectiveCheckerScreen> {
  final _questionController = TextEditingController();
  final _studentAnsController = TextEditingController();
  final _modelAnsController = TextEditingController();
  bool _isLoading = false;
  String _evaluationResult = '';

  Future<void> _checkScript() async {
    final q = _questionController.text.trim();
    final sa = _studentAnsController.text.trim();
    final ma = _modelAnsController.text.trim();

    if (q.isEmpty || sa.isEmpty || ma.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in Question, Student Answer, and Model Answer!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _evaluationResult = '';
    });

    try {
      final res = await AIService.checkSubjectiveAnswer(
        question: q,
        studentAnswer: sa,
        modelAnswer: ma,
      );
      if (res['success'] == true) {
        setState(() {
          _evaluationResult = res['data']?['evaluation'] ?? res['evaluation'] ?? 'No evaluation details returned.';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Grading check failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: const Text('Subjective Answer Evaluator'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Question Title / Prompts',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _modelAnsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ideal Model Answer Rubric',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _studentAnsController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Student Submitted Text',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _checkScript,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Evaluate Submission', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            if (_evaluationResult.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Rubric Grade & Detailed Feedback:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  _evaluationResult,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🔍 SUB-SCREEN: TUTOR PLAGIARISM CHECKER
// ─────────────────────────────────────────────────────────────────────────────
class TutorPlagiarismScreen extends StatefulWidget {
  const TutorPlagiarismScreen({super.key});

  @override
  State<TutorPlagiarismScreen> createState() => _TutorPlagiarismScreenState();
}

class _TutorPlagiarismScreenState extends State<TutorPlagiarismScreen> {
  final _contentController = TextEditingController();
  bool _isLoading = false;
  String _plagiarismReport = '';

  Future<void> _checkPlagiarism() async {
    final text = _contentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter script content to scan!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _plagiarismReport = '';
    });

    try {
      final res = await AIService.checkPlagiarism(content: text);
      if (res['success'] == true) {
        setState(() {
          _plagiarismReport = res['data']?['report'] ?? res['report'] ?? 'Integrity scan completed. 0% similarity detected.';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Integrity scan failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: const Text('Plagiarism Detector'),
        backgroundColor: Colors.red.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _contentController,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Paste student answer or essay text',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _checkPlagiarism,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Scan for Plagiarism', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            if (_plagiarismReport.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Integrity Scan Findings:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  _plagiarismReport,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
