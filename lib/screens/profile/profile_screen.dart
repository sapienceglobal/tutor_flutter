import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';
import '../../services/cloudinary_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/sapience_ui.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'notification_settings_screen.dart';
import 'language_settings_screen.dart';
import '../admin/subscription/subscription_screen.dart';
import '../common/subscription/personal_subscription_screen.dart';
import '../common/notifications/notifications_screen.dart';
import '../common/chat/conversations_screen.dart';
import '../common/announcements/announcements_screen.dart';
import '../student/analytics/student_analytics_screen.dart';
import '../student/certificates/student_certificates_screen.dart';
import '../student/payments/student_payments_screen.dart';
import '../student/student_batches_screen.dart';
import '../student/wishlist/student_wishlist_screen.dart';
import '../tutor/reports/tutor_reports_screen.dart';
import '../tutor/earnings/tutor_earnings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;
  Map<String, dynamic>? _studentStats;
  int _tutorCourses = 0;
  int _tutorStudents = 0;
  int _tutorExams = 0;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileStats();
  }

  Future<void> _loadProfileStats() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final role = authProvider.user?.role ?? 'student';
      final unread = await NotificationService.getUnreadCount();

      if (role == 'tutor') {
        final tStats = await DashboardService.getTutorStats();
        if (!mounted) return;
        setState(() {
          _unreadNotifications = unread;
          _tutorCourses = tStats?.courses.total ?? 0;
          _tutorStudents = tStats?.students.total ?? 0;
          _tutorExams = tStats?.content.quizzes ?? 0;
        });
      } else {
        final sStats = await DashboardService.getStudentStats();
        if (!mounted) return;
        setState(() {
          _unreadNotifications = unread;
          _studentStats = sStats;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final lang = user?.language ?? 'en';
    final localizations = AppLocalizations(lang);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final avatarUrl = ApiConfig.resolveMediaUrl(user.profileImage);
    final isTutor = user.role == 'tutor';

    return Scaffold(
      body: SapienceBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SapienceHeader(
                title: localizations.translate('profile'),
                leading: widget.embedded ? const SizedBox(width: 40) : null,
                actions: [
                  IconButton(
                    tooltip: localizations.translate('settings'),
                    icon: const Icon(Icons.settings_outlined, color: AppColors.navy, size: 25),
                    onPressed: () => _showSettingsSheet(context, authProvider, localizations, lang),
                    splashRadius: 20,
                  ),
                ],
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    await Future.wait([
                      authProvider.refreshUser(),
                      _loadProfileStats(),
                    ]);
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    children: [
                      // Navy Wave Profile Card matching Arjun Mehta's Learning Profile.png
                      SapienceNavyWaveBanner(
                        borderRadius: 22,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 86,
                                  height: 86,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.5),
                                    color: AppColors.primarySoft,
                                  ),
                                  child: ClipOval(
                                    child: avatarUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: avatarUrl,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) => const Icon(
                                              Icons.person_rounded,
                                              size: 42,
                                              color: AppColors.primary,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.person_rounded,
                                            size: 42,
                                            color: AppColors.primary,
                                          ),
                                  ),
                                ),
                                if (_isUploadingImage)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _isUploadingImage
                                        ? null
                                        : () => _showImageSourceDialog(context),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2.2),
                                      ),
                                      child: const Icon(Icons.edit_rounded,
                                          color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    user.email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.18),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          _getRoleText(user.role, lang),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () async {
                                          final res = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) => const EditProfileScreen()),
                                          );
                                          if (res == true) authProvider.refreshUser();
                                        },
                                        child: const Text(
                                          'Edit Profile',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF6BE07F),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // 4-Column Stats Bar (100% live backend metrics!)
                      SapienceStatsRow(
                        items: isTutor
                            ? [
                                SapienceStatItem(
                                  icon: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 22),
                                  value: '$_tutorCourses',
                                  label: 'Courses',
                                ),
                                SapienceStatItem(
                                  icon: const Icon(Icons.groups_rounded, color: AppColors.success, size: 22),
                                  value: '$_tutorStudents',
                                  label: 'Students',
                                ),
                                SapienceStatItem(
                                  icon: const Icon(Icons.quiz_rounded, color: AppColors.purple, size: 22),
                                  value: '$_tutorExams',
                                  label: 'Exams',
                                ),
                                SapienceStatItem(
                                  icon: const Icon(Icons.notifications_active_rounded, color: AppColors.warning, size: 22),
                                  value: '$_unreadNotifications',
                                  label: 'Alerts',
                                ),
                              ]
                            : [
                                SapienceStatItem(
                                  icon: const Icon(Icons.school_rounded, color: AppColors.primary, size: 22),
                                  value: '${_studentStats?['enrolledCourses'] ?? 0}',
                                  label: 'Courses',
                                ),
                                SapienceStatItem(
                                  icon: const Icon(Icons.assignment_turned_in_rounded, color: AppColors.success, size: 22),
                                  value: '${_studentStats?['completedCourses'] ?? 0}',
                                  label: 'Completed',
                                ),
                                SapienceStatItem(
                                  icon: const Icon(Icons.play_circle_filled_rounded, color: AppColors.primary, size: 22),
                                  value: '${_studentStats?['inProgress'] ?? 0}',
                                  label: 'In Progress',
                                ),
                                SapienceStatItem(
                                  icon: const Icon(Icons.emoji_events_rounded, color: AppColors.warning, size: 22),
                                  value: '${_studentStats?['averageExamScore'] ?? 0}%',
                                  label: 'Avg Score',
                                ),
                              ],
                      ),
                      const SizedBox(height: 16),
                      // Clean White Pill Menu Rows (exact match to Profile PNG!)
                      if (!isTutor) ...[
                        _buildPillRow(
                          icon: Icons.bar_chart_rounded,
                          iconColor: AppColors.primary,
                          title: 'My Learning Progress',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const StudentAnalyticsScreen()),
                          ),
                        ),
                        _buildPillRow(
                          icon: Icons.bookmark_border_rounded,
                          iconColor: AppColors.purple,
                          title: 'Saved Courses (Wishlist)',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const StudentWishlistScreen()),
                          ),
                        ),
                        _buildPillRow(
                          icon: Icons.workspace_premium_outlined,
                          iconColor: AppColors.success,
                          title: 'My Certificates',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const StudentCertificatesScreen()),
                          ),
                        ),
                        _buildPillRow(
                          icon: Icons.groups_outlined,
                          iconColor: AppColors.primary,
                          title: 'Batches & Schedule',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const StudentBatchesScreen()),
                          ),
                        ),
                        _buildPillRow(
                          icon: Icons.credit_card_rounded,
                          iconColor: AppColors.warning,
                          title: 'Payments & Plan',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const StudentPaymentsScreen()),
                          ),
                        ),
                      ] else ...[
                        _buildPillRow(
                          icon: Icons.bar_chart_rounded,
                          iconColor: AppColors.primary,
                          title: 'Performance Reports',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TutorReportsScreen()),
                          ),
                        ),
                        _buildPillRow(
                          icon: Icons.account_balance_wallet_outlined,
                          iconColor: AppColors.success,
                          title: 'Earnings & Payouts',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TutorEarningsScreen()),
                          ),
                        ),
                      ],
                      _buildPillRow(
                        icon: Icons.notifications_none_rounded,
                        iconColor: AppColors.purple,
                        title: 'Notifications',
                        showDot: _unreadNotifications > 0,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                          );
                          _loadProfileStats();
                        },
                      ),
                      _buildPillRow(
                        icon: Icons.chat_bubble_outline_rounded,
                        iconColor: AppColors.cyan,
                        title: 'Messages & Announcements',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ConversationsScreen()),
                        ),
                      ),
                      _buildPillRow(
                        icon: Icons.campaign_outlined,
                        iconColor: AppColors.primary,
                        title: 'Campus Announcements',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AnnouncementsScreen(
                              isTutor: authProvider.user?.role == 'tutor',
                            ),
                          ),
                        ),
                      ),
                      _buildPillRow(
                        icon: Icons.help_outline_rounded,
                        iconColor: AppColors.primary,
                        title: localizations.translate('helpAndSupport'),
                        onTap: () => _showHelpDialog(context, localizations),
                      ),
                      _buildPillRow(
                        icon: Icons.logout_rounded,
                        iconColor: AppColors.error,
                        title: 'Log Out',
                        onTap: () => _logout(context, localizations),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    bool showDot = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SapienceCard(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                  if (showDot) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.navy, size: 22),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet(
    BuildContext context,
    AuthProvider authProvider,
    AppLocalizations localizations,
    String lang,
  ) {
    final user = authProvider.user;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                localizations.translate('settings'),
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.navy),
              ),
              const SizedBox(height: 8),
              if (user?.role == 'admin' || user?.role == 'superadmin')
                ListTile(
                  leading: const Icon(Icons.workspace_premium, color: AppColors.primary),
                  title: const Text('Subscription & Billing'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.stars_rounded, color: AppColors.primary),
                  title: const Text('Personal Subscription'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalSubscriptionScreen()));
                  },
                ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined, color: AppColors.purple),
                title: Text(localizations.translate('notifications')),
                onTap: () async {
                  Navigator.pop(ctx);
                  final r = await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()));
                  if (r == true) authProvider.refreshUser();
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline, color: AppColors.navy),
                title: Text(localizations.translate('changePassword')),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.language, color: AppColors.success),
                title: Text(localizations.translate('language')),
                trailing: Text(lang == 'en' ? 'English' : 'हिंदी', style: const TextStyle(color: AppColors.textMuted)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final r = await Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()));
                  if (r == true) {
                    authProvider.refreshUser();
                    if (mounted) setState(() {});
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined, color: AppColors.warning),
                title: const Text('App Theme'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showThemeDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.textMuted),
                title: Text(localizations.translate('privacyPolicy')),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPrivacyPolicyDialog(context, localizations);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: AppColors.textMuted),
                title: Text(localizations.translate('about')),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAboutDialog(context, localizations);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleText(String role, String lang) {
    final localizations = AppLocalizations(lang);
    switch (role) {
      case 'student':
        return localizations.translate('student');
      case 'tutor':
        return localizations.translate('tutor');
      case 'admin':
        return localizations.translate('admin');
      default:
        return role;
    }
  }

  void _showImageSourceDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final lang = authProvider.user?.language ?? 'en';
    final localizations = AppLocalizations(lang);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localizations.translate('changeProfilePicture'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: Text(localizations.translate('takePhoto')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: Text(localizations.translate('chooseFromGallery')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        await _uploadImage(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final lang = authProvider.user?.language ?? 'en';
    final localizations = AppLocalizations(lang);

    setState(() {
      _isUploadingImage = true;
    });

    try {
      // Upload to Cloudinary
      final result = await CloudinaryService.uploadImage(imageFile);

      if (result != null && mounted) {
        // Update profile image in backend
        final success = await authProvider.updateProfileImage(
          profileImage: result['url'],
          cloudinaryId: result['publicId'],
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.translate('profileUpdated')),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (mounted) {
          throw Exception('Failed to update profile image');
        }
      } else if (mounted) {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  void _showHelpDialog(BuildContext context, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('helpAndSupport')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Need help? Contact us:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildContactItem(Icons.email, 'Email', 'support@tutormanagement.com'),
              const SizedBox(height: 12),
              _buildContactItem(Icons.phone, 'Phone', '+91 1234567890'),
              const SizedBox(height: 12),
              _buildContactItem(Icons.language, 'Website', 'www.tutormanagement.com'),
              const SizedBox(height: 16),
              const Text(
                'Available: Monday - Friday, 9 AM - 6 PM IST',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.translate('cancel')),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('about')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tutor Management App',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${localizations.translate('version')} 1.0.0',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            const Text(
              'A comprehensive platform to connect students with qualified tutors. Book appointments, manage schedules, and enhance your learning experience.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            Text(
              '© 2024 Tutor Management. All rights reserved.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.translate('cancel')),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(
      BuildContext context, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('privacyPolicy')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPolicySection(
                'Data Collection',
                'We collect personal information such as name, email, phone number, and profile pictures to provide our services.',
              ),
              _buildPolicySection(
                'Data Usage',
                'Your data is used to facilitate connections between students and tutors, manage appointments, and improve our services.',
              ),
              _buildPolicySection(
                'Data Security',
                'We implement industry-standard security measures to protect your personal information.',
              ),
              _buildPolicySection(
                'Third-Party Services',
                'We may use third-party services (like Cloudinary for image storage) that have their own privacy policies.',
              ),
              _buildPolicySection(
                'Your Rights',
                'You have the right to access, modify, or delete your personal information at any time.',
              ),
              const SizedBox(height: 8),
              Text(
                'Last updated: December 2024',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.translate('cancel')),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(
      BuildContext context, AppLocalizations localizations) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('logout')),
        content: Text(localizations.translate('areYouSureLogout')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.translate('no')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(localizations.translate('yes')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        return AlertDialog(
          title: const Text('Choose App Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Light Theme'),
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (mode) {
                  if (mode != null) {
                    themeProvider.setThemeMode(mode);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark Theme'),
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (mode) {
                  if (mode != null) {
                    themeProvider.setThemeMode(mode);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('System Default'),
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (mode) {
                  if (mode != null) {
                    themeProvider.setThemeMode(mode);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}