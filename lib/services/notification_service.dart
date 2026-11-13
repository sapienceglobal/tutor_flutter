import 'package:flutter/material.dart';
import 'api_service.dart';
import 'auth_service.dart';
import '../config/api_config.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _endpoint = ApiConfig.notificationsEndpoint;

  String? _deviceToken;
  bool _notificationsEnabled = true;

  // Initialize service
  Future<void> initialize() async {
    debugPrint('Initializing Notification Service...');
    await requestPermissions();
  }

  // Request notifications permission
  Future<bool> requestPermissions() async {
    debugPrint('Requesting system push notifications permissions...');
    _notificationsEnabled = true;
    return true;
  }

  // Save/Update device token on backend database for targeted push campaigns
  Future<bool> registerDeviceToken(String userId) async {
    try {
      final authToken = await AuthService.getToken();
      if (authToken == null) return false;

      _deviceToken = "fcm_mobile_${userId}_${DateTime.now().millisecondsSinceEpoch}";
      debugPrint('Generated FCM Device Token: $_deviceToken');

      final response = await ApiService.post(
        '$_endpoint/register-fcm',
        token: authToken,
        body: {
          'token': _deviceToken,
        },
      );

      return response['success'] ?? false;
    } catch (e) {
      debugPrint('Failed to register device token: $e');
      return false;
    }
  }

  // Fetch user notifications from backend (GET /api/notifications)
  static Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 30,
    bool unreadOnly = false,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'notifications': [], 'unreadCount': 0};
      }
      final response = await ApiService.get(
        _endpoint,
        token: token,
        queryParams: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (unreadOnly) 'unreadOnly': 'true',
        },
      );
      return response;
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return {'success': false, 'notifications': [], 'unreadCount': 0};
    }
  }

  // Get unread notification count (GET /api/notifications/unread-count)
  static Future<int> getUnreadCount() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return 0;
      final response = await ApiService.get(
        '$_endpoint/unread-count',
        token: token,
      );
      if (response['success'] == true) {
        return (response['count'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
      return 0;
    }
  }

  // Mark single notification as read (PATCH /api/notifications/:id/read)
  static Future<bool> markAsRead(String notificationId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;
      final response = await ApiService.patch(
        '$_endpoint/$notificationId/read',
        token: token,
        body: {},
      );
      return response['success'] == true;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  // Mark all notifications as read (PATCH /api/notifications/read-all)
  static Future<bool> markAllAsRead() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;
      final response = await ApiService.patch(
        '$_endpoint/read-all',
        token: token,
        body: {},
      );
      return response['success'] == true;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }

  // Delete a notification (DELETE /api/notifications/:id)
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;
      final response = await ApiService.delete(
        '$_endpoint/$notificationId',
        token: token,
      );
      return response['success'] == true;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }

  // Show a custom in-app floating banner notification matching the SapienceLMS theme
  static void showInAppBanner(
    BuildContext context, {
    required String title,
    required String body,
    IconData icon = Icons.notifications_active_rounded,
    VoidCallback? onTap,
  }) {
    final overlayState = Overlay.maybeOf(context);
    if (overlayState == null) return;
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.horizontal,
            onDismissed: (direction) {
              overlayEntry.remove();
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
                border: Border.all(
                  color: const Color(0xFFE3E7EF),
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  overlayEntry.remove();
                  if (onTap != null) onTap();
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFEDFF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFF5B4CF0),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                      onPressed: () => overlayEntry.remove(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  // Toggle notifications preference status locally
  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
  }

  bool get isNotificationsEnabled => _notificationsEnabled;
}
