import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/course_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class WishlistService {
  Future<List<CourseModel>> getWishlist() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/wishlist'),
      headers: ApiService.buildHeaders(token: token, includeJsonContentType: false),
    );

    if (response.statusCode == 200) {
      final data = ApiConfig.normalizeMediaUrlsDeep(json.decode(response.body));
      if (data['success'] == true) {
        final list = data['data'] ?? data['wishlist'];
        if (list == null) return [];
        
        final List<CourseModel> courses = [];
        for (var item in (list as List)) {
          final courseData = item['course'] ?? item['courseId'];
          if (courseData != null) {
            try {
              courses.add(CourseModel.fromJson(courseData));
            } catch (e) {
              print('Error parsing wishlist course: $e');
            }
          }
        }
        return courses;
      }
    }
    throw Exception('Failed to fetch wishlist');
  }

  Future<bool> addToWishlist(String courseId) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/wishlist'),
      headers: ApiService.buildHeaders(token: token),
      body: json.encode({'courseId': courseId}),
    );

    return response.statusCode == 201;
  }

  Future<bool> removeFromWishlist(String courseId) async {
    final token = await AuthService.getToken();

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/wishlist/$courseId'),
      headers: ApiService.buildHeaders(token: token, includeJsonContentType: false),
    );

    return response.statusCode == 200;
  }
}
