import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

const String _trainingApiBase = 'https://api.roswaltsmartcue.com';

bool _isDirectVideoUrl(String url) {
  final u = url.toLowerCase();
  return u.contains('.mp4') || u.contains('.mov') || u.contains('.webm') ||
      u.contains('api/attachments') || u.contains('roswaltsmartcue.com/api');
}

class CPTrainingScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  const CPTrainingScreen({super.key, this.onOpenDrawer});
  @override
  State<CPTrainingScreen> createState() => _CPTrainingScreenState();
}

class _CPTrainingScreenState extends State<CPTrainingScreen> {
  static const _bronze = Color(0xFF543813);
  static const _gold = Color(0xFFD4AF37);

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'label': 'All Videos'},
    {'id': 'product', 'label': 'Product Training'},
    {'id': 'sales', 'label': 'Sales Techniques'},
    {'id': 'legal', 'label': 'Legal & Compliance'},
    {'id': 'softskills', 'label': 'Soft Skills'},
  ];

  String _selectedCategory = 'all';
  List<Map<String, dynamic>> _videos = [];
  bool _loading = true;
  String? _fetchError;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    try {
      final res = await http.get(Uri.parse('$_trainingApiBase/api/training-videos'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _videos = List<Map<String, dynamic>>.from(data['data'] ?? []);
          _loading = false;
        });
      } else {
        setState(() { _loading = false; _fetchError = 'Failed to load videos'; });
      }
    } catch (e) {
      setState(() { _loading = false; _fetchError = e.toString(); });
    }
  }

  List<Map<String, dynamic>> get _filteredVideos {
    if (_selectedCategory == 'all') return _videos;
    return _videos.where((v) => v['category'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : AppTheme.creamBg;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF543813), Color(0xFF8B6914)],
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onOpenDrawer,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.menu, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Training Videos', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${_videos.length} Videos available', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _fetchVideos,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.refresh, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Category filter
            Container(
              height: 44,
              color: isDark ? const Color(0xFF1A0A00) : const Color(0xFF3A2509),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                itemCount: _categories.length,
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final isActive = _selectedCategory == cat['id'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat['id'] as String),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? _gold : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(cat['label'] as String,
                          style: TextStyle(color: isActive ? Colors.black : Colors.white70, fontSize: 12, fontWeight: isActive ? FontWeight.w700 : FontWeight.w400)),
                    ),
                  );
                },
              ),
            ),

            // Videos list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _bronze))
                  : _fetchError != null
                      ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                          const SizedBox(height: 12),
                          Text('Failed to load videos', style: TextStyle(color: Colors.red[400], fontSize: 14)),
                          const SizedBox(height: 8),
                          TextButton(onPressed: _fetchVideos, child: const Text('Retry')),
                        ]))
                      : _filteredVideos.isEmpty
                          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.video_library_outlined, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(_videos.isEmpty ? 'No videos uploaded yet' : 'No videos in this category',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                            ]))
                          : RefreshIndicator(
                              onRefresh: _fetchVideos,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredVideos.length,
                                itemBuilder: (_, i) => _buildVideoCard(_filteredVideos[i], cardBg, isDark),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video, Color cardBg, bool isDark) {
    final thumbnail = video['thumbnailUrl'] as String? ?? '';
    final isLocalAsset = thumbnail.startsWith('assets/');
    final isNew = video['isNew'] == true;
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: thumbnail.isNotEmpty && isLocalAsset
                      ? Image.asset(thumbnail, height: 160, width: double.infinity, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _thumbnailFallback())
                      : thumbnail.isNotEmpty
                          ? Image.network(thumbnail, height: 160, width: double.infinity, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _thumbnailFallback())
                          : _thumbnailFallback(),
                ),
                // Play button
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: const Center(child: Icon(Icons.play_circle_filled, color: Colors.white, size: 56)),
                  ),
                ),
                // Duration
                if (video['duration'] != null)
                  Positioned(bottom: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(6)),
                      child: Text(video['duration'] as String, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
                // New badge
                if (isNew)
                  Positioned(top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(6)),
                      child: const Text('NEW', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(video['title'] as String? ?? 'Untitled',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
                  const SizedBox(height: 6),
                  Text(video['description'] as String? ?? '',
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.4)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
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
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
    // Increment view count
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
        child: Column(
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2))),
            // Video area
            Container(
              width: double.infinity,
              color: Colors.black,
              child: (video['videoUrl'] as String?)?.isNotEmpty == true
                  ? _TrainingVideoPlayer(videoUrl: video['videoUrl'] as String)
                  : const SizedBox(
                      height: 220,
                      child: Center(
                        child: Text('Video unavailable', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                  ],
                ),
              ),
            ),
          ],
        ),
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
  static const _gold = Color(0xFFD4AF37);
  static const _bronze = Color(0xFF543813);

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
