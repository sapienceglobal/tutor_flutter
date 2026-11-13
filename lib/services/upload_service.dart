import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:my_app/config/api_config.dart';
import 'dart:convert';
import 'api_service.dart';
import 'auth_service.dart';

class UploadService {
  static const String _endpoint = '/upload';

  static Map<String, String> _multipartHeaders(String? token) {
    return {
      if (token != null) 'Authorization': 'Bearer $token',
      'x-api-key': ApiService.apiKey,
      'x-client-platform': 'mobile',
    };
  }

  // Upload single file (document/file)
  static Future<Map<String, dynamic>> uploadFile(File file) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}$_endpoint/file');

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_multipartHeaders(token));

      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final rawData = json.decode(response.body);
      final data = ApiConfig.normalizeMediaUrlsDeep(rawData) as Map<String, dynamic>;

      return data;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Upload image
  static Future<Map<String, dynamic>> uploadImage(File file) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}$_endpoint/image');

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_multipartHeaders(token));

      request.files.add(
        await http.MultipartFile.fromPath('image', file.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final rawData = json.decode(response.body);
      final data = ApiConfig.normalizeMediaUrlsDeep(rawData) as Map<String, dynamic>;

      return data;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Upload Video for HLS processing
  static Future<Map<String, dynamic>> uploadVideoHls(File file) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}$_endpoint/video-hls');

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_multipartHeaders(token));

      request.files.add(
        await http.MultipartFile.fromPath('video', file.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final rawData = json.decode(response.body);
      final data = ApiConfig.normalizeMediaUrlsDeep(rawData) as Map<String, dynamic>;

      return data;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}