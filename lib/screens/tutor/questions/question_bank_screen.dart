import 'package:flutter/material.dart';
import '../../../services/question_bank_service.dart';
import '../../../utils/constants.dart';
import '../../../widgets/sapience_ui.dart';
import 'comprehension_management_screen.dart';
import 'ai_bulk_generator_screen.dart';

class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  bool _isLoading = true;
  List<dynamic> _questions = [];
  String _filterType = 'all'; // all, mcq, true_false, fill_blank, subjective
  String _filterDifficulty = 'all'; // all, easy, medium, hard
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    try {
      final res = await QuestionBankService.getQuestions(
        type: _filterType,
        difficulty: _filterDifficulty,
        search: _searchController.text.trim(),
      );
      if (res['success'] == true) {
        setState(() {
          _questions = res['questions'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load questions: $e')),
        );
      }
    }
  }

  Future<void> _deleteQuestion(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final res = await QuestionBankService.deleteQuestion(id);
        if (res['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Question deleted successfully.')),
            );
          }
          _loadQuestions();
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')),
          );
        }
      }
    }
  }

  void _showAddEditQuestionSheet({Map<String, dynamic>? existingQuestion}) {
    final isEditing = existingQuestion != null;
    final formKey = GlobalKey<FormState>();

    // Input fields
    String questionText = existingQuestion?['question'] ?? '';
    String questionType = existingQuestion?['type'] ?? 'mcq';
    String difficulty = existingQuestion?['difficulty'] ?? 'medium';
    double points = (existingQuestion?['points'] ?? 1.0).toDouble();
    String explanation = existingQuestion?['explanation'] ?? '';
    String idealAnswer = existingQuestion?['idealAnswer'] ?? '';
    List<Map<String, dynamic>> options = [];

    if (existingQuestion != null && existingQuestion['options'] != null) {
      options = List<Map<String, dynamic>>.from(
        (existingQuestion['options'] as List).map(
          (o) => {'text': o['text'] ?? '', 'isCorrect': o['isCorrect'] == true},
        ),
      );
    } else {
      options = [
        {'text': '', 'isCorrect': false},
        {'text': '', 'isCorrect': false},
      ];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Question' : 'Create Question',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Question text
                  TextFormField(
                    initialValue: questionText,
                    decoration: const InputDecoration(
                      labelText: 'Question Prompt *',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter question text' : null,
                    onChanged: (val) => questionText = val,
                  ),
                  const SizedBox(height: 16),

                  // Difficulty & Type Row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: questionType,
                          decoration: const InputDecoration(labelText: 'Question Type', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'mcq', child: Text('MCQ')),
                            DropdownMenuItem(value: 'true_false', child: Text('True / False')),
                            DropdownMenuItem(value: 'fill_blank', child: Text('Fill in the Blanks')),
                            DropdownMenuItem(value: 'subjective', child: Text('Subjective')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() {
                                questionType = val;
                                if (val == 'true_false') {
                                  options = [
                                    {'text': 'True', 'isCorrect': true},
                                    {'text': 'False', 'isCorrect': false},
                                  ];
                                } else if (val == 'mcq' && options.length < 2) {
                                  options = [
                                    {'text': '', 'isCorrect': false},
                                    {'text': '', 'isCorrect': false},
                                  ];
                                }
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: difficulty,
                          decoration: const InputDecoration(labelText: 'Difficulty', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'easy', child: Text('Easy')),
                            DropdownMenuItem(value: 'medium', child: Text('Medium')),
                            DropdownMenuItem(value: 'hard', child: Text('Hard')),
                          ],
                          onChanged: (val) => setSheetState(() => difficulty = val ?? 'medium'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Points & Explanation
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: points.toString(),
                          decoration: const InputDecoration(labelText: 'Score / Points', border: OutlineInputBorder()),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (val) => double.tryParse(val ?? '') == null ? 'Enter valid number' : null,
                          onChanged: (val) => points = double.tryParse(val) ?? 1.0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: explanation,
                          decoration: const InputDecoration(labelText: 'Explanation (Optional)', border: OutlineInputBorder()),
                          onChanged: (val) => explanation = val,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dynamic Options configuration based on questionType
                  if (questionType == 'mcq') ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Options', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                        TextButton.icon(
                          onPressed: () => setSheetState(() => options.add({'text': '', 'isCorrect': false})),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Option'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...options.asMap().entries.map((entry) {
                      int idx = entry.key;
                      Map<String, dynamic> opt = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Checkbox(
                              value: opt['isCorrect'],
                              onChanged: (val) {
                                setSheetState(() {
                                  for (var o in options) {
                                    o['isCorrect'] = false; // single correct MCQ typical
                                  }
                                  opt['isCorrect'] = val ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: TextFormField(
                                initialValue: opt['text'],
                                decoration: InputDecoration(
                                  hintText: 'Option ${idx + 1}',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: options.length > 2
                                      ? IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () => setSheetState(() => options.removeAt(idx)),
                                        )
                                      : null,
                                ),
                                onChanged: (val) => opt['text'] = val,
                                validator: (val) => val == null || val.trim().isEmpty ? 'Enter option text' : null,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ] else if (questionType == 'true_false') ...[
                    const Text('Correct Answer', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('True'),
                            selected: options[0]['isCorrect'] == true,
                            onSelected: (val) {
                              setSheetState(() {
                                options[0]['isCorrect'] = true;
                                options[1]['isCorrect'] = false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('False'),
                            selected: options[1]['isCorrect'] == true,
                            onSelected: (val) {
                              setSheetState(() {
                                options[0]['isCorrect'] = false;
                                options[1]['isCorrect'] = true;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ] else if (questionType == 'fill_blank' || questionType == 'subjective') ...[
                    TextFormField(
                      initialValue: idealAnswer,
                      decoration: InputDecoration(
                        labelText: questionType == 'fill_blank' ? 'Correct Word / Text *' : 'Ideal Rubric Answer *',
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: questionType == 'subjective' ? 4 : 1,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter ideal answer' : null,
                      onChanged: (val) => idealAnswer = val,
                    ),
                  ],

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;

                      // Build submission payload
                      final payload = <String, dynamic>{
                        'question': questionText,
                        'type': questionType,
                        'difficulty': difficulty,
                        'points': points,
                        'explanation': explanation,
                      };

                      if (questionType == 'mcq' || questionType == 'true_false') {
                        payload['options'] = options;
                        // Validate correct option selected
                        final hasCorrect = options.any((o) => o['isCorrect'] == true);
                        if (!hasCorrect) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('At least one option must be marked correct.')),
                          );
                          return;
                        }
                      } else {
                        payload['idealAnswer'] = idealAnswer;
                      }

                      Navigator.pop(sheetContext);
                      setState(() => _isLoading = true);

                      try {
                        final res = isEditing
                            ? await QuestionBankService.updateQuestion(existingQuestion['_id'], payload)
                            : await QuestionBankService.createQuestion(payload);

                        if (res['success'] == true) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isEditing
                                    ? 'Question updated successfully! 🎉'
                                    : 'Question created successfully! 🎉'),
                              ),
                            );
                          }
                          _loadQuestions();
                        }
                      } catch (e) {
                        setState(() => _isLoading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to save question: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      isEditing ? 'Save Changes' : 'Create Question',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SapienceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SapienceHeader(
                title: 'Question Bank',
                actions: [
                  Tooltip(
                    message: 'Comprehension Passages',
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ComprehensionManagementScreen(),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                            boxShadow: const [AppThemeDesign.softShadow],
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: AppColors.navyInk,
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'AI Bulk Generator',
                    child: Material(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AiBulkGeneratorScreen(),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(14),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
          // Filter Panel
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search question content...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadQuestions();
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onSubmitted: (_) => _loadQuestions(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _filterType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Types')),
                          DropdownMenuItem(value: 'mcq', child: Text('MCQ')),
                          DropdownMenuItem(value: 'true_false', child: Text('True / False')),
                          DropdownMenuItem(value: 'fill_blank', child: Text('Fill Blank')),
                          DropdownMenuItem(value: 'subjective', child: Text('Subjective')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _filterType = val);
                            _loadQuestions();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _filterDifficulty,
                        decoration: const InputDecoration(
                          labelText: 'Difficulty',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Levels')),
                          DropdownMenuItem(value: 'easy', child: Text('Easy')),
                          DropdownMenuItem(value: 'medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'hard', child: Text('Hard')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _filterDifficulty = val);
                            _loadQuestions();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _questions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.question_mark_rounded, size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text('No questions found in repository.'),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadQuestions,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _questions.length,
                          itemBuilder: (ctx, index) {
                            final q = _questions[index];
                            return _buildQuestionCard(q);
                          },
                        ),
                      ),
          ),
        ],
      ),
              ),
            ],
          ),
        ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditQuestionSheet(),
        label: const Text('Add Question'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> q) {
    final type = q['type'] ?? 'mcq';
    final difficulty = q['difficulty'] ?? 'medium';
    final points = q['points'] ?? 1;

    Color diffColor;
    switch (difficulty) {
      case 'easy':
        diffColor = Colors.green;
        break;
      case 'hard':
        diffColor = Colors.red;
        break;
      default:
        diffColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: AppThemeDesign.borderRadiusMedium),
      child: ExpansionTile(
        title: Text(
          q['question'] ?? 'No text',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1E293B)),
        ),
        subtitle: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                type.toString().toUpperCase(),
                style: const TextStyle(color: Colors.teal, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: diffColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                difficulty.toString().toUpperCase(),
                style: TextStyle(color: diffColor, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$points Pts',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(),
                const SizedBox(height: 8),

                // Options list or ideal answers
                if (type == 'mcq' || type == 'true_false') ...[
                  const Text('Options:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 6),
                  ...(q['options'] as List? ?? []).map((o) {
                    final isCorrect = o['isCorrect'] == true;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.circle_outlined,
                            color: isCorrect ? Colors.green : Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              o['text'] ?? '',
                              style: TextStyle(
                                fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                color: isCorrect ? Colors.green.shade700 : Colors.black87,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ] else ...[
                  const Text('Ideal / Model Answer:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(
                    q['idealAnswer'] ?? 'None specified',
                    style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                  ),
                ],

                if (q['explanation'] != null && q['explanation'].toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Explanation:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(
                    q['explanation'],
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                ],

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.teal),
                      onPressed: () => _showAddEditQuestionSheet(existingQuestion: q),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteQuestion(q['_id']),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
