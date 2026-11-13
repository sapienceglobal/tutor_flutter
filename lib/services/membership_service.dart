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
}
