class ApiConfig {
  // ─── Backend URL ─────────────────────────────────────────
  // Local dev (physical device, same WiFi): 'http://192.168.1.7:4000/api'
  // Android Emulator: 'http://10.0.2.2:4000/api'
  // 
  // Production (Hostinger VPS - Option A: Direct Port 4000):
  // static const String baseUrl = 'http://195.35.20.207:4000/api';
  // 
  // Production (Hostinger VPS - Option B: Web Proxy via Port 5000 - recommended if port 4000 is firewalled):
  static const String baseUrl = 'https://yaadkaro.cloud/api/proxy';
  
  static const String webUrl = 'https://yaadkaro.cloud'; // Frontend URL for WebViews
  static const String mediaBaseUrl = 'http://195.35.20.207:4000'; // Direct Backend Media Origin (/uploads)

  static String get socketUrl {
    return 'http://195.35.20.207:4000';
  }

  /// Resolves relative media paths (/uploads/..., uploads/..., /media/...) and upgrades http://res.cloudinary.com to https://
  /// Identical to tutor-web/src/lib/mediaUrl.js so website & mobile app resolve media identically in production.
  static String resolveMediaUrl(String? value) {
    if (value == null) return '';
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';

    if (trimmed.startsWith('blob:') || trimmed.startsWith('data:')) {
      return trimmed;
    }

    if (trimmed.startsWith('//')) {
      return 'https:$trimmed';
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      if (trimmed.toLowerCase().startsWith('http://res.cloudinary.com')) {
        return trimmed.replaceFirst(RegExp(r'^http://', caseSensitive: false), 'https://');
      }
      return trimmed;
    }

    if (trimmed.startsWith('/')) {
      return '$mediaBaseUrl$trimmed';
    }

    final lower = trimmed.toLowerCase();
    if (lower.startsWith('uploads/') || lower.startsWith('media/')) {
      return '$mediaBaseUrl/$trimmed';
    }

    return trimmed;
  }

  static bool _looksLikeMediaPath(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    final lower = trimmed.toLowerCase();
    return lower.startsWith('blob:') ||
        lower.startsWith('data:image/') ||
        lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('/uploads/') ||
        lower.startsWith('uploads/') ||
        lower.startsWith('/media/') ||
        lower.startsWith('media/') ||
        lower.contains('res.cloudinary.com');
  }

  /// Recursively normalizes media URLs inside JSON maps/lists returned by the backend.
  static dynamic normalizeMediaUrlsDeep(dynamic input) {
    if (input is List) {
      return input.map((item) => normalizeMediaUrlsDeep(item)).toList();
    }
    if (input is Map) {
      final Map<String, dynamic> output = {};
      input.forEach((key, value) {
        output[key.toString()] = normalizeMediaUrlsDeep(value);
      });
      return output;
    }
    if (input is String && _looksLikeMediaPath(input)) {
      return resolveMediaUrl(input);
    }
    return input;
  }
  // ─── Auth ───────────────────────────────────────────────
  static const String authEndpoint = '/auth';

  // ─── Lookup / Browse ────────────────────────────────────
  static const String categoriesEndpoint = '/categories';
  static const String tutorsEndpoint = '/tutors';

  // ─── Courses (public + institute-scoped via Bearer token) ─
  static const String coursesEndpoint = '/courses';

  // ─── Lessons ────────────────────────────────────────────
  static const String lessonsEndpoint = '/lessons';

  // ─── Enrollments (student: my-enrollments, check, etc.) ──
  static const String enrollmentsEndpoint = '/enrollments';

  // ─── Progress (lesson watch progress) ───────────────────
  static const String progressEndpoint = '/progress';

  // ─── Appointments / Schedule ────────────────────────────
  static const String appointmentsEndpoint = '/appointments';

  // ─── Exams (tutor CRUD + submission) ────────────────────
  // Tutor: GET /api/exams/tutor/all
  // Tutor: POST /api/exams
  // Tutor: GET /api/exams/course/:courseId
  static const String examsEndpoint = '/exams';

  // ─── Student Exams (read-only student exam flow) ─────────
  // GET /api/student/exams/all          → list all available exams for student
  // GET /api/student/exams/history-all  → past attempt history
  // GET /api/student/exams/:id          → exam detail
  // POST /api/student/exams/:id/submit  → submit exam
  // GET /api/student/exams/attempt/:id  → attempt detail
  static const String studentExamsEndpoint = '/student/exams';

  // ─── Batches ────────────────────────────────────────────
  // GET /api/batches/my           → student: my batches
  // GET /api/batches/available    → student: available to join
  // POST /api/batches/:id/join    → student: join batch
  // GET /api/batches              → tutor: all batches
  // POST /api/batches             → tutor: create batch
  static const String batchesEndpoint = '/batches';

  // ─── Live Classes ───────────────────────────────────────
  static const String liveClassesEndpoint = '/live-classes';

  // ─── Assignments ────────────────────────────────────────
  static const String assignmentsEndpoint = '/assignments';

  // ─── Dashboards ─────────────────────────────────────────
  static const String tutorDashboardEndpoint = '/tutor/dashboard';
  static const String studentDashboardEndpoint = '/student/dashboard';

  // ─── AI (chat, study-plan, etc.) ────────────────────────
  // POST /api/ai/chat
  // POST /api/ai/study-plan
  static const String aiEndpoint = '/ai';

  // ─── Notifications ──────────────────────────────────────
  static const String notificationsEndpoint = '/notifications';

  // ─── Upload ─────────────────────────────────────────────
  static const String uploadEndpoint = '/upload';
}
