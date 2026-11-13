import 'api_service.dart';
import 'auth_service.dart';

class QuestionBankService {
  static const String _endpoint = '/question-bank/questions';

  // Get all questions from the question bank
  static Future<Map<String, dynamic>> getQuestions({
    String? type,
    String? difficulty,
    String? search,
  }) async {
    try {
      final token = await AuthService.getToken();
      final queryParams = <String, String>{};
      
      if (type != null && type != 'all') {
        queryParams['type'] = type;
      }
      if (difficulty != null && difficulty != 'all') {
        queryParams['difficulty'] = difficulty;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await ApiService.get(
        _endpoint,
        token: token,
        queryParams: queryParams,
      );
      return response;
    } catch (e) {
      print('❌ QuestionBankService.getQuestions error: $e');
      rethrow;
    }
  }

  // Create a new question
  static Future<Map<String, dynamic>> createQuestion(Map<String, dynamic> questionData) async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.post(
        _endpoint,
        body: questionData,
        token: token,
      );
      return response;
    } catch (e) {
      print('❌ QuestionBankService.createQuestion error: $e');
      rethrow;
    }
  }

  // Update an existing question
  static Future<Map<String, dynamic>> updateQuestion(String id, Map<String, dynamic> questionData) async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.patch(
        '$_endpoint/$id',
        body: questionData,
        token: token,
      );
      return response;
    } catch (e) {
      print('❌ QuestionBankService.updateQuestion error: $e');
      rethrow;
    }
  }

  // Delete a question
  static Future<Map<String, dynamic>> deleteQuestion(String id) async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.delete(
        '$_endpoint/$id',
        token: token,
      );
      return response;
    } catch (e) {
      print('❌ QuestionBankService.deleteQuestion error: $e');
      rethrow;
    }
  }

  // Get all comprehension passages
  static Future<Map<String, dynamic>> getComprehensions() async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.get(
        '/question-bank/comprehensions',
        token: token,
      );
      return response;
    } catch (e) {
      print('❌ QuestionBankService.getComprehensions error: $e');
      rethrow;
    }
  }

  // Create a new comprehension passage
  static Future<Map<String, dynamic>> createComprehension({
    required String title,
    required String content,
    List<dynamic> questions = const [],
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.post(
        '/question-bank/comprehensions',
        body: {
          'title': title,
          'content': content,
          'questions': questions,
        },
        token: token,
      );
      return response;
    } catch (e) {
      print('❌ QuestionBankService.createComprehension error: $e');
      rethrow;
    }
  }
}
