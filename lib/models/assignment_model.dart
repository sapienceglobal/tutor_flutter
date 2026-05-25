class Assignment {
  final String id;
  final String title;
  final String? description;
  final String? courseId;
  final String? courseTitle;
  final String? batchId;
  final DateTime? dueDate;
  final int totalMarks;
  final List<dynamic> attachments;
  final List<dynamic> rubric;
  final String status;
  final Submission? mySubmission;

  Assignment({
    required this.id,
    required this.title,
    this.description,
    this.courseId,
    this.courseTitle,
    this.batchId,
    this.dueDate,
    required this.totalMarks,
    required this.attachments,
    required this.rubric,
    required this.status,
    this.mySubmission,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      courseId: json['courseId'] is Map ? json['courseId']['_id'] : json['courseId'],
      courseTitle: json['courseTitle'], // Added by controller in list
      batchId: json['batchId'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      totalMarks: json['totalMarks'] ?? 0,
      attachments: json['attachments'] ?? [],
      rubric: json['rubric'] ?? [],
      status: json['status'] ?? 'draft',
      mySubmission: json['mySubmission'] != null 
          ? Submission.fromJson(json['mySubmission']) 
          : null,
    );
  }
}

class Submission {
  final String id;
  final String assignmentId;
  final String studentId;
  final String? content;
  final List<dynamic> attachments;
  final String status; // submitted, graded
  final double? grade;
  final String? feedback;
  final DateTime submittedAt;
  final DateTime? gradedAt;
  final String? gradedByName;

  Submission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    this.content,
    required this.attachments,
    required this.status,
    this.grade,
    this.feedback,
    required this.submittedAt,
    this.gradedAt,
    this.gradedByName,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['_id'] ?? '',
      assignmentId: json['assignmentId'] ?? '',
      studentId: json['studentId'] ?? '',
      content: json['content'],
      attachments: json['attachments'] ?? [],
      status: json['status'] ?? 'submitted',
      grade: json['grade'] != null ? (json['grade'] as num).toDouble() : null,
      feedback: json['feedback'],
      submittedAt: DateTime.parse(json['submittedAt']),
      gradedAt: json['gradedAt'] != null ? DateTime.parse(json['gradedAt']) : null,
      gradedByName: json['gradedBy'] is Map ? json['gradedBy']['name'] : null,
    );
  }
}
