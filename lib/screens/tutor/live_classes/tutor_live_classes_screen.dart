import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/live_class_model.dart';
import '../../../services/live_class_service.dart';
import '../../../utils/constants.dart';
import '../../../widgets/sapience_ui.dart';
import '../../common/live_meeting_screen.dart';
import 'schedule_live_class_screen.dart';

class TutorLiveClassesScreen extends StatefulWidget {
  final bool embedded;

  const TutorLiveClassesScreen({super.key, this.embedded = false});

  @override
  State<TutorLiveClassesScreen> createState() => _TutorLiveClassesScreenState();
}

class _TutorLiveClassesScreenState extends State<TutorLiveClassesScreen> {
  final LiveClassService _liveClassService = LiveClassService();
  List<LiveClass> _liveClasses = [];
  bool _isLoading = true;
  int _selectedTab = 0; // 0: Upcoming, 1: Live Now, 2: Completed

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Class'),
        content: const Text(
          'Are you sure you want to cancel and delete this live class?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes', style: TextStyle(color: AppColors.error)),
          ),
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

  List<LiveClass> get _filteredClasses {
    return _liveClasses.where((c) {
      final st = c.status.toLowerCase();
      if (_selectedTab == 1) {
        return st == 'ongoing' || st == 'live';
      }
      if (_selectedTab == 2) {
        return st == 'completed' || st == 'ended';
      }
      return st != 'completed' && st != 'ended' && st != 'ongoing' && st != 'live';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final liveNowCount = _liveClasses
        .where((c) => c.status.toLowerCase() == 'ongoing' || c.status.toLowerCase() == 'live')
        .length;

    return SapienceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SapienceHeader(
                title: 'Live Classes',
                onBack:
                    widget.embedded ? () {} : () => Navigator.of(context).pop(),
                leading: widget.embedded ? const SizedBox(width: 4) : null,
                actions: [
                  Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ScheduleLiveClassScreen(),
                          ),
                        );
                        if (result == true) _loadLiveClasses();
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: SapienceSegmentedTabs(
                  tabs: const ['Upcoming', 'Live Now', 'Completed'],
                  currentIndex: _selectedTab,
                  liveDotIndex: liveNowCount > 0 ? 1 : null,
                  onChanged: (idx) => setState(() => _selectedTab = idx),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadLiveClasses,
                        child: _filteredClasses.isEmpty
                            ? ListView(
                                padding: const EdgeInsets.all(24),
                                children: [
                                  const SizedBox(height: 36),
                                  SapienceCard(
                                    padding: const EdgeInsets.all(28),
                                    child: Column(
                                      children: [
                                        Image.asset(
                                          'assets/images/live-laptop.png',
                                          height: 92,
                                        ),
                                        const SizedBox(height: 14),
                                        const Text(
                                          'No classes in this schedule view',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.navyInk,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'Schedule interactive live classes and launch sessions directly from here.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        SapienceButton(
                                          label: 'Schedule Live Class',
                                          leadingIcon: Icons.videocam_rounded,
                                          variant:
                                              SapienceButtonVariant.greenToBlue,
                                          onTap: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const ScheduleLiveClassScreen(),
                                              ),
                                            );
                                            if (result == true) {
                                              _loadLiveClasses();
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 28),
                                itemCount: _filteredClasses.length,
                                itemBuilder: (context, index) {
                                  final liveClass = _filteredClasses[index];
                                  final isLive =
                                      liveClass.status.toLowerCase() == 'ongoing' ||
                                          liveClass.status.toLowerCase() == 'live';
                                  final canStart =
                                      liveClass.status.toLowerCase() !=
                                          'completed';

                                  return SapienceCard(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.all(16),
                                    borderRadius: 20,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            if (isLive)
                                              const SapienceLiveBadge()
                                            else
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryTint,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  liveClass.status.toUpperCase(),
                                                  style: const TextStyle(
                                                    color: AppColors.primary,
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            const Spacer(),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline_rounded,
                                                color: AppColors.error,
                                                size: 20,
                                              ),
                                              onPressed: () =>
                                                  _deleteClass(liveClass.id),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    liveClass.title,
                                                    style: const TextStyle(
                                                      fontSize: 16.5,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: AppColors.navyInk,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .calendar_today_rounded,
                                                        size: 14,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        DateFormat(
                                                                'MMM d, hh:mm a')
                                                            .format(liveClass
                                                                .dateTime),
                                                        style: const TextStyle(
                                                          fontSize: 12.5,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Image.asset(
                                              'assets/images/live-laptop.png',
                                              width: 62,
                                              height: 52,
                                              fit: BoxFit.contain,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        SapienceButton(
                                          label: isLive
                                              ? 'Resume Live Session'
                                              : canStart
                                                  ? 'Start Live Class'
                                                  : 'Session Completed',
                                          leadingIcon: Icons.videocam_rounded,
                                          variant: canStart
                                              ? SapienceButtonVariant
                                                  .greenToBlue
                                              : SapienceButtonVariant
                                                  .outlinedNavy,
                                          height: 44,
                                          onTap: canStart
                                              ? () => _startClass(liveClass)
                                              : null,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
