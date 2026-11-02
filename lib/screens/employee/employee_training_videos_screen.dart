import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

const _bronze = Color(0xFF543813);
const _gold = Color(0xFFD4AF37);
const _cream = Color(0xFFFFF8F1);

const String _trainingApiBase = 'https://api.roswaltsmartcue.com';

bool _isDirectVideoUrl(String url) {
  final u = url.toLowerCase();
  return u.contains('.mp4') || u.contains('.mov') || u.contains('.webm') ||
      u.contains('api/attachments') || u.contains('roswaltsmartcue.com/api');
}

// Employee-side Training Videos. Uploads happen entirely on SmartCue's own
// side (Aziz Khan's login there) — this screen only ever reads and plays
// them, same as the CP-facing screen (cp_training_screen.dart).
//
// SmartCue's /api/training-videos now has an `audience` field ("cp" |
// "employee", set at upload time) and honors ?audience=employee server-side,
// so this feed is genuinely separated from the CP screen's — see
// SMARTCUE_AUDIENCE_FIELD_REQUEST.md for the full shape.
class EmployeeTrainingVideosScreen extends StatefulWidget {
  const EmployeeTrainingVideosScreen({super.key});
  @override
  State<EmployeeTrainingVideosScreen> createState() => _EmployeeTrainingVideosScreenState();
}

class _EmployeeTrainingVideosScreenState extends State<EmployeeTrainingVideosScreen> {
  List<Map<String, dynamic>> _videos = [];
  bool _loading = true;
  String? _fetchError;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    setState(() { _loading = true; _fetchError = null; });
    try {
      final res = await http.get(Uri.parse('$_trainingApiBase/api/training-videos?audience=employee'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        var videos = List<Map<String, dynamic>>.from(data['data'] ?? []);
        setState(() { _videos = videos; _loading = false; });
      } else {
        setState(() { _loading = false; _fetchError = 'Failed to load videos'; });
      }
    } catch (e) {
      setState(() { _loading = false; _fetchError = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : _cream;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: _bronze,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Training Videos', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _fetchVideos),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _bronze))
          : _fetchError != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 12),
                  Text('Failed to load videos', style: TextStyle(color: Colors.red[400], fontSize: 14)),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _fetchVideos, child: const Text('Retry')),
                ]))
              : _videos.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.video_library_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text('No videos uploaded yet', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _fetchVideos,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _videos.length,
                        itemBuilder: (_, i) => _buildVideoCard(_videos[i], cardBg, isDark),
                      ),
                    ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video, Color cardBg, bool isDark) {
    final thumbnail = video['thumbnailUrl'] as String? ?? '';
    final views = video['views'] ?? 0;

    return GestureDetector(
      onTap: () => _showVideoPlayer(video),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: thumbnail.isNotEmpty
                  ? Image.network(thumbnail, height: 160, width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _thumbnailFallback())
                  : _thumbnailFallback(),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), color: Colors.black.withOpacity(0.3)),
                child: const Center(child: Icon(Icons.play_circle_filled, color: Colors.white, size: 56)),
              ),
            ),
            if (video['duration'] != null)
              Positioned(bottom: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(6)),
                  child: Text(video['duration'] as String, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(video['title'] as String? ?? 'Untitled',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
              const SizedBox(height: 6),
              Text(video['description'] as String? ?? '',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.4)),
              const SizedBox(height: 10),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: _bronze.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.person_outline, size: 14, color: _bronze),
                ),
                const SizedBox(width: 6),
                Text(video['instructor'] as String? ?? '', style: const TextStyle(fontSize: 12, color: _bronze, fontWeight: FontWeight.w500)),
                const Spacer(),
                const Icon(Icons.visibility_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('$views views', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _thumbnailFallback() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF543813), Color(0xFF8B6914)]),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Center(child: Icon(Icons.play_circle_outline, color: Colors.white54, size: 48)),
    );
  }

  void _showVideoPlayer(Map<String, dynamic> video) {
    final id = video['_id'];
    if (id != null) {
      http.patch(Uri.parse('$_trainingApiBase/api/training-videos/$id/view'));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        color: Colors.black,
        child: Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2))),
          Container(
            width: double.infinity,
            color: Colors.black,
            child: (video['videoUrl'] as String?)?.isNotEmpty == true
                ? _TrainingVideoPlayer(videoUrl: video['videoUrl'] as String)
                : const SizedBox(height: 220, child: Center(
                    child: Text('Video unavailable', style: TextStyle(color: Colors.white54, fontSize: 12)))),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(video['title'] as String? ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.access_time, color: Colors.white54, size: 14),
                  const SizedBox(width: 4),
                  Text(video['duration'] as String? ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(width: 16),
                  const Icon(Icons.person_outline, color: Colors.white54, size: 14),
                  const SizedBox(width: 4),
                  Text(video['instructor'] as String? ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ]),
                const SizedBox(height: 16),
                Text(video['description'] as String? ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _TrainingVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const _TrainingVideoPlayer({required this.videoUrl});
  @override
  State<_TrainingVideoPlayer> createState() => _TrainingVideoPlayerState();
}

class _TrainingVideoPlayerState extends State<_TrainingVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initializing = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    if (_isDirectVideoUrl(widget.videoUrl)) _initPlayer();
  }

  void _initPlayer() {
    setState(() { _initializing = true; _error = false; });
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    controller.initialize().then((_) {
      if (!mounted) { controller.dispose(); return; }
      setState(() { _controller = controller; _initializing = false; });
      controller.play();
    }).catchError((e) {
      debugPrint('Training video init error: $e');
      controller.dispose();
      if (!mounted) return;
      setState(() { _initializing = false; _error = true; });
    });
  }

  Future<void> _openExternally() async {
    final uri = Uri.parse(widget.videoUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $uri');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDirectVideoUrl(widget.videoUrl)) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.ondemand_video_rounded, color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            const Text('This video opens in your browser', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openExternally,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open Video'),
              style: ElevatedButton.styleFrom(backgroundColor: _bronze, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
          ]),
        ),
      );
    }
    if (_error) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            const SizedBox(height: 8),
            const Text('Could not play this video', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 12),
            TextButton(onPressed: _initPlayer, child: const Text('Retry', style: TextStyle(color: _gold))),
          ]),
        ),
      );
    }
    if (_initializing || _controller == null) {
      return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator(color: _gold)));
    }
    final c = _controller!;
    return AspectRatio(
      aspectRatio: c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
      child: GestureDetector(
        onTap: () => setState(() => c.value.isPlaying ? c.pause() : c.play()),
        child: ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: c,
          builder: (context, value, _) => Stack(alignment: Alignment.center, children: [
            VideoPlayer(c),
            if (!value.isPlaying)
              Container(
                decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                padding: const EdgeInsets.all(14),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
              ),
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: VideoProgressIndicator(c, allowScrubbing: true,
                  padding: EdgeInsets.zero,
                  colors: const VideoProgressColors(playedColor: _gold, bufferedColor: Colors.white24, backgroundColor: Colors.white10)),
            ),
          ]),
        ),
      ),
    );
  }
}
