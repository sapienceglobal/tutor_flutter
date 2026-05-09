import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class SubscriptionProvider with ChangeNotifier {
  Map<String, dynamic> _features = {};
  String _planName = '';
  String? _role;
  bool _isLoading = true;

  Map<String, dynamic> get features => _features;
  String get planName => _planName;
  String? get role => _role;
  bool get isLoading => _isLoading;

  SubscriptionProvider() {
    fetchSubscriptionData();
  }

  Future<void> fetchSubscriptionData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await ApiService.get('/auth/me', token: token);
      if (response['success'] == true && response['user'] != null) {
        final user = response['user'];
        _role = user['role'];
        if (user['instituteId'] != null) {
          _features = user['instituteId']['features'] ?? {};
          _planName = user['instituteId']['subscriptionPlan'] ?? 'Free';
        }
      }
    } catch (e) {
      print("Failed to fetch subscription context: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool hasFeature(String featureKey) {
    if (_role == 'superadmin') return true;
    return _features[featureKey] == true;
  }
}
