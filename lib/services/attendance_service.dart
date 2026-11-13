import '../services/api_service.dart';

class AttendanceService {
  // ── Tutor: Mark attendance for a batch ──
  static Future<Map<String, dynamic>> markAttendance({
    required String token,
    required String batchId,
    required String date,
    required List<Map<String, dynamic>> records, // [{studentId, status}]
  }) async {
    return ApiService.post(
      '/attendance/batch',
      body: {
        'batchId': batchId,
        'date': date,
        'records': records,
      },
      token: token,
    );
  }

  // ── Get attendance for a batch ──
  static Future<Map<String, dynamic>> getBatchAttendance({
    required String token,
    required String batchId,
    Map<String, String>? queryParams,
  }) async {
    return ApiService.get(
      '/attendance/batch/$batchId',
      token: token,
      queryParams: queryParams,
    );
  }
}
