class ApiConfig {
  // static const String baseUrl = 'https://tutor-backend-two.vercel.app/api';
  // Use 10.0.2.2 for Android Emulator, or 127.0.0.1 for iOS Simulator, or local IP like 192.168.1.X for physical devices.
  static const String baseUrl = 'http://192.168.1.6:4000/api';
  static const String webUrl = 'http://195.35.20.207:5000'; // Frontend URL for WebViews

  // Endpoints
  static const String authEndpoint = '/auth';
  static const String categoriesEndpoint = '/categories';
  static const String tutorsEndpoint = '/tutors';
  static const String appointmentsEndpoint = '/appointments';
  static const String coursesEndpoint = '/courses';
  static const String lessonsEndpoint = '/lessons';
  static const String enrollmentsEndpoint = '/enrollments';
  static const String progressEndpoint = '/progress';
  static const String uploadEndpoint = '/upload';
}
