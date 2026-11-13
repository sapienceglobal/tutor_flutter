import 'package:flutter/material.dart';
import '../../../services/ai_service.dart';
import '../../../services/enrollment_service.dart';
import '../../../utils/constants.dart';
import '../../../widgets/sapience_ui.dart';
import '../../../widgets/shimmer_loader.dart';
import 'ai_buddy_screen.dart';

class StudentAiHubScreen extends StatefulWidget {
  final bool embedded;
  const StudentAiHubScreen({super.key, this.embedded = false});

  @override
  State<StudentAiHubScreen> createState() => _StudentAiHubScreenState();
}

class _StudentAiHubScreenState extends State<StudentAiHubScreen> {
  final TextEditingController _askController = TextEditingController();
  List<String> _dynamicSuggestions = const [
    'What is a function in code?',
    'How does a loop work?',
    'Build my exam revision plan.',
    'Give me a small project idea.',
  ];

  @override
  void initState() {
    super.initState();
    _loadCourseAwarePrompts();
  }

  @override
  void dispose() {
    _askController.dispose();
    super.dispose();
  }

  Future<void> _loadCourseAwarePrompts() async {
    try {
      final enrollments = await EnrollmentService.getMyEnrollments();
      if (!mounted || enrollments.isEmpty) return;
      final firstCourse = enrollments.first.course.title;
      final secondCourse = enrollments.length > 1
          ? enrollments[1].course.title
          : enrollments.first.course.category.name;
      setState(() {
        _dynamicSuggestions = [
          'Explain key concepts in $firstCourse',
          'Create a quick quiz for $firstCourse',
          'Summarize $secondCourse notes',
          'Build a 7-day study plan for me',
        ];
      });
    } catch (_) {}
  }

  void _openAiChat([String? prompt]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiBuddyScreen(initialPrompt: prompt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quickActions = [
      (
        icon: Icons.help_outline_rounded,
        color: AppColors.primary,
        tone: SapienceTileTone.blue,
        title: 'Explain a\nConcept',
        prompt: 'Explain a tricky concept from my syllabus in simple steps with examples.',
      ),
      (
        icon: Icons.code_rounded,
        color: AppColors.warning,
        tone: SapienceTileTone.orange,
        title: 'Write a\nCode Example',
        prompt: 'Write a clean, well-commented code example with step-by-step walkthrough.',
      ),
      (
        icon: Icons.settings_suggest_rounded,
        color: AppColors.success,
        tone: SapienceTileTone.green,
        title: 'Solve a\nProblem',
        prompt: 'Help me solve a practice problem step-by-step and highlight common mistakes.',
      ),
      (
        icon: Icons.menu_book_rounded,
        color: AppColors.purple,
        tone: SapienceTileTone.purple,
        title: 'Quiz Me\non a Topic',
        prompt: 'Quiz me with 5 MCQs on my current topic, one question at a time.',
      ),
      (
        icon: Icons.layers_rounded,
        color: AppColors.primary,
        tone: SapienceTileTone.blue,
        title: 'Summarize\nThis Lesson',
        prompt: 'Summarize the core points of my current topic as crisp bullet revision notes.',
      ),
      (
        icon: Icons.lightbulb_outline_rounded,
        color: AppColors.warning,
        tone: SapienceTileTone.pink,
        title: 'Suggest\nPractice Ideas',
        prompt: 'Suggest practical exercises and mini-project ideas tailored to my level.',
      ),
    ];

    return Scaffold(
      body: SapienceBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SapienceHeader(
                title: 'AI Tutor',
                leading: widget.embedded ? const SizedBox(width: 40) : null,
                titleBadge: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'New',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Chat History',
                    icon: const Icon(Icons.history_rounded, color: AppColors.navy, size: 25),
                    onPressed: () => _openAiChat(),
                    splashRadius: 20,
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    // Robot mascot with soft radial halo (matches AI Tutor Learning Dashboard.png)
                    SizedBox(
                      height: 146,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 240,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFE7EEFC),
                                  const Color(0xFFEEF2FB).withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                          Image.asset(
                            'assets/images/ai-robot.png',
                            height: 140,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'Ask Anything, Learn Instantly',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Get instant answers, explanations, code examples and study support with your AI Tutor.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textBody,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 3x2 Pastel Quick Prompt Tiles
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.08,
                      ),
                      itemCount: quickActions.length,
                      itemBuilder: (_, i) {
                        final item = quickActions[i];
                        return SapienceTintedTile(
                          tone: item.tone,
                          borderRadius: 18,
                          onTap: () => _openAiChat(item.prompt),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(item.icon, color: item.color, size: 30),
                              const SizedBox(height: 6),
                              Text(
                                item.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy,
                                  height: 1.18,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Try Asking',
                      style: TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 4.1,
                      ),
                      itemCount: _dynamicSuggestions.length,
                      itemBuilder: (_, i) {
                        final text = _dynamicSuggestions[i];
                        return GestureDetector(
                          onTap: () => _openAiChat(text),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0xFFE3EAF6)),
                              boxShadow: const [AppThemeDesign.softShadow],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded, size: 15, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    text,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Study Suite Tools',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _suitePill(
                            'Shared Notes',
                            Icons.note_alt_outlined,
                            AppColors.teal,
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentSharedNotesScreen())),
                          ),
                          const SizedBox(width: 8),
                          _suitePill(
                            'Lecture Summaries',
                            Icons.summarize_outlined,
                            AppColors.warning,
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentLectureSummariesScreen())),
                          ),
                          const SizedBox(width: 8),
                          _suitePill(
                            'AI Study Plans',
                            Icons.calendar_month_outlined,
                            AppColors.purple,
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentStudyPlansScreen())),
                          ),
                          const SizedBox(width: 8),
                          _suitePill(
                            'Weak Topics',
                            Icons.analytics_outlined,
                            AppColors.error,
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentWeakTopicsScreen())),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Floating Ask Input Bar (exact match to bottom of AI Tutor Learning Dashboard.png)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFE3EAF6)),
                          boxShadow: const [AppThemeDesign.cardShadow],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _askController,
                                onSubmitted: (v) {
                                  if (v.trim().isNotEmpty) {
                                    final text = v.trim();
                                    _askController.clear();
                                    _openAiChat(text);
                                  }
                                },
                                style: const TextStyle(color: AppColors.navy, fontSize: 15),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  hintText: 'Ask me anything...',
                                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 15),
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _openAiChat(),
                              child: const Icon(Icons.mic_none_rounded, color: AppColors.textMuted, size: 22),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        final text = _askController.text.trim();
                        _askController.clear();
                        _openAiChat(text.isEmpty ? null : text);
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF3A8DFF), Color(0xFF0757EA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [AppThemeDesign.brandShadow],
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _suitePill(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: const [AppThemeDesign.softShadow],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 📝 SUB-SCREEN: STUDENT SHARED NOTES
// ─────────────────────────────────────────────────────────────────────────────
class StudentSharedNotesScreen extends StatefulWidget {
  const StudentSharedNotesScreen({super.key});

  @override
  State<StudentSharedNotesScreen> createState() => _StudentSharedNotesScreenState();
}

class _StudentSharedNotesScreenState extends State<StudentSharedNotesScreen> {
  bool _isLoading = true;
  List<dynamic> _notes = [];

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    setState(() => _isLoading = true);
    try {
      final res = await AIService.getStudentSharedNotes();
      if (res['success'] == true) {
        setState(() {
          _notes = res['data'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notes: $e')),
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
        title: const Text('Shared Revision Notes'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const ShimmerListView()
          : _notes.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notes.length,
                  itemBuilder: (ctx, i) {
                    final item = _notes[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          child: Icon(Icons.description),
                        ),
                        title: Text(
                          item['title'] ?? 'Simplified Revision Notes',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Shared by: ${item['tutor']?['name'] ?? 'Tutor'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: () => _showNotesDetailDialog(context, item),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_alt_outlined, size: 64, color: Colors.teal),
          SizedBox(height: 16),
          Text(
            'No Shared Notes Yet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 6),
          Text(
            'Notes simplified and shared by your tutors will appear here.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showNotesDetailDialog(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['title'] ?? 'Notes Detail'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              item['content'] ?? item['summary'] ?? 'No text content available.',
              style: const TextStyle(height: 1.5, fontSize: 14),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 📖 SUB-SCREEN: STUDENT LECTURE SUMMARIES
// ─────────────────────────────────────────────────────────────────────────────
class StudentLectureSummariesScreen extends StatefulWidget {
  const StudentLectureSummariesScreen({super.key});

  @override
  State<StudentLectureSummariesScreen> createState() => _StudentLectureSummariesScreenState();
}

class _StudentLectureSummariesScreenState extends State<StudentLectureSummariesScreen> {
  bool _isLoading = true;
  List<dynamic> _summaries = [];

  @override
  void initState() {
    super.initState();
    _fetchSummaries();
  }

  Future<void> _fetchSummaries() async {
    setState(() => _isLoading = true);
    try {
      final res = await AIService.getStudentLectureSummaries();
      if (res['success'] == true) {
        setState(() {
          _summaries = res['data'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load summaries: $e')),
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
        title: const Text('Lecture Summaries'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const ShimmerListView()
          : _summaries.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _summaries.length,
                  itemBuilder: (ctx, i) {
                    final item = _summaries[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          child: Icon(Icons.summarize),
                        ),
                        title: Text(
                          item['title'] ?? 'Lecture Summary',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          item['lecture']?['title'] ?? 'Course Lecture',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: () => _showSummaryDetail(context, item),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined, size: 64, color: Colors.orange),
          SizedBox(height: 16),
          Text(
            'No Lecture Summaries',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 6),
          Text(
            'Summaries of recorded lectures shared by your tutors will show up here.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showSummaryDetail(BuildContext context, dynamic item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    item['title'] ?? 'Lecture Summary',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Shared from Course Unit: ${item['lecture']?['title'] ?? 'Lecture'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const Divider(height: 24),
                  Text(
                    item['summary'] ?? item['content'] ?? 'No summaries provided.',
                    style: const TextStyle(fontSize: 14, height: 1.6),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 📅 SUB-SCREEN: STUDENT STUDY PLANS
// ─────────────────────────────────────────────────────────────────────────────
class StudentStudyPlansScreen extends StatefulWidget {
  const StudentStudyPlansScreen({super.key});

  @override
  State<StudentStudyPlansScreen> createState() => _StudentStudyPlansScreenState();
}

class _StudentStudyPlansScreenState extends State<StudentStudyPlansScreen> {
  bool _isLoading = true;
  bool _isGenerating = false;
  List<dynamic> _plans = [];

  final _examController = TextEditingController();
  final _daysController = TextEditingController();
  final _focusController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    setState(() => _isLoading = true);
    try {
      final res = await AIService.getStudentStudyPlans();
      if (res['success'] == true) {
        setState(() {
          _plans = res['data'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load study plans: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generatePlan() async {
    final exam = _examController.text.trim();
    final daysStr = _daysController.text.trim();
    if (exam.isEmpty || daysStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in Exam and Duration!')),
      );
      return;
    }

    final days = int.tryParse(daysStr);
    if (days == null || days <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number of days!')),
      );
      return;
    }

    Navigator.pop(context); // Close builder dialog
    setState(() => _isGenerating = true);

    try {
      final res = await AIService.generateStudentStudyPlan(
        targetExam: exam,
        durationDays: days,
        focusArea: _focusController.text.trim().isNotEmpty ? _focusController.text.trim() : null,
      );

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI Study Plan generated successfully! 📅')),
        );
        _examController.clear();
        _daysController.clear();
        _focusController.clear();
        _fetchPlans();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate plan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: const Text('My Study Plans'),
        backgroundColor: Colors.purple,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePlanModal,
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New AI Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isGenerating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.purple),
                  SizedBox(height: 16),
                  Text(
                    'Generating Personalized Study Plan...',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Structuring sessions, revision tags, and resources...',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            )
          : _isLoading
              ? const ShimmerListView()
              : _plans.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _plans.length,
                      itemBuilder: (ctx, i) {
                        final item = _plans[i];
                        final targetExam = item['targetExam'] ?? 'Specialized Goal';
                        final days = item['durationDays'] ?? 7;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              child: Icon(Icons.calendar_month),
                            ),
                            title: Text(
                              targetExam,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Syllabus Duration: $days Days Plan',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                            onTap: () => _showPlanDetail(context, item),
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_outlined, size: 64, color: Colors.purple),
          SizedBox(height: 16),
          Text(
            'No Custom Study Plans',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 6),
          Text(
            'Tap "New AI Plan" to generate your custom exam schedule.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showCreatePlanModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Create AI Study Plan 📅',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _examController,
                  decoration: const InputDecoration(
                    labelText: 'Target Exam Name (e.g. JEE Main Chemistry)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _daysController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (in Days, e.g. 14)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _focusController,
                  decoration: const InputDecoration(
                    labelText: 'Focus Topics (Optional, e.g. Organic Chemistry)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _generatePlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Generate Plan',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPlanDetail(BuildContext context, dynamic item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    item['targetExam'] ?? 'AI Study Plan',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Duration: ${item['durationDays'] ?? 7} Days',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const Divider(height: 24),
                  Text(
                    item['planDetails'] ?? item['content'] ?? 'No plan details provided.',
                    style: const TextStyle(fontSize: 14, height: 1.6),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ⚠️ SUB-SCREEN: STUDENT WEAK TOPICS
// ─────────────────────────────────────────────────────────────────────────────
class StudentWeakTopicsScreen extends StatefulWidget {
  const StudentWeakTopicsScreen({super.key});

  @override
  State<StudentWeakTopicsScreen> createState() => _StudentWeakTopicsScreenState();
}

class _StudentWeakTopicsScreenState extends State<StudentWeakTopicsScreen> {
  bool _isLoading = true;
  List<dynamic> _weakTopics = [];

  @override
  void initState() {
    super.initState();
    _fetchWeakTopics();
  }

  Future<void> _fetchWeakTopics() async {
    setState(() => _isLoading = true);
    try {
      final res = await AIService.getStudentWeakTopics();
      if (res['success'] == true) {
        setState(() {
          _weakTopics = res['data'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load weak topics: $e')),
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
        title: const Text('AI Weak Topics Diagnostics'),
        backgroundColor: Colors.pink,
      ),
      body: _isLoading
          ? const ShimmerListView()
          : _weakTopics.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _weakTopics.length,
                  itemBuilder: (ctx, i) {
                    final item = _weakTopics[i];
                    final score = item['score'] ?? 0.0;
                    final topic = item['topic'] ?? 'Topic Name';
                    final rec = item['recommendation'] ?? 'Review recommended reading sheets.';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    topic,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${(score * 100).toStringAsFixed(0)}% Weakness',
                                    style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: score,
                                color: Colors.red,
                                backgroundColor: Colors.grey.shade200,
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    rec,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
          SizedBox(height: 16),
          Text(
            'All Topics Strong! 🎉',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 6),
          Text(
            'AI diagnostics shows no academic weak points.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
