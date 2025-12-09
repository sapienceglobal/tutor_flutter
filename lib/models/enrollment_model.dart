import 'course_model.dart';
import 'user_model.dart';

class EnrollmentProgress {
  final List<String> completedLessons;
  final double percentage;

  EnrollmentProgress({
    this.completedLessons = const [],
    this.percentage = 0,
  });

  factory EnrollmentProgress.fromJson(Map<String, dynamic> json) {
    return EnrollmentProgress(
      completedLessons: List<String>.from(json['completedLessons'] ?? []),
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completedLessons': completedLessons,
      'percentage': percentage,
    };
  }
}

class EnrollmentModel {
  final String id;
  final UserModel student;
  final CourseModel course;
  final DateTime enrolledAt;
  final EnrollmentProgress progress;
  final String status;
  final DateTime lastAccessed;
  final DateTime? completedAt;

  EnrollmentModel({
    required this.id,
    required this.student,
    required this.course,
    required this.enrolledAt,
    required this.progress,
    this.status = 'active',
    required this.lastAccessed,
    this.completedAt,
  });

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentModel(
      id: json['_id'] ?? '',
      student: UserModel.fromJson(json['studentId'] ?? {}),
      course: CourseModel.fromJson(json['courseId'] ?? {}),
      enrolledAt: json['enrolledAt'] != null
          ? DateTime.parse(json['enrolledAt'])
          : DateTime.now(),
      progress: EnrollmentProgress.fromJson(json['progress'] ?? {}),
      status: json['status'] ?? 'active',
      lastAccessed: json['lastAccessed'] != null
          ? DateTime.parse(json['lastAccessed'])
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'studentId': student.toJson(),
      'courseId': course.toJson(),
      'enrolledAt': enrolledAt.toIso8601String(),
      'progress': progress.toJson(),
      'status': status,
      'lastAccessed': lastAccessed.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}