import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../utils/constants.dart';

class FeatureGate extends StatelessWidget {
  final String featureKey;
  final Widget child;
  final Widget? fallback;
  final bool showLockOverlay;

  const FeatureGate({
    super.key,
    required this.featureKey,
    required this.child,
    this.fallback,
    this.showLockOverlay = false,
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

    final bool hasAccess = subProvider.hasFeature(featureKey);

    if (hasAccess) {
      return child;
    }

    if (showLockOverlay) {
      return Stack(
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return fallback ?? const SizedBox.shrink();
  }
}
