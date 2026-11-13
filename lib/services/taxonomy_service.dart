import 'api_service.dart';
import 'auth_service.dart';

class TaxonomyService {
  static const String _endpoint = '/taxonomy';

  /// Fetch all topics (GET /api/taxonomy/topics)
  static Future<Map<String, dynamic>> getTopics() async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.get('$_endpoint/topics', token: token);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Create a new topic (POST /api/taxonomy/topics)
  static Future<Map<String, dynamic>> createTopic({
    required String name,
    String? courseId,
  }) async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.post(
        '$_endpoint/topics',
        body: {
          'name': name,
          if (courseId != null) 'courseId': courseId,
        },
        token: token,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Fetch all skills (GET /api/taxonomy/skills)
  static Future<Map<String, dynamic>> getSkills() async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.get('$_endpoint/skills', token: token);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Create a new skill (POST /api/taxonomy/skills)
  static Future<Map<String, dynamic>> createSkill({
    required String name,
  }) async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.post(
        '$_endpoint/skills',
        body: {'name': name},
        token: token,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
