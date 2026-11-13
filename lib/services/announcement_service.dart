import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class AnnouncementService {
  // Fetch announcements for student
  static Future<List<dynamic>> fetchStudentAnnouncements() async {
    final token = await AuthService.getToken();
    final apiKey = await AuthService.getApiKey();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.enrollmentsEndpoint}/my-announcements'),
      headers: {
        'Authorization': 'Bearer $token',
        'x-api-key': apiKey ?? '',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['announcements'] ?? [];
      }
    }
    throw Exception('Failed to load student announcements');
  }

  // Fetch announcements for tutor
  static Future<List<dynamic>> fetchTutorAnnouncements() async {
    final token = await AuthService.getToken();
    final apiKey = await AuthService.getApiKey();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tutorsEndpoint}/announcements'),
      headers: {
        'Authorization': 'Bearer $token',
        'x-api-key': apiKey ?? '',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['announcements'] ?? [];
      }
    }
    throw Exception('Failed to load tutor announcements');
  }

  // Create course announcement
  static Future<bool> createCourseAnnouncement(String courseId, {required String title, required String message}) async {
    final token = await AuthService.getToken();
    final apiKey = await AuthService.getApiKey();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.coursesEndpoint}/$courseId/announcements'),
      headers: {
        'Authorization': 'Bearer $token',
        'x-api-key': apiKey ?? '',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'title': title,
        'message': message,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['success'] == true;
    }
    throw Exception(json.decode(response.body)['message'] ?? 'Failed to create course announcement');
  }

  // Create batch announcement
  static Future<bool> createBatchAnnouncement(String batchId, {required String title, required String message}) async {
    final token = await AuthService.getToken();
    final apiKey = await AuthService.getApiKey();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.batchesEndpoint}/$batchId/announcements'),
      headers: {
        'Authorization': 'Bearer $token',
        'x-api-key': apiKey ?? '',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'title': title,
        'message': message,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['success'] == true;
    }
    throw Exception(json.decode(response.body)['message'] ?? 'Failed to create batch announcement');
  }
}
