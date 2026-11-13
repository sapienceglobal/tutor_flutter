import 'api_service.dart';
import 'auth_service.dart';

class DiscussionService {
  static const String _endpoint = '/comments';

  /// Fetch all moderation comments (GET /api/comments/moderation)
  static Future<Map<String, dynamic>> getModerationComments({
    String? status,
    String? courseId,
    String? search,
  }) async {
    try {
      final token = await AuthService.getToken();
      final queryParams = <String, String>{};
      if (status != null && status != 'all') queryParams['status'] = status;
      if (courseId != null && courseId != 'all') queryParams['courseId'] = courseId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final url = '$_endpoint/moderation${queryString.isNotEmpty ? '?$queryString' : ''}';

      return await ApiService.get(url, token: token);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Moderate a comment (PATCH /api/comments/moderation/:commentId)
  static Future<Map<String, dynamic>> moderateComment({
    required String commentId,
    required String action,
    String? reason,
  }) async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.patch(
        '$_endpoint/moderation/$commentId',
        body: {
          'action': action,
          if (reason != null) 'reason': reason,
        },
        token: token,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Reply to a comment (POST /api/comments/:commentId/reply)
  static Future<Map<String, dynamic>> replyToComment({
    required String commentId,
    required String text,
  }) async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.post(
        '$_endpoint/$commentId/reply',
        body: {'text': text},
        token: token,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
