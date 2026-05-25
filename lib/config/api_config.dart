class ApiConfig {
  // ─── Backend URL ─────────────────────────────────────────
  // Local dev (physical device, same WiFi): 'http://192.168.1.7:4000/api'
  // Android Emulator: 'http://10.0.2.2:4000/api'
  // 
  // Production (Hostinger VPS - Option A: Direct Port 4000):
  // static const String baseUrl = 'http://195.35.20.207:4000/api';
  // 
  // Production (Hostinger VPS - Option B: Web Proxy via Port 5000 - recommended if port 4000 is firewalled):
  static const String baseUrl = 'http://195.35.20.207:5000/api/proxy';
  
  static const String webUrl = 'http://195.35.20.207:5000'; // Frontend URL for WebViews
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
