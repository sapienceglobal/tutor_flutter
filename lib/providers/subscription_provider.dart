import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'workspace_provider.dart';

class SubscriptionProvider with ChangeNotifier {
  Map<String, dynamic> _features = {};
  String _planName = 'free';
  Map<String, dynamic> _personalSubscription = {};
  String? _role;
  String _workspaceType = 'institute';
  bool _isLoading = true;

  // AI Credit Tracking (matches web SubscriptionContext)
  int _instituteCredits = 0;
  int _instituteUsage = 0;

  Map<String, dynamic> get features => _features;
  String get planName => _planName;
  Map<String, dynamic> get personalSubscription => _personalSubscription;
  String? get role => _role;
  String get workspaceType => _workspaceType;
  bool get isPrivateStudioMode => _role == 'tutor' && _workspaceType == 'private_tutor';
  bool get isLoading => _isLoading;
  int get instituteCredits => _instituteCredits;
  int get instituteUsage => _instituteUsage;
  int get remainingCredits => (_instituteCredits - _instituteUsage).clamp(0, _instituteCredits);

  SubscriptionProvider() {
    fetchSubscriptionData();
  }

  void syncWithWorkspace({
    required Map<String, dynamic>? userMap,
    WorkspaceProvider? workspace,
  }) {
    if (userMap != null) {
      _role = userMap['role']?.toString() ?? _role;
      final pSub = userMap['personalSubscription'];
      _personalSubscription = pSub is Map ? Map<String, dynamic>.from(pSub) : {};
    }

    if (workspace != null) {
      _workspaceType = workspace.workspaceType;
    }

    if (_workspaceType == 'private_tutor') {
      if (_role == 'tutor') {
        final subFeatures = _personalSubscription['features'] is Map
            ? Map<String, dynamic>.from(_personalSubscription['features'])
            : <String, dynamic>{};
        _features = subFeatures;
        _planName = _personalSubscription['planName']?.toString() ?? 'free';
        _instituteCredits = (subFeatures['aiCreditsPerMonth'] ?? 0) is int
            ? (subFeatures['aiCreditsPerMonth'] ?? 0) as int
            : int.tryParse('${subFeatures['aiCreditsPerMonth'] ?? 0}') ?? 0;
        _instituteUsage = (subFeatures['aiUsageCount'] ?? 0) is int
            ? (subFeatures['aiUsageCount'] ?? 0) as int
            : int.tryParse('${subFeatures['aiUsageCount'] ?? 0}') ?? 0;
      } else {
        _features = {};
        _planName = 'free_student';
        _instituteCredits = 0;
        _instituteUsage = 0;
      }
      _isLoading = false;
      notifyListeners();
      return;
    }

    final Map<String, dynamic>? activeInst = workspace?.activeInstitute ??
        (userMap?['institute'] is Map
            ? Map<String, dynamic>.from(userMap!['institute'])
            : (userMap?['instituteId'] is Map
                ? Map<String, dynamic>.from(userMap!['instituteId'])
                : null));

    if (activeInst != null) {
      final instFeatures = activeInst['features'] is Map
          ? Map<String, dynamic>.from(activeInst['features'])
          : <String, dynamic>{};
      _features = instFeatures;
      _planName = activeInst['subscriptionPlan']?.toString() ?? 'free';
      final rawCredits = instFeatures['aiCreditsPerMonth'] ?? activeInst['aiUsageQuota'] ?? 0;
      final rawUsage = activeInst['aiUsageCount'] ?? 0;
      _instituteCredits = rawCredits is int ? rawCredits : int.tryParse('$rawCredits') ?? 0;
      _instituteUsage = rawUsage is int ? rawUsage : int.tryParse('$rawUsage') ?? 0;
    } else {
      _features = {};
      _planName = 'free';
      _instituteCredits = 0;
      _instituteUsage = 0;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchSubscriptionData({
    bool isSilent = false,
    WorkspaceProvider? workspace,
  }) async {
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
        final userMap = Map<String, dynamic>.from(response['user'] as Map);
        if (workspace != null && response['workspaceBootstrap'] is Map) {
          await workspace.applyBootstrap(
            Map<String, dynamic>.from(response['workspaceBootstrap'] as Map),
            userId: (userMap['_id'] ?? '').toString(),
            role: (userMap['role'] ?? 'student').toString(),
          );
        } else if (response['activeWorkspace'] is Map) {
          _workspaceType = response['activeWorkspace']['type']?.toString() ?? _workspaceType;
        }
        syncWithWorkspace(userMap: userMap, workspace: workspace);
        return;
      }
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool hasFeature(String featureKey, {bool isPersonal = false}) {
    if (_role == 'superadmin') return true;

    // Strict Policy: Students pay ₹0 and have complete, uninhibited access to all learning and AI features.
    // Subscriptions are strictly for Institutes and Tutors hosting on the platform.
    if (_role == 'student') {
      return true;
    }

    if (isPersonal || _workspaceType == 'private_tutor') {
      if (_personalSubscription.isEmpty) return false;
      final bool isActive = _personalSubscription['isActive'] == true;
      final features = _personalSubscription['features'] is Map
          ? _personalSubscription['features'] as Map
          : const {};
      return isActive && features[featureKey] == true;
    }

    return _features[featureKey] == true;
  }

  /// Call this after an AI action consumes credits to refresh quota display
  void onAIQuotaConsumed({WorkspaceProvider? workspace}) {
    fetchSubscriptionData(isSilent: true, workspace: workspace);
  }

  void clear() {
    _features = {};
    _planName = 'free';
    _personalSubscription = {};
    _role = null;
    _workspaceType = 'institute';
    _instituteCredits = 0;
    _instituteUsage = 0;
    _isLoading = false;
    notifyListeners();
  }
}

