import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:my_app/models/tutor_dashboard_stats_model.dart';
import 'package:my_app/providers/auth_provider.dart';
import 'package:my_app/providers/workspace_provider.dart';
import 'package:my_app/providers/category_provider.dart';
import 'package:my_app/providers/tutor_provider.dart';
import 'package:my_app/providers/appointment_provider.dart';
import 'package:my_app/providers/course_provider.dart';
import 'package:my_app/providers/enrollment_provider.dart';
import 'package:my_app/providers/tutor_dashboard_provider.dart';
import 'package:my_app/providers/subscription_provider.dart';
import 'package:my_app/providers/theme_provider.dart';
import 'package:my_app/screens/tutor/tutor_dashboard_screen.dart';

class FakeDashboardProvider extends DashboardProvider {
  final DashboardStatsModel? mockStats;
  FakeDashboardProvider({this.mockStats});

  @override
  DashboardStatsModel? get stats => mockStats;

  @override
  bool get isLoading => false;

  @override
  Future<void> fetchStats() async {}
}

class FakeCourseProvider extends CourseProvider {
  @override
  bool get isLoading => false;

  @override
  Future<void> fetchMyCourses() async {}
}

void main() {
  testWidgets('TutorDashboardScreen renders all sections cleanly with null stats',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => WorkspaceProvider()),
          ChangeNotifierProvider(create: (_) => CategoryProvider()),
          ChangeNotifierProvider(create: (_) => TutorProvider()),
          ChangeNotifierProvider(create: (_) => AppointmentProvider()),
          ChangeNotifierProvider<CourseProvider>(create: (_) => FakeCourseProvider()),
          ChangeNotifierProvider(create: (_) => EnrollmentProvider()),
          ChangeNotifierProvider<DashboardProvider>(create: (_) => FakeDashboardProvider(mockStats: null)),
          ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MaterialApp(
          home: TutorDashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(TutorDashboardScreen), findsOneWidget);
    expect(find.text('EDUCATOR WORKSPACE'), findsOneWidget);
    expect(find.text('Educator Toolkit'), findsOneWidget);
    expect(find.text('Action Queue'), findsOneWidget);
    expect(find.text('Performance & Growth'), findsOneWidget);
    expect(find.text('Recent Courses'), findsOneWidget);
  });

  testWidgets('TutorDashboardScreen renders all sections cleanly with real stats',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    final dummyStats = DashboardStatsModel(
      courses: CourseStats(total: 5, published: 4, draft: 1),
      students: StudentStats(total: 42, recentEnrollments: 3),
      appointments: AppointmentStats(total: 8, upcoming: 2, completed: 6),
      rating: RatingStats(average: 4.8, totalReviews: 19),
      revenue: RevenueStats(total: 24500),
      content: ContentStats(questions: 50, quizzes: 8, practiceSets: 2),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => WorkspaceProvider()),
          ChangeNotifierProvider(create: (_) => CategoryProvider()),
          ChangeNotifierProvider(create: (_) => TutorProvider()),
          ChangeNotifierProvider(create: (_) => AppointmentProvider()),
          ChangeNotifierProvider<CourseProvider>(create: (_) => FakeCourseProvider()),
          ChangeNotifierProvider(create: (_) => EnrollmentProvider()),
          ChangeNotifierProvider<DashboardProvider>(create: (_) => FakeDashboardProvider(mockStats: dummyStats)),
          ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MaterialApp(
          home: TutorDashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(TutorDashboardScreen), findsOneWidget);
    expect(find.text('EDUCATOR WORKSPACE'), findsOneWidget);
    expect(find.text('₹24500'), findsOneWidget);
    expect(find.text('Educator Toolkit'), findsOneWidget);
    expect(find.text('Action Queue'), findsOneWidget);
    expect(find.text('Performance & Growth'), findsOneWidget);
    expect(find.text('Recent Courses'), findsOneWidget);
  });
}
