class StudentDashboardStats {
  final int enrolledCourses;
  final int completedCourses;
  final int inProgressCourses;
  final int liveClassesToday;
  final double averageScore;
  final List<ChartDataPoint> performanceHistory;
  final List<Announcement> recentAnnouncements;
  final List<dynamic> todayExams;

  StudentDashboardStats({
    required this.enrolledCourses,
    required this.completedCourses,
    required this.inProgressCourses,
    required this.liveClassesToday,
    required this.averageScore,
    required this.performanceHistory,
    required this.recentAnnouncements,
    required this.todayExams,
  });

  factory StudentDashboardStats.fromJson(Map<String, dynamic> json) {
    return StudentDashboardStats(
      enrolledCourses: json['enrolledCourses'] ?? 0,
      completedCourses: json['completedCourses'] ?? 0,
      inProgressCourses: json['inProgress'] ?? 0,
      liveClassesToday: json['liveClassesToday'] ?? 0,
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      performanceHistory: (json['activity'] as List? ?? [])
          .map((item) => ChartDataPoint.fromJson(item))
          .toList(),
      recentAnnouncements: (json['announcements'] as List? ?? [])
          .map((item) => Announcement.fromJson(item))
          .toList(),
      todayExams: json['todayExams'] ?? [],
    );
  }
}

class TutorDashboardStats {
  final int totalStudents;
  final int activeCourses;
  final int upcomingClasses;
  final double totalEarnings;
  final Map<String, dynamic> trends;
  final List<ChartDataPoint> weeklyPerformance;
  final List<StudentActivity> recentActivity;
  final List<Announcement> announcements;
  final Map<String, dynamic> actionQueue;

  TutorDashboardStats({
    required this.totalStudents,
    required this.activeCourses,
    required this.upcomingClasses,
    required this.totalEarnings,
    required this.trends,
    required this.weeklyPerformance,
    required this.recentActivity,
    required this.announcements,
    required this.actionQueue,
  });

  factory TutorDashboardStats.fromJson(Map<String, dynamic> json) {
    return TutorDashboardStats(
      totalStudents: json['totalStudents'] ?? 0,
      activeCourses: json['activeCourses'] ?? 0,
      upcomingClasses: json['upcomingClassesCount'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      trends: json['trends'] ?? {},
      weeklyPerformance: (json['weeklyPerformance'] as List? ?? [])
          .map((item) => ChartDataPoint.fromJson(item))
          .toList(),
      recentActivity: (json['recentStudentActivity'] as List? ?? [])
          .map((item) => StudentActivity.fromJson(item))
          .toList(),
      announcements: (json['recentAnnouncements'] as List? ?? [])
          .map((item) => Announcement.fromJson(item))
          .toList(),
      actionQueue: {
        'pendingAssignments': json['pendingAssignmentReviews'] ?? 0,
        'unreadNotifications': json['unreadNotificationsCount'] ?? 0,
      },
    );
  }
}

class ChartDataPoint {
  final String label;
  final double value;
  final double? secondaryValue;

  ChartDataPoint({required this.label, required this.value, this.secondaryValue});

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      label: json['month'] ?? json['name'] ?? '',
      value: (json['score'] ?? json['enrollments'] ?? 0).toDouble(),
      secondaryValue: (json['completions'] ?? 0).toDouble(),
    );
  }
}

class StudentActivity {
  final String studentName;
  final String? studentImage;
  final String courseName;
  final int score;
  final String lastActivity;

  StudentActivity({
    required this.studentName,
    this.studentImage,
    required this.courseName,
    required this.score,
    required this.lastActivity,
  });

  factory StudentActivity.fromJson(Map<String, dynamic> json) {
    return StudentActivity(
      studentName: json['studentName'] ?? 'Student',
      studentImage: json['studentImage'],
      courseName: json['courseName'] ?? '',
      score: json['score'] ?? 0,
      lastActivity: json['lastActivity'] ?? '',
    );
  }
}

class Announcement {
  final String id;
  final String title;
  final String message;
  final String? courseTitle;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    this.courseTitle,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      courseTitle: json['courseTitle'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
