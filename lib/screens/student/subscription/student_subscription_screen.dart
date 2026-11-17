import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/workspace_provider.dart';
import '../../../utils/constants.dart';
import '../../../widgets/sapience_ui.dart';

class StudentSubscriptionScreen extends StatelessWidget {
  const StudentSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final workspace = Provider.of<WorkspaceProvider>(context);
    final activeLabel = workspace.activeWorkspaceLabel;
    final instituteCount = workspace.institutes.length;
    final tutorCount = workspace.linkedTutors.length;

    return SapienceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Student Learning Access'),
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SapienceNavyWaveBanner(
                borderRadius: 22,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '100% Free for Students',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Students never pay any platform subscription fee on Sapience LMS. All quizzes, live classes, study plans, and AI doubt-solving tools are included through your connected Institute or Private Tutor.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SapienceCard(
                padding: const EdgeInsets.all(18),
                borderRadius: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Active Workspace',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoRow(
                      icon: Icons.workspaces_rounded,
                      title: activeLabel,
                      subtitle: workspace.isInstituteWorkspace
                          ? 'AI credits & course tools provided by this Institute'
                          : 'AI credits & learning tools provided by your Private Tutor(s)',
                    ),
                    const Divider(height: 24),
                    _infoRow(
                      icon: Icons.apartment_rounded,
                      title: '$instituteCount Approved Institute(s)',
                      subtitle: 'Switch institutes anytime from your Home header',
                    ),
                    const SizedBox(height: 12),
                    _infoRow(
                      icon: Icons.co_present_rounded,
                      title: '$tutorCount Connected Private Tutor(s)',
                      subtitle: 'Approved 1-on-1 tuition classrooms in one login',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SapienceCard(
                padding: const EdgeInsets.all(18),
                borderRadius: 18,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Course Fees vs Platform Access',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Platform features & AI Tutor are always free for students.\n'
                      '• Only paid courses created by your Institute or verified Private Tutor require course enrollment (online Razorpay or offline fee confirmation).',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
