import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/leave_service.dart';
import '../../../utils/constants.dart';
import '../../../widgets/shimmer_loader.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_retry.dart';

class StudentLeaveRequestsScreen extends StatefulWidget {
  const StudentLeaveRequestsScreen({super.key});

  @override
  State<StudentLeaveRequestsScreen> createState() => _StudentLeaveRequestsScreenState();
}

class _StudentLeaveRequestsScreenState extends State<StudentLeaveRequestsScreen> {
  List<dynamic> _leaves = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLeaves();
  }

  Future<void> _fetchLeaves() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final res = await LeaveService.getMyLeaves(token: token);
      if (res['success'] == true || res['leaves'] != null) {
        setState(() => _leaves = res['leaves'] ?? []);
      } else {
        setState(() => _errorMessage = res['message'] ?? 'Failed to load leave requests');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showApplySheet() {
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Apply for Leave',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMain),
            ),
            const SizedBox(height: 6),
            Text(
              'Submit your leave request for approval',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),

            // Start Date
            _buildDateField(
              label: 'Start Date',
              controller: startCtrl,
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (c, child) => Theme(
                    data: Theme.of(c).copyWith(
                      colorScheme: const ColorScheme.light(primary: AppColors.primary),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  startDate = picked;
                  startCtrl.text = DateFormat('dd MMM yyyy').format(picked);
                }
              },
            ),
            const SizedBox(height: 16),

            // End Date
            _buildDateField(
              label: 'End Date',
              controller: endCtrl,
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: startDate ?? DateTime.now(),
                  firstDate: startDate ?? DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (c, child) => Theme(
                    data: Theme.of(c).copyWith(
                      colorScheme: const ColorScheme.light(primary: AppColors.primary),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  endDate = picked;
                  endCtrl.text = DateFormat('dd MMM yyyy').format(picked);
                }
              },
            ),
            const SizedBox(height: 16),

            // Reason
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Reason',
                hintText: 'Explain your reason for leave...',
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (startDate == null || endDate == null || reasonCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields'), behavior: SnackBarBehavior.floating),
                    );
                    return;
                  }
                  final token = Provider.of<AuthProvider>(context, listen: false).token;
                  if (token == null) return;
                  try {
                    await LeaveService.applyLeave(
                      token: token,
                      startDate: startDate!.toIso8601String(),
                      endDate: endDate!.toIso8601String(),
                      reason: reasonCtrl.text.trim(),
                    );
                    if (mounted) Navigator.pop(ctx);
                    _fetchLeaves();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Leave applied successfully!'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), behavior: SnackBarBehavior.floating),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Submit Leave Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({required String label, required TextEditingController controller, required VoidCallback onTap}) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        hintText: 'Select date',
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Leave Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textMain,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showApplySheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Apply Leave', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const ShimmerListView(itemCount: 5)
          : _errorMessage != null
              ? ErrorRetryWidget(
                  message: _errorMessage!,
                  onRetry: _fetchLeaves,
                )
              : _leaves.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _fetchLeaves,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _leaves.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) => _buildLeaveCard(_leaves[i]),
                      ),
                    ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: Icons.event_available_rounded,
      title: 'No Leave Requests',
      subtitle: 'Apply for leave easily by tapping the button below.',
      actionText: 'Apply Leave Now',
      onAction: _showApplySheet,
      iconColor: Colors.teal,
    );
  }

  Widget _buildLeaveCard(Map<String, dynamic> leave) {
    final status = (leave['status'] ?? 'pending').toString().toLowerCase();
    final startDate = leave['startDate'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(leave['startDate'])) : '—';
    final endDate = leave['endDate'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(leave['endDate'])) : '—';
    final reason = leave['reason'] ?? 'No reason provided';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'approved':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = AppColors.warning;
        statusIcon = Icons.hourglass_top_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppThemeDesign.borderRadiusMedium,
        boxShadow: const [AppThemeDesign.cardShadow],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(statusIcon, size: 20, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$startDate — $endDate',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reason,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
