import 'api_service.dart';
import 'auth_service.dart';

class MembershipService {
  static const String _endpoint = '/membership';

  /// Get list of memberships (GET /api/membership/my-institutes)
  static Future<Map<String, dynamic>> getMyInstitutes() async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.get('$_endpoint/my-institutes', token: token);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Switch active institute (POST /api/membership/switch-institute)
  static Future<Map<String, dynamic>> switchInstitute(String instituteId) async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.post(
        '$_endpoint/switch-institute',
        body: {'instituteId': instituteId},
        token: token,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Get pending & rejected membership requests for current user
  static Future<Map<String, dynamic>> getMyRequests() async {
    final token = await AuthService.getToken();
    return ApiService.get('$_endpoint/my-requests', token: token);
  }

  /// Submit self-join request to an Institute (Student or Tutor)
  static Future<Map<String, dynamic>> requestJoin({
    required String instituteId,
    String? roleInInstitute,
    String? requestedBatchId,
    String? requestMessage,
  }) async {
    final token = await AuthService.getToken();
    return ApiService.post(
      '$_endpoint/request-join',
      body: {
        'instituteId': instituteId,
        if (roleInInstitute != null && roleInInstitute.isNotEmpty)
          'roleInInstitute': roleInInstitute,
        if (requestedBatchId != null && requestedBatchId.isNotEmpty)
          'requestedBatchId': requestedBatchId,
        if (requestMessage != null && requestMessage.trim().isNotEmpty)
          'requestMessage': requestMessage.trim(),
      },
      token: token,
    );
  }

  /// Accept an institute invite code/token
  static Future<Map<String, dynamic>> acceptInvite(String inviteToken) async {
    final token = await AuthService.getToken();
    return ApiService.post(
      '$_endpoint/accept-invite',
      body: {'token': inviteToken.trim()},
      token: token,
    );
  }

  /// Leave an active institute
  static Future<Map<String, dynamic>> leaveInstitute(String instituteId) async {
    final token = await AuthService.getToken();
    return ApiService.delete('$_endpoint/leave/$instituteId', token: token);
  }

  /// Generate Invite Link token (POST /api/membership/generate-invite)
  static Future<Map<String, dynamic>> generateInvite({
    required String instituteId,
    required String roleInInstitute,
    Map<String, dynamic>? permissions,
  }) async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.post(
        '$_endpoint/generate-invite',
        body: {
          'instituteId': instituteId,
          'roleInInstitute': roleInInstitute,
          if (permissions != null) 'permissions': permissions,
        },
        token: token,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Get pending membership join requests for an institute (Admin/Tutor review)
  static Future<Map<String, dynamic>> getInstituteRequests({
    String? instituteId,
    String status = 'pending',
    String? role,
  }) async {
    final token = await AuthService.getToken();
    final url = instituteId != null && instituteId.isNotEmpty
        ? '$_endpoint/institute/$instituteId/requests'
        : '$_endpoint/requests';
    return ApiService.get(
      url,
      token: token,
      queryParams: {
        'status': status,
        if (role != null && role.isNotEmpty) 'role': role,
      },
    );
  }

  /// Approve a student or tutor membership request
  static Future<Map<String, dynamic>> approveMembership(
    String membershipId, {
    Map<String, dynamic>? permissions,
  }) async {
    final token = await AuthService.getToken();
    return ApiService.put(
      '$_endpoint/$membershipId/approve',
      body: {
        if (permissions != null) 'permissions': permissions,
      },
      token: token,
    );
  }

  /// Reject a student or tutor membership request
  static Future<Map<String, dynamic>> rejectMembership(
    String membershipId, {
    String? reason,
  }) async {
    final token = await AuthService.getToken();
    return ApiService.put(
      '$_endpoint/$membershipId/reject',
      body: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
      token: token,
    );
  }

  /// Withdraw / Cancel a pending membership request by applicant
  static Future<Map<String, dynamic>> withdrawJoinRequest(String membershipId) async {
    final token = await AuthService.getToken();
    return ApiService.delete(
      '$_endpoint/requests/$membershipId/withdraw',
      token: token,
    );
  }
}

