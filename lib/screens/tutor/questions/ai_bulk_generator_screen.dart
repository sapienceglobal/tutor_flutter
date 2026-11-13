import 'package:flutter/material.dart';
import '../../../services/ai_service.dart';
import '../../../services/taxonomy_service.dart';
import '../../../services/question_bank_service.dart';
import '../../../utils/constants.dart';

class AiBulkGeneratorScreen extends StatefulWidget {
  const AiBulkGeneratorScreen({super.key});

  @override
  State<AiBulkGeneratorScreen> createState() => _AiBulkGeneratorScreenState();
}

class _AiBulkGeneratorScreenState extends State<AiBulkGeneratorScreen> {
  bool _isGenerating = false;
  bool _isSaving = false;
  bool _isLoadingTaxonomy = true;

  List<dynamic> _topics = [];
  List<dynamic> _skills = [];
  List<dynamic> _generatedQuestions = [];

  // Form parameters
  final _topicPromptController = TextEditingController();
  int _questionCount = 5;
  String _difficulty = 'medium';
  String _questionType = 'mcq';

  // Metadata for saving
  String? _selectedTopicId;
  String? _selectedSkillId;
  double _points = 1.0;

  @override
  void initState() {
    super.initState();
    _fetchTaxonomy();
  }

  @override
  void dispose() {
    _topicPromptController.dispose();
    super.dispose();
  }

  Future<void> _fetchTaxonomy() async {
    setState(() => _isLoadingTaxonomy = true);
    try {
      final topicsRes = await TaxonomyService.getTopics();
      final skillsRes = await TaxonomyService.getSkills();

      if (mounted) {
        setState(() {
          _topics = topicsRes['topics'] ?? [];
          _skills = skillsRes['skills'] ?? [];
          _isLoadingTaxonomy = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load taxonomy: $e');
      if (mounted) {
        setState(() => _isLoadingTaxonomy = false);
      }
    }
  }

  Future<void> _generateQuestions() async {
    final topicPrompt = _topicPromptController.text.trim();
    if (topicPrompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a topic or text excerpt.')),
      );
      return;
      }

    setState(() {
      _isGenerating = true;
      _generatedQuestions = [];
    });

    try {
      final res = await AIService.generateQuestions(
        topic: topicPrompt,
        count: _questionCount,
        difficulty: _difficulty,
      );

      if (res['success'] == true && res['questions'] != null) {
        final List questionsList = res['questions'];
        setState(() {
          _generatedQuestions = questionsList.map((q) => {
            ...q,
            'type': _questionType,
            'difficulty': _difficulty,
          }).toList();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Generated ${_generatedQuestions.length} questions!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generation failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _saveAllQuestions() async {
    if (_generatedQuestions.isEmpty) return;
    if (_selectedTopicId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a topic.')),
      );
      return;
    }
    if (_selectedSkillId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a skill.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    int successCount = 0;
    int failCount = 0;

    for (final q in _generatedQuestions) {
      try {
        final payload = <String, dynamic>{
          'question': q['question'],
          'explanation': q['explanation'],
          'difficulty': q['difficulty']?.toString().toLowerCase() ?? 'medium',
          'type': q['type'],
          'topicId': _selectedTopicId,
          'skillId': _selectedSkillId,
          'points': _points,
        };

        if (q['type'] == 'mcq') {
          final List<dynamic> options = q['options'] ?? [];
          final String correctAnswer = q['correctAnswer'] ?? '';
          payload['options'] = options.map((opt) => {
            'text': opt.toString(),
            'isCorrect': opt.toString() == correctAnswer,
          }).toList();
        } else {
          payload['idealAnswer'] = q['idealAnswer'] ?? '';
        }

        final res = await QuestionBankService.createQuestion(payload);
        if (res['success'] == true) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (_) {
        failCount++;
      }
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (failCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully saved all $successCount questions to bank!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved $successCount, failed $failCount questions.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bulk AI Question Generator', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoadingTaxonomy
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Parameters Box ---
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'AI Generator Prompt',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Topic or Text Excerpt *',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _topicPromptController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Enter specific topic or paste text to generate questions from...',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Question Count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<int>(
                                          value: _questionCount,
                                          isExpanded: true,
                                          items: [3, 5, 10, 15]
                                              .map((c) => DropdownMenuItem(
                                                    value: c,
                                                    child: Text('$c Questions'),
                                                  ))
                                              .toList(),
                                          onChanged: (v) => setState(() => _questionCount = v!),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Difficulty', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _difficulty,
                                          isExpanded: true,
                                          items: ['easy', 'medium', 'hard']
                                              .map((d) => DropdownMenuItem(
                                                    value: d,
                                                    child: Text(d.toUpperCase()),
                                                  ))
                                              .toList(),
                                          onChanged: (v) => setState(() => _difficulty = v!),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Question Type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _questionType,
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(value: 'mcq', child: Text('Multiple Choice (MCQ)')),
                                      DropdownMenuItem(value: 'subjective', child: Text('Subjective / Written')),
                                    ],
                                    onChanged: (v) => setState(() => _questionType = v!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: _isGenerating ? null : _generateQuestions,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: _isGenerating
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.bolt, size: 18),
                              label: Text(_isGenerating ? 'Generating...' : 'Generate Questions', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_generatedQuestions.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    // --- Save Parameters Card ---
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.bookmark_outline, color: Colors.indigo, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Bank Assignment Metadata',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Assign Topic', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _selectedTopicId,
                                            isExpanded: true,
                                            hint: const Text('Select Topic'),
                                            items: _topics
                                                .map((t) => DropdownMenuItem<String>(
                                                      value: t['_id']?.toString(),
                                                      child: Text(t['name']?.toString() ?? 'Topic'),
                                                    ))
                                                .toList(),
                                            onChanged: (v) => setState(() => _selectedTopicId = v),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Assign Skill', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _selectedSkillId,
                                            isExpanded: true,
                                            hint: const Text('Select Skill'),
                                            items: _skills
                                                .map((s) => DropdownMenuItem<String>(
                                                      value: s['_id']?.toString(),
                                                      child: Text(s['name']?.toString() ?? 'Skill'),
                                                    ))
                                                .toList(),
                                            onChanged: (v) => setState(() => _selectedSkillId = v),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: _isSaving ? null : _saveAllQuestions,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.save_outlined, size: 18),
                                label: Text(_isSaving ? 'Saving to Bank...' : 'Save All to Question Bank', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Generated Questions Preview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _generatedQuestions.length,
                      itemBuilder: (context, idx) {
                        final q = _generatedQuestions[idx];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: AppColors.primary.withOpacity(0.1),
                                      child: Text('${idx + 1}', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _difficulty.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _difficulty == 'hard' ? Colors.red : (_difficulty == 'medium' ? Colors.orange : Colors.green),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  q['question'] ?? 'No Question Text',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                if (q['type'] == 'mcq' && q['options'] != null) ...[
                                  const SizedBox(height: 8),
                                  ...(q['options'] as List).map((opt) {
                                    final bool isCorrect = opt.toString() == q['correctAnswer'];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isCorrect ? Colors.green.shade50 : Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: isCorrect ? Colors.green.shade200 : Colors.grey.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(isCorrect ? Icons.check_circle : Icons.circle_outlined, size: 16, color: isCorrect ? Colors.green : Colors.grey),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(opt.toString(), style: const TextStyle(fontSize: 12))),
                                        ],
                                      ),
                                    );
                                  }),
                                ] else if (q['idealAnswer'] != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue.shade100),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Ideal Answer:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                                        const SizedBox(height: 4),
                                        Text(q['idealAnswer'].toString(), style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                                if (q['explanation'] != null) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    'Explanation: ${q['explanation']}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
