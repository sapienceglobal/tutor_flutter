import 'api_service.dart';
import 'auth_service.dart';

class AIService {
  static const String _endpoint = '/ai';

  // Generate questions using AI
  static Future<Map<String, dynamic>> generateQuestions({
    required String topic,
    int count = 5,
    String difficulty = 'medium',
  }) async {
    try {
      final token = await AuthService.getToken();

      final response = await ApiService.post(
        '$_endpoint/generate-questions',
        body: {
          'topic': topic,
          'count': count,
          'difficulty': difficulty,
        },
        token: token,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Generate quiz for specific lesson
  static Future<Map<String, dynamic>> generateLessonQuiz({
    required String lessonTitle,
    String? lessonDescription,
    int count = 5,
    String difficulty = 'medium',
    String? customInstructions,
  }) async {
    try {
      final token = await AuthService.getToken();

      final response = await ApiService.post(
        '$_endpoint/generate-lesson-quiz',
        body: {
          'lessonTitle': lessonTitle,
          if (lessonDescription != null) 'lessonDescription': lessonDescription,
          'count': count,
          'difficulty': difficulty,
          if (customInstructions != null)
            'customInstructions': customInstructions,
        },
        token: token,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Get Chat Sessions
  static Future<Map<String, dynamic>> getChatSessions() async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.get(
        '$_endpoint/chat-sessions',
        token: token,
      );
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Create Chat Session
  static Future<Map<String, dynamic>> createChatSession({
    required String title,
    String? initialMessage,
    String? courseId,
    String? persona,
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.post(
        '$_endpoint/chat-sessions',
        body: {
          'title': title,
          if (initialMessage != null) 'initialMessage': initialMessage,
          if (courseId != null) 'courseId': courseId,
          if (persona != null) 'persona': persona,
        },
        token: token,
      );
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Delete Chat Session
  static Future<Map<String, dynamic>> deleteChatSession(String sessionId) async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.delete(
        '$_endpoint/chat-sessions/$sessionId',
        token: token,
      );
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Get Chat Session By ID
  static Future<Map<String, dynamic>> getChatSessionById(String sessionId) async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.get(
        '$_endpoint/chat-sessions/$sessionId',
        token: token,
      );
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Add Message to Chat Session
  static Future<Map<String, dynamic>> addMessageToChatSession({
    required String sessionId,
    required String message,
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.post(
        '$_endpoint/chat-sessions/$sessionId/message',
        body: {
          'message': message,
        },
        token: token,
      );
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ── STUDENT SIDE AI ENDPOINTS ──

  static Future<Map<String, dynamic>> getStudentSharedNotes() async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.get('$_endpoint/student/shared-notes', token: token);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> getStudentLectureSummaries() async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.get('$_endpoint/student/lecture-summaries', token: token);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> getStudentStudyPlans() async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.get('$_endpoint/student/study-plans', token: token);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> getStudentWeakTopics() async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.get('$_endpoint/student/weak-topics', token: token);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> generateStudentStudyPlan({
    required String targetExam,
    required int durationDays,
    String? focusArea,
  }) async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.post(
        '$_endpoint/generate-study-plan',
        body: {
          'targetExam': targetExam,
          'durationDays': durationDays,
          if (focusArea != null) 'focusArea': focusArea,
        },
        token: token,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ── TUTOR SIDE AI ENDPOINTS ──

  static Future<Map<String, dynamic>> getTutorAIDashboardStats() async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.get('$_endpoint/tutor-dashboard-stats', token: token);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> getWeakTopics() async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.get('$_endpoint/weak-topics', token: token);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> getDropoutRisk() async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.get('$_endpoint/dropout-risk', token: token);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> getProctoringAlerts() async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.get('$_endpoint/proctoring/alerts', token: token);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> getRecentReports() async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.get('$_endpoint/report-gen/recent', token: token);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> generateReport({
    required String studentId,
  }) async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.post(
        '$_endpoint/report-gen/generate',
        body: {'studentId': studentId},
        token: token,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> simplifyNotes({
    required String notesTitle,
    required String content,
  }) async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.post(
        '$_endpoint/simplify-notes',
        body: {
          'title': notesTitle,
          'content': content,
        },
        token: token,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> generateLectureSummary({
    required String lectureTitle,
    required String content,
  }) async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.post(
        '$_endpoint/lecture-summary/generate',
        body: {
          'title': lectureTitle,
          'content': content,
        },
        token: token,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> checkSubjectiveAnswer({
    required String question,
    required String studentAnswer,
    required String modelAnswer,
  }) async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.post(
        '$_endpoint/subjective-check',
        body: {
          'question': question,
          'studentAnswer': studentAnswer,
          'modelAnswer': modelAnswer,
        },
        token: token,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> checkPlagiarism({
    required String content,
  }) async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.post(
        '$_endpoint/plagiarism-check',
        body: {'content': content},
        token: token,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> draftNotification({
    required String topic,
    required String targetAudience,
  }) async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.post(
        '$_endpoint/draft-notification',
        body: {
          'topic': topic,
          'targetAudience': targetAudience,
        },
        token: token,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}