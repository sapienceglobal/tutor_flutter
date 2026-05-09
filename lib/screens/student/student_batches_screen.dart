import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';

class StudentBatchesScreen extends StatefulWidget {
  const StudentBatchesScreen({super.key});

  @override
  State<StudentBatchesScreen> createState() => _StudentBatchesScreenState();
}

class _StudentBatchesScreenState extends State<StudentBatchesScreen> {
  bool _isLoading = true;
  List<dynamic> _myBatches = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = await AuthService.getToken();
      final res = await ApiService.get('/batches/my', token: token);
      if (res['success'] == true) {
        setState(() => _myBatches = res['batches'] ?? res['data'] ?? []);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinBatch(String batchId) async {
    try {
      final token = await AuthService.getToken();
      final res = await ApiService.post('/batches/$batchId/join', body: {}, token: token);
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joined batch!'), backgroundColor: Colors.green));
        _loadBatches();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadBatches,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(onPressed: _loadBatches, child: const Text('Retry')),
                  ],
                ))
              : _myBatches.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Column(children: [
                          Icon(Icons.group_outlined, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('No Batches Joined', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Join a batch to get started!', style: TextStyle(color: Colors.grey[500])),
                        ]),
                      ),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _myBatches.length,
                      itemBuilder: (context, index) {
                        final batch = _myBatches[index];
                        return _buildBatchCard(batch);
                      },
                    ),
    );
  }

  Widget _buildBatchCard(dynamic batch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
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
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.group, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(batch['name'] ?? 'Batch', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        batch['courseId']?['title'] ?? 'No Course',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Active', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoItem(Icons.people, '${batch['students']?.length ?? 0} Students'),
                const SizedBox(width: 16),
                if (batch['schedule'] != null)
                  _buildInfoItem(Icons.schedule, batch['schedule'].toString()),
                const Spacer(),
                if (batch['tutorId'] != null)
                  Row(children: [
                    const Icon(Icons.person, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(batch['tutorId']['name'] ?? 'Tutor', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ]),
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
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }
}
