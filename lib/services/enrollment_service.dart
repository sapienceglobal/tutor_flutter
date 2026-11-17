import '../config/api_config.dart';
import '../models/enrollment_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class EnrollmentService {
  static const String _endpoint = '/enrollments';

  // Enroll in course (free, online payment verified, or offline fee submission)
  static Future<Map<String, dynamic>> enrollInCourse(
    String courseId, {
    String? batchId,
    String? paymentId,
    String? note,
    String? transactionRef,
    double? declaredAmount,
  }) async {
    try {
      final token = await AuthService.getToken();

      final response = await ApiService.post(
        _endpoint,
        body: {
          'courseId': courseId,
          if (batchId != null && batchId.isNotEmpty) 'batchId': batchId,
          if (paymentId != null && paymentId.isNotEmpty) 'paymentId': paymentId,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
          if (transactionRef != null && transactionRef.trim().isNotEmpty)
            'transactionRef': transactionRef.trim(),
          if (declaredAmount != null) 'declaredAmount': declaredAmount,
        },
        token: token,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Get pending offline fee payment submissions (Tutor / Institute Admin)
  static Future<List<Map<String, dynamic>>> getOfflinePendingEnrollments() async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.get(
        '$_endpoint/offline-pending',
        token: token,
      );
      if (response['success'] == true) {
        final raw = response['enrollments'] as List? ?? const [];
        return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Approve an offline fee enrollment (Tutor / Admin)
  static Future<Map<String, dynamic>> approveOfflineEnrollment(
    String enrollmentId, {
    String? adminNote,
  }) async {
    final token = await AuthService.getToken();
    return ApiService.patch(
      '$_endpoint/$enrollmentId/approve-offline',
      body: {
        if (adminNote != null && adminNote.trim().isNotEmpty) 'adminNote': adminNote.trim(),
      },
      token: token,
    );
  }

  // Reject a pending enrollment (Tutor / Admin)
  static Future<Map<String, dynamic>> rejectEnrollment(String enrollmentId) async {
    final token = await AuthService.getToken();
    return ApiService.delete(
      '$_endpoint/$enrollmentId/reject',
      token: token,
    );
  }

  // Get my enrollments
  static Future<List<EnrollmentModel>> getMyEnrollments({
    String? status,
  }) async {
    try {
      final token = await AuthService.getToken();

      Map<String, String>? queryParams;
      if (status != null) {
        queryParams = {'status': status};
      }

      final response = await ApiService.get(
        '$_endpoint/my-enrollments',
        token: token,
        queryParams: queryParams,
      );

      if (response['success']) {
        final List<dynamic> enrollmentsJson = response['enrollments'];
        return enrollmentsJson
            .map((json) => EnrollmentModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Get enrollment by course
  static Future<EnrollmentModel?> getEnrollmentByCourse(String courseId) async {
    try {
      final token = await AuthService.getToken();

      final response = await ApiService.get(
        '$_endpoint/course/$courseId',
        token: token,
      );

      if (response['success']) {
        return EnrollmentModel.fromJson(response['enrollment']);
      }
      return null;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Get course students (Tutor)
  static Future<List<dynamic>> getCourseStudents(String courseId) async {
    try {
      final token = await AuthService.getToken();

      final response = await ApiService.get(
        '$_endpoint/students/$courseId',
        token: token,
      );

      if (response['success']) {
        return response['students'];
      }
      return [];
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Unenroll from course
  static Future<Map<String, dynamic>> unenrollFromCourse(
    String enrollmentId,
  ) async {
    try {
      final token = await AuthService.getToken();

      final response = await ApiService.delete(
        '$_endpoint/$enrollmentId',
        token: token,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ✅ NEW: Update lesson progress
  static Future<Map<String, dynamic>> updateProgress({
    required String courseId,
    required String lessonId,
    required int watchedDuration,
    bool isCompleted = false,
  }) async {
    try {
      final token = await AuthService.getToken();

      final response = await ApiService.post(
        ApiConfig.progressEndpoint,
        body: {
          'courseId': courseId,
          'lessonId': lessonId,
          'timeSpent': watchedDuration,
          'completed': isCompleted,
        },
        token: token,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ✅ NEW: Check if user is enrolled in a course
  static Future<bool> checkEnrollment(String courseId) async {
    try {
      final token = await AuthService.getToken();

      final response = await ApiService.get(
        '$_endpoint/check/$courseId',
        token: token,
      );

      return response['isEnrolled'] ?? false;
    } catch (e) {
      return false;
    }
  }
}
