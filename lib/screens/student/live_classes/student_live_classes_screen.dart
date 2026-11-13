import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/api_config.dart';
import '../../../models/live_class_model.dart';
import '../../../services/live_class_service.dart';
import '../../../utils/constants.dart';
import '../../../widgets/sapience_ui.dart';
import '../../../widgets/shimmer_loader.dart';
import '../../common/live_meeting_screen.dart';

class StudentLiveClassesScreen extends StatefulWidget {
  const StudentLiveClassesScreen({super.key});

  @override
  State<StudentLiveClassesScreen> createState() => _StudentLiveClassesScreenState();
}

class _StudentLiveClassesScreenState extends State<StudentLiveClassesScreen> {
  final LiveClassService _liveClassService = LiveClassService();
  List<LiveClass> _liveClasses = [];
  bool _isLoading = true;
  int _tabIndex = 0; // 0: Upcoming, 1: Live Now, 2: Completed

  @override
  void initState() {
    super.initState();
    _loadLiveClasses();
  }

  Future<void> _loadLiveClasses() async {
    setState(() => _isLoading = true);
    try {
      final classes = await _liveClassService.fetchLiveClasses();
      if (!mounted) return;
      setState(() {
        _liveClasses = classes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  bool _isLiveNow(LiveClass lc) {
    if (lc.status == 'ongoing') return true;
    if (lc.status == 'scheduled') {
      final now = DateTime.now();
      final end = lc.dateTime.add(Duration(minutes: lc.duration));
      return now.isAfter(lc.dateTime.subtract(const Duration(minutes: 10))) &&
          now.isBefore(end);
    }
    return false;
  }

  List<LiveClass> get _filteredClasses {
    if (_tabIndex == 1) {
      return _liveClasses.where(_isLiveNow).toList();
    } else if (_tabIndex == 2) {
      return _liveClasses
          .where((lc) => lc.status == 'completed' || lc.status == 'cancelled')
          .toList();
    }
    // Upcoming: scheduled future or currently live first
    final list = _liveClasses
        .where((lc) => lc.status != 'completed' && lc.status != 'cancelled')
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  Future<void> _joinClass(LiveClass liveClass) async {
    if (liveClass.status == 'completed' || liveClass.status == 'cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This class has ended or been cancelled.')),
      );
      return;
    }

    try {
      final config = await _liveClassService.getJoinConfig(liveClass.id);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveMeetingScreen(classId: liveClass.id, config: config),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Join Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLive = _liveClasses.any(_isLiveNow);
    final list = _filteredClasses;

    return Scaffold(
      body: SapienceBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SapienceHeader(
                title: 'Live Classes',
                actions: [
                  IconButton(
                    icon: const Icon(Icons.event_available_rounded, color: AppColors.navy, size: 25),
                    onPressed: _loadLiveClasses,
                    splashRadius: 20,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: SapienceSegmentedTabs(
                  tabs: const ['Upcoming', 'Live Now', 'Completed'],
                  currentIndex: _tabIndex,
                  liveDotIndex: hasLive ? 1 : null,
                  flat: false,
                  onChanged: (i) => setState(() => _tabIndex = i),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const ShimmerListView(itemCount: 4)
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadLiveClasses,
                        child: list.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  const SizedBox(height: 60),
                                  Center(
                                    child: SapienceCard(
                                      margin: const EdgeInsets.symmetric(horizontal: 24),
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        children: [
                                          Image.asset(
                                            'assets/images/live-laptop.png',
                                            width: 90,
                                            height: 76,
                                            fit: BoxFit.contain,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            _tabIndex == 1
                                                ? 'No live session ongoing right now'
                                                : _tabIndex == 2
                                                    ? 'No completed sessions yet'
                                                    : 'No upcoming live classes scheduled',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.navy,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Pull down to refresh your live class schedule.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                itemCount: list.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (_, i) => _buildClassCard(list[i], i),
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassCard(LiveClass lc, int index) {
    final isLive = _isLiveNow(lc);
    final isCompleted = lc.status == 'completed' || lc.status == 'cancelled';
    final endDt = lc.dateTime.add(Duration(minutes: lc.duration));
    final dateLabel = DateFormat('dd MMM').format(lc.dateTime);
    final now = DateTime.now();
    final isToday = lc.dateTime.year == now.year &&
        lc.dateTime.month == now.month &&
        lc.dateTime.day == now.day;
    final dayPrefix = isToday ? 'Today' : dateLabel;
    final timeRange =
        '$dayPrefix, ${DateFormat('h:mm a').format(lc.dateTime)} – ${DateFormat('h:mm a').format(endDt)}';

    final tutorAvatar = ApiConfig.resolveMediaUrl(lc.tutorImage);

    const tileGradients = [
      [Color(0xFFE7F7EE), Color(0xFF0E9F6E)],
      [Color(0xFFEAE8FF), Color(0xFF2079FF)],
      [Color(0xFFFFF0D8), Color(0xFFEA580C)],
      [Color(0xFFEAF1FF), Color(0xFF0650E8)],
    ];
    final palette = tileGradients[index % tileGradients.length];

    return SapienceCard(
      borderRadius: 20,
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      onTap: isCompleted ? null : () => _joinClass(lc),
      child: Row(
        children: [
          // Left square visual box matching Live Classes Dashboard.png
          Container(
            width: 102,
            height: isLive ? 124 : 98,
            decoration: BoxDecoration(
              color: isLive ? const Color(0xFFEEF3FB) : palette[0],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isLive)
                  Padding(
                    padding: const EdgeInsets.only(top: 18, left: 8, right: 8),
                    child: Image.asset(
                      'assets/images/live-laptop.png',
                      fit: BoxFit.contain,
                    ),
                  )
                else
                  Container(
                    width: 66,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [palette[1].withValues(alpha: 0.85), palette[1]],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: palette[1].withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                  ),
                if (isLive)
                  const Positioned(
                    top: 8,
                    left: 8,
                    child: SapienceLiveBadge(),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lc.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: AppColors.primarySoft,
                      backgroundImage:
                          tutorAvatar.isNotEmpty ? NetworkImage(tutorAvatar) : null,
                      child: tutorAvatar.isEmpty
                          ? const Icon(Icons.person_rounded, size: 13, color: AppColors.primary)
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'By ${lc.tutorName ?? 'Instructor'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textBody,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    if (!isLive) ...[
                      const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        timeRange,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textBody),
                      ),
                    ),
                  ],
                ),
                if (isLive) ...[
                  const SizedBox(height: 10),
                  SapienceButton(
                    label: 'Join Now',
                    variant: SapienceButtonVariant.blue,
                    height: 36,
                    fontSize: 14,
                    borderRadius: 12,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    onTap: () => _joinClass(lc),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            isCompleted ? Icons.check_circle_outline_rounded : Icons.chevron_right_rounded,
            color: isCompleted ? AppColors.success : AppColors.primary,
            size: 22,
          ),
        ],
      ),
    );
  }
}
