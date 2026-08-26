$path = "lib\screens\client\payments_screen.dart"
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
    $inner = $m[0].Groups[1].Value
    $newText = & $transform $inner
    return $content.Substring(0, $m[0].Index) + $newText + $content.Substring($m[0].Index + $m[0].Length)
}

# Edit A: single receipt header -> stacked, bigger logo
$content = Apply-Edit $content "pw\.Row\(crossAxisAlignment:\s*pw\.CrossAxisAlignment\.center,\s*children:\s*\[\s*pw\.Image\(logoImage,\s*width:\s*40,\s*height:\s*40\),\s*pw\.SizedBox\(width:\s*10\),\s*pw\.Column\(crossAxisAlignment:\s*pw\.CrossAxisAlignment\.start,\s*children:\s*\[\s*(.*?)\s*\]\),\s*\]\)," {
    param($inner)
@"
pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Image(logoImage, width: 70, height: 70),
                  pw.SizedBox(height: 6),
                  $inner
                ]),
"@
} "receipt_header_restack" ([ref]$fail)

# Edit B: ledger header -> stacked, bigger logo
$content = Apply-Edit $content "pw\.Row\(crossAxisAlignment:\s*pw\.CrossAxisAlignment\.start,\s*children:\s*\[\s*pw\.Image\(logoImage,\s*width:\s*36,\s*height:\s*36\),\s*pw\.SizedBox\(width:\s*8\),\s*(pw\.Column\(\s*crossAxisAlignment:\s*pw\.CrossAxisAlignment\.start,\s*children:\s*\[.*?\],\s*\)),\s*\]\)," {
    param($inner)
@"
pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Image(logoImage, width: 60, height: 60),
                    pw.SizedBox(height: 6),
                    $inner,
                  ]),
"@
} "ledger_header_restack" ([ref]$fail)

if ($fail.Count -gt 0) {
    Write-Host "FAILED steps: $($fail -join ', ')"
} else {
    Set-Content $path -Value $content -Encoding UTF8 -NoNewline
    Write-Host "Both edits applied successfully."
}
