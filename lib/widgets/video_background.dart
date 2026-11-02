import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Looping, muted, cover-fit background video — same pattern used on
/// login/splash. Falls back to [fallback] (a plain gradient/color) if the
/// asset isn't bundled yet, so screens can reference an asset path ahead of
/// the real file being dropped in without crashing.
class VideoBackground extends StatefulWidget {
  final String assetPath;
  final Widget fallback;
  final Widget? overlay;
  const VideoBackground({super.key, required this.assetPath, required this.fallback, this.overlay});

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.asset(widget.assetPath);
      await c.initialize();
      c.setLooping(true);
      c.setVolume(0);
      c.play();
      if (!mounted) return;
      setState(() => _controller = c);
    } catch (e) {
      debugPrint('VideoBackground (${widget.assetPath}) unavailable: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _controller != null && _controller!.value.isInitialized;
    return Stack(fit: StackFit.expand, children: [
      if (ready)
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(width: _controller!.value.size.width, height: _controller!.value.size.height, child: VideoPlayer(_controller!)),
        )
      else
        widget.fallback,
      if (!ready && !_failed) const SizedBox.shrink(),
      if (widget.overlay != null) widget.overlay!,
    ]);
  }
}
