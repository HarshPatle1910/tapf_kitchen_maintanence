import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';

/// A dedicated full-screen video player screen for verification videos.
/// Supports playing videos from Firebase/Supabase remote URLs as well as local file paths.
class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String? title;
  final String? subtitle;
  final String? fileName;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    this.title,
    this.subtitle,
    this.fileName,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = true;
  Timer? _hideControlsTimer;
  double _playbackSpeed = 1.0;
  bool _isMuted = false;
  BoxFit _videoFit = BoxFit.contain;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _isInitialized = false;
    });

    try {
      final cleanUrl = widget.videoUrl.trim();
      if (cleanUrl.isEmpty) {
        throw Exception("Video URL or file path is empty.");
      }

      // Dispose existing controller if retrying
      if (_controller != null) {
        _controller!.removeListener(_onControllerUpdate);
        await _controller!.dispose();
        _controller = null;
      }

      final isNetwork = cleanUrl.startsWith('http://') ||
          cleanUrl.startsWith('https://');

      if (isNetwork) {
        final parsedUri =
            Uri.tryParse(cleanUrl) ?? Uri.parse(Uri.encodeFull(cleanUrl));
        _controller = VideoPlayerController.networkUrl(
          parsedUri,
          httpHeaders: const {
            'User-Agent': 'Mozilla/5.0 (Mobile; Android; iOS)',
          },
        );
      } else {
        final file = File(cleanUrl);
        if (!await file.exists()) {
          throw Exception("Local video file does not exist at path: $cleanUrl");
        }
        _controller = VideoPlayerController.file(file);
      }

      await _controller!.initialize();
      _controller!.addListener(_onControllerUpdate);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller!.play();
        _startHideControlsTimer();
      }
    } catch (e) {
      debugPrint("Error initializing video player: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    if (_controller != null && _controller!.value.hasError) {
      final desc = _controller!.value.errorDescription ?? 'Playback error occurred.';
      debugPrint("VideoPlayer runtime error: $desc");
      setState(() {
        _hasError = true;
        _errorMessage = desc;
      });
      return;
    }
    setState(() {});
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _controller != null && _controller!.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideControlsTimer();
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _showControls = true;
        _hideControlsTimer?.cancel();
      } else {
        if (_controller!.value.position >= _controller!.value.duration) {
          _controller!.seekTo(Duration.zero);
        }
        _controller!.play();
        _startHideControlsTimer();
      }
    });
  }

  void _seekRelative(int seconds) {
    if (_controller == null || !_isInitialized) return;
    final currentPos = _controller!.value.position;
    final targetPos = currentPos + Duration(seconds: seconds);
    final clampedPos = targetPos < Duration.zero
        ? Duration.zero
        : (targetPos > _controller!.value.duration
            ? _controller!.value.duration
            : targetPos);
    _controller!.seekTo(clampedPos);
    _startHideControlsTimer();
  }

  void _setPlaybackSpeed(double speed) {
    if (_controller == null || !_isInitialized) return;
    _controller!.setPlaybackSpeed(speed);
    setState(() {
      _playbackSpeed = speed;
    });
    _startHideControlsTimer();
  }

  void _toggleMute() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
    _startHideControlsTimer();
  }

  void _toggleFit() {
    setState(() {
      _videoFit =
          _videoFit == BoxFit.contain ? BoxFit.cover : BoxFit.contain;
    });
    _startHideControlsTimer();
  }

  Future<void> _openExternalPlayer() async {
    final cleanUrl = widget.videoUrl.trim();
    final isNetwork = cleanUrl.startsWith('http://') ||
        cleanUrl.startsWith('https://');

    if (isNetwork) {
      final uri = Uri.tryParse(cleanUrl) ?? Uri.parse(Uri.encodeFull(cleanUrl));
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch video: $e')),
          );
        }
      }
    } else {
      try {
        await OpenFilex.open(cleanUrl);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open file: $e')),
          );
        }
      }
    }
  }

  Future<void> _openBrowser() async {
    final cleanUrl = widget.videoUrl.trim();
    if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
      final uri = Uri.tryParse(cleanUrl) ?? Uri.parse(Uri.encodeFull(cleanUrl));
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open in browser: $e')),
          );
        }
      }
    }
  }

  void _shareVideo() {
    final isNetwork = widget.videoUrl.startsWith('http://') ||
        widget.videoUrl.startsWith('https://');
    if (isNetwork) {
      Share.share(
        'Visual Verification Video: ${widget.videoUrl}',
        subject: widget.title ?? 'Verification Video',
      );
    } else {
      Share.shareXFiles(
        [XFile(widget.videoUrl)],
        text: widget.title ?? 'Verification Video',
      );
    }
  }

  String _formatDuration(Duration duration) {
    final twoDigits = (int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          bottom: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Main Video Area
              Center(
                child: _buildVideoContent(),
              ),

              // Tap detection overlay for toggling controls
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleControls,
                child: const SizedBox.expand(),
              ),

              // Control overlays (Top App Bar & Bottom Player Bar)
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Stack(
                    children: [
                      // Top Bar Gradient & Content
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: _buildTopBar(),
                      ),

                      // Center Play/Pause & Skip Buttons
                      if (_isInitialized && !_hasError)
                        Center(
                          child: _buildCenterControls(),
                        ),

                      // Bottom Scrubber Bar & Controls
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _buildBottomControls(),
                      ),
                    ],
                  ),
                ),
              ),

              // Error State Banner
              if (_hasError) _buildErrorView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_hasError) {
      return const SizedBox.shrink();
    }

    if (!_isInitialized || _controller == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            "Loading video...",
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    final size = _controller!.value.size;
    final aspectRatio = _controller!.value.aspectRatio > 0
        ? _controller!.value.aspectRatio
        : (size.width > 0 && size.height > 0
            ? size.width / size.height
            : 16 / 9);

    return FittedBox(
      fit: _videoFit,
      child: SizedBox(
        width: size.width > 0 ? size.width : 1280,
        height: size.height > 0 ? size.height : 720,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller!),
              if (_controller!.value.isBuffering)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                    strokeWidth: 2.5,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black87,
            Colors.black54,
            Colors.transparent,
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title ?? "Verification Video",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.subtitle != null || widget.fileName != null)
                  Text(
                    widget.subtitle ?? widget.fileName ?? '',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: "Share Video",
            icon: const Icon(
              Icons.share_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _shareVideo,
          ),
          IconButton(
            tooltip: "Open in System Player",
            icon: const Icon(
              Icons.open_in_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _openExternalPlayer,
          ),
        ],
      ),
    );
  }

  Widget _buildCenterControls() {
    final isPlaying = _controller?.value.isPlaying ?? false;
    final isEnded = _controller != null &&
        _controller!.value.position >= _controller!.value.duration &&
        _controller!.value.duration > Duration.zero;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 10s Rewind
        IconButton(
          iconSize: 36,
          icon: const Icon(
            Icons.replay_10_rounded,
            color: Colors.white,
          ),
          onPressed: () => _seekRelative(-10),
        ),
        const SizedBox(width: 24),

        // Main Play/Pause Button
        GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              isEnded
                  ? Icons.replay_rounded
                  : (isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
              color: Colors.white,
              size: 38,
            ),
          ),
        ),
        const SizedBox(width: 24),

        // 10s Forward
        IconButton(
          iconSize: 36,
          icon: const Icon(
            Icons.forward_10_rounded,
            color: Colors.white,
          ),
          onPressed: () => _seekRelative(10),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    if (!_isInitialized || _controller == null) return const SizedBox.shrink();

    final position = _controller!.value.position;
    final duration = _controller!.value.duration;
    final maxDurationMs = duration.inMilliseconds.toDouble();
    final currentPosMs = position.inMilliseconds.toDouble().clamp(
          0.0,
          maxDurationMs > 0 ? maxDurationMs : 0.0,
        );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black87,
            Colors.black54,
            Colors.transparent,
          ],
        ),
      ),
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slider and Duration Row
          Row(
            children: [
              Text(
                _formatDuration(position),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.5,
                    activeTrackColor: const Color(0xFFF59E0B),
                    inactiveTrackColor: Colors.white24,
                    thumbColor: const Color(0xFFF59E0B),
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayColor:
                        const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: currentPosMs,
                    min: 0.0,
                    max: maxDurationMs > 0 ? maxDurationMs : 1.0,
                    onChanged: (val) {
                      _startHideControlsTimer();
                      _controller!.seekTo(Duration(milliseconds: val.toInt()));
                    },
                  ),
                ),
              ),
              Text(
                _formatDuration(duration),
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Action Toolbar: Speed, Mute, Fit, External
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Speed selector
              PopupMenuButton<double>(
                initialValue: _playbackSpeed,
                tooltip: "Playback Speed",
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: _setPlaybackSpeed,
                itemBuilder: (ctx) => [
                  for (final speed in [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
                    PopupMenuItem(
                      value: speed,
                      child: Text(
                        "${speed}x",
                        style: GoogleFonts.inter(
                          color: _playbackSpeed == speed
                              ? const Color(0xFFF59E0B)
                              : Colors.white,
                          fontWeight: _playbackSpeed == speed
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${_playbackSpeed}x",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mute / Unmute
                  IconButton(
                    tooltip: _isMuted ? "Unmute" : "Mute",
                    icon: Icon(
                      _isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _toggleMute,
                  ),

                  // Fit Aspect Ratio Toggle
                  IconButton(
                    tooltip: _videoFit == BoxFit.contain
                        ? "Fill Screen"
                        : "Fit to Screen",
                    icon: Icon(
                      _videoFit == BoxFit.contain
                          ? Icons.fullscreen_rounded
                          : Icons.fullscreen_exit_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: _toggleFit,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    final isMissingPlugin = _errorMessage.contains('MissingPluginException') ||
        _errorMessage.contains('No implementation found');
    final isNetwork = widget.videoUrl.trim().startsWith('http://') ||
        widget.videoUrl.trim().startsWith('https://');

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF334155)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isMissingPlugin ? const Color(0xFFFEF3C7) : const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isMissingPlugin ? const Color(0xFFFDE68A) : const Color(0xFFFECACA),
                ),
              ),
              child: Icon(
                isMissingPlugin ? Icons.restart_alt_rounded : Icons.play_disabled_rounded,
                color: isMissingPlugin ? const Color(0xFFD97706) : const Color(0xFFDC2626),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isMissingPlugin ? "Full App Restart Required" : "Unable to Stream Video",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isMissingPlugin
                  ? "The 'video_player' plugin was newly installed. In Flutter, newly added native plugins require stopping the running app and restarting it via 'flutter run' so native player libraries are compiled."
                  : "The video could not be streamed directly by the in-app player. You can launch it seamlessly in your device's native media player or browser.",
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Text(
                  _errorMessage,
                  style: GoogleFonts.firaCode(
                    color: const Color(0xFFE2E8F0),
                    fontSize: 11,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openExternalPlayer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(
                  "Open in System Player",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (isNetwork) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openBrowser,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF59E0B),
                    side: const BorderSide(color: Color(0xFFF59E0B)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.language_rounded, size: 18),
                  label: Text(
                    "Open in Browser",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _initializePlayer,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF475569)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(
                      "Retry",
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF94A3B8),
                      side: const BorderSide(color: Color(0xFF475569)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: Text(
                      "Go Back",
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
