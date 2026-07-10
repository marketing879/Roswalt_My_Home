import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class ConstructionUpdate {
  final String id;
  final String project;
  final String title;
  final String description;
  final String youtubeUrl;
  final String phase;
  final DateTime createdAt;

  ConstructionUpdate({required this.id, required this.project, required this.title, required this.description, required this.youtubeUrl, required this.phase, required this.createdAt});

  factory ConstructionUpdate.fromJson(Map<String, dynamic> j) => ConstructionUpdate(
    id: j['_id'] ?? '', project: j['project'] ?? '', title: j['title'] ?? '',
    description: j['description'] ?? '', youtubeUrl: j['youtubeUrl'] ?? '',
    phase: j['phase'] ?? 'General',
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
  );

  bool get isDirectVideo {
    final u = youtubeUrl.toLowerCase();
    return u.contains('.mp4') || u.contains('.mov') || u.contains('.webm') ||
           u.contains('api/attachments') || u.contains('roswaltsmartcue.com/api');
  }

  String get thumbnailUrl {
    if (isDirectVideo) return '';
    final patterns = [
      RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]+)'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]+)'),
      RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]+)'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(youtubeUrl);
      if (m != null) return 'https://img.youtube.com/vi/${m.group(1)}/hqdefault.jpg';
    }
    return '';
  }
}

class ConstructionScreen extends StatefulWidget {
  const ConstructionScreen({super.key});
  @override
  State<ConstructionScreen> createState() => _ConstructionScreenState();
}

class _ConstructionScreenState extends State<ConstructionScreen> {
  List<ConstructionUpdate> _updates = [];
  bool _loading = true;
  String? _error;
  String _selectedProject = 'All';
  static const _api = 'https://api.roswaltsmartcue.com/api/construction-updates';
  final _projects = ['All','Roswalt Zaiden','Roswalt Ryla','Roswalt Raya','Roswalt Zeya','Roswalt Zyon'];

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(Uri.parse(_api)).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        setState(() { _updates = list.map((e) => ConstructionUpdate.fromJson(e)).toList(); _loading = false; });
      } else { setState(() { _error = 'Server error'; _loading = false; }); }
    } catch (_) { setState(() { _error = 'Could not connect.'; _loading = false; }); }
  }

  List<ConstructionUpdate> get _filtered =>
    _selectedProject == 'All' ? _updates : _updates.where((u) => u.project == _selectedProject).toList();

  Future<void> _openYouTube(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    if (d.inDays > 7) return '${dt.day} ${m[dt.month-1]} ${dt.year}';
    if (d.inDays > 0) return '${d.inDays}d ago';
    if (d.inHours > 0) return '${d.inHours}h ago';
    return 'Recently';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppTheme.creamBg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppTheme.primaryMaroon, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Construction Updates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppTheme.primaryMaroon)),
          Text('Live progress from site', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[500])),
        ]),
        actions: [IconButton(icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white54 : Colors.grey[600]), onPressed: _fetch)],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryMaroon))
        : _error != null
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Colors.grey[500])),
              const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: _fetch, icon: const Icon(Icons.refresh, size: 16), label: const Text('Retry'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryMaroon, foregroundColor: Colors.white)),
            ]))
          : Column(children: [
              SizedBox(height: 52, child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: _projects.length,
                itemBuilder: (_, i) {
                  final p = _projects[i];
                  final active = _selectedProject == p;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedProject = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? AppTheme.primaryMaroon : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: active ? AppTheme.primaryMaroon : (isDark ? Colors.white12 : Colors.black12)),
                      ),
                      child: Text(p == 'All' ? 'All Projects' : p.replaceAll('Roswalt ', ''),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: active ? Colors.white : (isDark ? Colors.white70 : Colors.grey[700]))),
                    ),
                  );
                },
              )),
              Expanded(child: _filtered.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.construction_outlined, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 14),
                    Text('No updates yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : Colors.grey[500])),
                  ]))
                : RefreshIndicator(
                    color: AppTheme.primaryMaroon,
                    onRefresh: _fetch,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final u = _filtered[i];
                        return _UpdateCard(
                          update: u,
                          isDark: isDark,
                          ago: _ago(u.createdAt),
                          onOpenYouTube: _openYouTube,
                        );
                      },
                    ),
                  )),
            ]),
    );
  }
}

class _UpdateCard extends StatefulWidget {
  final ConstructionUpdate update;
  final bool isDark;
  final String ago;
  final Future<void> Function(String) onOpenYouTube;
  const _UpdateCard({required this.update, required this.isDark, required this.ago, required this.onOpenYouTube});
  @override
  State<_UpdateCard> createState() => _UpdateCardState();
}

class _UpdateCardState extends State<_UpdateCard> {
  VideoPlayerController? _vpc;
  bool _videoReady = false;
  bool _playing = false;

  void _initVideo() {
    _vpc = VideoPlayerController.networkUrl(Uri.parse(widget.update.youtubeUrl))
      ..initialize().then((_) {
        if (mounted) setState(() { _videoReady = true; _vpc!.play(); _playing = true; });
      });
  }

  @override
  void dispose() { _vpc?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final u = widget.update;
    final isDark = widget.isDark;
    final thumb = u.thumbnailUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
        boxShadow: AppTheme.clayCardShadow(isDark: isDark),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: u.isDirectVideo
            ? _playing && _videoReady && _vpc != null
              ? GestureDetector(
                  onTap: () => setState(() { _vpc!.value.isPlaying ? _vpc!.pause() : _vpc!.play(); }),
                  child: AspectRatio(
                    aspectRatio: _vpc!.value.aspectRatio,
                    child: Stack(children: [
                      VideoPlayer(_vpc!),
                      if (!_vpc!.value.isPlaying)
                        Center(child: Container(
                          decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          padding: const EdgeInsets.all(14),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                        )),
                    ]),
                  ),
                )
              : GestureDetector(
                  onTap: () { setState(() => _playing = true); _initVideo(); },
                  child: Container(
                    height: 200, color: const Color(0xFF0A0A0A),
                    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        decoration: BoxDecoration(color: AppTheme.primaryMaroon, shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppTheme.primaryMaroon.withOpacity(0.5), blurRadius: 20, spreadRadius: 2)]),
                        padding: const EdgeInsets.all(18),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 12),
                      const Text('Tap to play', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ])),
                  ),
                )
            : GestureDetector(
                onTap: () => widget.onOpenYouTube(u.youtubeUrl),
                child: Stack(children: [
                  thumb.isNotEmpty
                    ? Image.network(thumb, width: double.infinity, height: 200, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(height: 200, color: const Color(0xFF1A0A0A),
                          child: Center(child: Icon(Icons.construction_rounded, size: 48, color: AppTheme.primaryMaroon.withOpacity(0.5)))))
                    : Container(height: 200, color: const Color(0xFF1A0A0A),
                        child: Center(child: Icon(Icons.construction_rounded, size: 48, color: AppTheme.primaryMaroon.withOpacity(0.5)))),
                  Positioned.fill(child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.55)]),
                    ),
                  )),
                  Positioned.fill(child: Center(child: Container(
                    decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 20, spreadRadius: 2)]),
                    padding: const EdgeInsets.all(16),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 38),
                  ))),
                  Positioned(bottom: 10, right: 10, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: const [
                      Icon(Icons.smart_display_rounded, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text('Watch on YouTube', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    ]),
                  )),
                  Positioned(top: 10, left: 10, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.primaryMaroon.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
                    child: Text(u.phase, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                  )),
                ]),
              ),
        ),
        Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppTheme.goldAccent.withOpacity(0.12), borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.goldAccent.withOpacity(0.3))),
              child: Text(u.project.replaceAll('Roswalt ', ''),
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.goldAccent)),
            ),
            const Spacer(),
            Text(widget.ago, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          ]),
          const SizedBox(height: 8),
          Text(u.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.3,
            color: isDark ? Colors.white : const Color(0xFF1A1610))),
          if (u.description.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(u.description, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, height: 1.5, color: isDark ? Colors.white54 : const Color(0xFF7A6E5C))),
          ],
        ])),
      ]),
    );
  }
}
