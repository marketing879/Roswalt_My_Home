$path = "lib\screens\client\construction_screen.dart"
$content = Get-Content $path -Raw
$fail = @()

# --- Edit 1: fix _UpdateCard constructor to accept a key ---
$old1 = "const _UpdateCard({required this.update, required this.isDark, required this.ago, required this.onOpenYouTube});"
$new1 = "const _UpdateCard({super.key, required this.update, required this.isDark, required this.ago, required this.onOpenYouTube});"
$count1 = ([regex]::Matches($content, [regex]::Escape($old1))).Count
if ($count1 -ne 1) {
    $fail += "constructor_key (found $count1)"
} else {
    $content = $content -replace [regex]::Escape($old1), $new1
}

# --- Edit 2: rebuild the entire broken ternary block between two unique, unambiguous anchors ---
$startAnchor = "child: u.isDirectVideo"
$endAnchor = "Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start,"

$startCount = ([regex]::Matches($content, [regex]::Escape($startAnchor))).Count
$endCount = ([regex]::Matches($content, [regex]::Escape($endAnchor))).Count

if ($startCount -ne 1 -or $endCount -ne 1) {
    $fail += "block_anchors (start=$startCount, end=$endCount)"
} else {
    $startIdx = $content.IndexOf($startAnchor)
    $endIdx = $content.IndexOf($endAnchor)
    if ($endIdx -le $startIdx) {
        $fail += "block_order_invalid"
    } else {
        $replacement = @"
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
                  onTap: () {
                    if (_vpc != null || _videoError) return;
                    setState(() => _playing = true);
                    _initVideo();
                  },
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
        $endAnchor
"@
        $content = $content.Substring(0, $startIdx) + $replacement + $content.Substring($endIdx + $endAnchor.Length)
    }
}

if ($fail.Count -gt 0) {
    Write-Host "FAILED steps: $($fail -join ', ')"
} else {
    Set-Content $path -Value $content -Encoding UTF8 -NoNewline
    Write-Host "Both edits applied successfully."
}
