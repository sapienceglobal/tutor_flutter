import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/membership_service.dart';

class WorkspaceProvider with ChangeNotifier {
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _hasActiveWorkspace = false;

  String _userId = '';
  String _role = 'student';
  String _workspaceType = 'institute'; // 'institute' | 'private_tutor'
  String? _activeInstituteId;
  String? _activeTutorFilterId;

  Map<String, dynamic> _bootstrap = {};
  List<Map<String, dynamic>> _institutes = [];
  Map<String, dynamic>? _privateTuition;
  List<Map<String, dynamic>> _linkedTutors = [];
  List<Map<String, dynamic>> _pendingInstitutes = [];
  List<Map<String, dynamic>> _pendingTutors = [];
  List<Map<String, dynamic>> _rejectedInstitutes = [];
  List<Map<String, dynamic>> _rejectedTutors = [];

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get hasActiveWorkspace => _hasActiveWorkspace;
  String get role => _role;
  String get workspaceType => _workspaceType;
  bool get isInstituteWorkspace => _workspaceType == 'institute';
  bool get isPrivateWorkspace => _workspaceType == 'private_tutor';
  String? get activeInstituteId => _activeInstituteId;
  String? get activeTutorFilterId => _activeTutorFilterId;
  Map<String, dynamic> get bootstrap => _bootstrap;

  List<Map<String, dynamic>> get institutes => _institutes;
  Map<String, dynamic>? get privateTuition => _privateTuition;
  bool get canUsePrivateWorkspace =>
      _privateTuition != null && _privateTuition!['enabled'] == true;
  List<Map<String, dynamic>> get linkedTutors => _linkedTutors;
  List<Map<String, dynamic>> get pendingInstitutes => _pendingInstitutes;
  List<Map<String, dynamic>> get pendingTutors => _pendingTutors;
  List<Map<String, dynamic>> get rejectedInstitutes => _rejectedInstitutes;
  List<Map<String, dynamic>> get rejectedTutors => _rejectedTutors;

  int get workspaceCount =>
      _institutes.length + (canUsePrivateWorkspace ? 1 : 0);

  bool get showWorkspaceSwitcher => workspaceCount >= 2;

  Map<String, dynamic>? get activeInstitute {
    if (_institutes.isEmpty) return null;
    if (_activeInstituteId != null) {
      for (final inst in _institutes) {
        final id = (inst['id'] ?? inst['_id'] ?? '').toString();
        if (id == _activeInstituteId) return inst;
      }
    }
    return _institutes.first;
  }

  String? get currentInstituteName =>
      activeInstitute?['name']?.toString() ??
      (_institutes.isNotEmpty ? _institutes.first['name']?.toString() : null);

  Map<String, dynamic>? get selectedLinkedTutor {
    if (_activeTutorFilterId == null || _activeTutorFilterId!.isEmpty) {
      return null;
    }
    for (final t in _linkedTutors) {
      final id = (t['tutorId'] ?? t['_id'] ?? '').toString();
      if (id == _activeTutorFilterId) return t;
    }
    return null;
  }

  String get activeWorkspaceLabel {
    if (_workspaceType == 'institute') {
      return activeInstitute?['name']?.toString() ?? 'Institute';
    }
    if (_role == 'tutor') return 'My Private Studio';
    return 'My Private Tutors';
  }

  String get _prefsKey => 'workspace_pref_${_userId.isEmpty ? 'guest' : _userId}';

  List<Map<String, dynamic>> _castMapList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> applyBootstrap(
    Map<String, dynamic>? rawBootstrap, {
    required String userId,
    required String role,
  }) async {
    _userId = userId;
    _role = role;

    if (rawBootstrap == null) {
      _hasActiveWorkspace = role == 'admin' || role == 'superadmin';
      _isInitialized = true;
      _syncApiHeaders();
      notifyListeners();
      return;
    }

    _bootstrap = Map<String, dynamic>.from(rawBootstrap);
    final workspaces = _bootstrap['workspaces'] is Map
        ? Map<String, dynamic>.from(_bootstrap['workspaces'])
        : <String, dynamic>{};

    _institutes = _castMapList(workspaces['institutes']);
    _privateTuition = workspaces['privateTuition'] is Map
        ? Map<String, dynamic>.from(workspaces['privateTuition'])
        : null;
    _linkedTutors = _castMapList(_privateTuition?['linkedTutors']);

    final pending = _bootstrap['pendingRequests'] is Map
        ? Map<String, dynamic>.from(_bootstrap['pendingRequests'])
        : <String, dynamic>{};
    _pendingInstitutes = _castMapList(pending['institutes']);
    _pendingTutors = _castMapList(pending['tutors']);

    final rejected = _bootstrap['rejectedRequests'] is Map
        ? Map<String, dynamic>.from(_bootstrap['rejectedRequests'])
        : <String, dynamic>{};
    _rejectedInstitutes = _castMapList(rejected['institutes']);
    _rejectedTutors = _castMapList(rejected['tutors']);

    _hasActiveWorkspace = _bootstrap['hasActiveWorkspace'] == true;

    // Resolve active workspace from persisted preference or defaultWorkspace
    String? preferredType;
    String? preferredInstId;
    String? preferredTutorFilter;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_prefsKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        final saved = jsonDecode(savedJson);
        if (saved is Map) {
          preferredType = saved['type']?.toString();
          preferredInstId = saved['instituteId']?.toString();
          preferredTutorFilter = saved['tutorFilterId']?.toString();
        }
      }
    } catch (_) {}

    final bool savedInstituteValid = preferredType == 'institute' &&
        preferredInstId != null &&
        _institutes.any(
          (i) => (i['id'] ?? i['_id'] ?? '').toString() == preferredInstId,
        );
    final bool savedPrivateValid =
        preferredType == 'private_tutor' && canUsePrivateWorkspace;

    if (savedInstituteValid) {
      _workspaceType = 'institute';
      _activeInstituteId = preferredInstId;
      _activeTutorFilterId = null;
    } else if (savedPrivateValid) {
      _workspaceType = 'private_tutor';
      _activeInstituteId = null;
      final bool tutorStillActive = preferredTutorFilter != null &&
          _linkedTutors.any(
            (t) =>
                (t['tutorId'] ?? t['_id'] ?? '').toString() ==
                preferredTutorFilter,
          );
      _activeTutorFilterId = tutorStillActive ? preferredTutorFilter : null;
    } else {
      final def = _bootstrap['defaultWorkspace'] is Map
          ? Map<String, dynamic>.from(_bootstrap['defaultWorkspace'])
          : null;
      if (def != null && def['type'] == 'private_tutor' && canUsePrivateWorkspace) {
        _workspaceType = 'private_tutor';
        _activeInstituteId = null;
        _activeTutorFilterId = null;
      } else if (_institutes.isNotEmpty) {
        _workspaceType = 'institute';
        _activeInstituteId =
            (def?['instituteId'] ?? _institutes.first['id'] ?? _institutes.first['_id'])
                .toString();
        _activeTutorFilterId = null;
      } else if (canUsePrivateWorkspace) {
        _workspaceType = 'private_tutor';
        _activeInstituteId = null;
        _activeTutorFilterId = null;
      } else {
        _workspaceType = 'institute';
        _activeInstituteId = null;
        _activeTutorFilterId = null;
      }
    }

    _isInitialized = true;
    _syncApiHeaders();
    await _persistSelection();
    notifyListeners();
  }

  void _syncApiHeaders() {
    if (!_hasActiveWorkspace) {
      ApiService.clearWorkspaceHeaders();
      return;
    }
    ApiService.setWorkspaceHeaders(
      type: _workspaceType,
      instituteId: _workspaceType == 'institute' ? _activeInstituteId : null,
      tutorId: (_role == 'student' && _workspaceType == 'private_tutor')
          ? _activeTutorFilterId
          : (_role == 'tutor' && _workspaceType == 'private_tutor')
              ? (_privateTuition?['tutorId']?.toString() ?? _userId)
              : null,
    );
  }

  Future<void> _persistSelection() async {
    if (_userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode({
          'type': _workspaceType,
          'instituteId': _activeInstituteId,
          'tutorFilterId': _activeTutorFilterId,
        }),
      );
    } catch (_) {}
  }

  Future<void> switchToInstitute(String instituteId) async {
    _workspaceType = 'institute';
    _activeInstituteId = instituteId;
    _activeTutorFilterId = null;
    _syncApiHeaders();
    await _persistSelection();
    notifyListeners();

    // Sync User.instituteId on backend quietly for legacy endpoints
    try {
      await MembershipService.switchInstitute(instituteId);
    } catch (_) {}
  }

  Future<void> switchToPrivateWorkspace() async {
    if (!canUsePrivateWorkspace) return;
    _workspaceType = 'private_tutor';
    _activeInstituteId = null;
    _syncApiHeaders();
    await _persistSelection();
    notifyListeners();
  }

  Future<void> setTutorFilter(String? tutorId) async {
    _activeTutorFilterId = (tutorId != null && tutorId.isNotEmpty) ? tutorId : null;
    _syncApiHeaders();
    await _persistSelection();
    notifyListeners();
  }

  Future<bool> refreshWorkspace() async {
    _isLoading = true;
    notifyListeners();
    try {
      final payload = await AuthService.getMePayload();
      if (payload != null && payload['user'] != null) {
        final user = Map<String, dynamic>.from(payload['user'] as Map);
        final role = (user['role'] ?? 'student').toString();
        Map<String, dynamic>? bootstrap = payload['workspaceBootstrap'] is Map
            ? Map<String, dynamic>.from(payload['workspaceBootstrap'])
            : null;

        if (bootstrap == null) {
          final instMap = user['institute'] is Map
              ? Map<String, dynamic>.from(user['institute'])
              : null;
          final rawInstId = user['instituteId'];
          final instituteId = rawInstId is Map
              ? (rawInstId['_id'] ?? rawInstId['id'])?.toString()
              : (rawInstId?.toString() ?? instMap?['_id']?.toString());
          final hasInst = instituteId != null &&
              instituteId.isNotEmpty &&
              instituteId != 'null';
          final isTutor = role == 'tutor';

          if (hasInst || isTutor) {
            final institutes = <Map<String, dynamic>>[];
            if (hasInst) {
              institutes.add({
                'id': instituteId,
                'name': instMap?['name']?.toString() ?? 'Institute',
                'subdomain': instMap?['subdomain']?.toString() ?? '',
                'logo': instMap?['logo']?.toString() ?? '',
                'roleInInstitute': role,
                'subscriptionPlan':
                    instMap?['subscriptionPlan']?.toString() ?? 'Free',
                'features': instMap?['features'] is Map
                    ? Map<String, dynamic>.from(instMap!['features'])
                    : <String, dynamic>{},
                'permissions': <String, dynamic>{},
                'isPrimary': true,
              });
            }
            bootstrap = {
              'hasActiveWorkspace': true,
              'defaultWorkspace': hasInst
                  ? {
                      'type': 'institute',
                      'instituteId': instituteId,
                      'name': instMap?['name']?.toString() ?? 'Institute',
                    }
                  : {
                      'type': 'private_tutor',
                      'tutorId': null,
                      'name': 'My Private Studio',
                    },
              'workspaces': {
                'institutes': institutes,
                'privateTuition': isTutor
                    ? {'enabled': true}
                    : {
                        'enabled': false,
                        'linkedTutors': <Map<String, dynamic>>[],
                      },
              },
              'pendingRequests': {
                'institutes': <Map<String, dynamic>>[],
                'tutors': <Map<String, dynamic>>[],
              },
              'rejectedRequests': {
                'institutes': <Map<String, dynamic>>[],
                'tutors': <Map<String, dynamic>>[],
              },
            };
          }
        }

        await applyBootstrap(
          bootstrap,
          userId: (user['_id'] ?? '').toString(),
          role: role,
        );
      }
      return _hasActiveWorkspace;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    ApiService.clearWorkspaceHeaders();
    _isInitialized = false;
    _hasActiveWorkspace = false;
    _userId = '';
    _role = 'student';
    _workspaceType = 'institute';
    _activeInstituteId = null;
    _activeTutorFilterId = null;
    _bootstrap = {};
    _institutes = [];
    _privateTuition = null;
    _linkedTutors = [];
    _pendingInstitutes = [];
    _pendingTutors = [];
    _rejectedInstitutes = [];
    _rejectedTutors = [];
    notifyListeners();
  }
}

