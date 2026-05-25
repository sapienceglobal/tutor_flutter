import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../profile/profile_screen.dart';
import 'student_exams_screen.dart';
import 'student_learning_screen.dart';
import 'student_batches_screen.dart';
import 'assignments/student_assignments_screen.dart';
import 'live_classes/student_live_classes_screen.dart';
import 'certificates/student_certificates_screen.dart';
import 'analytics/student_analytics_screen.dart';
import 'wishlist/student_wishlist_screen.dart';
import '../tutors/tutors_screen.dart';

class StudentMoreHubScreen extends StatelessWidget {
  const StudentMoreHubScreen({super.key});

  // Helper for resolve VPS image url bug
  String _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return 'https://via.placeholder.com/150';
    }
    if (path.startsWith('http')) return path;
    
    // Fallback to standard URL mapping
    return "http://195.35.20.207:5000$path"; 
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Learning Hub',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── PROFILE GRADIENT CARD ───
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      image: DecorationImage(
                        image: NetworkImage(_resolveImageUrl(user?.profileImage)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Student',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'learner@example.com',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Verified Student',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ─── SECTION 1: ACADEMIC & LEARNING HUB ───
            _buildSectionHeader('🎓 Academic Hub'),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.35,
              children: [
                _buildHubTile(
                  context,
                  title: 'Tests & Exams',
                  subtitle: 'Proctored exams',
                  icon: Icons.article_rounded,
                  color: Colors.indigo,
                  targetScreen: const StudentExamsScreen(),
                ),
                _buildHubTile(
                  context,
                  title: 'Assignments',
                  subtitle: 'Submit your tasks',
                  icon: Icons.assignment_outlined,
                  color: Colors.orange.shade700,
                  targetScreen: const StudentAssignmentsScreen(),
                ),
                _buildHubTile(
                  context,
                  title: 'Live Classes',
                  subtitle: 'Online webinars',
                  icon: Icons.videocam_outlined,
                  color: Colors.teal.shade700,
                  targetScreen: const StudentLiveClassesScreen(),
                ),
                _buildHubTile(
                  context,
                  title: 'My Batches',
                  subtitle: 'Your active slots',
                  icon: Icons.groups_outlined,
                  color: Colors.blue.shade700,
                  targetScreen: const StudentBatchesScreen(),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ─── SECTION 2: REPORTS & UTILITIES ───
            _buildSectionHeader('📊 Reports & Diagnostics'),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.35,
              children: [
                _buildHubTile(
                  context,
                  title: 'Analytics',
                  subtitle: 'AI-driven insights',
                  icon: Icons.bar_chart_outlined,
                  color: Colors.purple.shade600,
                  targetScreen: const StudentAnalyticsScreen(),
                ),
                _buildHubTile(
                  context,
                  title: 'Find a Tutor',
                  subtitle: 'Direct booking',
                  icon: Icons.person_search_outlined,
                  color: Colors.pink.shade600,
                  targetScreen: const TutorsScreen(),
                ),
                _buildHubTile(
                  context,
                  title: 'Certificates',
                  subtitle: 'Earned awards',
                  icon: Icons.workspace_premium_outlined,
                  color: Colors.amber.shade800,
                  targetScreen: const StudentCertificatesScreen(),
                ),
                _buildHubTile(
                  context,
                  title: 'Wishlist',
                  subtitle: 'Saved courses',
                  icon: Icons.favorite_border_rounded,
                  color: Colors.red.shade600,
                  targetScreen: const StudentWishlistScreen(),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ─── SECTION 3: ACCOUNT & SETTINGS ───
            _buildSectionHeader('⚙️ Account Hub'),
            const SizedBox(height: 12),
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildListTile(
                  context,
                  title: 'My Profile Settings',
                  subtitle: 'Manage notifications, language and profile info',
                  icon: Icons.person_outline_rounded,
                  color: Colors.indigo,
                  targetScreen: const ProfileScreen(),
                ),
                const SizedBox(height: 10),
                _buildListTile(
                  context,
                  title: 'Billing & Payments',
                  subtitle: 'Review subscription invoices and payment history',
                  icon: Icons.credit_card_outlined,
                  color: Colors.green.shade700,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payments are managed securely via sapience portal.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildHubTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    Widget? targetScreen,
  }) {
    return GestureDetector(
      onTap: () {
        if (targetScreen != null) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => targetScreen),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    Widget? targetScreen,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap();
        } else if (targetScreen != null) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => targetScreen),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
