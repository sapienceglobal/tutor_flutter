import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../courses/my_enrollments_screen.dart';
import 'student_exams_screen.dart';
import 'student_batches_screen.dart';

class StudentLearningScreen extends StatefulWidget {
  const StudentLearningScreen({super.key});

  @override
  State<StudentLearningScreen> createState() => _StudentLearningScreenState();
}

class _StudentLearningScreenState extends State<StudentLearningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Learning',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Courses'),
            Tab(text: 'Exams'),
            Tab(text: 'Batches'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          MyEnrollmentsScreen(embedded: true),
          StudentExamsScreen(embedded: true),
          StudentBatchesScreen(),
        ],
      ),
    );
  }
}
