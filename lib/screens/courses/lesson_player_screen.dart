import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/lesson_model.dart';
import '../../utils/constants.dart';
import '../../config/api_config.dart';
import '../../services/enrollment_service.dart';
import '../../widgets/sapience_ui.dart';

class LessonPlayerScreen extends StatefulWidget {
  final LessonModel lesson;
  final String courseId;

  const LessonPlayerScreen({
    super.key,
    required this.lesson,
    required this.courseId,
  });

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  YoutubePlayerController? _youtubeController;
  bool _isLoading = true;
  String? _error;
  late final String? _videoUrl;
  int _initialPositionSec = 0;
  int _selectedTab = 0;
  bool _isCompleted = false;
  bool _isMarkingComplete = false;

  String get _positionKey =>
      'lesson_pos_${widget.courseId}_${widget.lesson.id}';

  @override
  void initState() {
    super.initState();
    final rawUrl = widget.lesson.content.videoUrl;
    _videoUrl = (rawUrl != null && rawUrl.trim().isNotEmpty)
        ? ApiConfig.resolveMediaUrl(rawUrl)
        : null;
    _loadInitialPosition().then((_) => _initPlayer());
  }

  Future<void> _loadInitialPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _initialPositionSec = prefs.getInt(_positionKey) ?? 0;
    } catch (_) {
      _initialPositionSec = 0;
    }
  }

  bool _isYouTubeUrl(String? url) {
    if (url == null) return false;
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  Future<void> _initPlayer() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_videoUrl == null) {
        setState(() {
          _error = 'No video available for this lesson.';
          _isLoading = false;
        });
        return;
      }

      if (_isYouTubeUrl(_videoUrl)) {
        final videoId = YoutubePlayer.convertUrlToId(_videoUrl);
        if (videoId == null) {
          setState(() {
            _error = 'Invalid YouTube link.';
            _isLoading = false;
          });
          return;
        }

        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            disableDragSeek: false,
            loop: false,
            forceHD: false,
            enableCaption: true,
          ),
        );

        _youtubeController!.addListener(_youtubeListener);

        Future.delayed(const Duration(milliseconds: 500), () {
          if (_initialPositionSec > 0) {
            try {
              _youtubeController?.seekTo(
                Duration(seconds: _initialPositionSec),
              );
            } catch (_) {}
          }
        });

        setState(() {
          _isLoading = false;
        });
      } else {
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(_videoUrl),
        );

        await _videoPlayerController!.initialize();

        if (_initialPositionSec > 0) {
          final d = Duration(seconds: _initialPositionSec);
          if (d < _videoPlayerController!.value.duration) {
            await _videoPlayerController!.seekTo(d);
          }
        }

        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true,
          looping: false,
          allowMuting: true,
          allowPlaybackSpeedChanging: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: AppColors.primary,
            handleColor: AppColors.primary,
            backgroundColor: Colors.grey,
            bufferedColor: Colors.grey[300]!,
          ),
          placeholder: Container(color: Colors.black),
          autoInitialize: true,
        );

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, st) {
      print('Error initializing video: $e\n$st');
      setState(() {
        _error = 'Failed to load video. Tap retry.';
        _isLoading = false;
      });
    }
  }

  void _youtubeListener() {}

  @override
  void dispose() {
    _savePosition();
    _youtubeController?.removeListener(_youtubeListener);
    _youtubeController?.pause();
    _youtubeController?.dispose();
    _chewieController?.pause();
    _chewieController?.dispose();
    _videoPlayerController?.pause();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _savePosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int pos = 0;
      if (_youtubeController != null) {
        final v = _youtubeController!.value;
        pos = v.position.inSeconds;
      } else if (_videoPlayerController != null) {
        pos = _videoPlayerController!.value.position.inSeconds;
      }
      await prefs.setInt(_positionKey, pos);
    } catch (_) {}
  }

  Future<void> _retry() async {
    await _disposeControllers();
    await _loadInitialPosition();
    await _initPlayer();
  }

  Future<void> _disposeControllers() async {
    try {
      _youtubeController?.removeListener(_youtubeListener);
      _youtubeController?.dispose();
      _youtubeController = null;
    } catch (_) {}
    try {
      _chewieController?.dispose();
      _chewieController = null;
    } catch (_) {}
    try {
      await _videoPlayerController?.dispose();
      _videoPlayerController = null;
    } catch (_) {}
  }

  Future<void> _openInExternal() async {
    final url = _videoUrl;
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cannot open link.')));
    }
  }

  Future<void> _markLessonComplete() async {
    if (_isMarkingComplete) return;
    setState(() => _isMarkingComplete = true);
    try {
      int pos = 0;
      if (_youtubeController != null) {
        pos = _youtubeController!.value.position.inSeconds;
      } else if (_videoPlayerController != null) {
        pos = _videoPlayerController!.value.position.inSeconds;
      }

      await EnrollmentService.updateProgress(
        courseId: widget.courseId,
        lessonId: widget.lesson.id,
        watchedDuration: pos,
        isCompleted: true,
      );

      if (!mounted) return;
      setState(() => _isCompleted = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lesson marked as complete!'),
          backgroundColor: AppColors.secondary,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update progress: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isMarkingComplete = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attachments = widget.lesson.content.attachments;
    final documents = widget.lesson.content.documents;

    return SapienceBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SapienceHeader(
                title: widget.lesson.title,
                actions: [
                  _headerActionIcon(
                    icon: Icons.open_in_new_rounded,
                    tooltip: 'Open externally',
                    onTap: _openInExternal,
                  ),
                  const SizedBox(width: 8),
                  _headerActionIcon(
                    icon: Icons.refresh_rounded,
                    tooltip: 'Reload',
                    onTap: _retry,
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rounded Video Player Frame matching PNG
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A142D),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [AppThemeDesign.cardShadow],
                          border: Border.all(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildPlayerBody(),
                      ),
                      const SizedBox(height: 14),

                      // Metadata Card
                      SapienceCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.lesson.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.navyInk,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                                if (_isCompleted) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 14,
                                          color: AppColors.secondary,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Completed',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryTint,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    widget.lesson.type.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                if (widget.lesson.content.duration != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F6FD),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.schedule_rounded,
                                          size: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${(widget.lesson.content.duration! / 60).ceil()} min',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.navyInk,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (widget.lesson.isFree)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.secondary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'FREE PREVIEW',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      SapienceSegmentedTabs(
                        tabs: [
                          'Overview',
                          'Resources (${attachments.length + documents.length})',
                        ],
                        currentIndex: _selectedTab,
                        onChanged: (i) => setState(() => _selectedTab = i),
                      ),
                      const SizedBox(height: 14),

                      if (_selectedTab == 0)
                        _buildOverviewSection()
                      else
                        _buildResourcesSection(attachments, documents),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              border: Border(top: BorderSide(color: AppColors.border)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0E2960).withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: SapienceButton(
                    label: 'Back to Course',
                    variant: SapienceButtonVariant.outlinedNavy,
                    height: 48,
                    fontSize: 13.5,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: SapienceButton(
                    label: _isMarkingComplete
                        ? 'Saving...'
                        : _isCompleted
                            ? 'Completed ✓'
                            : 'Mark Complete',
                    variant: _isCompleted
                        ? SapienceButtonVariant.green
                        : SapienceButtonVariant.greenToBlue,
                    trailingIcon: _isCompleted
                        ? Icons.check_rounded
                        : Icons.check_circle_outline_rounded,
                    height: 48,
                    fontSize: 14,
                    onTap: _isMarkingComplete ? null : _markLessonComplete,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerActionIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: const [AppThemeDesign.softShadow],
            ),
            child: Icon(icon, color: AppColors.navyInk, size: 19),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerBody() {
    if (_isLoading) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_error != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh_rounded, size: 17),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.navyInk,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _openInExternal,
                    icon: const Icon(Icons.open_in_new_rounded, size: 17),
                    label: const Text('Open External'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_youtubeController != null) {
      return YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppColors.primary,
          onReady: () {},
        ),
        builder: (context, player) {
          return AspectRatio(aspectRatio: 16 / 9, child: player);
        },
      );
    }

    if (_chewieController != null) {
      return AspectRatio(
        aspectRatio: _videoPlayerController!.value.aspectRatio > 0
            ? _videoPlayerController!.value.aspectRatio
            : 16 / 9,
        child: Chewie(controller: _chewieController!),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppThemeDesign.navyWaveGradient,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${widget.lesson.type.toUpperCase()} LESSON',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    final desc = widget.lesson.description.trim();
    return SapienceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lesson Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.navyInk,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            desc.isNotEmpty
                ? desc
                : 'Watch or review this lesson carefully, then mark it as complete when you finish.',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6FD),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: const [
                SapienceCheckBadge(size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Playback position is saved automatically on this device.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navyInk,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesSection(
    List<LessonAttachment> attachments,
    List<DocumentData> documents,
  ) {
    if (attachments.isEmpty && documents.isEmpty) {
      return SapienceCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              children: const [
                Icon(
                  Icons.folder_open_rounded,
                  size: 38,
                  color: AppColors.textMuted,
                ),
                SizedBox(height: 8),
                Text(
                  'No downloadable resources for this lesson.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        ...documents.map(
          (doc) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SapienceTintedTile(
              tone: SapienceTileTone.blue,
              onTap: () => _openAttachmentUrl(doc.url),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.name.isNotEmpty
                              ? doc.name
                              : 'Lesson Document / Slides',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.navyInk,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          doc.type.isNotEmpty
                              ? doc.type.toUpperCase()
                              : 'Tap to open material',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.open_in_new_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        ...attachments.map(
          (attachment) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SapienceCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () => _openAttachmentUrl(attachment.url),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.attach_file_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attachment.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.navyInk,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          attachment.type.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.download_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openAttachmentUrl(String rawUrl) async {
    final resolved = ApiConfig.resolveMediaUrl(rawUrl);
    if (resolved.isEmpty) return;
    final uri = Uri.tryParse(resolved);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open attachment URL')),
      );
    }
  }
}
