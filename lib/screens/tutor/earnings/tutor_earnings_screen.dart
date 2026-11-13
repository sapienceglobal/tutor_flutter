import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/payout_service.dart';
import '../../../utils/constants.dart';
import '../../../widgets/shimmer_loader.dart';
import '../../../widgets/error_retry.dart';

class TutorEarningsScreen extends StatefulWidget {
  const TutorEarningsScreen({super.key});

  @override
  State<TutorEarningsScreen> createState() => _TutorEarningsScreenState();
}

class _TutorEarningsScreenState extends State<TutorEarningsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _reportData;
  List<dynamic> _payoutsList = [];

  // Payout request variables
  final _amountController = TextEditingController();
  final _holderController = TextEditingController();
  final _bankController = TextEditingController();
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _upiController = TextEditingController();
  String _payoutMethod = 'bank'; // 'bank' or 'upi'

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await PayoutService.getPayoutReport();
      setState(() {
        _reportData = data;
        _payoutsList = data['payouts'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelPayout(String id) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this pending payout request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final res = await PayoutService.cancelPayout(id);
                if (res['success'] == true) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payout request cancelled successfully.')),
                    );
                  }
                  _fetchReport();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cancellation failed: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRequestPayoutSheet() {
    final summary = _reportData?['summary'] ?? {};
    final withdrawable = (summary['withdrawableBalance'] ?? 0.0) as num;
    final minAmount = (summary['minimumPayoutAmount'] ?? 500) as num;

    if (withdrawable < minAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Withdrawable balance (₹${withdrawable.toStringAsFixed(2)}) is less than minimum payout (₹$minAmount)',
          ),
        ),
      );
      return;
    }

    _amountController.text = withdrawable.toStringAsFixed(2);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Request Payout Withdrawal',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'Available Withdrawable: ₹${withdrawable.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Withdrawal Amount (INR)',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choose Payout Route',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Bank Transfer'),
                        selected: _payoutMethod == 'bank',
                        onSelected: (val) => setSheetState(() => _payoutMethod = 'bank'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('UPI ID'),
                        selected: _payoutMethod == 'upi',
                        onSelected: (val) => setSheetState(() => _payoutMethod = 'upi'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_payoutMethod == 'bank') ...[
                  TextField(
                    controller: _holderController,
                    decoration: const InputDecoration(
                      labelText: 'Account Holder Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bankController,
                    decoration: const InputDecoration(
                      labelText: 'Bank Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _accountController,
                    decoration: const InputDecoration(
                      labelText: 'Account Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ifscController,
                    decoration: const InputDecoration(
                      labelText: 'IFSC Code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: _upiController,
                    decoration: const InputDecoration(
                      labelText: 'UPI Address / ID',
                      hintText: 'e.g. mobile@upi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final reqAmt = double.tryParse(_amountController.text) ?? 0.0;
                    if (reqAmt < minAmount || reqAmt > withdrawable) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        SnackBar(content: Text('Invalid amount. Must be between ₹$minAmount and ₹$withdrawable')),
                      );
                      return;
                    }

                    final bankDetails = <String, dynamic>{};
                    if (_payoutMethod == 'bank') {
                      if (_holderController.text.trim().isEmpty ||
                          _bankController.text.trim().isEmpty ||
                          _accountController.text.trim().isEmpty ||
                          _ifscController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(content: Text('Please fill all bank details!')),
                        );
                        return;
                      }
                      bankDetails['accountHolderName'] = _holderController.text.trim();
                      bankDetails['bankName'] = _bankController.text.trim();
                      bankDetails['accountNumber'] = _accountController.text.trim();
                      bankDetails['ifscCode'] = _ifscController.text.trim();
                    } else {
                      if (_upiController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(content: Text('Please enter UPI ID!')),
                        );
                        return;
                      }
                      bankDetails['upiId'] = _upiController.text.trim();
                    }

                    Navigator.pop(sheetContext);
                    setState(() => _isLoading = true);

                    try {
                      final res = await PayoutService.requestPayout(
                        amount: reqAmt,
                        bankDetails: bankDetails,
                      );
                      if (res['success'] == true) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Payout requested successfully! 🎉')),
                          );
                        }
                        _fetchReport();
                      }
                    } catch (e) {
                      setState(() => _isLoading = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Payout request failed: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Submit Request',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Earnings & Payout Console', style: TextStyle(fontWeight: FontWeight.bold)),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF134E5E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const ShimmerDashboard(),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Earnings & Payout Console', style: TextStyle(fontWeight: FontWeight.bold)),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF134E5E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: ErrorRetryWidget(
          message: _errorMessage!,
          onRetry: _fetchReport,
        ),
      );
    }

    final summary = _reportData?['summary'] ?? {};
    final totalEarnings = (summary['totalEarnings'] ?? 0.0) as num;
    final withdrawable = (summary['withdrawableBalance'] ?? 0.0) as num;
    final pending = (summary['pendingAmount'] ?? 0.0) as num;
    final paidOut = (summary['paidAmount'] ?? 0.0) as num;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Earnings & Payout Console', style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF134E5E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF0D9488),
        onRefresh: _fetchReport,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── WITHDRAWAL HERO CARD ───
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppThemeDesign.borderRadiusMedium,
                  boxShadow: const [AppThemeDesign.brandShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Withdrawable Balance',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${withdrawable.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showRequestPayoutSheet,
                          icon: const Icon(Icons.account_balance_wallet, size: 16),
                          label: const Text('Withdraw'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMiniSummaryText('Total Earnings', '₹${totalEarnings.toStringAsFixed(2)}'),
                        _buildMiniSummaryText('Pending Payouts', '₹${pending.toStringAsFixed(2)}'),
                        _buildMiniSummaryText('Paid Out', '₹${paidOut.toStringAsFixed(2)}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── MONTHLY REVENUE LINE CHART ───
              const Text(
                'Monthly Sales Revenue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              Container(
                height: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppThemeDesign.borderRadiusMedium,
                  boxShadow: const [AppThemeDesign.cardShadow],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: _buildRevenueChart(),
              ),
              const SizedBox(height: 24),

              // ─── COURSE SPLIT BREAKDOWN ───
              const Text(
                'Earnings by Curriculum',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              _buildCourseRevenueList(),
              const SizedBox(height: 24),

              // ─── PAYOUT LOGS HISTORY ───
              const Text(
                'Payout History Logs',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              _buildPayoutHistoryList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniSummaryText(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildRevenueChart() {
    final List<dynamic> monthly = _reportData?['monthlyRevenue'] ?? [];
    if (monthly.isEmpty) {
      return const Center(child: Text('No sales records to plot.'));
    }

    final double maxRev = monthly.fold<double>(
      0.0,
      (max, item) => (item['revenue'] as num).toDouble() > max ? (item['revenue'] as num).toDouble() : max,
    );

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int idx = value.toInt();
                if (idx < 0 || idx >= monthly.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    monthly[idx]['monthLabel'] ?? '',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('₹0');
                if (value >= 1000) {
                  return Text('₹${(value / 1000).toStringAsFixed(0)}k');
                }
                return Text('₹${value.toStringAsFixed(0)}');
              },
              reservedSize: 42,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: monthly.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), (e.value['revenue'] as num).toDouble());
            }).toList(),
            isCurved: true,
            color: const Color(0xFF0D9488),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF0D9488).withValues(alpha: 0.08),
            ),
          ),
        ],
        minY: 0,
        maxY: maxRev > 0 ? maxRev * 1.2 : 1000,
      ),
    );
  }

  Widget _buildCourseRevenueList() {
    final List<dynamic> courses = _reportData?['courseRevenue'] ?? [];
    if (courses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No courses with enrollment transactions found.'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      itemBuilder: (ctx, index) {
        final c = courses[index];
        final rev = (c['revenue'] ?? 0.0) as num;
        final enrolls = c['enrollments'] ?? 0;
        final share = c['revenueSharePct'] ?? 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppThemeDesign.borderRadiusMedium,
            boxShadow: const [AppThemeDesign.softShadow],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.school_outlined, color: Colors.teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c['title'] ?? 'Untitled Course',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$enrolls enrollments • $share% share',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${rev.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPayoutHistoryList() {
    if (_payoutsList.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No payout transactions requested yet.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _payoutsList.length,
      itemBuilder: (ctx, index) {
        final p = _payoutsList[index];
        final amount = (p['amount'] ?? 0.0) as num;
        final status = p['status'] ?? 'pending';
        final isCancelable = status == 'pending';
        final created = p['createdAt'] != null
            ? DateTime.tryParse(p['createdAt'])?.toLocal().toString().substring(0, 16) ?? ''
            : '';

        Color statusColor;
        switch (status) {
          case 'paid':
            statusColor = Colors.green;
            break;
          case 'processing':
            statusColor = Colors.orange;
            break;
          case 'rejected':
            statusColor = Colors.red;
            break;
          default:
            statusColor = Colors.indigo;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppThemeDesign.borderRadiusMedium,
            boxShadow: const [AppThemeDesign.softShadow],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    created,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isCancelable) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _cancelPayout(p['_id']),
                      child: const Text(
                        'Cancel Request',
                        style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
