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
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.post(
        '$_endpoint/chat-sessions',
        body: {
          'title': title,
          if (initialMessage != null) 'initialMessage': initialMessage,
        },
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
}