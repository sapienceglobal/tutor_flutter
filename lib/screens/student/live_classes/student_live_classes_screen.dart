import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/live_class_model.dart';
import '../../../services/live_class_service.dart';
import '../../common/live_meeting_screen.dart';

class StudentLiveClassesScreen extends StatefulWidget {
  const StudentLiveClassesScreen({Key? key}) : super(key: key);

  @override
  State<StudentLiveClassesScreen> createState() => _StudentLiveClassesScreenState();
}

class _StudentLiveClassesScreenState extends State<StudentLiveClassesScreen> {
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

  void _joinClass(LiveClass liveClass) async {
    if (liveClass.status == 'completed' || liveClass.status == 'cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This class has ended or been cancelled')),
      );
      return;
    }

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
          SnackBar(content: Text('Join Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Classes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLiveClasses,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLiveClasses,
              child: _liveClasses.isEmpty
                  ? const Center(child: Text('No live classes scheduled.'))
                  : ListView.builder(
                      itemCount: _liveClasses.length,
                      padding: const EdgeInsets.all(12),
                      itemBuilder: (context, index) {
                        final liveClass = _liveClasses[index];
                        final bool isLive = liveClass.status == 'ongoing' ||
                            (liveClass.status == 'scheduled' &&
                                liveClass.dateTime.isBefore(DateTime.now().add(const Duration(minutes: 5))));

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isLive ? Colors.green : Colors.grey,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isLive ? 'LIVE' : liveClass.status.toUpperCase(),
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (liveClass.courseTitle != null)
                                  Text(
                                    'Course: ${liveClass.courseTitle}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 14, color: Colors.blue),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat('EEE, MMM d, yyyy').format(liveClass.dateTime),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.access_time, size: 14, color: Colors.blue),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat('hh:mm a').format(liveClass.dateTime),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: isLive ? () => _joinClass(liveClass) : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: Colors.grey[300],
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Join Class'),
                                  ),
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
