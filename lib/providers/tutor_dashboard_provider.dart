import 'package:flutter/material.dart';
import '../models/tutor_dashboard_stats_model.dart';
import '../services/notification_service.dart';
import '../services/tutor_dashboard_service.dart';

class DashboardProvider with ChangeNotifier {
  DashboardStatsModel? _stats;
  List<Map<String, dynamic>> _recentEnrollments = [];
  List<Map<String, dynamic>> _recentAppointments = [];
  List<Map<String, dynamic>> _monthlyEarnings = [];
  List<Map<String, dynamic>> _earningsByCourse = [];
  int _unreadNotifications = 0;
  bool _isLoading = false;
  String? _error;

  DashboardStatsModel? get stats => _stats;
  List<Map<String, dynamic>> get recentEnrollments => _recentEnrollments;
  List<Map<String, dynamic>> get recentAppointments => _recentAppointments;
  List<Map<String, dynamic>> get monthlyEarnings => _monthlyEarnings;
  List<Map<String, dynamic>> get earningsByCourse => _earningsByCourse;
  int get unreadNotifications => _unreadNotifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch dashboard statistics, real activities, earnings, and unread count in parallel
  Future<void> fetchStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>([
        DashboardService.getTutorStats(),
        DashboardService.getRecentActivities().catchError((_) => null),
        DashboardService.getEarningsOverview().catchError((_) => null),
        NotificationService.getUnreadCount().catchError((_) => 0),
      ]);

      _stats = results[0] as DashboardStatsModel?;

      final activities = results[1] as Map<String, dynamic>?;
      if (activities != null) {
        final rawEnrollments = activities['enrollments'];
        if (rawEnrollments is List) {
          _recentEnrollments = rawEnrollments
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        final rawAppointments = activities['appointments'];
        if (rawAppointments is List) {
          _recentAppointments = rawAppointments
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }

      final earnings = results[2] as Map<String, dynamic>?;
      if (earnings != null) {
        final rawMonthly = earnings['monthly'];
        if (rawMonthly is List) {
          _monthlyEarnings = rawMonthly
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        final rawByCourse = earnings['byCourse'];
        if (rawByCourse is List) {
          _earningsByCourse = rawByCourse
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }

      _unreadNotifications = (results[3] as int?) ?? 0;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
