import '../services/api_service.dart';

class LeaveService {
  // ── Student/Tutor: Apply for leave ──
  static Future<Map<String, dynamic>> applyLeave({
    required String token,
    required String startDate,
    required String endDate,
    required String reason,
    String? leaveType,
  }) async {
    return ApiService.post(
      '/leaves',
      body: {
        'startDate': startDate,
        'endDate': endDate,
        'reason': reason,
        if (leaveType != null) 'leaveType': leaveType,
      },
      token: token,
    );
  }

  // ── Student/Tutor: Get my leaves ──
  static Future<Map<String, dynamic>> getMyLeaves({required String token}) async {
    return ApiService.get('/leaves/my', token: token);
  }

  // ── Student/Tutor: Update my leave ──
  static Future<Map<String, dynamic>> updateMyLeave({
    required String token,
    required String leaveId,
    required Map<String, dynamic> body,
  }) async {
    return ApiService.put('/leaves/$leaveId', body: body, token: token);
  }

  // ── Student/Tutor: Delete/Cancel my leave ──
  static Future<Map<String, dynamic>> deleteMyLeave({
    required String token,
    required String leaveId,
  }) async {
    return ApiService.delete('/leaves/$leaveId', token: token);
  }

  // ── Admin/Tutor: Get all leaves (for approval) ──
  static Future<Map<String, dynamic>> getAllLeaves({required String token}) async {
    return ApiService.get('/leaves', token: token);
  }

  // ── Admin/Tutor: Approve/Reject leave ──
  static Future<Map<String, dynamic>> updateLeaveStatus({
    required String token,
    required String leaveId,
    required String status, // 'approved' or 'rejected'
  }) async {
    return ApiService.put(
      '/leaves/$leaveId/status',
      body: {'status': status},
      token: token,
    );
  }
}
