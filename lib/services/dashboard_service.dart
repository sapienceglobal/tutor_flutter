import '../models/tutor_dashboard_stats_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class DashboardService {
  static const String _endpoint = '/dashboard';

  // Get tutor statistics
  static Future<DashboardStatsModel?> getTutorStats() async {
    try {
      print('🔄 Fetching tutor stats...');
      final token = await AuthService.getToken();

      final response = await ApiService.get(
        '$_endpoint/stats',
        token: token,
      );

      print('📥 Dashboard stats response: ${response['success']}');

      if (response['success']) {
        return DashboardStatsModel.fromJson(response['stats']);
      }
      return null;
    } catch (e) {
      print('❌ DashboardService.getTutorStats error: $e');
      throw Exception(e.toString());
    }
  }

  // Get recent activities
  static Future<Map<String, dynamic>?> getRecentActivities() async {
    try {
      final token = await AuthService.getToken();

      final response = await ApiService.get(
        '$_endpoint/activities',
        token: token,
      );

      if (response['success']) {
        return response['activities'];
      }
      return null;
    } catch (e) {
      print('❌ DashboardService.getRecentActivities error: $e');
      throw Exception(e.toString());
    }
  }

  // Get earnings overview
  static Future<Map<String, dynamic>?> getEarningsOverview() async {
    try {
      final token = await AuthService.getToken();

      final response = await ApiService.get(
        '$_endpoint/earnings',
        token: token,
      );

      if (response['success']) {
        return response['earnings'];
      }
      return null;
    } catch (e) {
      print('❌ DashboardService.getEarningsOverview error: $e');
      throw Exception(e.toString());
    }
  }

  // ✅ Get tutor students
  static Future<Map<String, dynamic>?> getTutorStudents() async {
    try {
      print('🔄 Fetching tutor students...');
      final token = await AuthService.getToken();

      final response = await ApiService.get(
        '$_endpoint/students',
        token: token,
      );

      print('📥 Students response: ${response['success']}');

      if (response['success']) {
        return {
          'totalStudents': response['totalStudents'],
          'students': response['students'],
          'byCourse': response['byCourse'],
        };
      }
      return null;
    } catch (e) {
      print('❌ DashboardService.getTutorStudents error: $e');
      throw Exception(e.toString());
    }
  }
}