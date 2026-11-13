import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/announcement_service.dart';
import '../../../services/batch_service.dart';
import '../../../providers/course_provider.dart';
import '../../../utils/constants.dart';

class AnnouncementsScreen extends StatefulWidget {
  final bool isTutor;
  const AnnouncementsScreen({super.key, required this.isTutor});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<dynamic> _announcements = [];
  List<dynamic> _batches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
    if (widget.isTutor) {
      _loadTutorOptions();
    }
  }

  Future<void> _fetchAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      final List<dynamic> list;
      if (widget.isTutor) {
        list = await AnnouncementService.fetchTutorAnnouncements();
      } else {
        list = await AnnouncementService.fetchStudentAnnouncements();
      }
      setState(() {
        _announcements = list;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notice board: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadTutorOptions() async {
    try {
      final courseProv = Provider.of<CourseProvider>(context, listen: false);
      if (courseProv.myCourses.isEmpty) {
        await courseProv.fetchMyCourses();
      }
      final res = await BatchService.getAllBatches();
      if (res['success'] == true) {
        setState(() {
          _batches = res['batches'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error loading tutor courses/batches: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notice Board & Announcements', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAnnouncements,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _announcements.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _fetchAnnouncements,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _announcements.length,
                    itemBuilder: (ctx, i) {
                      return _buildAnnouncementCard(_announcements[i]);
                    },
                  ),
                ),
      floatingActionButton: widget.isTutor
          ? FloatingActionButton.extended(
              onPressed: _showCreateAnnouncementDialog,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.campaign),
              label: const Text('Broadcast Notice'),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign_outlined, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Announcements Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isTutor
                  ? 'Send notices, reminders, and schedules to your courses and batches.'
                  : 'Important notices from your instructors will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            if (widget.isTutor) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _showCreateAnnouncementDialog,
                icon: const Icon(Icons.add),
                label: const Text('Send First Announcement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(dynamic announcement) {
    final title = announcement['title'] ?? 'Notice';
    final message = announcement['message'] ?? '';
    final createdAtStr = announcement['createdAt'];
    String dateLabel = '';
    if (createdAtStr != null) {
      dateLabel = DateFormat('dd MMM yyyy, h:mm a').format(DateTime.parse(createdAtStr).toLocal());
    }

    final String sourceType = announcement['sourceType'] ?? 'course';
    final String sourceName = announcement['sourceName'] ?? 'Course';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppThemeDesign.borderRadiusMedium,
        boxShadow: const [AppThemeDesign.cardShadow],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sourceType == 'batch'
                        ? Colors.blue.withValues(alpha: 0.1)
                        : Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    sourceName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: sourceType == 'batch' ? Colors.blue.shade800 : Colors.purple.shade800,
                    ),
                  ),
                ),
                Text(
                  dateLabel,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textMain),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateAnnouncementDialog() {
    final titleCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    
    String targetType = 'course'; // course, batch
    String? selectedCourseId;
    String? selectedBatchId;

    final courses = Provider.of<CourseProvider>(context, listen: false).myCourses;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Compose Announcement Notice',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    // Segmented Target Type
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('To Course')),
                            selected: targetType == 'course',
                            onSelected: (val) {
                              if (val) setDialogState(() => targetType = 'course');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('To Batch')),
                            selected: targetType == 'batch',
                            onSelected: (val) {
                              if (val) setDialogState(() => targetType = 'batch');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (targetType == 'course') ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedCourseId,
                        hint: const Text('Select Target Course'),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: courses.map((c) {
                          return DropdownMenuItem(value: c.id, child: Text(c.title));
                        }).toList(),
                        onChanged: (val) => setDialogState(() => selectedCourseId = val),
                      ),
                    ] else ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedBatchId,
                        hint: const Text('Select Target Batch'),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: _batches.map((b) {
                          return DropdownMenuItem(value: b['_id'] as String, child: Text(b['name'] ?? 'Batch'));
                        }).toList(),
                        onChanged: (val) => setDialogState(() => selectedBatchId = val),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Notice Headline / Title *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: messageCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Write details message *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final title = titleCtrl.text.trim();
                            final message = messageCtrl.text.trim();

                            if (title.isEmpty || message.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill all mandatory fields'), behavior: SnackBarBehavior.floating),
                              );
                              return;
                            }

                            if (targetType == 'course' && selectedCourseId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select target course'), behavior: SnackBarBehavior.floating),
                              );
                              return;
                            }

                            if (targetType == 'batch' && selectedBatchId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select target batch'), behavior: SnackBarBehavior.floating),
                              );
                              return;
                            }

                            Navigator.of(ctx).pop();
                            setState(() => _isLoading = true);

                            try {
                              bool success = false;
                              if (targetType == 'course') {
                                success = await AnnouncementService.createCourseAnnouncement(
                                  selectedCourseId!,
                                  title: title,
                                  message: message,
                                );
                              } else {
                                success = await AnnouncementService.createBatchAnnouncement(
                                  selectedBatchId!,
                                  title: title,
                                  message: message,
                                );
                              }

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Announcement sent successfully!'), behavior: SnackBarBehavior.floating),
                                );
                                _fetchAnnouncements();
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to publish notice: $e'), behavior: SnackBarBehavior.floating),
                              );
                              setState(() => _isLoading = false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Broadcast Notice'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
