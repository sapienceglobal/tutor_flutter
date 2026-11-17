import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/socket_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  Map<String, dynamic>? _rawUser;
  String? _token;
  Map<String, dynamic>? _workspaceBootstrap;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  Map<String, dynamic>? get rawUser => _rawUser;
  String? get token => _token;
  Map<String, dynamic>? get workspaceBootstrap => _workspaceBootstrap;
  bool get hasActiveWorkspace =>
      _workspaceBootstrap?['hasActiveWorkspace'] == true ||
      (_user?.role == 'admin' || _user?.role == 'superadmin');
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Map<String, dynamic>? _resolveBootstrap(
    Map<String, dynamic>? payload,
    Map<String, dynamic>? rawUser,
    String role,
  ) {
    if (payload != null && payload['workspaceBootstrap'] is Map) {
      return Map<String, dynamic>.from(payload['workspaceBootstrap']);
    }
    if (rawUser == null) return null;

    final instMap = rawUser['institute'] is Map
        ? Map<String, dynamic>.from(rawUser['institute'])
        : null;
    final rawInstId = rawUser['instituteId'];
    final instituteId = rawInstId is Map
        ? (rawInstId['_id'] ?? rawInstId['id'])?.toString()
        : (rawInstId?.toString() ?? instMap?['_id']?.toString());

    final hasInst = instituteId != null &&
        instituteId.isNotEmpty &&
        instituteId != 'null';
    final isTutor = role == 'tutor';

    if (!hasInst && !isTutor) return null;

    final institutes = <Map<String, dynamic>>[];
    if (hasInst) {
      institutes.add({
        'id': instituteId,
        'name': instMap?['name']?.toString() ?? 'Institute',
        'subdomain': instMap?['subdomain']?.toString() ?? '',
        'logo': instMap?['logo']?.toString() ?? '',
        'roleInInstitute': role,
        'subscriptionPlan': instMap?['subscriptionPlan']?.toString() ?? 'Free',
        'features': instMap?['features'] is Map
            ? Map<String, dynamic>.from(instMap!['features'])
            : <String, dynamic>{},
        'permissions': <String, dynamic>{},
        'isPrimary': true,
      });
    }

    return {
      'hasActiveWorkspace': hasInst || isTutor,
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
            : {'enabled': false, 'linkedTutors': <Map<String, dynamic>>[]},
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

  // Initialize - Check if user is already logged in
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      if (isLoggedIn) {
        final payload = await AuthService.getMePayload();
        final currentUser = payload != null && payload['user'] != null
            ? UserModel.fromJson(payload['user'])
            : await AuthService.getCurrentUser();
        if (currentUser != null && (currentUser.role == 'student' || currentUser.role == 'tutor')) {
          _user = currentUser;
          _rawUser = payload?['user'] is Map
              ? Map<String, dynamic>.from(payload!['user'])
              : currentUser.toJson();
          _token = await AuthService.getToken();
          _workspaceBootstrap = _resolveBootstrap(payload, _rawUser, currentUser.role);
          if (_token != null) {
            SocketService().connect(token: _token!, userName: currentUser.name);
          }
          // Register device token for push notifications
          NotificationService().registerDeviceToken(currentUser.id);
        } else {
          await AuthService.logout();
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send OTP for email registration
  Future<bool> sendOtp({
    required String email,
    String purpose = 'email-verification',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await AuthService.sendOtp(email: email, purpose: purpose);
      _isLoading = false;
      notifyListeners();
      return res['success'] == true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Verify OTP & Complete Registration with Institute/Private Tutors Join Request
  Future<bool> verifyOtpAndRegister({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String otp,
    String role = 'student',
    String purpose = 'email-verification',
    String? instituteId,
    List<String>? tutorIds,
    String? inviteToken,
    String? requestMessage,
    String? subjects,
    String? title,
    String? bio,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await AuthService.verifyOtpAndRegister(
        name: name,
        email: email,
        password: password,
        phone: phone,
        otp: otp,
        role: role,
        purpose: purpose,
        instituteId: instituteId,
        tutorIds: tutorIds,
        inviteToken: inviteToken,
        requestMessage: requestMessage,
        subjects: subjects,
        title: title,
        bio: bio,
      );

      if (response['success'] == true) {
        _user = UserModel.fromJson(response['user']);
        _rawUser = response['user'] is Map
            ? Map<String, dynamic>.from(response['user'])
            : _user?.toJson();
        _token = response['token'];
        _workspaceBootstrap = response['workspaceBootstrap'] is Map
            ? Map<String, dynamic>.from(response['workspaceBootstrap'])
            : null;
        if (_token != null) {
          SocketService().connect(token: _token!, userName: _user!.name);
        }
        NotificationService().registerDeviceToken(_user!.id);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _error = response['message'] ?? 'Registration failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register (Direct fallback / invite)
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    String role = 'student',
    String? instituteId,
    List<String>? tutorIds,
    String? inviteToken,
    String? requestMessage,
    String? subjects,
    String? title,
    String? bio,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await AuthService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
        instituteId: instituteId,
        tutorIds: tutorIds,
        inviteToken: inviteToken,
        requestMessage: requestMessage,
        subjects: subjects,
        title: title,
        bio: bio,
      );

      if (response['success']) {
        _user = UserModel.fromJson(response['user']);
        _rawUser = response['user'] is Map
            ? Map<String, dynamic>.from(response['user'])
            : _user?.toJson();
        _token = response['token'];
        _workspaceBootstrap = response['workspaceBootstrap'] is Map
            ? Map<String, dynamic>.from(response['workspaceBootstrap'])
            : null;
        if (_token != null) {
          SocketService().connect(token: _token!, userName: _user!.name);
        }
        NotificationService().registerDeviceToken(_user!.id);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await AuthService.login(
        email: email,
        password: password,
      );

      if (response['success']) {
        final userModel = UserModel.fromJson(response['user']);
        
        // Strictly allow only students and tutors
        if (userModel.role != 'student' && userModel.role != 'tutor') {
          await AuthService.logout();
          _error = 'Only students and tutors can access the mobile app. Admins please use the web dashboard.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        _user = userModel;
        _rawUser = response['user'] is Map
            ? Map<String, dynamic>.from(response['user'])
            : userModel.toJson();
        _token = response['token'];
        _workspaceBootstrap = _resolveBootstrap(response, _rawUser, userModel.role);
        if (_workspaceBootstrap == null) {
          final mePayload = await AuthService.getMePayload();
          if (mePayload != null && mePayload['user'] is Map) {
            _rawUser = Map<String, dynamic>.from(mePayload['user']);
            _workspaceBootstrap =
                _resolveBootstrap(mePayload, _rawUser, userModel.role);
          }
        }
        SocketService().connect(token: _token!, userName: userModel.name);
        // Register device token for push notifications
        NotificationService().registerDeviceToken(userModel.id);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update profile
  Future<bool> updateProfile({
    required String name,
    required String phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await AuthService.updateProfile(
        name: name,
        phone: phone,
      );

      if (response['success']) {
        _user = UserModel.fromJson(response['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update profile image
  Future<bool> updateProfileImage({
    required String profileImage,
    String? cloudinaryId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await AuthService.updateProfileImage(
        profileImage: profileImage,
        cloudinaryId: cloudinaryId,
      );

      if (response['success']) {
        _user = UserModel.fromJson(response['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update notification settings
  Future<bool> updateNotificationSettings({
    required bool email,
    required bool push,
    required bool sms,
  }) async {
    try {
      final response = await AuthService.updateNotificationSettings(
        email: email,
        push: push,
        sms: sms,
      );

      if (response['success']) {
        _user = _user?.copyWith(
          notificationSettings: NotificationSettings(
            email: email,
            push: push,
            sms: sms,
          ),
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Update language
  Future<bool> updateLanguage(String language) async {
    try {
      final response = await AuthService.updateLanguage(language: language);

      if (response['success']) {
        _user = _user?.copyWith(language: language);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Refresh user data
  Future<void> refreshUser() async {
    try {
      final payload = await AuthService.getMePayload();
      if (payload != null && payload['user'] != null) {
        _user = UserModel.fromJson(payload['user']);
        _rawUser = payload['user'] is Map
            ? Map<String, dynamic>.from(payload['user'])
            : _user?.toJson();
        _workspaceBootstrap = _resolveBootstrap(
              payload,
              _rawUser,
              _user?.role ?? 'student',
            ) ??
            _workspaceBootstrap;
      } else {
        _user = await AuthService.getCurrentUser();
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    await AuthService.logout();
    SocketService().disconnect();
    _user = null;
    _rawUser = null;
    _token = null;
    _workspaceBootstrap = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}