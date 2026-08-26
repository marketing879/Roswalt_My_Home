import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const _bronze = Color(0xFF543813);
const _gold = Color(0xFFD4AF37);

const _allProjects = 'All Projects';

// Marketing collateral for each project lives in a shared Google Drive
// folder (no CMS/API backend for this exists) — the app just embeds the
// folder's public "embeddedfolderview" so CPs can browse/open files.
const Map<String, String> _driveFolderIds = {
  'Roswalt Zaiden': '1HO3Nuq-cIkFuqJw6MHVSlr4deXtUOnUd',
  'Roswalt Ryla': '167yLVHTyjXLX0gcsCMROGmTChiSN27xA',
  'Roswalt Raya': '1b-jmsnIrAfw-ulua2k5RWBLxsAeIxbl5',
  'Roswalt Zyon': '1v82NOvby7ARDwYs8so5QC-OZFk7OqNAX',
};

final _dropdownOptions = [_allProjects, ..._driveFolderIds.keys];

String _embedUrl(String folderId) => 'https://drive.google.com/embeddedfolderview?id=$folderId#grid';
String _driveUrl(String folderId) => 'https://drive.google.com/drive/folders/$folderId';

class CPMarketingCollateralScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  const CPMarketingCollateralScreen({super.key, this.onOpenDrawer});
  @override
  State<CPMarketingCollateralScreen> createState() => _CPMarketingCollateralScreenState();
}

class _CPMarketingCollateralScreenState extends State<CPMarketingCollateralScreen> {
  String _selectedProject = _allProjects;
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() { _loading = true; _error = null; });
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onWebResourceError: (error) {
          if (mounted) setState(() { _loading = false; _error = error.description; });
        },
      ));
  }

  void _selectProject(String project) {
    setState(() => _selectedProject = project);
    if (project == _allProjects) return;
    final folderId = _driveFolderIds[project];
    if (folderId == null) {
      setState(() { _loading = false; _error = 'No collateral folder configured for this project.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    _controller.loadRequest(Uri.parse(_embedUrl(folderId)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFFFF8F1);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final folderId = _driveFolderIds[_selectedProject];
    final showingAll = _selectedProject == _allProjects;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: _bronze,
        leading: IconButton(icon: const Icon(Icons.menu_rounded, color: Colors.white), onPressed: () => widget.onOpenDrawer?.call()),
        title: const Text('Marketing Collateral', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          if (!showingAll) ...[
            IconButton(
              icon: const Icon(Icons.open_in_new, color: Colors.white),
              tooltip: 'Open in Drive',
              onPressed: folderId == null ? null : () => launchUrl(Uri.parse(_driveUrl(folderId)), mode: LaunchMode.externalApplication),
            ),
            IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () => _selectProject(_selectedProject)),
          ],
        ],
      ),
      body: Column(children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF6B4A1E), _bronze, Color(0xFF3A2509)]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _gold.withOpacity(0.5), width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedProject,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _gold),
              dropdownColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF3A2509),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
              selectedItemBuilder: (context) => _dropdownOptions.map((p) => Row(children: [
                    const Icon(Icons.apartment_rounded, size: 16, color: _gold),
                    const SizedBox(width: 8),
                    Text(p, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  ])).toList(),
              items: _dropdownOptions.map((p) => DropdownMenuItem(value: p, child: Row(children: [
                    const Icon(Icons.apartment_outlined, size: 16, color: _gold),
                    const SizedBox(width: 8),
                    Text(p, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ]))).toList(),
              onChanged: (value) {
                if (value != null) _selectProject(value);
              },
            ),
          ),
        ),
        Expanded(
          child: showingAll
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: _driveFolderIds.keys.map((p) => GestureDetector(
                        onTap: () => _selectProject(p),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _gold.withOpacity(0.15))),
                          child: Row(children: [
                            Container(width: 46, height: 46,
                              decoration: BoxDecoration(color: _bronze.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.folder_outlined, color: _bronze, size: 22)),
                            const SizedBox(width: 14),
                            Expanded(child: Text(p, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1A0A00)))),
                            Icon(Icons.chevron_right, color: isDark ? Colors.white38 : Colors.grey[400]),
                          ]),
                        ),
                      )).toList(),
                )
              : Stack(children: [
                  WebViewWidget(controller: _controller),
                  if (_loading) const Center(child: CircularProgressIndicator(color: _bronze)),
                  if (_error != null)
                    Container(
                      color: bg,
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                          const SizedBox(height: 12),
                          Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red[400], fontSize: 14)),
                          const SizedBox(height: 12),
                          TextButton(onPressed: () => _selectProject(_selectedProject), child: const Text('Retry')),
                        ]),
                      ),
                    ),
                ]),
        ),
      ]),
    );
  }
}
