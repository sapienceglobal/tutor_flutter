import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/subscription_plan_model.dart';
import '../models/institute_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class SubscriptionService {
  Future<List<SubscriptionPlan>> fetchPlans({String? planRole}) async {
    final token = await AuthService.getToken();
    final url = planRole != null && planRole.isNotEmpty
        ? '${ApiConfig.baseUrl}/subscriptions?planRole=$planRole'
        : '${ApiConfig.baseUrl}/subscriptions';

    final response = await http.get(
      Uri.parse(url),
      headers: ApiService.buildHeaders(token: token, includeJsonContentType: false),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return (data['plans'] as List)
            .map((json) => SubscriptionPlan.fromJson(json))
            .toList();
      }
    }
    throw Exception(json.decode(response.body)['message'] ?? 'Failed to fetch subscription plans');
  }

  Future<Institute> fetchInstituteData() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/user-institute/me'),
      headers: ApiService.buildHeaders(token: token, includeJsonContentType: false),
    );

    if (response.statusCode == 200) {
      final data = ApiConfig.normalizeMediaUrlsDeep(json.decode(response.body));
      if (data['success']) {
        return Institute.fromJson(data['institute']);
      }
    }
    throw Exception(json.decode(response.body)['message'] ?? 'Failed to fetch institute data');
  }

  Future<Map<String, dynamic>> createPersonalRenewalOrder(String planId) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/payments/renew-subscription'),
      headers: ApiService.buildHeaders(token: token),
      body: json.encode({
        'planId': planId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      if (data['success']) {
        return data;
      }
    }
    throw Exception(json.decode(response.body)['message'] ?? 'Failed to initiate personal payment');
  }

  Future<Map<String, dynamic>> createRenewalOrder(String planId, String instituteId) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/payments/renew-subscription'),
      headers: ApiService.buildHeaders(token: token),
      body: json.encode({
        'planId': planId,
        'instituteId': instituteId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      if (data['success']) {
        return data;
      }
    }
    throw Exception(json.decode(response.body)['message'] ?? 'Failed to initiate payment');
  }

  Future<bool> verifyPayment(Map<String, dynamic> paymentData) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/payments/verify'),
      headers: ApiService.buildHeaders(token: token),
      body: json.encode(paymentData),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] == true;
    }
    return false;
  }
}
