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

# Edit 1: wrap _initVideo body in try/catch to catch synchronous Uri.parse failures
$content = Apply-Edit $content "void\s+_initVideo\(\)\s*\{\s*_vpc\s*=\s*VideoPlayerController\.networkUrl\(Uri\.parse\(widget\.update\.youtubeUrl\)\);\s*_vpc!\.initialize\(\)\.then\(\(_\)\s*\{\s*if\s*\(mounted\)\s*setState\(\(\)\s*\{\s*_videoReady\s*=\s*true;\s*_vpc!\.play\(\);\s*_playing\s*=\s*true;\s*\}\);\s*\}\)\.catchError\(\(e\)\s*\{\s*debugPrint\('Video init error: '\s*\+\s*e\.toString\(\)\);\s*if\s*\(mounted\)\s*setState\(\(\)\s*\{\s*_videoError\s*=\s*true;\s*_videoErrorMessage\s*=\s*e\.toString\(\);\s*\}\);\s*\}\);\s*\}" {
    param($o)
@"
void _initVideo() {
    try {
      _vpc = VideoPlayerController.networkUrl(Uri.parse(widget.update.youtubeUrl));
      _vpc!.initialize().then((_) {
        if (mounted) setState(() { _videoReady = true; _vpc!.play(); _playing = true; });
      }).catchError((e) {
        debugPrint('Video init error: ' + e.toString());
        if (mounted) setState(() { _videoError = true; _videoErrorMessage = e.toString(); });
      });
    } catch (e) {
      debugPrint('Video init sync error: ' + e.toString());
      if (mounted) setState(() { _videoError = true; _videoErrorMessage = e.toString(); });
    }
  }
"@
} "wrap_initvideo_trycatch" ([ref]$fail)

# Edit 2: guard against double-tap re-init
$content = Apply-Edit $content "onTap:\s*\(\)\s*\{\s*setState\(\(\)\s*=>\s*_playing\s*=\s*true\);\s*_initVideo\(\);\s*\}," {
    param($o)
    "onTap: () {`n                    if (_vpc != null || _videoError) return;`n                    setState(() => _playing = true);`n                    _initVideo();`n                  },"
} "guard_double_tap" ([ref]$fail)

# Edit 3: add stable key to each _UpdateCard
$content = Apply-Edit $content "return\s+_UpdateCard\(\s*update:\s*u,\s*isDark:\s*isDark,\s*ago:\s*_ago\(u\.createdAt\),\s*onOpenYouTube:\s*_openYouTube,\s*\);" {
    param($o)
@"
return _UpdateCard(
                            key: ValueKey(u.id),
                            update: u,
                            isDark: isDark,
                            ago: _ago(u.createdAt),
                            onOpenYouTube: _openYouTube,
                          );
"@
} "add_stable_key" ([ref]$fail)

if ($fail.Count -gt 0) {
    Write-Host "FAILED steps: $($fail -join ', ')"
} else {
    Set-Content $path -Value $content -Encoding UTF8 -NoNewline
    Write-Host "All 3 edits applied successfully."
}
