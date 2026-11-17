import 'api_service.dart';
import 'auth_service.dart';

class TutorLinkService {
  static const String _endpoint = '/tutor-links';

  /// Student searches & requests one or multiple Private Tutors
  static Future<Map<String, dynamic>> requestTutorLinks({
    required List<String> tutorIds,
    String? requestMessage,
    List<String>? subjects,
  }) async {
    final token = await AuthService.getToken();
    return ApiService.post(
      '$_endpoint/request',
      body: {
        'tutorIds': tutorIds,
        if (requestMessage != null && requestMessage.trim().isNotEmpty)
          'requestMessage': requestMessage.trim(),
        if (subjects != null && subjects.isNotEmpty) 'subjects': subjects,
      },
      token: token,
    );
  }

  /// Student gets active, pending, and rejected private tutor connections
  static Future<Map<String, dynamic>> getMyTutors({String? status}) async {
    final token = await AuthService.getToken();
    return ApiService.get(
      '$_endpoint/my-tutors',
      token: token,
      queryParams: status != null && status.isNotEmpty ? {'status': status} : null,
    );
  }

  /// Student withdraws pending request or disconnects an active tutor link
  static Future<Map<String, dynamic>> removeTutorLink(String linkId) async {
    final token = await AuthService.getToken();
    return ApiService.delete(
      '$_endpoint/$linkId',
      token: token,
    );
  }

  /// Tutor lists private student join requests & active roster
  static Future<Map<String, dynamic>> getTutorStudentRequests({String status = 'all'}) async {
    final token = await AuthService.getToken();
    return ApiService.get(
      '$_endpoint/students',
      token: token,
      queryParams: {'status': status},
    );
  }

  /// Tutor approves a private student join request
  static Future<Map<String, dynamic>> approveStudentLink(String linkId) async {
    final token = await AuthService.getToken();
    return ApiService.put(
      '$_endpoint/$linkId/approve',
      body: {},
      token: token,
    );
  }

  /// Tutor rejects a private student join request
  static Future<Map<String, dynamic>> rejectStudentLink(
    String linkId, {
    String? rejectionReason,
  }) async {
    final token = await AuthService.getToken();
    return ApiService.put(
      '$_endpoint/$linkId/reject',
      body: {
        if (rejectionReason != null && rejectionReason.trim().isNotEmpty)
          'rejectionReason': rejectionReason.trim(),
      },
      token: token,
    );
  }

  /// Tutor suspends/unlinks an active private student
  static Future<Map<String, dynamic>> suspendStudentLink(String linkId) async {
    final token = await AuthService.getToken();
    return ApiService.put(
      '$_endpoint/$linkId/suspend',
      body: {},
      token: token,
    );
  }

  /// Tutor manually links an existing registered student by email into Private Studio
  static Future<Map<String, dynamic>> addPrivateStudentByEmail({
    required String email,
    List<String>? subjects,
  }) async {
    final token = await AuthService.getToken();
    return ApiService.post(
      '$_endpoint/add-student',
      body: {
        'email': email.trim(),
        if (subjects != null && subjects.isNotEmpty) 'subjects': subjects,
      },
      token: token,
    );
  }
}

