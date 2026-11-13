import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../models/subscription_plan_model.dart';
import '../../../services/subscription_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../utils/constants.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';

class PersonalSubscriptionScreen extends StatefulWidget {
  const PersonalSubscriptionScreen({super.key});

  @override
  State<PersonalSubscriptionScreen> createState() => _PersonalSubscriptionScreenState();
}

class _PersonalSubscriptionScreenState extends State<PersonalSubscriptionScreen> {
  final _subscriptionService = SubscriptionService();
  late Razorpay _razorpay;

  List<SubscriptionPlan> _plans = [];
  bool _isLoading = true;
  Map<String, dynamic>? _personalSub;
  String _userRole = 'student';

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
      // 1. Fetch available plans
      final plans = await _subscriptionService.fetchPlans();
      
      // 2. Fetch current profile
      final token = await AuthService.getToken();
      final profileRes = await ApiService.get('/auth/me', token: token);
      
      setState(() {
        _plans = plans;
        if (profileRes['success'] == true && profileRes['user'] != null) {
          _personalSub = profileRes['user']['personalSubscription'];
          _userRole = profileRes['user']['role'] ?? 'student';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load subscription details: $e')),
        );
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Personal Subscription Activated Successfully! 🎉')),
          );
          // Refresh user context in providers
          Provider.of<AuthProvider>(context, listen: false).refreshUser();
          Provider.of<SubscriptionProvider>(context, listen: false).fetchSubscriptionData();
        }
        _loadData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment verification failed.')),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification Error: $e')),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Cancelled/Failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet Selected: ${response.walletName}')),
    );
  }

  void _initiatePersonalUpgrade(SubscriptionPlan plan) async {
    setState(() => _isLoading = true);
    try {
      final orderData = await _subscriptionService.createPersonalRenewalOrder(plan.id);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      var options = {
        'key': orderData['key'],
        'amount': orderData['order']['amount'],
        'name': 'Sapience Learning Platform',
        'order_id': orderData['order']['id'],
        'description': 'Upgrade to ${plan.name} Personal Plan',
        'prefill': {
          'name': user?.name ?? 'User',
          'email': user?.email ?? '',
        },
        'theme': {'color': '#6B4DF1'}
      };

      setState(() => _isLoading = false);
      _razorpay.open(options);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize subscription: $e')),
        );
      }
    }
  }

  LinearGradient _getPlanGradient(String planName) {
    switch (planName.toLowerCase()) {
      case 'premium':
      case 'pro':
      case 'elite':
      case 'gold':
        return const LinearGradient(
          colors: [Color(0xFF6B4DF1), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'standard':
      case 'silver':
        return const LinearGradient(
          colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveSub = _personalSub?['isActive'] == true;
    final planName = _personalSub?['planName'] ?? 'Free Tier';
    final expiryStr = _personalSub?['subscriptionExpiresAt'];
    String expiryLabel = 'No Expiry';
    if (expiryStr != null) {
      expiryLabel = DateFormat('MMMM d, yyyy').format(DateTime.parse(expiryStr).toLocal());
    }

    final personalRemainingCredits = hasActiveSub 
        ? ((_personalSub?['features']?['aiCreditsPerMonth'] ?? 0) - (_personalSub?['features']?['aiUsageCount'] ?? 0))
        : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Personal Subscription Hub', style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF27225B), Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── ACTIVE PLAN HERO CARD ───
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: _getPlanGradient(planName),
                      borderRadius: AppThemeDesign.borderRadiusMedium,
                      boxShadow: const [AppThemeDesign.brandShadow],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.stars_rounded, color: Colors.amber, size: 48),
                        const SizedBox(height: 10),
                        Text(
                          '${planName.toUpperCase()} MEMBERSHIP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            hasActiveSub ? 'ACTIVE SUBSCRIBER' : 'FREE USER',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (hasActiveSub) ...[
                          Text(
                            'Personal AI Credits remaining: $personalRemainingCredits',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          hasActiveSub ? 'Valid Until: $expiryLabel' : 'Upgrade to access next-gen tools & analytics',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ─── PREMIUM PERKS CHECKLIST ───
                  const Text(
                    'Exclusive Premium Perks',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),
                  _buildPremiumFeaturesList(),
                  const SizedBox(height: 28),

                  // ─── AVAILABLE PLANS LIST ───
                  const Text(
                    'Choose Your Upgrade Plan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),
                  _buildPlansSection(planName),
                ],
              ),
            ),
    );
  }

  Widget _buildPremiumFeaturesList() {
    final features = _userRole == 'tutor'
        ? [
            {'title': 'AI Dropout Risk Predictor', 'subtitle': 'Identify students who are struggling or risk dropping out.'},
            {'title': 'AI Weak Topics Analyzer', 'subtitle': 'Understand which curriculum topics need more revision in classes.'},
            {'title': 'Automated Exam Proctoring', 'subtitle': 'Monitor test integrity with audio/video and tab-switch sensors.'},
            {'title': 'Private Course AI Assistants', 'subtitle': 'Equip your private classes with interactive chatbot assistants.'},
          ]
        : [
            {'title': 'AI Study Co-Pilot & Chats', 'subtitle': 'Get 1-on-1 AI tutoring & notes simplified.'},
            {'title': 'Subjective Grading Rubrics', 'subtitle': 'Upload answer keys and get dynamic scoring.'},
            {'title': 'Plagiarism Detection Tools', 'subtitle': 'Verify originality before final test submissions.'},
            {'title': 'Extended Learning Events', 'subtitle': 'Participate in premium live webinars & interactive workshops.'},
          ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppThemeDesign.borderRadiusMedium,
        boxShadow: const [AppThemeDesign.softShadow],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: features.map((f) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF4F46E5), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f['title']!,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        f['subtitle']!,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlansSection(String currentPlanName) {
    final filteredPlans = _plans.where((p) => p.planRole == _userRole || p.planRole == 'all').toList();
    
    if (filteredPlans.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No public pricing plans configured at this time.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredPlans.length,
      itemBuilder: (ctx, index) {
        final plan = filteredPlans[index];
        final isCurrent = plan.name.toLowerCase() == currentPlanName.toLowerCase();
        
        final hasAiAssistant = plan.features['aiAssistant'] == true;
        final hasAiAssessment = plan.features['aiAssessment'] == true;
        final hasAiIntelligence = plan.features['aiIntelligence'] == true;
        final aiCredits = plan.features['aiCreditsPerMonth'] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppThemeDesign.borderRadiusMedium,
            boxShadow: const [AppThemeDesign.softShadow],
            border: Border.all(
              color: isCurrent ? const Color(0xFF4F46E5) : Colors.grey.shade100,
              width: isCurrent ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        if (plan.description != null && plan.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            plan.description!,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  isCurrent
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'CURRENT',
                            style: TextStyle(color: Colors.green.shade800, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () => _initiatePersonalUpgrade(plan),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text('Select'),
                        ),
                ],
              ),
              const Divider(height: 24, thickness: 0.5),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '₹${plan.price.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 22),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/ ${plan.billingCycle}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              
              // ─── SPECIFIC DETAILED FEATURES LIST (AS PER WEBSITE) ───
              _buildFeatureDetailRow('AI Assistant Chat', hasAiAssistant),
              _buildFeatureDetailRow('AI Homework Evaluation & Proctoring', hasAiAssessment),
              _buildFeatureDetailRow('AI Insights & Risk Analytics', hasAiIntelligence),
              if (aiCredits > 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.bolt, color: Colors.amber, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '$aiCredits AI credits per month included',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureDetailRow(String label, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
            color: active ? const Color(0xFF10B981) : Colors.grey.shade300,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: active ? Colors.grey.shade800 : Colors.grey.shade400,
              fontWeight: active ? FontWeight.w500 : FontWeight.normal,
              decoration: active ? null : TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }
}
