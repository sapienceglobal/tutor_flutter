import 'package:flutter/material.dart';
import '../../models/tutor_model.dart';
import '../../services/tutor_service.dart';
import '../../widgets/tutor_card.dart';
import '../../utils/constants.dart';

class TutorsScreen extends StatefulWidget {
  const TutorsScreen({super.key});

  @override
  State<TutorsScreen> createState() => _TutorsScreenState();
}

class _TutorsScreenState extends State<TutorsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<TutorModel> _instituteTutors = [];
  List<TutorModel> _globalTutors = [];

  bool _isLoadingInstitute = true;
  bool _isLoadingGlobal = true;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadAllTutors();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllTutors() async {
    await Future.wait([
      _fetchInstituteTutors(),
      _fetchGlobalTutors(),
    ]);
  }

  Future<void> _fetchInstituteTutors() async {
    if (!mounted) return;
    setState(() => _isLoadingInstitute = true);
    try {
      final res = await TutorService.getAllTutors(scope: 'institute');
      if (mounted) {
        setState(() {
          _instituteTutors = res;
          _isLoadingInstitute = false;
        });
      }
    } catch (e) {
      print('Error fetching institute tutors: $e');
      if (mounted) {
        setState(() => _isLoadingInstitute = false);
      }
    }
  }

  Future<void> _fetchGlobalTutors() async {
    if (!mounted) return;
    setState(() => _isLoadingGlobal = true);
    try {
      final res = await TutorService.getAllTutors(scope: 'global');
      if (mounted) {
        setState(() {
          _globalTutors = res;
          _isLoadingGlobal = false;
        });
      }
    } catch (e) {
      print('Error fetching global tutors: $e');
      if (mounted) {
        setState(() => _isLoadingGlobal = false);
      }
    }
  }

  List<TutorModel> _applySearch(List<TutorModel> list) {
    if (_searchQuery.isEmpty) return list;
    return list.where((t) {
      final nameMatches = t.user.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final bioMatches = t.bio.toLowerCase().contains(_searchQuery.toLowerCase());
      final subjectMatches = t.subjects.any((s) => s.toLowerCase().contains(_searchQuery.toLowerCase()));
      return nameMatches || bioMatches || subjectMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Tutors Directory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: 'My Institute Tutors'),
            Tab(text: 'Discover Global'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search box
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
                      ? 'Search my institute tutors...'
                      : 'Search global tutors...',
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

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTutorsList(
                  isLoading: _isLoadingInstitute,
                  list: _instituteTutors,
                  onRefresh: _fetchInstituteTutors,
                  emptyText: 'No tutors found in your institute.',
                ),
                _buildTutorsList(
                  isLoading: _isLoadingGlobal,
                  list: _globalTutors,
                  onRefresh: _fetchGlobalTutors,
                  emptyText: 'No global tutors found.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorsList({
    required bool isLoading,
    required List<TutorModel> list,
    required Future<void> Function() onRefresh,
    required String emptyText,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _applySearch(list);

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.5,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 70, color: Colors.grey[300]),
                const SizedBox(height: 14),
                Text(
                  emptyText,
                  style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final tutor = filtered[index];
          return TutorCard(tutor: tutor);
        },
      ),
    );
  }
}
