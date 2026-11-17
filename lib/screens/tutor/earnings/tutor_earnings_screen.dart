import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../providers/workspace_provider.dart';
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
  Map<String, dynamic>? _payoutAccount;
  Map<String, dynamic>? _privateTeaching;

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
      final results = await Future.wait<dynamic>([
        PayoutService.getPayoutReport(),
        PayoutService.getMyPayoutAccount().catchError((_) => <String, dynamic>{}),
      ]);
      final data = results[0] as Map<String, dynamic>;
      final accountRes = results[1] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _reportData = data;
        _payoutsList = data['payouts'] ?? [];
        _payoutAccount = accountRes['payoutAccount'] is Map
            ? Map<String, dynamic>.from(accountRes['payoutAccount'])
            : null;
        _privateTeaching = accountRes['privateTeaching'] is Map
            ? Map<String, dynamic>.from(accountRes['privateTeaching'])
            : null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
              const SizedBox(height: 20),

              _buildPayoutKycAndStudioCard(),
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

  Widget _buildPayoutKycAndStudioCard() {
    final account = _payoutAccount ?? {};
    final studio = _privateTeaching ?? {};
    final status = (account['verificationStatus'] ?? 'not_configured').toString();
    final method = (account['method'] ?? '').toString();
    final holder = (account['accountHolderName'] ?? '').toString();
    final bankName = (account['bankName'] ?? '').toString();
    final accMasked = (account['accountNumberMasked'] ?? '').toString();
    final ifsc = (account['ifscCode'] ?? '').toString();
    final upi = (account['upiId'] ?? '').toString();
    final rejectionReason = (account['rejectionReason'] ?? '').toString();

    final bool isEnabled = studio['isEnabled'] == true;
    final bool acceptRequests = studio['acceptSelfJoinRequests'] != false;
    final String headline = (studio['headline'] ?? '').toString();
    final String city = (studio['city'] ?? '').toString();

    Color badgeColor;
    String badgeLabel;
    switch (status) {
      case 'verified':
        badgeColor = AppColors.success;
        badgeLabel = 'VERIFIED';
        break;
      case 'pending':
        badgeColor = Colors.orange;
        badgeLabel = 'PENDING REVIEW';
        break;
      case 'rejected':
        badgeColor = AppColors.error;
        badgeLabel = 'REJECTED';
        break;
      default:
        badgeColor = Colors.blueGrey;
        badgeLabel = 'NOT CONFIGURED';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppThemeDesign.borderRadiusMedium,
        boxShadow: const [AppThemeDesign.softShadow],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payout KYC & Private Studio',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Required for Online Razorpay fees in Private Studio',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: method == 'upi' && upi.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UPI ID: $upi',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      if (holder.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Account Holder: $holder',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ],
                  )
                : method == 'bank_account' && (bankName.isNotEmpty || accMasked.isNotEmpty)
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${bankName.isNotEmpty ? bankName : 'Bank'} • $accMasked',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Holder: $holder${ifsc.isNotEmpty ? '  •  IFSC: $ifsc' : ''}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                      )
                    : Text(
                        'Add your Bank Account or UPI ID to verify payout KYC. Until verified, paid Private Studio courses only support Offline / Direct fee collection.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
          ),
          if (status == 'rejected' && rejectionReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Rejection note: $rejectionReason',
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showConfigurePayoutAccountSheet,
                  icon: const Icon(Icons.account_balance_outlined, size: 17),
                  label: Text(
                    status == 'not_configured'
                        ? 'Configure Bank / UPI'
                        : 'Update Bank / UPI',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Private Tuition Studio',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isEnabled ? AppColors.success : Colors.grey)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isEnabled ? 'ACTIVE' : 'OFF',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isEnabled ? AppColors.success : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isEnabled
                          ? '${acceptRequests ? 'Accepting student join requests' : 'Invite/manual add only'}${headline.isNotEmpty ? ' • $headline' : ''}${city.isNotEmpty ? ' ($city)' : ''}'
                          : 'Enable Private Tuition Studio to teach students directly outside institutes.',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _showPrivateStudioSettingsDialog,
                icon: const Icon(Icons.tune_rounded, size: 17),
                label: const Text('Settings'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showConfigurePayoutAccountSheet() {
    final account = _payoutAccount ?? {};
    String selectedMethod = account['method']?.toString() == 'upi'
        ? 'upi'
        : 'bank_account';
    String holderName = (account['accountHolderName'] ?? '').toString();
    String bankName = (account['bankName'] ?? '').toString();
    String accountNumber = '';
    String ifscCode = (account['ifscCode'] ?? '').toString();
    String upiId = (account['upiId'] ?? '').toString();
    bool isSaving = false;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configure Payout Account (KYC)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Verified Bank or UPI details unlock Online Razorpay fee collection in your Private Studio.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Bank Account')),
                            selected: selectedMethod == 'bank_account',
                            onSelected: (_) =>
                                setSheetState(() => selectedMethod = 'bank_account'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('UPI ID')),
                            selected: selectedMethod == 'upi',
                            onSelected: (_) =>
                                setSheetState(() => selectedMethod = 'upi'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      initialValue: holderName,
                      onChanged: (v) => holderName = v,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Enter account holder name' : null,
                      decoration: const InputDecoration(
                        labelText: 'Account Holder Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (selectedMethod == 'bank_account') ...[
                      TextFormField(
                        initialValue: bankName,
                        onChanged: (v) => bankName = v,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Enter bank name' : null,
                        decoration: const InputDecoration(
                          labelText: 'Bank Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: accountNumber,
                        onChanged: (v) => accountNumber = v,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final trimmed = v?.trim() ?? '';
                          if (!RegExp(r'^\d{8,20}$').hasMatch(trimmed)) {
                            return 'Enter 8–20 digit account number';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Account Number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: ifscCode,
                        onChanged: (v) => ifscCode = v.toUpperCase(),
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) {
                          final trimmed = (v ?? '').trim().toUpperCase();
                          if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(trimmed)) {
                            return 'Enter valid 11-char IFSC (e.g. HDFC0001234)';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'IFSC Code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ] else ...[
                      TextFormField(
                        initialValue: upiId,
                        onChanged: (v) => upiId = v,
                        validator: (v) {
                          final trimmed = (v ?? '').trim();
                          if (!RegExp(r'^[\w.-]{2,}@[a-zA-Z]{2,}$').hasMatch(trimmed)) {
                            return 'Enter valid UPI ID (e.g. name@okaxis)';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'UPI ID',
                          hintText: 'tutor@okaxis',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!(formKey.currentState?.validate() ?? false)) {
                                  return;
                                }
                                setSheetState(() => isSaving = true);
                                try {
                                  await PayoutService.upsertMyPayoutAccount(
                                    method: selectedMethod,
                                    accountHolderName: holderName,
                                    bankName: selectedMethod == 'bank_account'
                                        ? bankName
                                        : null,
                                    accountNumber: selectedMethod == 'bank_account'
                                        ? accountNumber
                                        : null,
                                    ifscCode: selectedMethod == 'bank_account'
                                        ? ifscCode
                                        : null,
                                    upiId: selectedMethod == 'upi' ? upiId : null,
                                  );
                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Payout details saved! Sent for KYC verification.',
                                        ),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                    _fetchReport();
                                  }
                                } catch (e) {
                                  setSheetState(() => isSaving = false);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to save KYC details: $e'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save & Submit for KYC',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
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

  void _showPrivateStudioSettingsDialog() {
    final studio = _privateTeaching ?? {};
    bool isEnabled = studio['isEnabled'] == true;
    bool acceptSelfJoinRequests = studio['acceptSelfJoinRequests'] != false;
    String headline = (studio['headline'] ?? '').toString();
    String city = (studio['city'] ?? '').toString();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Private Studio Settings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable Private Tuition Studio'),
                    subtitle: const Text(
                      'Teach private students outside your institutes',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: isEnabled,
                    onChanged: (val) => setDialogState(() => isEnabled = val),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Accept Student Join Requests'),
                    subtitle: const Text(
                      'Let students search your studio & request to connect',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: acceptSelfJoinRequests,
                    onChanged: isEnabled
                        ? (val) =>
                            setDialogState(() => acceptSelfJoinRequests = val)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: headline,
                    onChanged: (v) => headline = v,
                    decoration: const InputDecoration(
                      labelText: 'Studio Headline',
                      hintText: 'e.g. IIT-JEE Physics & Math Mentor',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: city,
                    onChanged: (v) => city = v,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      hintText: 'e.g. Kota / Delhi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        setDialogState(() => isSaving = true);
                        try {
                          await PayoutService.updatePrivateTeachingSettings(
                            isEnabled: isEnabled,
                            acceptSelfJoinRequests: acceptSelfJoinRequests,
                            headline: headline,
                            city: city,
                          );
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (mounted) {
                            await Provider.of<WorkspaceProvider>(
                              context,
                              listen: false,
                            ).refreshWorkspace();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Private Studio settings updated!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            _fetchReport();
                          }
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('Update failed: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(isSaving ? 'Saving...' : 'Save Settings'),
              ),
            ],
          );
        },
      ),
    );
  }
}
