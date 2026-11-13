import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/leave_service.dart';
import '../../../services/tutor_service.dart';
import '../../../models/tutor_model.dart';
import '../../../utils/constants.dart';

class TutorLeaveRequestsScreen extends StatefulWidget {
  const TutorLeaveRequestsScreen({super.key});

  @override
  State<TutorLeaveRequestsScreen> createState() => _TutorLeaveRequestsScreenState();
}

class _TutorLeaveRequestsScreenState extends State<TutorLeaveRequestsScreen> {
  List<dynamic> _leaves = [];
  List<TutorModel> _otherTutors = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeavesAndTutors();
  }

  Future<void> _fetchLeavesAndTutors() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    setState(() => _loading = true);
    try {
      final res = await LeaveService.getMyLeaves(token: token);
      final tutorsList = await TutorService.getAllTutors();
      setState(() {
        _leaves = res['leaves'] ?? [];
        _otherTutors = tutorsList;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e'), behavior: SnackBarBehavior.floating),
        );
      }
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
    String? selectedSubstituteId;
    String selectedLeaveType = 'Sick Leave';

    final leaveTypes = [
      'Sick Leave', 'Medical Appointment', 'Personal Reasons',
      'Family Emergency', 'Family Function', 'Conference / Training', 'Vacation', 'Other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  'Request a Leave',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMain),
                ),
                const SizedBox(height: 6),
                Text(
                  'Submit your leave request with dates and reasons',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                const SizedBox(height: 20),

                // Leave Type
                const Text('Leave Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedLeaveType,
                  items: leaveTypes.map((type) => DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontSize: 14)))).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedLeaveType = val);
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

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
                    );
                    if (picked != null) {
                      startDate = picked;
                      startCtrl.text = DateFormat('dd MMM yyyy').format(picked);
                      setModalState(() {});
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
                    );
                    if (picked != null) {
                      endDate = picked;
                      endCtrl.text = DateFormat('dd MMM yyyy').format(picked);
                      setModalState(() {});
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Substitute Tutor Dropdown
                const Text('Substitute Instructor (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  initialValue: selectedSubstituteId,
                  hint: const Text('Select a substitute', style: TextStyle(fontSize: 14)),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('No substitute needed', style: TextStyle(fontSize: 14))),
                    ..._otherTutors.map((t) => DropdownMenuItem<String?>(value: t.id, child: Text(t.user.name, style: const TextStyle(fontSize: 14)))),
                  ],
                  onChanged: (val) {
                    setModalState(() => selectedSubstituteId = val);
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                // Reason
                TextField(
                  controller: reasonCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Reason',
                    hintText: 'Provide complete reason...',
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
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
                          reason: '[$selectedLeaveType] ${reasonCtrl.text.trim()}',
                          leaveType: selectedLeaveType,
                        );
                        if (mounted) Navigator.pop(ctx);
                        _fetchLeavesAndTutors();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Leave requested successfully!'),
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
                    child: const Text('Submit Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Instructor Leave Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textMain,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showApplySheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Request Leave', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _leaves.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _fetchLeavesAndTutors,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_available_rounded, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('No Leaves Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
          const SizedBox(height: 8),
          Text('Tap Request Leave to submit a new leave', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildLeaveCard(Map<String, dynamic> leave) {
    final status = (leave['status'] ?? 'pending').toString().toLowerCase();
    final startDate = leave['startDate'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(leave['startDate'])) : '—';
    final endDate = leave['endDate'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(leave['endDate'])) : '—';
    
    // Parse leave type from reason if encapsulated e.g. [Sick Leave] Reason
    final rawReason = leave['reason'] ?? 'No reason provided';
    final match = RegExp(r'^\[(.+?)\]\s*(.*)').firstMatch(rawReason);
    final leaveType = match?.group(1) ?? 'Leave';
    final reason = match?.group(2) ?? rawReason;

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
                      'Type: $leaveType',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
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
