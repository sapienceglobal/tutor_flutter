import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/lesson_model.dart';
import '../../utils/constants.dart';

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

  String get _positionKey =>
      'lesson_pos_${widget.courseId}_${widget.lesson.id}';

  @override
  void initState() {
    super.initState();
    _videoUrl = widget.lesson.content.videoUrl;
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
        // no video url
        setState(() {
          _error = 'No video available for this lesson.';
          _isLoading = false;
        });
        return;
      }

      if (_isYouTubeUrl(_videoUrl)) {
        // Use Youtube player
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

        // Wait until ready then seek to saved position
        _youtubeController!.addListener(_youtubeListener);

        // If initial position exists, seek after a short delay when ready
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
        // Use VideoPlayer + Chewie for direct links
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(_videoUrl),
        );

        await _videoPlayerController!.initialize();

        // seek to saved position if exists
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

  void _youtubeListener() {
    // placeholder if you want to track state changes
  }

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
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cannot open link.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.lesson.title,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Open in external app',
            onPressed: _openInExternal,
            icon: const Icon(Icons.open_in_new),
          ),
          IconButton(
            tooltip: 'Retry',
            onPressed: _retry,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _openInExternal,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open externally'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Player area
                if (_youtubeController != null)
                  YoutubePlayerBuilder(
                    player: YoutubePlayer(
                      controller: _youtubeController!,
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: AppColors.primary,
                      onReady: () {
                        // ready
                      },
                    ),
                    builder: (context, player) {
                      return AspectRatio(aspectRatio: 16 / 9, child: player);
                    },
                  )
                else if (_chewieController != null)
                  AspectRatio(
                    aspectRatio: _videoPlayerController!.value.aspectRatio > 0
                        ? _videoPlayerController!.value.aspectRatio
                        : 16 / 9,
                    child: Chewie(controller: _chewieController!),
                  )
                else
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                // Content below
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            widget.lesson.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Type & Duration
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.lesson.type.toUpperCase(),
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (widget.lesson.content.duration != null) ...[
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${(widget.lesson.content.duration! / 60).toStringAsFixed(0)} min',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Description
                          if (widget.lesson.description.isNotEmpty) ...[
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.lesson.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Attachments
                          if (widget.lesson.content.attachments.isNotEmpty) ...[
                            const Text(
                              'Attachments',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...widget.lesson.content.attachments.map((
                              attachment,
                            ) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.attach_file,
                                    color: AppColors.primary,
                                  ),
                                  title: Text(attachment.name),
                                  subtitle: Text(attachment.type),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.download),
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Download feature coming soon!',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            }),
                          ],
                          const SizedBox(height: 80), // spacing for bottom bar
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // TODO: go to previous lesson logic
                },
                child: const Text('Previous'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: mark complete and navigate to next lesson
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Marked complete (demo).')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Complete & Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
