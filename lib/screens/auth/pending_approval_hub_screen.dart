import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../services/auth_service.dart';
import '../../services/membership_service.dart';
import '../../services/tutor_link_service.dart';
import '../../utils/constants.dart';
import '../../widgets/sapience_ui.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class PendingApprovalHubScreen extends StatefulWidget {
  final bool allowBackToPortal;

  const PendingApprovalHubScreen({
    super.key,
    this.allowBackToPortal = false,
  });

  @override
  State<PendingApprovalHubScreen> createState() =>
      _PendingApprovalHubScreenState();
}

class _PendingApprovalHubScreenState extends State<PendingApprovalHubScreen> {
  final _searchController = TextEditingController();
  final _inviteController = TextEditingController();
  Timer? _debounce;

  String _searchMode = 'institute'; // 'institute' | 'tutor' | 'invite'
  bool _isSearching = false;
  bool _submitting = false;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workspace = Provider.of<WorkspaceProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final isStudent = auth.user?.role == 'student';
      if (isStudent && (workspace.institutes.isNotEmpty || workspace.pendingInstitutes.isNotEmpty)) {
        setState(() => _searchMode = 'tutor');
      }
      _refreshStatus(autoNavigateIfApproved: false);
      _runSearch('');
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _inviteController.dispose();
    super.dispose();
  }

  Future<void> _refreshStatus({bool autoNavigateIfApproved = true}) async {
    final workspace = Provider.of<WorkspaceProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final sub = Provider.of<SubscriptionProvider>(context, listen: false);

    final approved = await workspace.refreshWorkspace();
    await auth.refreshUser();
    if (!mounted) return;

    if (approved && autoNavigateIfApproved) {
      await sub.fetchSubscriptionData(workspace: workspace, isSilent: true);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else if (!approved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status refreshed. Waiting for Institute/Tutor approval.'),
        ),
      );
    }
  }

  Future<void> _runSearch(String query) async {
    if (_searchMode == 'invite') return;
    setState(() => _isSearching = true);
    try {
      final results = _searchMode == 'institute'
          ? await AuthService.searchPublicInstitutes(search: query)
          : await AuthService.searchPublicTutors(search: query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSearching = false);
    }
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _runSearch(val);
    });
  }

  Future<void> _requestInstituteJoin(String instituteId, String name) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final workspace = Provider.of<WorkspaceProvider>(context, listen: false);
    final isStudent = auth.user?.role == 'student';

    if (isStudent && workspace.institutes.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are already enrolled in an institute. Students can only enroll in one institute at a time.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (isStudent && workspace.pendingInstitutes.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You already have a pending request for ${workspace.pendingInstitutes.first['name'] ?? 'an institute'}. Please withdraw it first to choose another.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await MembershipService.requestJoin(
        instituteId: instituteId,
        roleInInstitute: auth.user?.role ?? 'student',
      );
      await _refreshStatus(autoNavigateIfApproved: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Join request sent to $name'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _requestTutorJoin(String tutorId, String name) async {
    setState(() => _submitting = true);
    try {
      await TutorLinkService.requestTutorLinks(tutorIds: [tutorId]);
      await _refreshStatus(autoNavigateIfApproved: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Join request sent to $name'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _withdrawInstituteRequest(String membershipId) async {
    setState(() => _submitting = true);
    try {
      await MembershipService.withdrawJoinRequest(membershipId);
      await _refreshStatus(autoNavigateIfApproved: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Institute join request withdrawn'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _withdrawTutorRequest(String linkId) async {
    setState(() => _submitting = true);
    try {
      await TutorLinkService.removeTutorLink(linkId);
      await _refreshStatus(autoNavigateIfApproved: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _acceptInvite() async {
    final code = _inviteController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an invite token or code')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await MembershipService.acceptInvite(code);
      _inviteController.clear();
      await _refreshStatus(autoNavigateIfApproved: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _logout() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final workspace = Provider.of<WorkspaceProvider>(context, listen: false);
    final sub = Provider.of<SubscriptionProvider>(context, listen: false);
    await auth.logout();
    workspace.clear();
    sub.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final workspace = Provider.of<WorkspaceProvider>(context);
    final userRole = auth.user?.role ?? 'student';

    final pendingInst = workspace.pendingInstitutes;
    final pendingTutors = workspace.pendingTutors;
    final rejectedInst = workspace.rejectedInstitutes;
    final rejectedTutors = workspace.rejectedTutors;

    return SapienceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: widget.allowBackToPortal,
          title: Text(
            widget.allowBackToPortal
                ? 'Connect Institute or Tutor'
                : 'Workspace Admission Hub',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh Approval Status',
              onPressed: workspace.isLoading
                  ? null
                  : () => _refreshStatus(autoNavigateIfApproved: true),
              icon: const Icon(Icons.refresh_rounded),
            ),
            if (!widget.allowBackToPortal)
              IconButton(
                tooltip: 'Sign Out',
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded),
              ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => _refreshStatus(autoNavigateIfApproved: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.allowBackToPortal) ...[
                  SapienceNavyWaveBanner(
                    borderRadius: 20,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.hourglass_top_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hi ${auth.user?.name ?? 'Learner'},',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Your workspace unlocks automatically once an Institute or Tutor approves your request.',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SapienceButton(
                          label: workspace.isLoading
                              ? 'Checking Status...'
                              : 'Check Approval Status',
                          trailingIcon: Icons.verified_rounded,
                          variant: SapienceButtonVariant.greenToBlue,
                          height: 44,
                          onTap: () => _refreshStatus(autoNavigateIfApproved: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Pending Requests Card
                if (pendingInst.isNotEmpty || pendingTutors.isNotEmpty) ...[
                  SapienceCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pending Approval Requests',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...pendingInst.map(
                          (req) => _statusTile(
                            title: req['instituteName']?.toString() ?? 'Institute',
                            subtitle:
                                'Role: ${req['roleInInstitute'] ?? userRole} • Awaiting Admin review',
                            statusLabel: 'Pending',
                            color: AppColors.warning,
                            bgColor: AppColors.warningSoft,
                            trailingAction: IconButton(
                              tooltip: 'Withdraw Request',
                              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                              onPressed: _submitting
                                  ? null
                                  : () => _withdrawInstituteRequest(req['id'].toString()),
                            ),
                          ),
                        ),
                        ...pendingTutors.map(
                          (req) => _statusTile(
                            title: req['tutorName']?.toString() ?? 'Private Tutor',
                            subtitle:
                                (req['subjects'] is List && (req['subjects'] as List).isNotEmpty)
                                    ? 'Subjects: ${(req['subjects'] as List).join(', ')}'
                                    : 'Awaiting Tutor approval',
                            statusLabel: 'Pending',
                            color: AppColors.warning,
                            bgColor: AppColors.warningSoft,
                            trailingAction: IconButton(
                              tooltip: 'Withdraw Request',
                              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                              onPressed: _submitting
                                  ? null
                                  : () => _withdrawTutorRequest(req['id'].toString()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Rejected Requests Card (with reason)
                if (rejectedInst.isNotEmpty || rejectedTutors.isNotEmpty) ...[
                  SapienceCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Declined Requests',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...rejectedInst.map(
                          (req) => _statusTile(
                            title: req['instituteName']?.toString() ?? 'Institute',
                            subtitle: (req['rejectionReason']?.toString().isNotEmpty ?? false)
                                ? 'Reason: ${req['rejectionReason']}'
                                : 'Declined by institute admin',
                            statusLabel: 'Declined',
                            color: AppColors.error,
                            bgColor: AppColors.errorSoft,
                          ),
                        ),
                        ...rejectedTutors.map(
                          (req) => _statusTile(
                            title: req['tutorName']?.toString() ?? 'Private Tutor',
                            subtitle: (req['rejectionReason']?.toString().isNotEmpty ?? false)
                                ? 'Reason: ${req['rejectionReason']}'
                                : 'Declined by tutor',
                            statusLabel: 'Declined',
                            color: AppColors.error,
                            bgColor: AppColors.errorSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Search & Request Additional Workspaces
                SapienceCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Find & Request Workspace Access',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userRole == 'student'
                            ? 'Search your Institute and/or multiple Private Tutors (Maths, Bio, Hindi, etc.) — one login works everywhere.'
                            : 'Search registered Institutes to apply as Faculty or redeem an Institute invite token.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (userRole == 'student' && (workspace.institutes.isNotEmpty || workspace.pendingInstitutes.isNotEmpty)) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.school_rounded, color: AppColors.primary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  workspace.institutes.isNotEmpty
                                      ? 'Enrolled in ${workspace.currentInstituteName ?? 'your institute'}. Student admission is single-institute compliant. Connect with 1:1 Private Tutors below for personal guidance.'
                                      : 'Admission request pending with ${workspace.pendingInstitutes.first['name'] ?? 'an institute'}. Under single-institute guidelines, you can connect with 1:1 Private Tutors below, or withdraw your request above to choose another institute.',
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.navy, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (workspace.institutes.isEmpty && (userRole != 'student' || workspace.pendingInstitutes.isEmpty))
                            _modeChip('institute', 'Institutes', Icons.apartment_rounded),
                          if (userRole == 'student')
                            _modeChip('tutor', 'Private Tutors', Icons.co_present_rounded),
                          _modeChip('invite', 'Invite Code', Icons.vpn_key_rounded),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_searchMode == 'invite') ...[
                        TextField(
                          controller: _inviteController,
                          decoration: const InputDecoration(
                            labelText: 'Institute Invite Code / Token',
                            hintText: 'Paste invite code shared by Institute Admin',
                            prefixIcon: Icon(Icons.vpn_key_outlined, size: 20),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SapienceButton(
                          label: _submitting ? 'Applying...' : 'Accept Invite & Enter',
                          height: 44,
                          onTap: _submitting ? null : _acceptInvite,
                        ),
                      ] else ...[
                        TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: _searchMode == 'institute'
                                ? 'Search institute name or city...'
                                : 'Search tutor name or subject (Bio, Maths...)...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_isSearching)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        else if (_searchResults.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                'No matching results found. Try a different search.',
                                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                              ),
                            ),
                          )
                        else
                          ..._searchResults.take(15).map((item) {
                            final id = (item['_id'] ?? item['tutorId'] ?? '').toString();
                            final name = item['name']?.toString() ?? 'Unknown';
                            final isInst = _searchMode == 'institute';
                            final alreadyPending = isInst
                                ? pendingInst.any((p) => p['instituteId'].toString() == id)
                                : pendingTutors.any((p) => p['tutorId'].toString() == id);
                            final alreadyActive = isInst
                                ? workspace.institutes.any((i) => i['id'].toString() == id)
                                : workspace.linkedTutors.any((t) => t['tutorId'].toString() == id);

                            String meta = '';
                            if (isInst) {
                              final disc = item['discovery'] is Map ? item['discovery'] as Map : const {};
                              final city = disc['city']?.toString() ?? '';
                              final tagline = disc['tagline']?.toString() ?? '';
                              meta = [city, tagline].where((s) => s.isNotEmpty).join(' • ');
                            } else {
                              final subjects = item['subjects'] is List
                                  ? (item['subjects'] as List).take(3).join(', ')
                                  : '';
                              final city = item['city']?.toString() ?? '';
                              meta = [subjects, city].where((s) => s.isNotEmpty).join(' • ');
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.innerSurface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.navy,
                                          ),
                                        ),
                                        if (meta.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            meta,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: AppColors.textMuted,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (alreadyActive)
                                    _miniTag('Connected', AppColors.success, AppColors.successSoft)
                                  else if (alreadyPending)
                                    _miniTag('Requested', AppColors.warning, AppColors.warningSoft)
                                  else
                                    ElevatedButton(
                                      onPressed: _submitting
                                          ? null
                                          : () => isInst
                                              ? _requestInstituteJoin(id, name)
                                              : _requestTutorJoin(id, name),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text(
                                        'Request',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeChip(String mode, String label, IconData icon) {
    final active = _searchMode == mode;
    return ChoiceChip(
      selected: active,
      onSelected: (_) {
        setState(() {
          _searchMode = mode;
          _searchResults = [];
        });
        _runSearch(_searchController.text);
      },
      avatar: Icon(
        icon,
        size: 16,
        color: active ? Colors.white : AppColors.primary,
      ),
      label: Text(label),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.primarySoft,
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: active ? Colors.white : AppColors.navy,
      ),
      side: BorderSide.none,
    );
  }

  Widget _statusTile({
    required String title,
    required String subtitle,
    required String statusLabel,
    required Color color,
    required Color bgColor,
    Widget? trailingAction,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.innerSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          _miniTag(statusLabel, color, bgColor),
          if (trailingAction != null) trailingAction,
        ],
      ),
    );
  }

  Widget _miniTag(String text, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

