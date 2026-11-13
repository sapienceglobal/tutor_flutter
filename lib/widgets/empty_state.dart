import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Premium empty state widget with icon, title, subtitle, and optional CTA button.
/// Replaces plain "No data found" text with beautiful illustrated empty states.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  final Color? iconColor;
  final double iconSize;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle = '',
    this.actionText,
    this.onAction,
    this.iconColor,
    this.iconSize = 64,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveIconColor = iconColor ?? AppColors.primary.withValues(alpha: 0.35);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Decorative icon container with gradient background
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    effectiveIconColor.withValues(alpha: 0.15),
                    effectiveIconColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: effectiveIconColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                letterSpacing: -0.3,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.grey.shade500,
                  height: 1.4,
                ),
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  actionText!,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── PRE-BUILT EMPTY STATE VARIANTS ───

class EmptyCoursesState extends StatelessWidget {
  final VoidCallback? onBrowse;
  const EmptyCoursesState({super.key, this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.school_outlined,
      title: 'No Courses Yet',
      subtitle: 'Browse our catalog to find the perfect course for your learning journey.',
      actionText: onBrowse != null ? 'Browse Courses' : null,
      onAction: onBrowse,
      iconColor: Colors.indigo,
    );
  }
}

class EmptyExamsState extends StatelessWidget {
  const EmptyExamsState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.assignment_outlined,
      title: 'No Exams Available',
      subtitle: 'When your tutors create exams, they will appear here. Stay tuned!',
      iconColor: Colors.teal,
    );
  }
}

class EmptyAssignmentsState extends StatelessWidget {
  const EmptyAssignmentsState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.task_outlined,
      title: 'No Assignments Yet',
      subtitle: 'Your assignments and homework will show up here once assigned by your tutor.',
      iconColor: Colors.orange,
    );
  }
}

class EmptyMessagesState extends StatelessWidget {
  const EmptyMessagesState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.forum_outlined,
      title: 'No Conversations',
      subtitle: 'Start a conversation with your tutors or students to get help and collaborate.',
      iconColor: Colors.blue,
    );
  }
}

class EmptyLiveClassesState extends StatelessWidget {
  const EmptyLiveClassesState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.videocam_off_outlined,
      title: 'No Upcoming Classes',
      subtitle: 'When live classes are scheduled, they will appear here with join links.',
      iconColor: Colors.red,
    );
  }
}

class EmptySearchState extends StatelessWidget {
  final String query;
  const EmptySearchState({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.search_off_rounded,
      title: 'No Results Found',
      subtitle: 'We couldn\'t find anything matching "$query". Try a different search term.',
      iconColor: Colors.grey,
    );
  }
}
