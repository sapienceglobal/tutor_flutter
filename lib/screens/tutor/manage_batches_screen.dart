import 'package:flutter/material.dart';
import '../../services/batch_service.dart';
import '../../utils/constants.dart';
import 'package:intl/intl.dart';
import 'batch_editor_screen.dart';

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

  void _showCreateBatchDialog() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BatchEditorScreen()),
    );
    if (result == true) {
      _loadBatches();
    }
  }

  void _showEditBatch(dynamic batch) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BatchEditorScreen(batch: batch)),
    );
    if (result == true) {
      _loadBatches();
    }
  }

  Future<void> _deleteBatch(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppThemeDesign.borderRadiusMedium),
        title: const Text('Delete Batch?'),
        content: const Text('Are you sure you want to delete this batch? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final res = await BatchService.deleteBatch(id);
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Batch deleted successfully!'), backgroundColor: Colors.green),
          );
          _loadBatches();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed to delete batch.')),
          );
          setState(() => _isLoading = false);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
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
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppThemeDesign.borderRadiusMedium,
        boxShadow: const [AppThemeDesign.cardShadow],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: InkWell(
        onTap: () => _showEditBatch(batch),
        borderRadius: AppThemeDesign.borderRadiusMedium,
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
                  Row(
                    children: [
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
                      const SizedBox(width: 8),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        onPressed: () => _deleteBatch(batch['_id']),
                      ),
                    ],
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
