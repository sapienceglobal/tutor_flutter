import 'api_service.dart';
import 'auth_service.dart';

class ExamReevaluationService {
  static const String _endpoint = '/exams';

  /// Get tutor's re-evaluation requests (GET /api/exams/re-evaluation-requests)
  static Future<Map<String, dynamic>> getReevaluationRequests({
    String? status,
    String? examId,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await AuthService.getToken();
      final queryParams = <String, String>{};
      if (status != null && status != 'all') queryParams['status'] = status;
      if (examId != null && examId.isNotEmpty) queryParams['examId'] = examId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      queryParams['page'] = page.toString();
      queryParams['limit'] = limit.toString();

      return await ApiService.get('$_endpoint/re-evaluation-requests', token: token, queryParams: queryParams);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Review re-evaluation request (PATCH /api/exams/re-evaluation-requests/:requestId/review)
  static Future<Map<String, dynamic>> reviewReevaluationRequest({
    required String requestId,
    required String decision, // 'approved' or 'rejected'
    required String tutorRemarks,
    double? revisedScore,
  }) async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.patch(
        '$_endpoint/re-evaluation-requests/$requestId/review',
        body: {
          'decision': decision,
          'tutorRemarks': tutorRemarks,
          if (revisedScore != null) 'revisedScore': revisedScore,
        },
        token: token,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
