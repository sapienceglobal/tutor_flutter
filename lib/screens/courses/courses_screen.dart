import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/api_config.dart';
import '../../models/course_model.dart';
import '../../models/enrollment_model.dart';
import '../../services/course_service.dart';
import '../../services/enrollment_service.dart';
import '../../services/notification_service.dart';
import '../../utils/constants.dart';
import '../../widgets/sapience_ui.dart';
import '../../widgets/shimmer_loader.dart';
import '../common/notifications/notifications_screen.dart';
import 'course_detail_screen.dart';

class CoursesScreen extends StatefulWidget {
  final bool embedded;
  const CoursesScreen({super.key, this.embedded = false});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<EnrollmentModel> _enrolledCourses = [];
  List<CourseModel> _instituteCourses = [];
  List<CourseModel> _globalCourses = [];

  bool _isLoading = true;
  int _unreadCount = 0;

  // Filters matching PNG: All, Popular, New / Discover, In Progress
  String _selectedTab = 'All';
  String _searchQuery = '';
  String _selectedLevel = 'all';
  bool _showFreeOnly = false;

  static const _filterPills = ['All', 'In Progress', 'Popular', 'Institute'];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        EnrollmentService.getMyEnrollments().catchError((_) => <EnrollmentModel>[]),
        CourseService.getAllCourses(scope: 'institute').catchError((_) => <CourseModel>[]),
        CourseService.getAllCourses(scope: 'global').catchError((_) => <CourseModel>[]),
        NotificationService.getUnreadCount().catchError((_) => 0),
      ]);
      if (!mounted) return;
      setState(() {
        _enrolledCourses = results[0] as List<EnrollmentModel>;
        _instituteCourses = results[1] as List<CourseModel>;
        _globalCourses = results[2] as List<CourseModel>;
        _unreadCount = results[3] as int;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDuration(double duration) {
    if (duration <= 0) return 'Self-paced';
    final int mins = duration < 24 ? (duration * 60).round() : duration.round();
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  Map<String, EnrollmentModel> get _enrollmentByCourseId {
    final map = <String, EnrollmentModel>{};
    for (final e in _enrolledCourses) {
      map[e.course.id] = e;
    }
    return map;
  }

  List<CourseModel> get _combinedCatalog {
    final seen = <String>{};
    final out = <CourseModel>[];
    for (final e in _enrolledCourses) {
      if (seen.add(e.course.id)) out.add(e.course);
    }
    for (final c in _instituteCourses) {
      if (seen.add(c.id)) out.add(c);
    }
    for (final c in _globalCourses) {
      if (seen.add(c.id)) out.add(c);
    }
    return out;
  }

  List<CourseModel> get _filteredCourses {
    List<CourseModel> base;
    if (_selectedTab == 'In Progress') {
      base = _enrolledCourses.map((e) => e.course).toList();
    } else if (_selectedTab == 'Institute') {
      base = List<CourseModel>.from(_instituteCourses);
    } else if (_selectedTab == 'Popular') {
      base = List<CourseModel>.from(_combinedCatalog)
        ..sort((a, b) => b.enrolledCount.compareTo(a.enrolledCount));
    } else {
      base = _combinedCatalog;
    }

    return base.where((course) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = course.title.toLowerCase().contains(q) ||
            course.description.toLowerCase().contains(q) ||
            course.category.name.toLowerCase().contains(q);
        if (!match) return false;
      }
      if (_selectedLevel != 'all' &&
          course.level.toLowerCase() != _selectedLevel.toLowerCase()) {
        return false;
      }
      if (_showFreeOnly && !course.isFree) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredCourses;
    final enrollMap = _enrollmentByCourseId;

    return Scaffold(
      body: SapienceBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SapienceHeader(
                title: 'Courses',
                leading: widget.embedded ? const SizedBox(width: 40) : null,
                actions: [
                  IconButton(
                    icon: Icon(
                      _selectedLevel != 'all' || _showFreeOnly
                          ? Icons.filter_alt_rounded
                          : Icons.tune_rounded,
                      color: _selectedLevel != 'all' || _showFreeOnly
                          ? AppColors.primary
                          : AppColors.navy,
                      size: 24,
                    ),
                    onPressed: _showFilterSheet,
                    splashRadius: 20,
                  ),
                  SapienceBellButton(
                    unreadCount: _unreadCount,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                      final c = await NotificationService.getUnreadCount();
                      if (mounted) setState(() => _unreadCount = c);
                    },
                  ),
                ],
              ),
              // Search Pill Bar (exact match to Modern Courses Dashboard App UI.png)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFE3EAF6)),
                    boxShadow: const [AppThemeDesign.softShadow],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 21),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: const TextStyle(color: AppColors.navy, fontSize: 15),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            hintText: 'Search for courses...',
                            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14.5),
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ),
              ),
              // Horizontal Filter Chips
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filterPills.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final label = _filterPills[i];
                    final isOn = _selectedTab == label;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTab = label),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: isOn ? AppColors.primaryGradient : null,
                          color: isOn ? null : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isOn ? Colors.transparent : const Color(0xFFE7EDF8),
                          ),
                          boxShadow: isOn
                              ? const [AppThemeDesign.brandShadow]
                              : const [AppThemeDesign.softShadow],
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isOn ? FontWeight.w700 : FontWeight.w600,
                            color: isOn ? Colors.white : AppColors.navy,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _isLoading
                    ? const ShimmerListView(itemCount: 5)
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadAllData,
                        child: items.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  const SizedBox(height: 70),
                                  Center(
                                    child: SapienceCard(
                                      margin: const EdgeInsets.symmetric(horizontal: 24),
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        children: [
                                          const Icon(Icons.menu_book_rounded, size: 46, color: AppColors.primary),
                                          const SizedBox(height: 10),
                                          const Text(
                                            'No courses found',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.navy,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Try changing your filter or pull down to refresh.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                itemCount: items.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (_, i) {
                                  final course = items[i];
                                  final enrollment = enrollMap[course.id];
                                  return _buildCourseListCard(course, enrollment);
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseListCard(CourseModel course, EnrollmentModel? enrollment) {
    final thumbUrl = ApiConfig.resolveMediaUrl(course.thumbnail);
    final isEnrolled = enrollment != null;
    final pct = isEnrolled ? enrollment.progress.percentage.round().clamp(0, 100) : 0;
    final moduleCount = course.modules.isNotEmpty
        ? '${course.modules.length} Modules'
        : course.category.name;
    final durStr = _formatDuration(course.duration);

    return SapienceCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(12),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CourseDetailScreen(courseId: course.id)),
        );
        _loadAllData();
      },
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: thumbUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: thumbUrl,
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _courseFallbackIcon(course.title),
                  )
                : _courseFallbackIcon(course.title),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$moduleCount  •  $durStr',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textBody,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                if (isEnrolled) ...[
                  Text(
                    pct > 0 ? '$pct% Completed' : '0% Not Started',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: pct > 0 ? FontWeight.w700 : FontWeight.w600,
                      color: pct > 0 ? AppColors.success : AppColors.textBody,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SapienceProgressBar(value: pct / 100, height: 8),
                ] else ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: course.isFree ? AppColors.successSoft : AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          course.isFree ? 'FREE' : '₹${course.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: course.isFree ? AppColors.success : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${course.enrolledCount} learners • ${course.level}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          SapiencePlayCircle(
            solid: true,
            size: 38,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CourseDetailScreen(courseId: course.id)),
              ).then((_) => _loadAllData());
            },
          ),
        ],
      ),
    );
  }

  Widget _courseFallbackIcon(String title) {
    final hash = title.hashCode.abs();
    const palettes = [
      [Color(0xFF0B1A45), Color(0xFF13398A)],
      [Color(0xFF2079FF), Color(0xFF0650E8)],
      [Color(0xFFF59E0B), Color(0xFFEA580C)],
      [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
      [Color(0xFFEC4899), Color(0xFFBE185D)],
    ];
    final colors = palettes[hash % palettes.length];
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 36),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Filter Courses',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.navy),
              ),
              const SizedBox(height: 14),
              const Text(
                'Difficulty Level',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.navy),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['all', 'beginner', 'intermediate', 'advanced'].map((lvl) {
                  final sel = _selectedLevel == lvl;
                  return ChoiceChip(
                    label: Text(lvl.toUpperCase()),
                    selected: sel,
                    selectedColor: AppColors.primarySoft,
                    labelStyle: TextStyle(
                      color: sel ? AppColors.primary : AppColors.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedLevel = lvl);
                      setModalState(() {});
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Free Courses Only',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
                ),
                value: _showFreeOnly,
                activeThumbColor: AppColors.primary,
                onChanged: (v) {
                  setState(() => _showFreeOnly = v);
                  setModalState(() {});
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SapienceButton(
                      label: 'Reset',
                      variant: SapienceButtonVariant.outlinedNavy,
                      onTap: () {
                        setState(() {
                          _selectedLevel = 'all';
                          _showFreeOnly = false;
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SapienceButton(
                      label: 'Apply Filters',
                      variant: SapienceButtonVariant.blue,
                      onTap: () => Navigator.pop(ctx),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
