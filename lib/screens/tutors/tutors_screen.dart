import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tutor_model.dart';
import '../../providers/workspace_provider.dart';
import '../../services/tutor_service.dart';
import '../../utils/constants.dart';
import '../../widgets/tutor_card.dart';
import '../../widgets/workspace_switcher.dart';
import '../auth/pending_approval_hub_screen.dart';

class TutorsScreen extends StatefulWidget {
  const TutorsScreen({super.key});

  @override
  State<TutorsScreen> createState() => _TutorsScreenState();
}

class _TutorsScreenState extends State<TutorsScreen> {
  List<TutorModel> _tutors = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchWorkspaceTutors();
  }

  Future<void> _fetchWorkspaceTutors() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final workspace = Provider.of<WorkspaceProvider>(context, listen: false);
      final scope = workspace.isPrivateWorkspace ? 'private' : 'institute';
      final res = await TutorService.getAllTutors(scope: scope);
      if (!mounted) return;
      setState(() {
        _tutors = res;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<TutorModel> _applySearch(List<TutorModel> list) {
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.trim().toLowerCase();
    return list.where((t) {
      final nameMatches = t.user.name.toLowerCase().contains(q);
      final bioMatches = t.bio.toLowerCase().contains(q);
      final subjectMatches = t.subjects.any((s) => s.toLowerCase().contains(q));
      return nameMatches || bioMatches || subjectMatches;
    }).toList();
  }

  void _openJoinHub() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PendingApprovalHubScreen(allowBackToPortal: true),
      ),
    ).then((_) {
      if (mounted) _fetchWorkspaceTutors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final workspace = Provider.of<WorkspaceProvider>(context);
    final filtered = _applySearch(_tutors);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          workspace.isPrivateWorkspace
              ? 'My Private Tutors'
              : 'My Institute Tutors',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        elevation: 0.5,
        actions: [
          TextButton.icon(
            onPressed: _openJoinHub,
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: const Text(
              'Connect',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: WorkspaceSwitcherBar(
              compact: true,
              onWorkspaceChanged: _fetchWorkspaceTutors,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: workspace.isPrivateWorkspace
                      ? 'Search connected private tutors...'
                      : 'Search institute tutors...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[400]),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _fetchWorkspaceTutors,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.52,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline,
                                    size: 68, color: Colors.grey[350]),
                                const SizedBox(height: 14),
                                Text(
                                  workspace.isPrivateWorkspace
                                      ? 'No connected private tutors match this workspace filter.'
                                      : 'No tutors found in this institute workspace.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _openJoinHub,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('Connect a Tutor or Institute'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchWorkspaceTutors,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) =>
                              TutorCard(tutor: filtered[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
