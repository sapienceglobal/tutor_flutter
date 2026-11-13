import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class SubscriptionProvider with ChangeNotifier {
  Map<String, dynamic> _features = {};
  String _planName = '';
  Map<String, dynamic> _personalSubscription = {};
  String? _role;
  bool _isLoading = true;
  
  // 🌟 AI Credit Tracking (matches web SubscriptionContext)
  int _instituteCredits = 0;
  int _instituteUsage = 0;

  Map<String, dynamic> get features => _features;
  String get planName => _planName;
  Map<String, dynamic> get personalSubscription => _personalSubscription;
  String? get role => _role;
  bool get isLoading => _isLoading;
  int get instituteCredits => _instituteCredits;
  int get instituteUsage => _instituteUsage;
  int get remainingCredits => (_instituteCredits - _instituteUsage).clamp(0, _instituteCredits);

  SubscriptionProvider() {
    fetchSubscriptionData();
  }

  Future<void> fetchSubscriptionData({bool isSilent = false}) async {
    if (!isSilent) {
      _isLoading = true;
      notifyListeners();
    }

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
        
        // Parse personal subscription context
        _personalSubscription = user['personalSubscription'] ?? {};
        
        if (user['instituteId'] != null) {
          final inst = user['instituteId'];
          _features = inst['features'] ?? {};
          _planName = inst['subscriptionPlan'] ?? 'Free';
          // 🌟 AI Credit tracking
          _instituteCredits = inst['features']?['aiCreditsPerMonth'] ?? inst['aiUsageQuota'] ?? 0;
          _instituteUsage = inst['aiUsageCount'] ?? 0;
        } else if (_personalSubscription.isNotEmpty && _personalSubscription['isActive'] == true) {
          _planName = _personalSubscription['planName'] ?? 'Free';
          _features = _personalSubscription['features'] ?? {};
          _instituteCredits = 0;
          _instituteUsage = 0;
        } else {
          _features = {};
          _planName = 'Free';
          _instituteCredits = 0;
          _instituteUsage = 0;
        }
      }
    } catch (e) {
      print("Failed to fetch subscription context: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool hasFeature(String featureKey, {bool isPersonal = false}) {
    if (_role == 'superadmin') return true;
    
    // Auto-fallback: if explicitly personal OR if user has no active institute plan,
    // check personal subscription features. Matches web SubscriptionContext.js behavior.
    final checkPersonal = isPersonal || _planName.isEmpty || _planName.toLowerCase() == 'free';
    if (checkPersonal) {
      if (_personalSubscription.isEmpty) return false;
      final bool isActive = _personalSubscription['isActive'] == true;
      final features = _personalSubscription['features'] ?? {};
      return isActive && features[featureKey] == true;
    }
    
    return _features[featureKey] == true;
  }
  
  /// Call this after an AI action consumes credits to refresh quota display
  void onAIQuotaConsumed() {
    fetchSubscriptionData(isSilent: true);
  }
}

