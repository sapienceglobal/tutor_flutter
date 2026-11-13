import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';

class CourseProvider with ChangeNotifier {
  List<CourseModel> _courses = [];
  List<CourseModel> _myCourses = [];
  List<CourseModel> _filteredCourses = [];
  bool _isLoading = false;
  String? _error;

  List<CourseModel> get courses =>
      _filteredCourses.isEmpty ? _courses : _filteredCourses;
  List<CourseModel> get myCourses => _myCourses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all courses
  Future<void> fetchCourses({
    String? categoryId,
    String? level,
    bool? isFree,
    String? search,
    String? tutorId,
    String? scope,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📱 CourseProvider: Fetching courses with scope: $scope...');
      _courses = await CourseService.getAllCourses(
        categoryId: categoryId,
        level: level,
        isFree: isFree,
        search: search,
        tutorId: tutorId,
        scope: scope,
      );
      _filteredCourses = [];
      print('✅ CourseProvider: ${_courses.length} courses loaded');
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      print('❌ CourseProvider: Error - $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch my courses (Tutor)
  Future<void> fetchMyCourses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📱 CourseProvider: Fetching my courses...');
      _myCourses = await CourseService.getMyCourses();
      print('✅ CourseProvider: ${_myCourses.length} my courses loaded');
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      print('❌ CourseProvider: Error - $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search courses locally
  void searchCourses(String query) {
    if (query.isEmpty) {
      _filteredCourses = [];
    } else {
      _filteredCourses = _courses
          .where((course) =>
              course.title.toLowerCase().contains(query.toLowerCase()) ||
              course.description.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  // Filter by level
  void filterByLevel(String level) {
    if (level.isEmpty || level == 'all') {
      _filteredCourses = [];
    } else {
      _filteredCourses =
          _courses.where((course) => course.level == level).toList();
    }
    notifyListeners();
  }

  // Filter by price
  void filterByPrice(bool showFreeOnly) {
    if (showFreeOnly) {
      _filteredCourses = _courses.where((course) => course.isFree).toList();
    } else {
      _filteredCourses = [];
    }
    notifyListeners();
  }

  // Get course by ID
  CourseModel? getCourseById(String id) {
    try {
      return _courses.firstWhere((course) => course.id == id);
    } catch (e) {
      return null;
    }
  }

  // Create course (Tutor)
  Future<bool> createCourse({
    required String title,
    required String description,
    required String categoryId,
    String? thumbnail,
    double price = 0,
    String level = 'beginner',
    double duration = 0,
    String language = 'English',
    List<Map<String, dynamic>>? modules,
    List<String>? requirements,
    List<String>? whatYouWillLearn,
    bool requireApproval = false,
    int maxStudents = 0,
    String visibility = 'institute',
    Map<String, dynamic>? audience,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await CourseService.createCourse(
        title: title,
        description: description,
        categoryId: categoryId,
        thumbnail: thumbnail,
        price: price,
        level: level,
        duration: duration,
        language: language,
        modules: modules,
        requirements: requirements,
        whatYouWillLearn: whatYouWillLearn,
        requireApproval: requireApproval,
        maxStudents: maxStudents,
        visibility: visibility,
        audience: audience,
      );

      if (response['success']) {
        await fetchMyCourses();
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

  // Update course (Tutor)
  Future<bool> updateCourse({
    required String id,
    Map<String, dynamic>? updates,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await CourseService.updateCourse(
        id: id,
        updates: updates,
      );

      if (response['success']) {
        await fetchMyCourses();
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

  // Delete course (Tutor)
  Future<bool> deleteCourse(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await CourseService.deleteCourse(id);

      if (response['success']) {
        await fetchMyCourses();
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

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _filteredCourses = [];
    notifyListeners();
  }
}