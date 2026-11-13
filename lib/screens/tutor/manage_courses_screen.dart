import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/course_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/sapience_ui.dart';
import 'create_course_screen.dart';
import 'edit_course_screen.dart';
import 'manage_lessons_screen.dart';
import 'manage_exam_screen.dart';
import 'tutor_students_screen.dart';
import 'reports/tutor_reports_screen.dart';

class ManageCoursesScreen extends StatefulWidget {
  final bool embedded;

  const ManageCoursesScreen({super.key, this.embedded = false});

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  int _selectedTab = 0; // 0: Published, 1: Drafts, 2: Archived

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CourseProvider>(context, listen: false).fetchMyCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);

    final publishedCourses =
        courseProvider.myCourses.where((c) => c.status == 'published').toList();
    final draftCourses =
        courseProvider.myCourses.where((c) => c.status == 'draft').toList();
    final archivedCourses =
        courseProvider.myCourses.where((c) => c.status == 'archived').toList();

    final activeList = _selectedTab == 0
        ? publishedCourses
        : _selectedTab == 1
            ? draftCourses
            : archivedCourses;

    return SapienceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SapienceHeader(
                title: 'My Courses',
                onBack:
                    widget.embedded ? () {} : () => Navigator.of(context).pop(),
                leading: widget.embedded ? const SizedBox(width: 4) : null,
                actions: [
                  Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CreateCourseScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: SapienceSegmentedTabs(
                  tabs: [
                    'Published (${publishedCourses.length})',
                    'Drafts (${draftCourses.length})',
                    'Archived (${archivedCourses.length})',
                  ],
                  currentIndex: _selectedTab,
                  onChanged: (idx) => setState(() => _selectedTab = idx),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => courseProvider.fetchMyCourses(),
                  child: courseProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildCoursesList(activeList),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoursesList(List courses) {
    if (courses.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 36),
          SapienceCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.school_outlined,
                    size: 34,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'No courses in this tab',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyInk,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Create a course to organize modules, video lessons, and proctored tests.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                SapienceButton(
                  label: 'Create Course',
                  leadingIcon: Icons.add_rounded,
                  variant: SapienceButtonVariant.greenToBlue,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CreateCourseScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
      itemCount: courses.length,
      itemBuilder: (context, index) => _buildCourseCard(courses[index]),
    );
  }

  Widget _buildCourseCard(course) {
    final statusColor = _getStatusColor(course.status);

    return SapienceCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: course.thumbnail,
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 84,
                    height: 84,
                    color: AppColors.primaryTint,
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 84,
                    height: 84,
                    color: AppColors.primaryTint,
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 34,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTint,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            course.category.name,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            course.status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => _showOptionsMenu(context, course),
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.more_vert_rounded,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyInk,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildStatChip(
                          Icons.people_outline_rounded,
                          '${course.enrolledCount}',
                        ),
                        const SizedBox(width: 10),
                        _buildStatChip(
                          Icons.star_rounded,
                          course.rating.toStringAsFixed(1),
                          iconColor: AppColors.warning,
                        ),
                        const SizedBox(width: 10),
                        _buildStatChip(
                          Icons.schedule_rounded,
                          '${course.duration.toStringAsFixed(0)}h',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SapienceButton(
                  label: 'Lessons',
                  leadingIcon: Icons.video_library_rounded,
                  variant: SapienceButtonVariant.outlinedNavy,
                  height: 40,
                  fontSize: 12.5,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ManageLessonsScreen(course: course),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SapienceButton(
                  label: 'Exams',
                  leadingIcon: Icons.assignment_rounded,
                  variant: SapienceButtonVariant.outlinedGreen,
                  height: 40,
                  fontSize: 12.5,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ManageExamsScreen(course: course),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SapienceButton(
                  label: 'Edit',
                  leadingIcon: Icons.edit_rounded,
                  variant: SapienceButtonVariant.blue,
                  height: 40,
                  fontSize: 12.5,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditCourseScreen(course: course),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    IconData icon,
    String text, {
    Color iconColor = AppColors.textSecondary,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.navyInk,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'published':
        return AppColors.secondary;
      case 'draft':
        return const Color(0xFFE07A16);
      case 'archived':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  void _showOptionsMenu(BuildContext context, course) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              ListTile(
                leading: Icon(
                  course.status == 'published'
                      ? Icons.archive_outlined
                      : Icons.publish_rounded,
                  color: AppColors.primary,
                ),
                title: Text(
                  course.status == 'published'
                      ? 'Archive Course'
                      : 'Publish Course',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _updateCourseStatus(
                    course.id,
                    course.status == 'published' ? 'archived' : 'published',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.people_outline_rounded,
                    color: AppColors.primary),
                title: const Text(
                  'View Students',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(this.context).push(
                    MaterialPageRoute(
                      builder: (_) => const TutorStudentsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics_outlined,
                    color: AppColors.secondary),
                title: const Text(
                  'View Analytics',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(this.context).push(
                    MaterialPageRoute(
                      builder: (_) => const TutorReportsScreen(),
                    ),
                  );
                },
              ),
              const Divider(color: AppColors.border),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                title: const Text(
                  'Delete Course',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(this.context, course.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateCourseStatus(String courseId, String newStatus) async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    final success = await courseProvider.updateCourse(
      id: courseId,
      updates: {'status': newStatus},
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Course ${newStatus == 'published' ? 'published' : 'archived'} successfully',
          ),
          backgroundColor: AppColors.secondary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(courseProvider.error ?? 'Failed to update course'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context, String courseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Course'),
        content: const Text(
          'Are you sure you want to delete this course? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteCourse(courseId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCourse(String courseId) async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    final success = await courseProvider.deleteCourse(courseId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course deleted successfully'),
          backgroundColor: AppColors.secondary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(courseProvider.error ?? 'Failed to delete course'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
