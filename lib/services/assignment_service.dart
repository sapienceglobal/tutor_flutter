import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/assignment_model.dart';
import 'auth_service.dart';

class AssignmentService {
  final AuthService _authService = AuthService();

  Future<List<Assignment>> fetchAssignments() async {
    final token = await AuthService.getToken();
    final apiKey = await AuthService.getApiKey();

    // The backend seems to provide assignments via individual course calls or a dedicated list
    // Based on the web controller, we'll fetch my enrollments first then their assignments
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.enrollmentsEndpoint}/my-enrollments'),
      headers: {
        'Authorization': 'Bearer $token',
        'x-api-key': apiKey ?? '',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List enrollments = data['enrollments'] ?? [];
      List<Assignment> allAssignments = [];

      for (var enr in enrollments) {
        final cid = enr['courseId'] is Map ? enr['courseId']['_id'] : enr['courseId'];
        final courseTitle = enr['courseId'] is Map ? enr['courseId']['title'] : 'Course';
        
        if (cid == null) continue;

        try {
          final asgnRes = await http.get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.assignmentsEndpoint}/course/$cid'),
            headers: {
              'Authorization': 'Bearer $token',
              'x-api-key': apiKey ?? '',
            },
          );

          if (asgnRes.statusCode == 200) {
            final asgnData = ApiConfig.normalizeMediaUrlsDeep(json.decode(asgnRes.body));
            final List assignmentsJson = asgnData['assignments'] ?? [];
            for (var aj in assignmentsJson) {
              final a = Assignment.fromJson(aj);
              // Adding course title manually as it's useful for the general list
              allAssignments.add(Assignment(
                id: a.id,
                title: a.title,
                description: a.description,
                courseId: a.courseId,
                courseTitle: courseTitle,
                batchId: a.batchId,
                dueDate: a.dueDate,
                totalMarks: a.totalMarks,
                attachments: a.attachments,
                rubric: a.rubric,
                status: a.status,
                mySubmission: a.mySubmission,
              ));
            }
          }
        } catch (e) {
          print('Error fetching assignments for $cid: $e');
        }
      }
      
      allAssignments.sort((a, b) => (b.dueDate ?? DateTime(0)).compareTo(a.dueDate ?? DateTime(0)));
      return allAssignments;
    }
    throw Exception('Failed to load assignments');
  }

  Future<List<Assignment>> fetchAssignmentsByCourse(String courseId) async {
    final token = await AuthService.getToken();
    final apiKey = await AuthService.getApiKey();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.assignmentsEndpoint}/course/$courseId'),
      headers: {
        'Authorization': 'Bearer $token',
        'x-api-key': apiKey ?? '',
      },
    );

    if (response.statusCode == 200) {
      final data = ApiConfig.normalizeMediaUrlsDeep(json.decode(response.body));
      final List assignmentsJson = data['assignments'] ?? [];
      return assignmentsJson.map((aj) => Assignment.fromJson(aj)).toList();
    }
    throw Exception('Failed to load course assignments');
  }

  Future<Assignment> fetchAssignmentDetails(String id) async {
    final token = await AuthService.getToken();
    final apiKey = await AuthService.getApiKey();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.assignmentsEndpoint}/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'x-api-key': apiKey ?? '',
      },
    );

    if (response.statusCode == 200) {
      final data = ApiConfig.normalizeMediaUrlsDeep(json.decode(response.body));
      if (data['success']) {
        final a = Assignment.fromJson(data['assignment']);
        // If student, attach their submission from responseData.mySubmission
        if (data['mySubmission'] != null) {
            return Assignment(
                id: a.id,
                title: a.title,
                description: a.description,
                courseId: a.courseId,
                courseTitle: a.courseTitle,
                batchId: a.batchId,
                dueDate: a.dueDate,
                totalMarks: a.totalMarks,
                attachments: a.attachments,
                rubric: a.rubric,
                status: a.status,
                mySubmission: Submission.fromJson(data['mySubmission']),
            );
        }
        return a;
      }
    }
    throw Exception('Failed to fetch assignment details');
  }

  Future<bool> submitAssignment(String assignmentId, {String? content, List<Map<String, dynamic>>? attachments}) async {
    final token = await AuthService.getToken();
    final apiKey = await AuthService.getApiKey();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.assignmentsEndpoint}/$assignmentId/submit'),
      headers: {
        'Authorization': 'Bearer $token',
        'x-api-key': apiKey ?? '',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'content': content,
        'attachments': attachments ?? [],
      }),
    );

    if (response.statusCode == 200) {
      return true;
    }
    throw Exception(json.decode(response.body)['message'] ?? 'Submission failed');
  }

  // --- TUTOR SERVICES ---

  Future<Assignment> createAssignment({
    required String courseId,
    String? batchId,
    required String title,
    required String description,
    required DateTime dueDate,
    required int totalMarks,
    List<Map<String, dynamic>>? attachments,
    String status = 'published',
  }) async {
    final token = await AuthService.getToken();
    final apiKey = await AuthService.getApiKey();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.assignmentsEndpoint}'),
      headers: {
        'Authorization': 'Bearer $token',
        'x-api-key': apiKey ?? '',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'courseId': courseId,
        if (batchId != null) 'batchId': batchId,
        'title': title,
        'description': description,
        'dueDate': dueDate.toIso8601String(),
        'totalMarks': totalMarks,
        'attachments': attachments ?? [],
        'status': status,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return Assignment.fromJson(data['assignment']);
      }
    }
    throw Exception(json.decode(response.body)['message'] ?? 'Failed to create assignment');
  }

  Future<Assignment> updateAssignment(
    String id, {
    String? title,
    String? description,
    DateTime? dueDate,
    int? totalMarks,
    String? status,
  }) async {
    final token = await AuthService.getToken();
    final apiKey = await AuthService.getApiKey();

    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.assignmentsEndpoint}/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'x-api-key': apiKey ?? '',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
        if (totalMarks != null) 'totalMarks': totalMarks,
        if (status != null) 'status': status,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return Assignment.fromJson(data['assignment']);
      }
    }
    throw Exception(json.decode(response.body)['message'] ?? 'Failed to update assignment');
  }

  Future<bool> deleteAssignment(String id) async {
    final token = await AuthService.getToken();
    final apiKey = await AuthService.getApiKey();

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.assignmentsEndpoint}/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'x-api-key': apiKey ?? '',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] == true;
    }
    throw Exception(json.decode(response.body)['message'] ?? 'Failed to delete assignment');
  }

  Future<List<Map<String, dynamic>>> getAssignmentSubmissions(String id) async {
    final token = await AuthService.getToken();
    final apiKey = await AuthService.getApiKey();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.assignmentsEndpoint}/$id/submissions'),
      headers: {
        'Authorization': 'Bearer $token',
        'x-api-key': apiKey ?? '',
      },
    );

    if (response.statusCode == 200) {
      final data = ApiConfig.normalizeMediaUrlsDeep(json.decode(response.body));
      if (data['success'] == true) {
        final List submissionsJson = data['submissions'] ?? [];
        return List<Map<String, dynamic>>.from(submissionsJson);
      }
    }
    throw Exception(json.decode(response.body)['message'] ?? 'Failed to load submissions');
  }

  Future<bool> gradeSubmission(
    String submissionId, {
    required double grade,
    String? feedback,
  }) async {
    final token = await AuthService.getToken();
    final apiKey = await AuthService.getApiKey();

    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.assignmentsEndpoint}/submissions/$submissionId/grade'),
      headers: {
        'Authorization': 'Bearer $token',
        'x-api-key': apiKey ?? '',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'grade': grade,
        'feedback': feedback ?? '',
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] == true;
    }
    throw Exception(json.decode(response.body)['message'] ?? 'Failed to grade submission');
  }
}
