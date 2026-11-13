import 'api_service.dart';
import 'auth_service.dart';
import '../config/api_config.dart';

class BatchService {
  static const String _endpoint = ApiConfig.batchesEndpoint;

  // Get all batches for a tutor (or admin)
  static Future<Map<String, dynamic>> getAllBatches({String? courseId}) async {
    try {
      final token = await AuthService.getToken();
      Map<String, String>? queryParams;
      if (courseId != null) {
        queryParams = {'courseId': courseId};
      }
      return await ApiService.get(_endpoint, token: token, queryParams: queryParams);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Create a new batch
  static Future<Map<String, dynamic>> createBatch(Map<String, dynamic> data) async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.post(_endpoint, body: data, token: token);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Update a batch
  static Future<Map<String, dynamic>> updateBatch(String id, Map<String, dynamic> data) async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.patch('$_endpoint/$id', body: data, token: token);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Delete a batch
  static Future<Map<String, dynamic>> deleteBatch(String id) async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.delete('$_endpoint/$id', token: token);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Get single batch by ID
  static Future<Map<String, dynamic>> getBatchById(String id) async {
    try {
      final token = await AuthService.getToken();
      return await ApiService.get('$_endpoint/$id', token: token);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
