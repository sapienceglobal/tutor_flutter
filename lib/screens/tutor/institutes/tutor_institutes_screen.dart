import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../providers/workspace_provider.dart';
import '../../../services/membership_service.dart';
import '../../../utils/constants.dart';
import '../../auth/pending_approval_hub_screen.dart';

class TutorInstitutesScreen extends StatefulWidget {
  const TutorInstitutesScreen({super.key});

  @override
  State<TutorInstitutesScreen> createState() => _TutorInstitutesScreenState();
}

class _TutorInstitutesScreenState extends State<TutorInstitutesScreen> {
  bool _isLoading = true;
  List<dynamic> _institutes = [];
  dynamic _currentInstitute;

  @override
  void initState() {
    super.initState();
    _loadInstitutes();
  }

  Future<void> _loadInstitutes() async {
    setState(() => _isLoading = true);
    try {
      final res = await MembershipService.getMyInstitutes();
      if (res['success'] == true && mounted) {
        setState(() {
          _institutes = res['institutes'] ?? [];
          _currentInstitute = res['currentInstitute'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load institutes: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Load failed: $e')),
        );
      }
    }
  }

  Future<void> _switchInstitute(String instituteId) async {
    setState(() => _isLoading = true);
    try {
      final workspace = Provider.of<WorkspaceProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final sub = Provider.of<SubscriptionProvider>(context, listen: false);

      await workspace.switchToInstitute(instituteId);
      sub.syncWithWorkspace(userMap: auth.rawUser, workspace: workspace);
      await workspace.refreshWorkspace();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Active workspace switched to institute!'),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadInstitutes();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Switch failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _openJoinRequestsHub() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PendingApprovalHubScreen(allowBackToPortal: true),
      ),
    );
    if (!mounted) return;
    await Provider.of<WorkspaceProvider>(context, listen: false).refreshWorkspace();
    await _loadInstitutes();
  }

  Future<void> _generateInviteLink(String instituteId, String role) async {
    try {
      final permissions = role == 'tutor'
          ? {
              'canCreateCourses': true,
              'canCreateExams': true,
              'canViewAnalytics': true,
              'canManageStudents': false
            }
          : {
              'canCreateCourses': false,
              'canCreateExams': false,
              'canViewAnalytics': false,
              'canManageStudents': false
            };

      final res = await MembershipService.generateInvite(
        instituteId: instituteId,
        roleInInstitute: role,
        permissions: permissions,
      );

      if (res['success'] == true && mounted) {
        final token = res['inviteToken'];
        // Web page format: `/join/invite/${token}`
        final inviteLink = 'https://sapience-lms.web.app/join/invite/$token';

        await Clipboard.setData(ClipboardData(text: inviteLink));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$role invite link copied to clipboard!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate invite: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showInviteOptions(String instituteId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generate Invite Link',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select role for new institute member invite link:',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF1F5F9),
                child: Icon(Icons.school_outlined, color: Colors.blueGrey),
              ),
              title: const Text('Student', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Access to exams, live classes & learning'),
              onTap: () {
                Navigator.pop(ctx);
                _generateInviteLink(instituteId, 'student');
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFDF2F8),
                child: Icon(Icons.psychology_outlined, color: Colors.pink),
              ),
              title: const Text('Tutor', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Permissions to manage courses and evaluate exams'),
              onTap: () {
                Navigator.pop(ctx);
                _generateInviteLink(instituteId, 'tutor');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workspace = Provider.of<WorkspaceProvider>(context);
    final currentInstId = workspace.isInstituteWorkspace
        ? (workspace.activeInstituteId ?? _currentInstitute?['_id']?.toString())
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Institutes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _openJoinRequestsHub,
            icon: const Icon(Icons.add_business_outlined, size: 18),
            label: const Text('Connect'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadInstitutes,
              color: AppColors.primary,
              child: _institutes.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 36),
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.business_outlined,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'No Connected Institutes Yet',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                workspace.isPrivateWorkspace
                                    ? 'You are teaching in your Private Tuition Studio. Connect with an institute anytime or enter an invite token.'
                                    : 'Search and request to join an institute or redeem an invite token.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton.icon(
                                onPressed: _openJoinRequestsHub,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.add_business_outlined, size: 18),
                                label: const Text(
                                  'Connect to an Institute',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _institutes.length,
                      itemBuilder: (context, idx) {
                        final inst = _institutes[idx];
                        final instId = inst['_id']?.toString() ?? '';
                        final name = inst['name']?.toString() ?? 'Institute';
                        final plan = inst['subscriptionPlan']?.toString() ?? 'Free';
                        final bool isActive = instId == currentInstId;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isActive
                                  ? AppColors.primary.withValues(alpha: 0.5)
                                  : Colors.grey.shade200,
                              width: isActive ? 2 : 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: (isActive ? AppColors.primary : Colors.grey)
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.business_outlined,
                                        color: isActive ? AppColors.primary : Colors.grey,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  plan.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue.shade700,
                                                  ),
                                                ),
                                              ),
                                              if (isActive) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.success.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Text(
                                                    'ACTIVE',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.success,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (isActive)
                                      ElevatedButton.icon(
                                        onPressed: () => _showInviteOptions(instId),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: AppColors.primary,
                                          elevation: 0,
                                          side: BorderSide(
                                            color: AppColors.primary.withValues(alpha: 0.3),
                                          ),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        icon: const Icon(Icons.share_outlined, size: 16),
                                        label: const Text('Invite Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      )
                                    else
                                      ElevatedButton(
                                        onPressed: () => _switchInstitute(instId),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          elevation: 0,
                                        ),
                                        child: const Text('Switch Active', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
