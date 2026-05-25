import 'package:flutter/material.dart';
import '../../services/batch_service.dart';
import '../../utils/constants.dart';
import 'package:intl/intl.dart';

class ManageBatchesScreen extends StatefulWidget {
  const ManageBatchesScreen({super.key});

  @override
  State<ManageBatchesScreen> createState() => _ManageBatchesScreenState();
}

class _ManageBatchesScreenState extends State<ManageBatchesScreen> {
  bool _isLoading = true;
  List<dynamic> _batches = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await BatchService.getAllBatches();
      if (res['success'] == true) {
        setState(() {
          _batches = res['data'] ?? res['batches'] ?? [];
        });
      } else {
        setState(() => _error = res['message'] ?? 'Failed to load batches');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCreateBatchDialog() {
    // Basic dialog to show feature
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create Batch feature available on web dashboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Batches'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary),
            onPressed: _showCreateBatchDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!),
                      TextButton(onPressed: _loadBatches, child: const Text('Retry')),
                    ],
                  ),
                )
              : _batches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group_off, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('No Batches Found',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Create a batch to group your students.',
                              style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBatches,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _batches.length,
                        itemBuilder: (context, index) {
                          final batch = _batches[index];
                          return _buildBatchCard(batch);
                        },
                      ),
                    ),
    );
  }

  Widget _buildBatchCard(dynamic batch) {
    DateTime? startDate = batch['startDate'] != null ? DateTime.tryParse(batch['startDate']) : null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    batch['name'] ?? 'Unnamed Batch',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (batch['status'] == 'active' ? Colors.green : Colors.grey).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (batch['status'] ?? 'unknown').toUpperCase(),
                    style: TextStyle(
                      color: batch['status'] == 'active' ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Course: ${batch['courseId'] != null ? (batch['courseId']['title'] ?? 'Unknown Course') : 'N/A'}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoCol(Icons.people, 'Students', '${batch['students']?.length ?? 0}/${batch['capacity'] ?? '∞'}'),
                _buildInfoCol(Icons.calendar_today, 'Start Date', startDate != null ? DateFormat('MMM d, y').format(startDate) : 'N/A'),
                _buildInfoCol(Icons.schedule, 'Schedule', batch['schedule'] ?? 'Not set'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCol(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
