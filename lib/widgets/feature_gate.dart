import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../screens/common/subscription/personal_subscription_screen.dart';

class FeatureGate extends StatelessWidget {
  final String featureKey;
  final Widget child;
  final Widget? fallback;
  final bool showLockOverlay;
  final bool isPersonal; // Personal context flag

  const FeatureGate({
    super.key,
    required this.featureKey,
    required this.child,
    this.fallback,
    this.showLockOverlay = false,
    this.isPersonal = false,
  });

  @override
  Widget build(BuildContext context) {
    final subProvider = Provider.of<SubscriptionProvider>(context);

    if (subProvider.isLoading) {
      return const SizedBox(
        height: 50,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Check access based on personal vs institute context
    final bool hasAccess = subProvider.hasFeature(featureKey, isPersonal: isPersonal);

    if (hasAccess) {
      return child;
    }

    if (showLockOverlay) {
      return GestureDetector(
        onTap: () => _showUpsellModal(context, subProvider),
        child: Stack(
          children: [
            Opacity(
              opacity: 0.5,
              child: IgnorePointer(child: child),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.3),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.workspace_premium, color: Colors.purple, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Premium Feature',
                          style: TextStyle(
                            color: Colors.purple[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, color: Colors.purple[400], size: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return fallback ?? const SizedBox.shrink();
  }

  /// Shows a premium upsell bottom sheet matching web's UpsellModal
  void _showUpsellModal(BuildContext context, SubscriptionProvider subProvider) {
    final role = subProvider.role ?? 'student';
    final planName = subProvider.planName;

    final featureDetails = {
      'zoomIntegration': {'label': 'Zoom Live Classes', 'icon': Icons.videocam_outlined, 'color': Colors.blue},
      'hlsStreaming': {'label': 'HLS Video Security', 'icon': Icons.security_outlined, 'color': Colors.green},
      'aiAssistant': {'label': 'AI Assistant (Chat & Summary)', 'icon': Icons.auto_awesome, 'color': Colors.amber},
      'aiAssessment': {'label': 'AI Assessment (Proctoring)', 'icon': Icons.psychology_outlined, 'color': Colors.purple},
      'aiIntelligence': {'label': 'AI Intelligence (Analytics)', 'icon': Icons.insights, 'color': Colors.pink},
      'customBranding': {'label': 'White-Label Branding', 'icon': Icons.palette_outlined, 'color': Colors.indigo},
      'apiAccess': {'label': 'Enterprise API', 'icon': Icons.code, 'color': Colors.grey},
    };

    final feature = featureDetails[featureKey] ?? {
      'label': featureKey,
      'icon': Icons.lock_outlined,
      'color': Colors.purple,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.55,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) => SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF27225B), Color(0xFF3B33A0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF97316).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.workspace_premium, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Unlock Your True Potential',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        role == 'admin'
                            ? "Upgrade your institute's plan to access enterprise-grade features."
                            : "This feature requires a premium plan. Upgrade to supercharge your experience!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.blue.shade100,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Current locked feature
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: (feature['color'] as Color).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: (feature['color'] as Color).withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (feature['color'] as Color).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(feature['icon'] as IconData, color: feature['color'] as Color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                feature['label'] as String,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Requires premium subscription',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock, size: 12, color: Colors.red.shade400),
                              const SizedBox(width: 4),
                              Text('Locked', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade400)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Current plan info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Text(
                          'Current Plan: ',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF6B4DF1), Color(0xFF8B73F7)]),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            planName.isEmpty ? 'Free' : planName,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Upgrade button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PersonalSubscriptionScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4DF1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        shadowColor: const Color(0xFF6B4DF1).withOpacity(0.4),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rocket_launch, size: 18),
                          SizedBox(width: 8),
                          Text('View Upgrade Plans', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

