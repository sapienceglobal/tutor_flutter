class LiveClass {
  final String id;
  final String tutorId;
  final String? tutorName;
  final String? tutorImage;
  final String title;
  final String? description;
  final String? courseId;
  final String? courseTitle;
  final String? batchId;
  final DateTime dateTime;
  final int duration; // in minutes
  final String? meetingLink;
  final String? meetingId;
  final String? passcode;
  final String platform;
  final String status;
  final String? recordingLink;
  final String? materialLink;

  LiveClass({
    required this.id,
    required this.tutorId,
    this.tutorName,
    this.tutorImage,
    required this.title,
    this.description,
    this.courseId,
    this.courseTitle,
    this.batchId,
    required this.dateTime,
    required this.duration,
    this.meetingLink,
    this.meetingId,
    this.passcode,
    required this.platform,
    required this.status,
    this.recordingLink,
    this.materialLink,
  });

  factory LiveClass.fromJson(Map<String, dynamic> json) {
    // Handle nested tutor object if populated
    String? tName;
    String? tImage;
    String tId = '';

    if (json['tutorId'] is Map) {
      tId = json['tutorId']['_id'] ?? '';
      if (json['tutorId']['userId'] is Map) {
        tName = json['tutorId']['userId']['name'];
        tImage = json['tutorId']['userId']['profileImage'];
      }
    } else {
      tId = json['tutorId'] ?? '';
    }

    return LiveClass(
      id: json['_id'] ?? '',
      tutorId: tId,
      tutorName: tName,
      tutorImage: tImage,
      title: json['title'] ?? '',
      description: json['description'],
      courseId: json['courseId'] is Map ? json['courseId']['_id'] : json['courseId'],
      courseTitle: json['courseId'] is Map ? json['courseId']['title'] : null,
      batchId: json['batchId'],
      dateTime: DateTime.parse(json['dateTime']),
      duration: json['duration'] ?? 60,
      meetingLink: json['meetingLink'],
      meetingId: json['meetingId'],
      passcode: json['passcode'],
      platform: json['platform'] ?? 'jitsi',
      status: json['status'] ?? 'scheduled',
      recordingLink: json['recordingLink'],
      materialLink: json['materialLink'],
    );
  }
}
