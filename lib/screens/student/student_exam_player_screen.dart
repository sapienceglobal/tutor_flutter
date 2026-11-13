import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'dart:async';
import 'dart:io';

import '../../services/auth_service.dart';
import '../../services/exam_service.dart';
import '../../config/api_config.dart';
import '../../utils/constants.dart';

class StudentExamPlayerScreen extends StatefulWidget {
  final String examId;

  const StudentExamPlayerScreen({super.key, required this.examId});

  @override
  State<StudentExamPlayerScreen> createState() => _StudentExamPlayerScreenState();
}

class _StudentExamPlayerScreenState extends State<StudentExamPlayerScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  String? _errorMessage;

  // Exam Details
  dynamic _examData;
  List<dynamic> _questions = [];
  int _currentQuestionIndex = 0;
  DateTime? _startedAt;

  // Answers State
  final Map<String, Map<String, dynamic>> _userAnswers = {}; // questionId -> answer payload
  // Local state for matching question dropdowns: questionId -> { leftItem: rightItem }
  final Map<String, Map<String, String>> _matchState = {};
  // Local controllers for subjective text fields: questionId -> TextEditingController
  final Map<String, TextEditingController> _textControllers = {};

  // Timer Variables
  Timer? _countdownTimer;
  int _secondsRemaining = 0;

  // Proctoring Variables
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  AudioRecorder? _audioRecorder;
  bool _isProctoringActive = false;
  int _tabSwitchCount = 0;
  Timer? _proctoringTimer;
  String _proctoringStatus = "Initializing...";
  bool _faceDetected = false;
  int _consecutiveNoFace = 0;
  final List<Map<String, dynamic>> _proctoringEvents = [];
  String? _activeWarning;
  Timer? _warningTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startedAt = DateTime.now();
    _fetchExamAndInitProctoring();
  }

  Future<void> _cleanupProctoring() async {
    _proctoringTimer?.cancel();
    _proctoringTimer = null;
    
    if (_audioRecorder != null) {
      try {
        if (await _audioRecorder!.isRecording()) {
          await _audioRecorder!.stop();
        }
      } catch (e) {
        debugPrint("Error stopping audio recorder: $e");
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _warningTimer?.cancel();
    _cleanupProctoring();
    _cameraController?.dispose();
    _faceDetector?.close();
    _audioRecorder?.dispose();
    _textControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> _fetchExamAndInitProctoring() async {
    try {
      final res = await ExamService.getStudentExamById(widget.examId);
      if (res['success'] == true && res['exam'] != null) {
        setState(() {
          _examData = res['exam'];
          _questions = _examData['questions'] ?? [];
          
          // Initialize answer map and controllers
          for (var q in _questions) {
            final qId = q['_id'];
            final qType = q['type'] ?? q['questionType'] ?? 'MCQ';
            
            if (qType == 'subjective') {
              _textControllers[qId] = TextEditingController();
            } else if (qType == 'match') {
              _matchState[qId] = {};
            }
          }
          
          _isLoading = false;
        });

        final num durationNum = _examData['duration'] ?? 30;
        final int durationMins = durationNum.toInt();
        _startCountdownTimer(durationMins);

        // Proctoring initialization
        final bool faceProctor = _examData['isProctoringEnabled'] ?? false;
        final bool audioProctor = _examData['isAudioProctoringEnabled'] ?? false;
        if (faceProctor || audioProctor) {
          _initProctoring(faceProctor, audioProctor);
        } else {
          setState(() {
            _isProctoringActive = false;
            _proctoringStatus = "Not Required";
          });
        }
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Failed to load exam details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading exam: $e';
        _isLoading = false;
      });
    }
  }

  void _startCountdownTimer(int durationMinutes) {
    _secondsRemaining = durationMinutes * 60;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
        _autoSubmitExam(reason: "Time Expired");
      } else {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // --- Proctoring Logic ---

  Future<void> _initProctoring(bool faceProctor, bool audioProctor) async {
    try {
      // 1. Camera Init (Face Proctoring)
      if (faceProctor) {
        final cameras = await availableCameras();
        final frontCamera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front);

        _cameraController = CameraController(frontCamera, ResolutionPreset.low, enableAudio: false);
        await _cameraController!.initialize();

        _faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            enableLandmarks: true,
            enableClassification: true,
            performanceMode: FaceDetectorMode.fast,
          ),
        );
      }

      // 2. Audio Init (Audio Proctoring)
      if (audioProctor) {
        _audioRecorder = AudioRecorder();
        if (await _audioRecorder!.hasPermission()) {
          final tempDir = Directory.systemTemp;
          final path = '${tempDir.path}/exam_audio.aac';
          // Delete old file if exists
          final oldFile = File(path);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
          await _audioRecorder!.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
        }
      }

      if (mounted) {
        setState(() {
          _isProctoringActive = true;
          _proctoringStatus = "Active";
        });
        _startProctoringLoop(faceProctor, audioProctor);
      }
    } catch (e) {
      debugPrint("Proctoring Init Error: $e");
      if (mounted) {
        setState(() => _proctoringStatus = "Hardware Error");
      }
    }
  }

  void _startProctoringLoop(bool faceProctor, bool audioProctor) {
    // Run loop every 2.5 seconds matching the web's detection interval
    _proctoringTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) async {
      if (audioProctor) {
        _analyzeAudioNoise();
      }
      if (faceProctor) {
        _analyzeFaceFrame();
      }
    });
  }

  Future<void> _analyzeAudioNoise() async {
    try {
      if (_audioRecorder != null && await _audioRecorder!.isRecording()) {
        final amplitude = await _audioRecorder!.getAmplitude();
        // Normalize from [-60.0, 0.0] dB to [0.0, 100.0]
        double vol = ((amplitude.current + 60.0) / 60.0 * 100.0).clamp(0.0, 100.0);
        
        if (vol > 35.0) {
          _logProctoringEvent(
            "audio_anomaly",
            "medium",
            "Suspicious background noise or talking detected (Vol: ${vol.round()})",
          );
        }
      }
    } catch (e) {
      debugPrint("Audio Proctoring Loop Error: $e");
    }
  }

  Future<void> _analyzeFaceFrame() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final faces = await _faceDetector!.processImage(inputImage);

      // Clean up the temporary captured file immediately
      try {
        final file = File(image.path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}

      final count = faces.length;
      final bool detected = count > 0;

      if (mounted && (detected != _faceDetected)) {
        setState(() => _faceDetected = detected);
      }

      if (!detected) {
        _consecutiveNoFace++;
        if (_consecutiveNoFace >= 2) {
          _logProctoringEvent(
            "no_face",
            _consecutiveNoFace >= 4 ? "high" : "medium",
            "No face detected in camera for ${_consecutiveNoFace * 2.5}s",
          );
        }
      } else {
        _consecutiveNoFace = 0;

        if (count > 1) {
          _logProctoringEvent(
            "multiple_faces",
            "high",
            "$count faces detected in camera — possible assistance!",
          );
        } else {
          // 1 face detected, analyze head pose (yaw/pitch)
          final face = faces.first;
          final double yaw = face.headEulerAngleY ?? 0.0; // Left/Right (Degrees)
          final double pitch = face.headEulerAngleX ?? 0.0; // Up/Down (Degrees)

          if (yaw.abs() > 25.0) {
            final String direction = yaw > 0 ? "right" : "left";
            _logProctoringEvent(
              "audio_anomaly",
              "low",
              "Student looking $direction continuously",
            );
          } else if (pitch < -20.0) {
            _logProctoringEvent(
              "unauthorized_object",
              "medium",
              "Student looking down continuously (Suspected phone/book usage on desk)",
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Face Proctoring Loop Error: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _tabSwitchCount++;
      _logProctoringEvent(
        "tab_switch", 
        "medium", 
        "Student switched tab or minimized app (Switch count: $_tabSwitchCount)"
      );
      _logTabSwitch();

      // Enforce strict tab switching limit (5 tab switches)
      final bool strictTab = _examData?['strictTabSwitching'] ?? false;
      if (strictTab && _tabSwitchCount >= 5) {
        _autoSubmitExam(reason: "Strict tab limit exceeded");
      }
    }
  }

  Future<void> _logTabSwitch() async {
    final token = await AuthService.getToken();
    final apiKey = await AuthService.getApiKey();
    
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.studentExamsEndpoint}/${widget.examId}/tab-switch'),
        headers: {
          'Authorization': 'Bearer $token',
          'x-api-key': apiKey ?? '',
        },
      );
    } catch (e) {
      debugPrint("Tab Switch Log Error: $e");
    }
  }

  void _logProctoringEvent(String type, String severity, String details) {
    debugPrint("PROCTORING ALERT: [$severity] $type - $details");
    
    final event = {
      "eventType": type,
      "severity": severity,
      "timestamp": DateTime.now().toIso8601String(),
      "details": details,
      "videoTimestamp": 0,
    };
    
    _proctoringEvents.add(event);

    if (mounted) {
      setState(() {
        if (type == 'no_face') {
          _activeWarning = "⚠️ CAMERA WARNING: Keep your face fully visible in the camera frame!";
        } else if (type == 'multiple_faces') {
          _activeWarning = "🚨 MULTIPLE PERSONS: Ensure you are alone taking the exam!";
        } else if (type == 'audio_anomaly') {
          if (details.toLowerCase().contains('looking')) {
            _activeWarning = "⚠️ EYE POSITION: Focus on the screen and look at the camera!";
          } else {
            _activeWarning = "🔊 NOISE WARNING: Keep background noise or talking absolutely silent!";
          }
        } else if (type == 'unauthorized_object') {
          _activeWarning = "🚨 SUSPICIOUS POSITION: Looking down detected. Keep eyes level on the screen!";
        } else if (type == 'tab_switch') {
          _activeWarning = "🚨 WARNING: Tab/app switching is tracked! Strict limit is 5 switches.";
        } else {
          _activeWarning = "🚨 PROCTORING ALERT: $details";
        }
      });

      _warningTimer?.cancel();
      _warningTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _activeWarning = null;
          });
        }
      });
    }
  }

  Future<void> _autoSubmitExam({String? reason}) async {
    // Show blocking warning overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text("Exam Submitting", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(reason != null 
              ? "Your exam is being automatically submitted because: $reason." 
              : "Your exam time has expired. Submitting your answers now..."),
        ),
      ),
    );

    // Brief delay for readability
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      Navigator.of(context).pop(); // Dismiss warning overlay
      _executeSubmission(isAuto: true);
    }
  }

  Future<void> _confirmExit() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Exam?'),
        content: const Text('Are you sure you want to leave? Your progress will not be saved and this attempt may count as used.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continue Exam'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submitExam() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Submit Exam?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to finish and submit your exam? You cannot modify your answers after submitting.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    _executeSubmission();
  }

  Future<void> _executeSubmission({bool isAuto = false}) async {
    // Show a loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // Stop timer & cleanup proctoring cleanly
    _countdownTimer?.cancel();
    await _cleanupProctoring();

    final answersList = _userAnswers.values.toList();
    final num durationNum = _examData['duration'] ?? 30;
    final int totalDurationSeconds = durationNum.toInt() * 60;
    final int timeSpentSeconds = (totalDurationSeconds - _secondsRemaining).clamp(0, totalDurationSeconds);

    try {
      final res = await ExamService.submitExam(
        examId: widget.examId,
        answers: answersList,
        timeSpent: timeSpentSeconds,
        startedAt: _startedAt ?? DateTime.now(),
        tabSwitchCount: _tabSwitchCount,
        proctoringEvents: _proctoringEvents,
      );

      // Dismiss loading overlay
      if (mounted) Navigator.of(context).pop();

      if (res['success'] == true) {
        _showSuccessResultDialog(res);
      } else {
        _showErrorSnackBar(res['message'] ?? 'Failed to submit exam. Please try again.');
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showErrorSnackBar('Network error submitting exam: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessResultDialog(dynamic attemptData) {
    final bool showResult = _examData['showResultImmediately'] ?? true;
    
    final num rawScore = attemptData?['score'] ?? 0;
    final num rawTotal = _examData['totalMarks'] ?? 100;
    final num rawPct = attemptData?['percentage'] ?? 0.0;

    final double score = rawScore.toDouble();
    final double totalMarks = rawTotal.toDouble();
    final double pct = rawPct.toDouble();
    
    final String scoreStr = score == score.toInt() ? score.toInt().toString() : score.toStringAsFixed(2);
    final String totalMarksStr = totalMarks == totalMarks.toInt() ? totalMarks.toInt().toString() : totalMarks.toStringAsFixed(2);

    final bool isPassed = attemptData?['isPassed'] ?? false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isPassed ? Colors.green.shade50 : Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPassed ? Icons.emoji_events : Icons.assignment_turned_in_outlined, 
                    color: isPassed ? Colors.green : AppColors.primary, 
                    size: 48
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Exam Submitted!", 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 8),
                Text(
                  isPassed ? "Congratulations! You passed the exam." : "You have successfully submitted the exam.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 24),
                if (showResult) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _resultStatRow("Score", "$scoreStr / $totalMarksStr"),
                        const Divider(height: 20),
                        _resultStatRow("Percentage", "${pct.toStringAsFixed(1)}%"),
                        const Divider(height: 20),
                        _resultStatRow(
                          "Result", 
                          isPassed ? "PASSED" : "FAILED",
                          valueColor: isPassed ? Colors.green : Colors.red
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop(); // dismiss dialog
                      Navigator.of(context).pop(); // exit exam screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Go to Exams Menu", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultStatRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(
          value, 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 14, 
            color: valueColor ?? Colors.black87
          )
        ),
      ],
    );
  }

  // --- UI Layouts ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exam Portal')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.red)),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Go Back')),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _confirmExit();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: Text(_examData?['title'] ?? 'Exam Portal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmExit,
          ),
          actions: [
            // Timer displays in real-time
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _secondsRemaining < 60 ? Colors.red.shade50 : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _secondsRemaining < 60 ? Colors.red : AppColors.primary),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined, 
                    size: 16, 
                    color: _secondsRemaining < 60 ? Colors.red : AppColors.primary
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatTime(_secondsRemaining),
                    style: TextStyle(
                      color: _secondsRemaining < 60 ? Colors.red : AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            _buildProctoringIndicator(),
          ],
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildQuestionContent(),
            ),
            _buildCameraPreview(),
            if (_activeWarning != null)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 10,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _activeWarning!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _activeWarning = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildProctoringIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _isProctoringActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isProctoringActive ? Colors.green : Colors.red),
      ),
      child: Center(
        child: Text(
          _proctoringStatus,
          style: TextStyle(color: _isProctoringActive ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return const SizedBox();

    return Positioned(
      bottom: 20,
      right: 20,
      child: Container(
        width: 100,
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _faceDetected ? Colors.green : Colors.red, width: 2),
          boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  Widget _buildQuestionContent() {
    if (_questions.isEmpty) return const SizedBox();
    
    final question = _questions[_currentQuestionIndex];
    final String qId = question['_id'];
    final String type = question['type'] ?? question['questionType'] ?? 'MCQ';
    final String questionText = question['question'] ?? '';
    final String? passage = question['passage'];
    final int points = question['points'] ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            Text(
              '+$points Marks',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Passage Display
        if (passage != null && passage.isNotEmpty) ...[
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 180),
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Scrollbar(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.menu_book, size: 16, color: Colors.grey),
                        SizedBox(width: 6),
                        Text(
                          "Read Passage Context:", 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      passage,
                      style: const TextStyle(fontSize: 13, height: 1.5, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        // Question Text
        Text(
          questionText,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.4, color: Colors.black87),
        ),
        const SizedBox(height: 24),

        // Inputs depending on Type
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: _buildInputsForType(question, type, qId),
          ),
        ),
      ],
    );
  }

  Widget _buildInputsForType(dynamic question, String type, String qId) {
    if (type == 'subjective') {
      return _buildSubjectiveInput(qId);
    } else if (type == 'match') {
      return _buildMatchInput(question, qId);
    } else {
      return _buildMCQInput(question, qId);
    }
  }

  Widget _buildMCQInput(dynamic question, String qId) {
    final List<dynamic> options = question['options'] ?? [];
    final selectedAnswerMap = _userAnswers[qId];
    final int selectedIndex = selectedAnswerMap != null ? selectedAnswerMap['selectedOption'] : -1;

    return Column(
      children: List.generate(options.length, (index) {
        final option = options[index];
        final String optionText = option['text'] ?? '';
        final bool isSelected = selectedIndex == index;

        final charBullet = String.fromCharCode(65 + index); // A, B, C, D...

        return GestureDetector(
          onTap: () {
            setState(() {
              _userAnswers[qId] = {
                'questionId': qId,
                'selectedOption': index,
                'selectedOptionText': optionText,
              };
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.06) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))]
                  : [],
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      charBullet,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    optionText,
                    style: TextStyle(
                      color: isSelected ? Colors.black87 : Colors.grey[800],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: AppColors.primary, size: 20),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSubjectiveInput(String qId) {
    final controller = _textControllers[qId]!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            maxLines: 8,
            style: const TextStyle(fontSize: 14, height: 1.4),
            decoration: InputDecoration(
              hintText: "Type your detailed answer here... Your response will be securely analyzed.",
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
            ),
            onChanged: (text) {
              setState(() {
                _userAnswers[qId] = {
                  'questionId': qId,
                  'textAnswer': text,
                };
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.bottomRight,
          child: Text(
            "${controller.text.length} characters",
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchInput(dynamic question, String qId) {
    final List<dynamic> pairs = question['pairs'] ?? [];
    if (pairs.isEmpty) return const SizedBox();

    final List<String> rightOptions = pairs.map<String>((p) => (p['right'] ?? '').toString()).toList();
    final uniqueRightOptions = rightOptions.toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            "Match the items on the left with their correct pairs on the right:",
            style: TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ),
        ...List.generate(pairs.length, (index) {
          final pair = pairs[index];
          final String leftVal = pair['left'] ?? '';
          
          final currentMap = _matchState[qId] ?? {};
          final String? selectedRightVal = currentMap[leftVal];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    leftVal,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRightVal,
                        hint: Text("Select match...", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                        isExpanded: true,
                        style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold),
                        items: uniqueRightOptions.map((val) {
                          return DropdownMenuItem<String>(
                            value: val,
                            child: Text(val),
                          );
                        }).toList(),
                        onChanged: (newVal) {
                          if (newVal == null) return;
                          setState(() {
                            _matchState[qId]![leftVal] = newVal;
                            
                            final compiled = _matchState[qId]!
                                .entries
                                .map((e) => "${e.key} -> ${e.value}")
                                .join(", ");
                            
                            _userAnswers[qId] = {
                              'questionId': qId,
                              'textAnswer': compiled,
                            };
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomBar() {
    if (_questions.isEmpty) return const SizedBox();
    
    final bool isFirst = _currentQuestionIndex == 0;
    final bool isLast = _currentQuestionIndex == _questions.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: isFirst ? null : () {
              setState(() {
                _currentQuestionIndex--;
              });
            },
            icon: const Icon(Icons.arrow_back),
            color: AppColors.primary,
            disabledColor: Colors.grey.shade300,
          ),
          OutlinedButton.icon(
            onPressed: _openQuestionGridSheet,
            icon: const Icon(Icons.grid_view, size: 16),
            label: Text("${_currentQuestionIndex + 1}/${_questions.length}"),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          ElevatedButton(
            onPressed: isLast ? _submitExam : () {
              setState(() {
                _currentQuestionIndex++;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isLast ? Colors.green : AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: Text(
              isLast ? 'Submit Test' : 'Next Question',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _openQuestionGridSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("All Questions Grid", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 6),
                Text("Jump to any question quickly. Your progress is auto-saved.", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                const SizedBox(height: 20),
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _questions.length,
                    itemBuilder: (context, index) {
                      final q = _questions[index];
                      final String qId = q['_id'];
                      final bool isCurrent = _currentQuestionIndex == index;
                      final bool isAnswered = _userAnswers.containsKey(qId);
                      
                      Color boxColor = Colors.grey.shade100;
                      Color textColor = Colors.black87;
                      Border? border;

                      if (isCurrent) {
                        boxColor = AppColors.primary.withOpacity(0.1);
                        textColor = AppColors.primary;
                        border = Border.all(color: AppColors.primary, width: 2);
                      } else if (isAnswered) {
                        boxColor = Colors.green.shade50;
                        textColor = Colors.green.shade700;
                        border = Border.all(color: Colors.green.shade300);
                      }

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentQuestionIndex = index;
                          });
                          Navigator.of(ctx).pop();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: boxColor,
                            borderRadius: BorderRadius.circular(12),
                            border: border,
                          ),
                          child: Center(
                            child: Text(
                              "${index + 1}",
                              style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }
      ),
    );
  }
}
