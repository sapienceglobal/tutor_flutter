import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/socket_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  // Initialize - Check if user is already logged in
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      if (isLoggedIn) {
        final currentUser = await AuthService.getCurrentUser();
        if (currentUser != null && (currentUser.role == 'student' || currentUser.role == 'tutor')) {
          _user = currentUser;
          _token = await AuthService.getToken();
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

  // Register
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    String role = 'student',
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
      );

      if (response['success']) {
        _user = UserModel.fromJson(response['user']);
        _token = response['token'];
        SocketService().connect(token: _token!, userName: _user!.name);
        // Register device token for push notifications
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
        _token = response['token'];
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
      _user = await AuthService.getCurrentUser();
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
    _token = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}