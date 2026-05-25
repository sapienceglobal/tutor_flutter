import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../models/subscription_plan_model.dart';
import '../../../models/institute_model.dart';
import '../../../services/subscription_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _subscriptionService = SubscriptionService();
  late Razorpay _razorpay;

  Institute? _institute;
  List<SubscriptionPlan> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadData();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final institute = await _subscriptionService.fetchInstituteData();
      final plans = await _subscriptionService.fetchPlans();
      setState(() {
        _institute = institute;
        _plans = plans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Verify on backend
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await _subscriptionService.verifyPayment({
        'razorpayOrderId': response.orderId,
        'razorpayPaymentId': response.paymentId,
        'razorpaySignature': response.signature,
      });

      if (mounted) Navigator.pop(context); // close loader

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription Upgraded Successfully! 🎉')),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment verification failed.')),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification Error: $e')));
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet: ${response.walletName}')),
    );
  }

  void _initiateUpgrade(SubscriptionPlan plan) async {
    if (_institute == null) return;

    try {
      final orderData = await _subscriptionService.createRenewalOrder(plan.id, _institute!.id);
      
      var options = {
        'key': orderData['key'],
        'amount': orderData['order']['amount'],
        'name': 'Sapience LMS',
        'order_id': orderData['order']['id'],
        'description': 'Upgrade to ${plan.name} Plan',
        'prefill': {
          'name': _institute!.name,
          'email': _institute!.contactEmail ?? '',
        },
        'theme': {'color': '#6B4DF1'}
      };

      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  LinearGradient _getPlanGradient(String plan) {
    switch (plan.toLowerCase()) {
      case 'enterprise':
      case 'enterprise plus':
        return const LinearGradient(colors: [Color(0xFF6B4DF1), Color(0xFF8B73F7)]);
      case 'pro':
        return const LinearGradient(colors: [Color(0xFF4F7BF0), Color(0xFF6EA0FF)]);
      case 'starter':
      case 'basic':
        return const LinearGradient(colors: [Color(0xFF4ABCA8), Color(0xFF60D3C0)]);
      default:
        return const LinearGradient(colors: [Color(0xFFA0ABC0), Color(0xFFCBD5E1)]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription & Billing'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentPlanHero(),
                  const SizedBox(height: 24),
                  const Text('Usage Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildUsageSection(),
                  const SizedBox(height: 24),
                  const Text('Available Plans', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildPlansList(),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentPlanHero() {
    if (_institute == null) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: _getPlanGradient(_institute!.subscriptionPlan),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium, color: Colors.white, size: 48),
          const SizedBox(height: 8),
          Text(
            '${_institute!.subscriptionPlan.toUpperCase()} PLAN',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(backgroundColor: _institute!.isExpired ? Colors.red : Colors.green, radius: 4),
                const SizedBox(width: 8),
                Text(
                  _institute!.isExpired ? 'EXPIRED' : 'ACTIVE',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Valid Until: ${_institute!.subscriptionExpiresAt != null ? DateFormat('MMMM d, yyyy').format(_institute!.subscriptionExpiresAt!) : 'Lifetime'}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageSection() {
    if (_institute == null) return const SizedBox();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildUsageRow('Instructors', _institute!.maxTutors),
            const Divider(),
            _buildUsageRow('Students', _institute!.maxStudents),
            const Divider(),
            _buildUsageRow('Storage (GB)', _institute!.storageLimitGB),
            const Divider(),
            _buildUsageRow('AI Credits', _institute!.aiCreditsPerMonth, isCredits: true),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageRow(String label, int value, {bool isCredits = false}) {
    String displayValue = value == -1 ? 'Unlimited' : value.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(displayValue, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildPlansList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _plans.length,
      itemBuilder: (context, index) {
        final plan = _plans[index];
        final isCurrent = plan.name.toLowerCase() == _institute?.subscriptionPlan.toLowerCase();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isCurrent ? const BorderSide(color: Color(0xFF6B4DF1), width: 2) : BorderSide.none,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(plan.description ?? '', style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                Text(
                  '${plan.currency} ${plan.price} / ${plan.billingCycle}',
                  style: const TextStyle(color: Color(0xFF6B4DF1), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            trailing: isCurrent
                ? const Chip(label: Text('Current'), backgroundColor: Colors.green, labelStyle: TextStyle(color: Colors.white, fontSize: 10))
                : ElevatedButton(
                    onPressed: () => _initiateUpgrade(plan),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B4DF1), foregroundColor: Colors.white),
                    child: const Text('Upgrade'),
                  ),
          ),
        );
      },
    );
  }
}
