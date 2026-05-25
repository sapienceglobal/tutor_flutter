import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class PaymentService {
  Future<Map<String, dynamic>> createCourseOrder(String courseId) async {
    final token = await AuthService.getToken();
    final apiKey = await AuthService.getApiKey();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/payments/create-order'),
      headers: {
        'Authorization': 'Bearer $token',
        'x-api-key': apiKey ?? '',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'courseId': courseId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return data;
      }
    }
    throw Exception(json.decode(response.body)['message'] ?? 'Failed to create payment order');
  }

  Future<bool> verifyPayment(Map<String, dynamic> paymentData) async {
    final token = await AuthService.getToken();
    final apiKey = await AuthService.getApiKey();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/payments/verify'),
      headers: {
        'Authorization': 'Bearer $token',
        'x-api-key': apiKey ?? '',
        'Content-Type': 'application/json',
      },
      body: json.encode(paymentData),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  Future<List<dynamic>> getMyPayments() async {
    final token = await AuthService.getToken();
    final apiKey = await AuthService.getApiKey();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/payments/my-payments'),
      headers: {
        'Authorization': 'Bearer $token',
        'x-api-key': apiKey ?? '',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return data['payments'] ?? [];
      }
    }
    throw Exception('Failed to load payment history');
  }
}
