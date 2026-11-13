import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Premium shimmer skeleton loaders that mimic actual content layout.
/// Use these instead of CircularProgressIndicator for industry-level UX.
class ShimmerLoader extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoader({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: baseColor ?? (isDark ? const Color(0xFF2D2D3A) : const Color(0xFFE8E8F0)),
      highlightColor: highlightColor ?? (isDark ? const Color(0xFF3D3D4A) : const Color(0xFFF5F5FA)),
      child: child,
    );
  }
}

/// Shimmer block — a rounded rectangle placeholder
class ShimmerBlock extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBlock({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Shimmer circle — for avatars
class ShimmerCircle extends StatelessWidget {
  final double size;

  const ShimmerCircle({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─── PRE-BUILT SHIMMER LAYOUTS ───

/// Shimmer for list items (icon + title + subtitle)
class ShimmerListItem extends StatelessWidget {
  const ShimmerListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            const ShimmerCircle(size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBlock(height: 14, width: MediaQuery.of(context).size.width * 0.5),
                  const SizedBox(height: 8),
                  ShimmerBlock(height: 10, width: MediaQuery.of(context).size.width * 0.35),
                ],
              ),
            ),
            const ShimmerBlock(width: 60, height: 28, borderRadius: 14),
          ],
        ),
      ),
    );
  }
}

/// Shimmer for stat cards (2-column grid)
class ShimmerStatCard extends StatelessWidget {
  const ShimmerStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBlock(width: 30, height: 30, borderRadius: 8),
            SizedBox(height: 12),
            ShimmerBlock(width: 60, height: 24),
            SizedBox(height: 6),
            ShimmerBlock(width: 80, height: 10),
            SizedBox(height: 4),
            ShimmerBlock(width: 100, height: 10),
          ],
        ),
      ),
    );
  }
}

/// Shimmer for course card
class ShimmerCourseCard extends StatelessWidget {
  const ShimmerCourseCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            const ShimmerBlock(height: 140, borderRadius: 16),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBlock(height: 16, width: MediaQuery.of(context).size.width * 0.6),
                  const SizedBox(height: 8),
                  const ShimmerBlock(height: 12, width: 120),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const ShimmerCircle(size: 24),
                      const SizedBox(width: 8),
                      ShimmerBlock(height: 12, width: MediaQuery.of(context).size.width * 0.3),
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

/// Shimmer for Quick Action grid (2x2)
class ShimmerQuickActions extends StatelessWidget {
  final int count;
  const ShimmerQuickActions({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.55,
        ),
        itemCount: count,
        itemBuilder: (_, __) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShimmerCircle(size: 36),
              SizedBox(height: 10),
              ShimmerBlock(height: 12, width: 90),
              SizedBox(height: 6),
              ShimmerBlock(height: 10, width: 60),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full dashboard shimmer layout (stats + actions + course list)
class ShimmerDashboard extends StatelessWidget {
  const ShimmerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          const Row(
            children: [
              Expanded(child: ShimmerStatCard()),
              SizedBox(width: 12),
              Expanded(child: ShimmerStatCard()),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: ShimmerStatCard()),
              SizedBox(width: 12),
              Expanded(child: ShimmerStatCard()),
            ],
          ),
          const SizedBox(height: 24),
          // Quick actions header
          ShimmerLoader(
            child: ShimmerBlock(height: 18, width: MediaQuery.of(context).size.width * 0.35),
          ),
          const SizedBox(height: 12),
          const ShimmerQuickActions(),
          const SizedBox(height: 24),
          // Course list
          const ShimmerCourseCard(),
          const ShimmerCourseCard(),
        ],
      ),
    );
  }
}

/// Shimmer for list screens (e.g. exams, assignments, leaves)
class ShimmerListView extends StatelessWidget {
  final int itemCount;
  const ShimmerListView({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (_, __) => const ShimmerListItem(),
    );
  }
}
