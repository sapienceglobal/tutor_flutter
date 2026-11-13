import 'api_service.dart';
import 'auth_service.dart';

class PayoutService {
  static const String _baseEndpoint = '/tutors/payouts';

  // Fetch complete financial + payout report
  static Future<Map<String, dynamic>> getPayoutReport({int months = 6}) async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.get(
        '$_baseEndpoint/report',
        token: token,
        queryParams: {'months': months.toString()},
      );
      return response;
    } catch (e) {
      print('❌ PayoutService.getPayoutReport error: $e');
      rethrow;
    }
  }

  // Fetch list of payout requests
  static Future<Map<String, dynamic>> getPayouts({String? status, int limit = 100}) async {
    try {
      final token = await AuthService.getToken();
      final query = <String, String>{'limit': limit.toString()};
      if (status != null && status.isNotEmpty) {
        query['status'] = status;
      }
      final response = await ApiService.get(
        _baseEndpoint,
        token: token,
        queryParams: query,
      );
      return response;
    } catch (e) {
      print('❌ PayoutService.getPayouts error: $e');
      rethrow;
    }
  }

  // Request a new payout withdrawal
  static Future<Map<String, dynamic>> requestPayout({
    required double amount,
    required Map<String, dynamic> bankDetails,
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.post(
        '$_baseEndpoint/request',
        body: {
          'amount': amount,
          'bankDetails': bankDetails,
        },
        token: token,
      );
      return response;
    } catch (e) {
      print('❌ PayoutService.requestPayout error: $e');
      rethrow;
    }
  }

  // Cancel a pending payout request
  static Future<Map<String, dynamic>> cancelPayout(String payoutId) async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.patch(
        '$_baseEndpoint/$payoutId/cancel',
        body: {},
        token: token,
      );
      return response;
    } catch (e) {
      print('❌ PayoutService.cancelPayout error: $e');
      rethrow;
    }
  }
}
