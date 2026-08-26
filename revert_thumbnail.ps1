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

# Edit 1: remove the two added imports
$content = Apply-Edit $content "import 'package:video_player/video_player\.dart';\s*import 'package:video_thumbnail/video_thumbnail\.dart';\s*import 'dart:typed_data';" {
    param($o) "import 'package:video_player/video_player.dart';"
} "remove_imports" ([ref]$fail)

# Edit 2: remove thumbnail state/initState/loader, restore original two fields only
$content = Apply-Edit $content "bool\s+_videoError\s*=\s*false;\s*String\?\s*_videoErrorMessage;\s*Uint8List\?\s*_thumbBytes;\s*bool\s+_thumbLoading\s*=\s*false;\s*@override\s*void initState\(\)\s*\{\s*super\.initState\(\);\s*if \(widget\.update\.isDirectVideo\) _loadThumbnail\(\);\s*\}\s*Future<void> _loadThumbnail\(\) async \{.*?\}\s*\}" {
    param($o) "bool _videoError = false;`n  String? _videoErrorMessage;"
} "remove_thumb_state" ([ref]$fail)

# Edit 3: revert placeholder Stack back to plain black Container
$content = Apply-Edit $content "SizedBox\(\s*height:\s*200,\s*child:\s*Stack\(\s*fit:\s*StackFit\.expand,\s*children:\s*\[\s*_thumbBytes\s*!=\s*null.*?\]\s*\),\s*\)," {
    param($o)
@"
Container(
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
"@
} "revert_placeholder" ([ref]$fail)

if ($fail.Count -gt 0) {
    Write-Host "FAILED steps: $($fail -join ', ')"
} else {
    Set-Content $path -Value $content -Encoding UTF8 -NoNewline
    Write-Host "Reverted successfully, crash fixes kept intact."
}
