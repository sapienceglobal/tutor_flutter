import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:record/record.dart';
import 'dart:async';
import 'dart:io';

import '../../models/exam_model.dart';
import '../../utils/constants.dart';
import 'student_exam_player_screen.dart';

class ExamSetupScreen extends StatefulWidget {
  final String examId;
  final ExamModel exam;

  const ExamSetupScreen({
    super.key,
    required this.examId,
    required this.exam,
  });

  @override
  State<ExamSetupScreen> createState() => _ExamSetupScreenState();
}

class _ExamSetupScreenState extends State<ExamSetupScreen> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  final AudioRecorder _audioRecorder = AudioRecorder();

  // Verification Checklist State
  bool _cameraPermission = false;
  bool _micPermission = false;
  bool _faceAligned = false;
  bool _audioChecked = false;
  bool _isChecking = true;

  String _verificationMessage = "Starting system diagnostics...";
  bool _hasInitialDiagnostics = false;

  Timer? _verificationTimer;
  bool _isProcessingFrame = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _cameraController?.dispose();
    _faceDetector?.close();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _runDiagnostics() async {
    try {
      // 1. Camera Access
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _cameraPermission = true;
          _verificationMessage = "Camera access granted. Detecting face...";
        });
      }

      // 2. Microphone Access (If audio proctoring is enabled)
      if (widget.exam.isAudioProctoringEnabled) {
        final hasMic = await _audioRecorder.hasPermission();
        if (mounted) {
          setState(() {
            _micPermission = hasMic;
            _audioChecked = hasMic;
            if (!hasMic) {
              _verificationMessage = "Please grant microphone permissions to proceed.";
            }
          });
        }
      } else {
        setState(() {
          _micPermission = true;
          _audioChecked = true;
        });
      }

      // 3. Face Detector Init
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,
          enableClassification: true,
          performanceMode: FaceDetectorMode.fast,
        ),
      );

      setState(() {
        _hasInitialDiagnostics = true;
      });

      // 4. Start Real-time Face check loop (every 1.5 seconds)
      _verificationTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
        if (_cameraPermission && _micPermission) {
          _checkFaceAlignment();
        }
      });

    } catch (e) {
      if (mounted) {
        setState(() {
          _verificationMessage = "Diagnostics failed: Check device permissions.";
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _checkFaceAlignment() async {
    if (_isProcessingFrame || _cameraController == null || !_cameraController!.value.isInitialized) return;
    _isProcessingFrame = true;

    try {
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final faces = await _faceDetector!.processImage(inputImage);

      // Clean file immediately
      try {
        final file = File(image.path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}

      final count = faces.length;
      bool isGood = false;
      String msg = "Position your face inside the circle.";

      if (count == 0) {
        msg = "No face detected. Align your face clearly in the frame.";
      } else if (count > 1) {
        msg = "Multiple faces detected. Ensure you are alone.";
      } else {
        final face = faces.first;
        final yaw = face.headEulerAngleY ?? 0.0;
        final pitch = face.headEulerAngleX ?? 0.0;

        if (yaw.abs() > 15.0) {
          msg = "Look straight into the camera.";
        } else if (pitch.abs() > 15.0) {
          msg = "Adjust camera. Keep eyes leveled.";
        } else {
          isGood = true;
          msg = "Verification successful! Press Start below.";
        }
      }

      if (mounted) {
        setState(() {
          _faceAligned = isGood;
          _verificationMessage = msg;
          _isChecking = false;
        });
      }
    } catch (e) {
      debugPrint("Pre-Verification Frame Error: $e");
    } finally {
      _isProcessingFrame = false;
    }
  }

  void _proceedToExam() async {
    // Stop local camera before pushing so that PlayerScreen can initialize cleanly!
    _verificationTimer?.cancel();
    await _cameraController?.dispose();
    _cameraController = null;
    await _faceDetector?.close();
    _faceDetector = null;

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => StudentExamPlayerScreen(examId: widget.examId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool allChecksPassed = _cameraPermission && _micPermission && _faceAligned && _audioChecked;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('AI Proctoring Setup', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Scanner circular preview
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulsing circular glow
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: _faceAligned ? Colors.green : AppColors.primary,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_faceAligned ? Colors.green : AppColors.primary).withValues(alpha: 0.25),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    // Live camera window
                    ClipOval(
                      child: SizedBox(
                        width: 236,
                        height: 236,
                        child: (_hasInitialDiagnostics && _cameraController != null && _cameraController!.value.isInitialized)
                            ? CameraPreview(_cameraController!)
                            : const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                    // Scanning line visual effect (animated scanning)
                    if (!_faceAligned && _cameraPermission)
                      const Positioned(
                        child: _ScanningLineEffect(),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Realtime Feedback Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _faceAligned ? Colors.green.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _faceAligned ? Colors.green.shade200 : Colors.blue.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _faceAligned ? Icons.verified : Icons.info_outline,
                      color: _faceAligned ? Colors.green.shade700 : Colors.blue.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _verificationMessage,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _faceAligned ? Colors.green.shade900 : Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Checklist Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "System Diagnostics Checklist",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _checkRow("Camera Access Allowed", _cameraPermission),
                    if (widget.exam.isAudioProctoringEnabled)
                      _checkRow("Microphone Access Allowed", _micPermission),
                    _checkRow("Face Alignment Detected", _faceAligned),
                    if (widget.exam.isAudioProctoringEnabled)
                      _checkRow("Background Sound Capture Ready", _audioChecked),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: allChecksPassed ? _proceedToExam : null,
                  icon: const Icon(Icons.lock_open, size: 20),
                  label: const Text(
                    "Start Secure Exam",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: allChecksPassed ? 6 : 0,
                    shadowColor: Colors.green.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _checkRow(String text, bool isChecked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isChecked ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                color: isChecked ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanningLineEffect extends StatefulWidget {
  const _ScanningLineEffect();

  @override
  State<_ScanningLineEffect> createState() => _ScanningLineEffectState();
}

class _ScanningLineEffectState extends State<_ScanningLineEffect> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 10.0, end: 220.0).animate(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          top: _animation.value,
          left: 10,
          right: 10,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
