$path = "lib\screens\client\construction_screen.dart"
$content = Get-Content $path -Raw
$fail = @()

function Apply-Edit {
    param($content, $pattern, $transform, $label, [ref]$failList)
    $rx = New-Object System.Text.RegularExpressions.Regex($pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $m = $rx.Matches($content)
    if ($m.Count -ne 1) {
        $failList.Value += "$label (found $($m.Count))"
        return $content
    }
    $original = $m[0].Value
    $newText = & $transform $original
    return $content.Substring(0, $m[0].Index) + $newText + $content.Substring($m[0].Index + $m[0].Length)
}

# Edit 1: add imports
$content = Apply-Edit $content "import 'package:video_player/video_player\.dart';" {
    param($o) $o + "`nimport 'package:video_thumbnail/video_thumbnail.dart';`nimport 'dart:typed_data';"
} "imports" ([ref]$fail)

# Edit 2: add thumbnail state + initState + loader after existing error fields
$content = Apply-Edit $content "bool\s+_videoError\s*=\s*false;\s*String\?\s*_videoErrorMessage;" {
    param($o)
@"
$o
  Uint8List? _thumbBytes;
  bool _thumbLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.update.isDirectVideo) _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    if (!mounted) return;
    setState(() => _thumbLoading = true);
    try {
      final bytes = await VideoThumbnail.thumbnailData(
        video: widget.update.youtubeUrl,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 400,
        quality: 50,
      );
      if (mounted) setState(() { _thumbBytes = bytes; _thumbLoading = false; });
    } catch (e) {
      debugPrint('Thumbnail generation error: ' + e.toString());
      if (mounted) setState(() => _thumbLoading = false);
    }
  }
"@
} "add_thumb_state" ([ref]$fail)

# Edit 3: swap black placeholder for thumbnail-backed Stack
$content = Apply-Edit $content "Container\(\s*height:\s*200,\s*color:\s*const Color\(0xFF0A0A0A\),\s*child:\s*Center\(child:\s*Column\(mainAxisSize:\s*MainAxisSize\.min,\s*children:\s*\[\s*Container\(\s*decoration:\s*BoxDecoration\(color:\s*AppTheme\.primaryMaroon,\s*shape:\s*BoxShape\.circle,\s*boxShadow:\s*\[BoxShadow\(color:\s*AppTheme\.primaryMaroon\.withOpacity\(0\.5\),\s*blurRadius:\s*20,\s*spreadRadius:\s*2\)\]\),\s*padding:\s*const EdgeInsets\.all\(18\),\s*child:\s*const Icon\(Icons\.play_arrow_rounded,\s*color:\s*Colors\.white,\s*size:\s*40\),\s*\),\s*const SizedBox\(height:\s*12\),\s*const Text\('Tap to play',\s*style:\s*TextStyle\(color:\s*Colors\.white70,\s*fontSize:\s*12\)\),\s*\]\)\),\s*\)," {
    param($o)
@"
SizedBox(
                      height: 200,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _thumbBytes != null
                            ? Image.memory(_thumbBytes!, fit: BoxFit.cover)
                            : Container(color: const Color(0xFF0A0A0A)),
                          Container(color: Colors.black.withOpacity(0.35)),
                          Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              decoration: BoxDecoration(color: AppTheme.primaryMaroon, shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: AppTheme.primaryMaroon.withOpacity(0.5), blurRadius: 20, spreadRadius: 2)]),
                              padding: const EdgeInsets.all(18),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                            ),
                            const SizedBox(height: 12),
                            const Text('Tap to play', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ])),
                        ],
                      ),
                    ),
"@
} "swap_placeholder_thumbnail" ([ref]$fail)

if ($fail.Count -gt 0) {
    Write-Host "FAILED steps: $($fail -join ', ')"
} else {
    Set-Content $path -Value $content -Encoding UTF8 -NoNewline
    Write-Host "All 3 edits applied successfully."
}
