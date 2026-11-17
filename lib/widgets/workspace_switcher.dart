import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/workspace_provider.dart';
import '../screens/auth/pending_approval_hub_screen.dart';
import '../utils/constants.dart';

class WorkspaceSwitcherBar extends StatelessWidget {
  final VoidCallback? onWorkspaceChanged;
  final bool compact;

  const WorkspaceSwitcherBar({
    super.key,
    this.onWorkspaceChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final workspace = Provider.of<WorkspaceProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    if (!workspace.isInitialized) return const SizedBox.shrink();

    final isTutor = (auth.user?.role ?? workspace.role) == 'tutor';
    final bool showTutorChips = !isTutor &&
        workspace.isPrivateWorkspace &&
        workspace.linkedTutors.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openWorkspaceSheet(context, workspace, isTutor),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: compact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: const [AppThemeDesign.softShadow],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    workspace.isInstituteWorkspace
                        ? Icons.apartment_rounded
                        : (isTutor
                            ? Icons.co_present_rounded
                            : Icons.groups_rounded),
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workspace.activeWorkspaceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      Text(
                        workspace.isInstituteWorkspace
                            ? 'Institute Workspace'
                            : (isTutor
                                ? 'Private Teaching Studio'
                                : (workspace.selectedLinkedTutor != null
                                    ? 'Viewing ${workspace.selectedLinkedTutor!['name'] ?? 'Tutor'}'
                                    : '${workspace.linkedTutors.length} Connected Private Tutor(s)')),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.innerSurface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        workspace.showWorkspaceSwitcher ? 'Switch' : 'Manage',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showTutorChips) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _TutorFilterChip(
                  label: 'All Tutors',
                  selected: workspace.activeTutorFilterId == null,
                  onTap: () async {
                    if (workspace.activeTutorFilterId == null) return;
                    await workspace.setTutorFilter(null);
                    onWorkspaceChanged?.call();
                  },
                ),
                ...workspace.linkedTutors.map((t) {
                  final id = (t['tutorId'] ?? t['_id'] ?? '').toString();
                  final name = (t['name'] ?? 'Tutor').toString();
                  final subjects = (t['subjects'] as List?)
                          ?.map((e) => e.toString())
                          .toList() ??
                      const <String>[];
                  final label = subjects.isNotEmpty
                      ? '$name • ${subjects.first}'
                      : name;
                  final selected = workspace.activeTutorFilterId == id;
                  return _TutorFilterChip(
                    label: label,
                    selected: selected,
                    onTap: () async {
                      if (selected) return;
                      await workspace.setTutorFilter(id);
                      onWorkspaceChanged?.call();
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _openWorkspaceSheet(
    BuildContext context,
    WorkspaceProvider workspace,
    bool isTutor,
  ) {
    final sub = Provider.of<SubscriptionProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const Text(
                'Switch Workspace',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'All courses, exams, live classes, and chats isolate strictly to the selected workspace.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              if (workspace.institutes.isNotEmpty) ...[
                const Text(
                  'INSTITUTES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                ...workspace.institutes.map((inst) {
                  final id = (inst['id'] ?? inst['_id'] ?? '').toString();
                  final isActive = workspace.isInstituteWorkspace &&
                      workspace.activeInstituteId == id;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: isActive ? AppColors.primarySoft : null,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primarySoft,
                      child: const Icon(
                        Icons.apartment_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      inst['name']?.toString() ?? 'Institute',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isActive ? AppColors.primary : AppColors.navy,
                      ),
                    ),
                    subtitle: Text(
                      'Plan: ${(inst['subscriptionPlan'] ?? 'Free').toString().toUpperCase()}',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    trailing: isActive
                        ? const Icon(Icons.check_circle, color: AppColors.primary)
                        : null,
                    onTap: () async {
                      Navigator.pop(ctx);
                      await workspace.switchToInstitute(id);
                      sub.syncWithWorkspace(
                        userMap: auth.rawUser ?? auth.user?.toJson(),
                        workspace: workspace,
                      );
                      onWorkspaceChanged?.call();
                    },
                  );
                }),
                const SizedBox(height: 10),
              ],
              if (workspace.canUsePrivateWorkspace) ...[
                Text(
                  isTutor ? 'PRIVATE TEACHING' : 'PRIVATE TUTORS',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor:
                      workspace.isPrivateWorkspace ? AppColors.primarySoft : null,
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFDCFCE7),
                    child: Icon(
                      isTutor ? Icons.co_present_rounded : Icons.groups_rounded,
                      color: AppColors.success,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    isTutor ? 'My Private Studio' : 'My Private Tutors',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: workspace.isPrivateWorkspace
                          ? AppColors.primary
                          : AppColors.navy,
                    ),
                  ),
                  subtitle: Text(
                    isTutor
                        ? 'Independent home-tuition studio'
                        : '${workspace.linkedTutors.length} approved tutor(s)',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  trailing: workspace.isPrivateWorkspace
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await workspace.switchToPrivateWorkspace();
                    sub.syncWithWorkspace(
                      userMap: auth.rawUser ?? auth.user?.toJson(),
                      workspace: workspace,
                    );
                    onWorkspaceChanged?.call();
                  },
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const PendingApprovalHubScreen(allowBackToPortal: true),
                    ),
                  ).then((_) {
                    workspace.refreshWorkspace().then((_) {
                      onWorkspaceChanged?.call();
                    });
                  });
                },
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: Text(
                  isTutor
                      ? 'Connect Another Institute / View Requests'
                      : 'Join Another Institute or Private Tutor',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TutorFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.navy,
          ),
        ),
        selected: selected,
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.cardBorder,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}

