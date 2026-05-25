import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/live_class_model.dart';
import '../../../services/live_class_service.dart';
import '../../common/live_meeting_screen.dart';
import 'schedule_live_class_screen.dart';

class TutorLiveClassesScreen extends StatefulWidget {
  const TutorLiveClassesScreen({Key? key}) : super(key: key);

  @override
  State<TutorLiveClassesScreen> createState() => _TutorLiveClassesScreenState();
}

class _TutorLiveClassesScreenState extends State<TutorLiveClassesScreen> {
  final LiveClassService _liveClassService = LiveClassService();
  List<LiveClass> _liveClasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLiveClasses();
  }

  Future<void> _loadLiveClasses() async {
    setState(() => _isLoading = true);
    try {
      final classes = await _liveClassService.fetchLiveClasses();
      setState(() {
        _liveClasses = classes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _startClass(LiveClass liveClass) async {
    try {
      final config = await _liveClassService.getJoinConfig(liveClass.id);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LiveMeetingScreen(
              classId: liveClass.id,
              config: config,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Start Error: $e')),
        );
      }
    }
  }

  void _deleteClass(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Class'),
        content: const Text('Are you sure you want to cancel and delete this live class?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _liveClassService.deleteLiveClass(id);
        _loadLiveClasses();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Live Classes'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLiveClasses,
              child: _liveClasses.isEmpty
                  ? const Center(child: Text('You have not scheduled any live classes.'))
                  : ListView.builder(
                      itemCount: _liveClasses.length,
                      padding: const EdgeInsets.all(12),
                      itemBuilder: (context, index) {
                        final liveClass = _liveClasses[index];
                        final bool canStart = liveClass.status != 'completed';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        liveClass.title,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _deleteClass(liveClass.id),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Date: ${DateFormat('MMM d, hh:mm a').format(liveClass.dateTime)}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: canStart ? () => _startClass(liveClass) : null,
                                        icon: const Icon(Icons.videocam),
                                        label: Text(liveClass.status == 'ongoing' ? 'Resume Class' : 'Start Class'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.indigo,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScheduleLiveClassScreen()),
          );
          if (result == true) _loadLiveClasses();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
