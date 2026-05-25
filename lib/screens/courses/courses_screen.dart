import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../models/enrollment_model.dart';
import '../../services/course_service.dart';
import '../../services/enrollment_service.dart';
import '../../widgets/course_card.dart';
import '../../utils/constants.dart';
import 'course_detail_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // States
  List<EnrollmentModel> _enrolledCourses = [];
  List<CourseModel> _instituteCourses = [];
  List<CourseModel> _globalCourses = [];
  
  bool _isLoadingEnrolled = true;
  bool _isLoadingInstitute = true;
  bool _isLoadingGlobal = true;
  
  String _searchQuery = '';
  String _selectedLevel = 'all';
  bool _showFreeOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // refresh actions based on current tab
    });
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _fetchEnrolledCourses(),
      _fetchInstituteCourses(),
      _fetchGlobalCourses(),
    ]);
  }

  Future<void> _fetchEnrolledCourses() async {
    if (!mounted) return;
    setState(() => _isLoadingEnrolled = true);
    try {
      final res = await EnrollmentService.getMyEnrollments();
      if (mounted) {
        setState(() {
          _enrolledCourses = res;
          _isLoadingEnrolled = false;
        });
      }
    } catch (e) {
      print('Error fetching enrolled: $e');
      if (mounted) {
        setState(() => _isLoadingEnrolled = false);
      }
    }
  }

  Future<void> _fetchInstituteCourses() async {
    if (!mounted) return;
    setState(() => _isLoadingInstitute = true);
    try {
      final res = await CourseService.getAllCourses(scope: 'institute');
      if (mounted) {
        setState(() {
          _instituteCourses = res;
          _isLoadingInstitute = false;
        });
      }
    } catch (e) {
      print('Error fetching institute courses: $e');
      if (mounted) {
        setState(() => _isLoadingInstitute = false);
      }
    }
  }

  Future<void> _fetchGlobalCourses() async {
    if (!mounted) return;
    setState(() => _isLoadingGlobal = true);
    try {
      final res = await CourseService.getAllCourses(scope: 'global');
      if (mounted) {
        setState(() {
          _globalCourses = res;
          _isLoadingGlobal = false;
        });
      }
    } catch (e) {
      print('Error fetching global courses: $e');
      if (mounted) {
        setState(() => _isLoadingGlobal = false);
      }
    }
  }

  // Filter Helper
  List<T> _applyFilters<T>(List<T> items, CourseModel Function(T) getCourse) {
    return items.where((item) {
      final course = getCourse(item);
      
      // Search check
      final matchesSearch = course.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          course.description.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;
      
      // Level check
      if (_selectedLevel != 'all' && course.level.toLowerCase() != _selectedLevel.toLowerCase()) {
        return false;
      }
      
      // Free Only check
      if (_showFreeOnly && !course.isFree) {
        return false;
      }
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('My Courses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'My Enrolled'),
            Tab(text: 'Discover Inst.'),
            Tab(text: 'Discover Global'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Elegant Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: _tabController.index == 0
                      ? 'Search my enrolled courses...'
                      : 'Search courses in discovery...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[400]),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
          ),

          // Active Filters Display
          if (_selectedLevel != 'all' || _showFreeOnly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_selectedLevel != 'all')
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text('Level: ${_selectedLevel.toUpperCase()}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () {
                          setState(() {
                            _selectedLevel = 'all';
                          });
                        },
                      ),
                    ),
                  if (_showFreeOnly)
                    Chip(
                      label: const Text('Free Only', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.teal.withOpacity(0.1),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () {
                        setState(() {
                          _showFreeOnly = false;
                        });
                      },
                    ),
                ],
              ),
            ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEnrolledTab(),
                _buildDiscoveryTab(
                  isLoading: _isLoadingInstitute,
                  courses: _instituteCourses,
                  onRefresh: _fetchInstituteCourses,
                  emptyText: 'No institute courses discovered.',
                ),
                _buildDiscoveryTab(
                  isLoading: _isLoadingGlobal,
                  courses: _globalCourses,
                  onRefresh: _fetchGlobalCourses,
                  emptyText: 'No global courses discovered.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrolledTab() {
    if (_isLoadingEnrolled) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _applyFilters(_enrolledCourses, (e) => e.course);

    if (filtered.isEmpty) {
      return _buildEmptyState('No enrolled courses found.', Icons.menu_book_outlined);
    }

    return RefreshIndicator(
      onRefresh: _fetchEnrolledCourses,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final enrollment = filtered[index];
          final course = enrollment.course;
          final pct = enrollment.progress.percentage;

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            color: Colors.white,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CourseDetailScreen(courseId: course.id),
                  ),
                ).then((_) => _loadAllData());
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        course.thumbnail,
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 76,
                          height: 76,
                          color: Colors.grey[200],
                          child: Icon(Icons.school, color: Colors.grey[400], size: 36),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    
                    // Course Details & Progress Bar
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            course.tutor.user.name,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 12),
                          
                          // Linear progress
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct / 100,
                                    backgroundColor: const Color(0xFFF0F2F6),
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${pct.toStringAsFixed(0)}%',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiscoveryTab({
    required bool isLoading,
    required List<CourseModel> courses,
    required Future<void> Function() onRefresh,
    required String emptyText,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _applyFilters(courses, (c) => c);

    if (filtered.isEmpty) {
      return _buildEmptyState(emptyText, Icons.explore_outlined);
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final course = filtered[index];
          return CourseCard(course: course);
        },
      ),
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 70, color: Colors.grey[300]),
            const SizedBox(height: 14),
            Text(
              text,
              style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Courses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Level:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip(setModalState, 'All', 'all'),
                      _buildFilterChip(setModalState, 'Beginner', 'beginner'),
                      _buildFilterChip(setModalState, 'Intermediate', 'intermediate'),
                      _buildFilterChip(setModalState, 'Advanced', 'advanced'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show Free Courses Only', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    activeColor: AppColors.primary,
                    value: _showFreeOnly,
                    onChanged: (value) {
                      setModalState(() {
                        _showFreeOnly = value;
                      });
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedLevel = 'all';
                              _showFreeOnly = false;
                            });
                            setState(() {});
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text('Clear Filters', style: TextStyle(color: Colors.black)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(StateSetter setModalState, String label, String value) {
    final isSelected = _selectedLevel == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary.withOpacity(0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          setModalState(() {
            _selectedLevel = value;
          });
          setState(() {});
        }
      },
    );
  }
}