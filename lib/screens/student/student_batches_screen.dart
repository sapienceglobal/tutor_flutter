import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import '../../utils/constants.dart';
import 'attendance/student_batch_attendance_screen.dart';

class StudentBatchesScreen extends StatefulWidget {
  const StudentBatchesScreen({super.key});

  @override
  State<StudentBatchesScreen> createState() => _StudentBatchesScreenState();
}

class _StudentBatchesScreenState extends State<StudentBatchesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoadingMy = true;
  bool _isLoadingAvailable = true;

  List<dynamic> _myBatches = [];
  List<dynamic> _availableBatches = [];

  String? _errorMy;
  String? _errorAvailable;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadAllBatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllBatches() async {
    await Future.wait([
      _loadMyBatches(),
      _loadAvailableBatches(),
    ]);
  }

  Future<void> _loadMyBatches() async {
    if (!mounted) return;
    setState(() {
      _isLoadingMy = true;
      _errorMy = null;
    });
    try {
      final token = await AuthService.getToken();
      final res = await ApiService.get('${ApiConfig.batchesEndpoint}/my', token: token);
      if (res['success'] == true && mounted) {
        setState(() {
          _myBatches = res['batches'] ?? res['data'] ?? [];
          _isLoadingMy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMy = e.toString();
          _isLoadingMy = false;
        });
      }
    }
  }

  Future<void> _loadAvailableBatches() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAvailable = true;
      _errorAvailable = null;
    });
    try {
      final token = await AuthService.getToken();
      final res = await ApiService.get('${ApiConfig.batchesEndpoint}/available', token: token);
      if (res['success'] == true && mounted) {
        setState(() {
          _availableBatches = res['batches'] ?? res['data'] ?? [];
          _isLoadingAvailable = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorAvailable = e.toString();
          _isLoadingAvailable = false;
        });
      }
    }
  }

  Future<void> _joinBatch(String batchId) async {
    try {
      final token = await AuthService.getToken();
      final res = await ApiService.post('${ApiConfig.batchesEndpoint}/$batchId/join', body: {}, token: token);
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined batch!'), backgroundColor: Colors.green),
        );
        _loadAllBatches();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining batch: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Batches', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
            Tab(text: 'My Batches'),
            Tab(text: 'Discover Batches'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyBatchesTab(),
          _buildAvailableBatchesTab(),
        ],
      ),
    );
  }

  Widget _buildMyBatchesTab() {
    if (_isLoadingMy) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMy != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_errorMy!, textAlign: TextAlign.center),
            TextButton(onPressed: _loadMyBatches, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_myBatches.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadMyBatches,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            Center(
              child: Column(
                children: [
                  Icon(Icons.group_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No Enrolled Batches', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Discover and join new batches from the discovery tab!', style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyBatches,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myBatches.length,
        itemBuilder: (context, index) {
          final batch = _myBatches[index];
          return _buildBatchCard(batch, isEnrolled: true);
        },
      ),
    );
  }

  Widget _buildAvailableBatchesTab() {
    if (_isLoadingAvailable) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorAvailable != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_errorAvailable!, textAlign: TextAlign.center),
            TextButton(onPressed: _loadAvailableBatches, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_availableBatches.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAvailableBatches,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            Center(
              child: Column(
                children: [
                  Icon(Icons.explore_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No Available Batches', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Check back later for new batches!', style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAvailableBatches,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _availableBatches.length,
        itemBuilder: (context, index) {
          final batch = _availableBatches[index];
          return _buildBatchCard(batch, isEnrolled: false);
        },
      ),
    );
  }

  Widget _buildBatchCard(dynamic batch, {required bool isEnrolled}) {
    final batchName = batch['name'] ?? 'Batch Name';
    final courseTitle = batch['courseId']?['title'] ?? 'General Course';
    final studentsCount = batch['students']?.length ?? 0;
    final tutorName = batch['tutorId']?['name'] ?? 'Assigned Tutor';
    final schedule = batch['schedule']?.toString() ?? 'Flexible Schedule';
    final batchId = batch['_id'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.group, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(batchName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        courseTitle,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isEnrolled ? Colors.green.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isEnrolled ? 'Joined' : 'Open',
                    style: TextStyle(
                      color: isEnrolled ? Colors.green : Colors.amber.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoItem(Icons.people, '$studentsCount Students'),
                const SizedBox(width: 16),
                _buildInfoItem(Icons.schedule, schedule),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(tutorName, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
                if (!isEnrolled)
                  ElevatedButton(
                    onPressed: () => _joinBatch(batchId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Join Batch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                if (isEnrolled)
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StudentBatchAttendanceScreen(
                            batchId: batchId,
                            batchName: batchName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.fact_check_outlined, size: 14),
                    label: const Text('Attendance', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }
}
