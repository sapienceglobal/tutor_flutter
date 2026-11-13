import '../models/tutor_dashboard_stats_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class DashboardService {
  static const String _endpoint = '/tutor/dashboard';
  static const String _studentEndpoint = '/student/dashboard';

  // Get tutor statistics
  static Future<DashboardStatsModel?> getTutorStats() async {
    try {
      final token = await AuthService.getToken();

      final response = await ApiService.get(
        '$_endpoint/stats',
        token: token,
      );

      if (response['success'] == true && response['stats'] != null) {
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

      if (response['success'] == true) {
        return response['activities'] as Map<String, dynamic>?;
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

      if (response['success'] == true) {
        return response['earnings'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('❌ DashboardService.getEarningsOverview error: $e');
      throw Exception(e.toString());
    }
  }

  // Get tutor students
  static Future<Map<String, dynamic>?> getTutorStudents() async {
    try {
      final token = await AuthService.getToken();

      final response = await ApiService.get(
        '$_endpoint/students',
        token: token,
      );

      if (response['success'] == true) {
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

  // Get student performance report (for tutor)
  static Future<Map<String, dynamic>> getStudentPerformanceReport() async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.get(
        '$_endpoint/reports/students',
        token: token,
      );
      return response;
    } catch (e) {
      print('❌ DashboardService.getStudentPerformanceReport error: $e');
      rethrow;
    }
  }

  // Get student dashboard stats (GET /api/student/dashboard/stats)
  static Future<Map<String, dynamic>?> getStudentStats({String scope = 'all'}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;
      final response = await ApiService.get(
        '$_studentEndpoint/stats',
        token: token,
        queryParams: {'scope': scope},
      );
      if (response['success'] == true) {
        return response['stats'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('❌ DashboardService.getStudentStats error: $e');
      return null;
    }
  }

  // Get student 7-day learning activity (GET /api/student/dashboard/activity)
  static Future<List<Map<String, dynamic>>> getStudentActivity({String scope = 'all'}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return [];
      final response = await ApiService.get(
        '$_studentEndpoint/activity',
        token: token,
        queryParams: {'scope': scope},
      );
      if (response['success'] == true && response['activity'] is List) {
        return List<Map<String, dynamic>>.from(response['activity']);
      }
      return [];
    } catch (e) {
      print('❌ DashboardService.getStudentActivity error: $e');
      return [];
    }
  }
}