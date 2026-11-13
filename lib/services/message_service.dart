import '../services/api_service.dart';

class MessageService {
  // ── Get all conversations ──
  static Future<Map<String, dynamic>> getConversations({required String token}) async {
    return ApiService.get('/messages/conversations', token: token);
  }

  // ── Get messages with a specific partner ──
  static Future<Map<String, dynamic>> getConversationMessages({
    required String token,
    required String partnerId,
  }) async {
    return ApiService.get('/messages/conversations/$partnerId', token: token);
  }

  // ── Send a message ──
  static Future<Map<String, dynamic>> sendMessage({
    required String token,
    required String partnerId,
    required String body,
    String? courseId,
  }) async {
    return ApiService.post(
      '/messages',
      body: {
        'partnerId': partnerId,
        'body': body,
        if (courseId != null) 'courseId': courseId,
      },
      token: token,
    );
  }

  // ── Mark conversation as read ──
  static Future<Map<String, dynamic>> markAsRead({
    required String token,
    required String partnerId,
  }) async {
    return ApiService.patch(
      '/messages/conversations/$partnerId/read',
      body: {},
      token: token,
    );
  }
}
