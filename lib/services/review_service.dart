import '../services/api_service.dart';

class ReviewService {
  // ── Get reviews for a course (public) ──
  static Future<Map<String, dynamic>> getCourseReviews({
    required String courseId,
    String? token,
  }) async {
    return ApiService.get('/reviews/course/$courseId', token: token);
  }

  // ── Get review stats for a course ──
  static Future<Map<String, dynamic>> getReviewStats({
    required String courseId,
    String? token,
  }) async {
    return ApiService.get('/reviews/stats/$courseId', token: token);
  }

  // ── Student: Create review ──
  static Future<Map<String, dynamic>> createReview({
    required String token,
    required String courseId,
    required int rating,
    required String comment,
  }) async {
    return ApiService.post(
      '/reviews',
      body: {
        'courseId': courseId,
        'rating': rating,
        'comment': comment,
      },
      token: token,
    );
  }

  // ── Student: Update review ──
  static Future<Map<String, dynamic>> updateReview({
    required String token,
    required String reviewId,
    required int rating,
    required String comment,
  }) async {
    return ApiService.put(
      '/reviews/$reviewId',
      body: {
        'rating': rating,
        'comment': comment,
      },
      token: token,
    );
  }

  // ── Student: Get my review for a course ──
  static Future<Map<String, dynamic>> getMyReview({
    required String token,
    required String courseId,
  }) async {
    return ApiService.get('/reviews/my-review/$courseId', token: token);
  }

  // ── Tutor: Get all reviews received ──
  static Future<Map<String, dynamic>> getTutorReviews({required String token}) async {
    return ApiService.get('/reviews/tutor/all', token: token);
  }

  // ── Tutor: Reply to a review ──
  static Future<Map<String, dynamic>> replyToReview({
    required String token,
    required String reviewId,
    required String reply,
  }) async {
    return ApiService.post(
      '/reviews/$reviewId/reply',
      body: {'comment': reply},
      token: token,
    );
  }

  // ── Toggle helpful on a review ──
  static Future<Map<String, dynamic>> toggleHelpful({
    required String token,
    required String reviewId,
  }) async {
    return ApiService.post(
      '/reviews/$reviewId/helpful',
      body: {},
      token: token,
    );
  }
}
