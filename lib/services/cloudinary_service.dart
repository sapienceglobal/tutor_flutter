import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'auth_service.dart';
import '../config/api_config.dart';

class CloudinaryService {
  static Future<Map<String, dynamic>?> uploadImage(File imageFile) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        print('❌ No auth token found');
        return null;
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/upload/image');
      final request = http.MultipartRequest('POST', url);

      request.headers['Authorization'] = 'Bearer $token';

      String mimeType = '';
      if (imageFile.path.endsWith('.png')) {
        mimeType = 'png';
      } else if (imageFile.path.endsWith('.jpg') || imageFile.path.endsWith('.jpeg')) {
        mimeType = 'jpeg';
      } else if (imageFile.path.endsWith('.webp')) {
        mimeType = 'webp';
      } else {
        mimeType = 'jpeg';
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // Changed to match backend single('image')
          imageFile.path,
          contentType: MediaType('image', mimeType),
        ),
      );

      print('📤 Uploading image...');
      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(body);
        print('✅ Upload successful!');
        return {
          'url': jsonData['url'],
          'publicId': jsonData['cloudinaryId'],
        };
      } else {
        print('❌ Upload failed: $body');
        return null;
      }
    } catch (e) {
      print('❌ Upload error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> uploadFile(File file) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final url = Uri.parse('${ApiConfig.baseUrl}/upload/file');
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
        ),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(body);
      } else {
        return null;
      }
    } catch (e) {
      print('❌ Upload error: $e');
      return null;
    }
  }
}
