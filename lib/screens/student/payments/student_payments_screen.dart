import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/payment_service.dart';
import '../../../utils/constants.dart';

import '../../../widgets/shimmer_loader.dart';

class StudentPaymentsScreen extends StatefulWidget {
  const StudentPaymentsScreen({super.key});

  @override
  State<StudentPaymentsScreen> createState() => _StudentPaymentsScreenState();
}

class _StudentPaymentsScreenState extends State<StudentPaymentsScreen> {
  final _paymentService = PaymentService();
  bool _isLoading = true;
  List<dynamic> _payments = [];

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    setState(() => _isLoading = true);
    try {
      final list = await _paymentService.getMyPayments();
      setState(() {
        _payments = list;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load payment history: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Billing & Payment History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPayments,
          ),
        ],
      ),
      body: _isLoading
          ? const ShimmerListView()
          : _payments.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: Colors.green,
                  onRefresh: _fetchPayments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _payments.length,
                    itemBuilder: (ctx, i) {
                      return _buildPaymentCard(_payments[i]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.green),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Payments Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain),
            ),
            const SizedBox(height: 8),
            Text(
              'You do not have any transaction invoices or active billing history.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(dynamic payment) {
    final amount = payment['amount'] ?? 0;
    final status = payment['status'] ?? 'pending';
    final courseName = payment['course']?['title'] ?? payment['courseTitle'] ?? 'Course Enrollment';
    final razorpayId = payment['razorpayPaymentId'] ?? payment['paymentId'] ?? '—';
    final createdAtStr = payment['createdAt'];
    
    String dateLabel = '—';
    if (createdAtStr != null) {
      dateLabel = DateFormat('dd MMM yyyy, h:mm a').format(DateTime.parse(createdAtStr).toLocal());
    }

    final lowercaseStatus = status.toString().toLowerCase();
    final isSuccess = lowercaseStatus == 'completed' || lowercaseStatus == 'success' || lowercaseStatus == 'paid';
    final isRefunded = lowercaseStatus == 'refunded';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppThemeDesign.borderRadiusMedium,
        boxShadow: const [AppThemeDesign.cardShadow],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSuccess 
                    ? Colors.green.withValues(alpha: 0.1) 
                    : isRefunded 
                        ? Colors.grey.withValues(alpha: 0.1)
                        : Colors.amber.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess 
                    ? Icons.check_circle_outline 
                    : isRefunded 
                        ? Icons.settings_backup_restore_outlined
                        : Icons.pending_actions_outlined,
                color: isSuccess 
                    ? Colors.green 
                    : isRefunded 
                        ? Colors.grey 
                        : Colors.amber.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          courseName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain),
                        ),
                      ),
                      Text(
                        '₹$amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSuccess 
                              ? Colors.green.shade700 
                              : isRefunded 
                                  ? Colors.grey.shade700
                                  : Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ref ID: $razorpayId',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateLabel,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSuccess 
                              ? Colors.green.withValues(alpha: 0.08) 
                              : isRefunded 
                                  ? Colors.grey.withValues(alpha: 0.08)
                                  : Colors.amber.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status.toString().toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isSuccess 
                                ? Colors.green 
                                : isRefunded 
                                    ? Colors.grey 
                                    : Colors.amber.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
