import 'package:flutter/material.dart';
import '../../services/exam_service.dart';
import '../../models/exam_model.dart';
import '../../utils/constants.dart';
import 'student_exam_player_screen.dart';
import 'exam_setup_screen.dart';

class ExamInstructionsScreen extends StatefulWidget {
  final String examId;
  final int existingAttempts;
  final int maxAttempts;

  const ExamInstructionsScreen({
    super.key,
    required this.examId,
    required this.existingAttempts,
    required this.maxAttempts,
  });

  @override
  State<ExamInstructionsScreen> createState() => _ExamInstructionsScreenState();
}

class _ExamInstructionsScreenState extends State<ExamInstructionsScreen> {
  bool _isLoading = true;
  ExamModel? _exam;
  bool _agreedToInstructions = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchExamDetails();
  }

  Future<void> _fetchExamDetails() async {
    try {
      final res = await ExamService.getStudentExamById(widget.examId);
      if (res['success'] == true && res['exam'] != null) {
        setState(() {
          _exam = ExamModel.fromJson(res['exam']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Failed to load exam details.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _startExam() {
    if (!_agreedToInstructions) return;
    
    final bool hasProctoring = _exam!.isProctoringEnabled || _exam!.isAudioProctoringEnabled;
    if (hasProctoring) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ExamSetupScreen(
            examId: widget.examId,
            exam: _exam!,
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => StudentExamPlayerScreen(examId: widget.examId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: const Text('Exam Instructions'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: const Text('Exam Instructions'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final exam = _exam!;
    final bool hasProctoringWarning = exam.isProctoringEnabled || exam.isAudioProctoringEnabled;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Exam Instructions'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Exam Title Card ──────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exam.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (exam.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      exam.description,
                      style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Test Summary Card ────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.analytics_outlined, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Test Summary',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _summaryRow(Icons.timer_outlined, 'Duration', '${exam.duration} minutes'),
                        _summaryRow(Icons.quiz_outlined, 'Questions', '${exam.questions.length}'),
                        _summaryRow(Icons.star_outlined, 'Total Marks', '${exam.totalMarks}'),
                        _summaryRow(Icons.replay, 'Attempts', '${widget.existingAttempts} / ${widget.maxAttempts}'),
                        _summaryRow(
                          Icons.remove_circle_outline,
                          'Negative Marking',
                          exam.negativeMarking ? 'Yes' : 'No',
                          valueColor: exam.negativeMarking ? Colors.red : Colors.green,
                        ),
                        if (hasProctoringWarning)
                          _summaryRow(
                            Icons.videocam_outlined,
                            'AI Proctoring',
                            'Enabled',
                            valueColor: Colors.red,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Instructions Card ────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Please Read Carefully',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _instructionItem('This test contains ${exam.questions.length} questions'),
                        _instructionItem('Total duration is ${exam.duration} minutes'),
                        _instructionItem('You cannot pause the test once started'),
                        _instructionItem('Do not switch apps or minimize during the exam'),
                        _instructionItem('Test will auto-submit after time expires'),
                        _instructionItem('Your progress is saved automatically'),
                        _instructionItem('Ensure stable internet connection'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Negative Marking Warning ─────────────────
            if (exam.negativeMarking) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Negative marking is enabled — incorrect answers will deduct marks. Only answer questions you are confident about.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade800,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Proctoring Warning ───────────────────────
            if (hasProctoringWarning) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurple.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.videocam, color: Colors.deepPurple.shade700, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'AI Proctoring Enabled',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Camera access is required for face monitoring\n'
                      '• Your face must remain visible throughout the exam\n'
                      '• Tab/app switching will be tracked and reported\n'
                      '${exam.isAudioProctoringEnabled ? '• Microphone access is required for audio monitoring\n' : ''}'
                      '${exam.strictTabSwitching ? '• Strict mode: 5 tab switches = auto-submission' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.deepPurple.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Agreement Checkbox ───────────────────────
            Container(
              decoration: BoxDecoration(
                color: _agreedToInstructions
                    ? AppColors.primary.withValues(alpha: 0.06)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _agreedToInstructions
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : Colors.grey.shade300,
                ),
              ),
              child: CheckboxListTile(
                value: _agreedToInstructions,
                onChanged: (v) => setState(() => _agreedToInstructions = v ?? false),
                title: const Text(
                  "I've read all instructions carefully and have understood them",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 20),

            // ── Action Buttons ───────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      'Back to Exams',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black54),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _agreedToInstructions ? _startExam : null,
                    icon: Icon(
                      hasProctoringWarning ? Icons.videocam : Icons.play_arrow_rounded,
                      size: 22,
                    ),
                    label: Text(
                      hasProctoringWarning ? 'Proceed to Setup' : 'Start Test',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade500,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: _agreedToInstructions ? 4 : 0,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _instructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
