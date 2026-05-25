import '../config/api_config.dart';

class Certificate {
  final String id;
  final String? credentialId;
  final String courseId;
  final String courseName;
  final String? instituteName;
  final DateTime issuedAt;
  final String? downloadUrl;
  final String? verificationUrl;

  Certificate({
    required this.id,
    this.credentialId,
    required this.courseId,
    required this.courseName,
    this.instituteName,
    required this.issuedAt,
    this.downloadUrl,
    this.verificationUrl,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    final courseObj = json['courseId'];
    final courseIdStr = courseObj is Map ? (courseObj['_id'] ?? '') : (courseObj ?? '');
    final courseTitleStr = courseObj is Map ? (courseObj['title'] ?? 'Course') : 'Course';
    final certId = json['certificateId'] ?? '';

    DateTime parsedDate;
    try {
      parsedDate = json['issuedAt'] != null ? DateTime.parse(json['issuedAt']) : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return Certificate(
      id: json['_id'] ?? '',
      credentialId: certId,
      courseId: courseIdStr.toString(),
      courseName: courseTitleStr.toString(),
      instituteName: json['instituteName'] ?? 'Sapience LMS',
      issuedAt: parsedDate,
      downloadUrl: '${ApiConfig.baseUrl}/certificates/generate/$courseIdStr',
      verificationUrl: '${ApiConfig.webUrl}/verify/$certId',
    );
  }
}

class InProgressCourse {
  final String id;
  final String title;
  final int progress; // percentage

  InProgressCourse({
    required this.id,
    required this.title,
    required this.progress,
  });

  factory InProgressCourse.fromJson(Map<String, dynamic> json) {
    num prog = json['progress'] ?? 0;
    return InProgressCourse(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      progress: prog.toInt(),
    );
  }
}
