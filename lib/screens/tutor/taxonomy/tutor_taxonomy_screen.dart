import 'package:flutter/material.dart';
import '../../../services/taxonomy_service.dart';
import '../../../utils/constants.dart';

class TutorTaxonomyScreen extends StatefulWidget {
  const TutorTaxonomyScreen({super.key});

  @override
  State<TutorTaxonomyScreen> createState() => _TutorTaxonomyScreenState();
}

class _TutorTaxonomyScreenState extends State<TutorTaxonomyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _topics = [];
  List<dynamic> _skills = [];
  bool _isLoadingTopics = true;
  bool _isLoadingSkills = true;
  String _topicSearch = '';
  String _skillSearch = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTopics();
    _fetchSkills();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTopics() async {
    setState(() => _isLoadingTopics = true);
    try {
      final res = await TaxonomyService.getTopics();
      if (res['success'] == true && mounted) {
        setState(() {
          _topics = res['topics'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error loading topics: $e');
    } finally {
      if (mounted) setState(() => _isLoadingTopics = false);
    }
  }

  Future<void> _fetchSkills() async {
    setState(() => _isLoadingSkills = true);
    try {
      final res = await TaxonomyService.getSkills();
      if (res['success'] == true && mounted) {
        setState(() {
          _skills = res['skills'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error loading skills: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSkills = false);
    }
  }

  void _showCreateDialog(String type) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                type == 'topic' ? Icons.topic_outlined : Icons.psychology_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Create ${type == 'topic' ? 'Topic' : 'Skill'}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter ${type == 'topic' ? 'topic' : 'skill'} name...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);

              try {
                if (type == 'topic') {
                  await TaxonomyService.createTopic(name: name);
                  _fetchTopics();
                } else {
                  await TaxonomyService.createSkill(name: name);
                  _fetchSkills();
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${type == 'topic' ? 'Topic' : 'Skill'} created successfully!'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to create: $e'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Taxonomy', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Topics'),
            Tab(text: 'Skills'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTopicsTab(),
          _buildSkillsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final type = _tabController.index == 0 ? 'topic' : 'skill';
          _showCreateDialog(type);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTopicsTab() {
    if (_isLoadingTopics) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final filtered = _topics.where((t) {
      final name = (t['name'] ?? '').toString().toLowerCase();
      final courseName = (t['courseId']?['title'] ?? '').toString().toLowerCase();
      return name.contains(_topicSearch.toLowerCase()) ||
          courseName.contains(_topicSearch.toLowerCase());
    }).toList();

    return RefreshIndicator(
      onRefresh: _fetchTopics,
      color: AppColors.primary,
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _topicSearch = v),
              decoration: InputDecoration(
                hintText: 'Search topics...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          // Stats header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B4DF1), Color(0xFF8B73F7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.topic_outlined, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    '${filtered.length} Topics',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Manage subject topics for questions',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // List
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState('No topics found', Icons.topic_outlined)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final topic = filtered[index];
                      return _buildTaxonomyCard(
                        name: topic['name'] ?? 'Untitled',
                        subtitle: topic['courseId']?['title'] ?? 'General',
                        icon: Icons.topic_outlined,
                        color: Colors.indigo,
                        date: topic['createdAt'],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsTab() {
    if (_isLoadingSkills) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final filtered = _skills.where((s) {
      final name = (s['name'] ?? '').toString().toLowerCase();
      return name.contains(_skillSearch.toLowerCase());
    }).toList();

    return RefreshIndicator(
      onRefresh: _fetchSkills,
      color: AppColors.primary,
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _skillSearch = v),
              decoration: InputDecoration(
                hintText: 'Search skills...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          // Stats header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade600, Colors.teal.shade400],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology_outlined, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    '${filtered.length} Skills',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Manage learner skill taxonomy',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // List
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState('No skills found', Icons.psychology_outlined)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final skill = filtered[index];
                      return _buildTaxonomyCard(
                        name: skill['name'] ?? 'Untitled',
                        subtitle: 'Skill Tag',
                        icon: Icons.psychology_outlined,
                        color: Colors.teal,
                        date: skill['createdAt'],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxonomyCard({
    required String name,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? date,
  }) {
    String formattedDate = '';
    if (date != null) {
      try {
        final dt = DateTime.parse(date);
        formattedDate = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          if (formattedDate.isNotEmpty)
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade400,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: AppColors.primary.withOpacity(0.3)),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + to create one',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
