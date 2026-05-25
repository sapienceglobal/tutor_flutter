// exam_service.dart
import '../config/api_config.dart';

import '../models/exam_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class ExamService {
  static const String _endpoint = '/exams';

  // Get exams by course (Tutor)
  static Future<Map<String, dynamic>> getExamsByCourse(String courseId) async {
    try {
      final token = await AuthService.getToken();

      final response = await ApiService.get(
        '$_endpoint/course/$courseId',
        token: token,
      );

      if (response['success']) {
        final List<dynamic> examsJson = response['exams'];
        final exams = examsJson.map((json) => ExamModel.fromJson(json)).toList();

        return {
          'success': true,
          'exams': exams,
        };
      }
      return {'success': false, 'exams': []};
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Get single exam
  static Future<Map<String, dynamic>> getExamById(String id) async {
    try {
      final token = await AuthService.getToken();

      final response = await ApiService.get(
        '$_endpoint/$id',
        token: token,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Create exam (Tutor)
  static Future<Map<String, dynamic>> createExam({
    required String courseId,
    required String title,
    String? description,
    String type = 'assessment',
    String? instructions,
    required int duration,
    required int passingMarks,
    required List<Map<String, dynamic>> questions,
    bool shuffleQuestions = false,
    bool shuffleOptions = false,
    bool showResultImmediately = false,
    bool showCorrectAnswers = true,
    bool allowRetake = false,
    int maxAttempts = 1,
    bool isProctoringEnabled = false,
    bool isAudioProctoringEnabled = false,
    bool strictTabSwitching = false,
    bool negativeMarking = false,
    bool hideSolutions = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final token = await AuthService.getToken();

      final response = await ApiService.post(
        _endpoint,
        body: {
          'courseId': courseId,
          'title': title,
          if (description != null) 'description': description,
          'type': type,
          if (instructions != null) 'instructions': instructions,
          'duration': duration,
          'passingMarks': passingMarks,
          'questions': questions,
          'shuffleQuestions': shuffleQuestions,
          'shuffleOptions': shuffleOptions,
          'showResultImmediately': showResultImmediately,
          'showCorrectAnswers': showCorrectAnswers,
          'allowRetake': allowRetake,
          'maxAttempts': maxAttempts,
          'isProctoringEnabled': isProctoringEnabled,
          'isAudioProctoringEnabled': isAudioProctoringEnabled,
          'strictTabSwitching': strictTabSwitching,
          'negativeMarking': negativeMarking,
          'hideSolutions': hideSolutions,
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
        },
        token: token,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Update exam (Tutor)
  static Future<Map<String, dynamic>> updateExam({
    required String id,
    Map<String, dynamic>? updates,
  }) async {
    try {
      final token = await AuthService.getToken();

      final response = await ApiService.patch(
        '$_endpoint/$id',
        body: updates ?? {},
        token: token,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Delete exam (Tutor)
  static Future<Map<String, dynamic>> deleteExam(String id) async {
    try {
      final token = await AuthService.getToken();

      final response = await ApiService.delete(
        '$_endpoint/$id',
        token: token,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Submit exam (Student)
  static Future<Map<String, dynamic>> submitExam({
    required String examId,
    required List<Map<String, dynamic>> answers,
    required int timeSpent,
    required DateTime startedAt,
    int tabSwitchCount = 0,
    List<Map<String, dynamic>> proctoringEvents = const [],
  }) async {
    try {
      final token = await AuthService.getToken();

      final response = await ApiService.post(
        '/student/exams/$examId/submit',
        body: {
          'answers': answers,
          'timeSpent': timeSpent,
          'startedAt': startedAt.toIso8601String(),
          'tabSwitchCount': tabSwitchCount,
          'proctoringEvents': proctoringEvents,
        },
        token: token,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Get all exams for student
  static Future<Map<String, dynamic>> getAllStudentExams({String? scope}) async {
    try {
      final token = await AuthService.getToken();

      Map<String, String>? queryParams;
      if (scope != null) {
        queryParams = {'scope': scope};
      }

      final response = await ApiService.get(
        '${ApiConfig.studentExamsEndpoint}/all',
        token: token,
        queryParams: queryParams,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Get exam details for student (taking)
  static Future<Map<String, dynamic>> getStudentExamById(String id) async {
    try {
      final token = await AuthService.getToken();

      final response = await ApiService.get(
        '/student/exams/$id',
        token: token,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Check if student can attempt
  static Future<Map<String, dynamic>> checkCanAttempt(String id) async {
    try {
      final token = await AuthService.getToken();

      final response = await ApiService.get(
        '/student/exams/$id/can-attempt',
        token: token,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Get Attempt Details
  static Future<Map<String, dynamic>> getAttemptDetails(String attemptId) async {
    try {
      final token = await AuthService.getToken();

      final response = await ApiService.get(
        '/student/exams/attempt/$attemptId',
        token: token,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}