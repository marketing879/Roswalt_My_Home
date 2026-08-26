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
    $original = $m[0].Value
    $newText = & $transform $original
    return $content.Substring(0, $m[0].Index) + $newText + $content.Substring($m[0].Index + $m[0].Length)
}

# Edit 1: import
$content = Apply-Edit $content "import 'package:flutter/material\.dart';" { param($o) $o + "`nimport 'package:flutter/services.dart' show rootBundle;" } "import" ([ref]$fail)

# Edit 2: helper before _downloadSingleReceipt
$helper = @"
  String _getProjectLogoAsset(String? projectName) {
    if (projectName == null) return 'logos/ryla.png';
    final p = projectName.toLowerCase();
    if (p.contains('zaiden')) return 'logos/zaiden.png';
    if (p.contains('raya')) return 'logos/raya.png';
    if (p.contains('zeya')) return 'logos/zeya.png';
    if (p.contains('ryla')) return 'logos/ryla.png';
    return 'logos/ryla.png';
  }

"@
$content = Apply-Edit $content "Future<void>\s+_downloadSingleReceipt\(BuildContext context, Map<String, dynamic> r\)\s+async\s*\{" { param($o) $helper + $o } "helper_anchor" ([ref]$fail)

# Edit 3: load logo bytes in _downloadSingleReceipt
$content = Apply-Edit $content "Future<void>\s+_downloadSingleReceipt\(BuildContext context, Map<String, dynamic> r\)\s+async\s*\{\s*final provider = Provider\.of<BookingProvider>\(context, listen: false\);\s*final booking = provider\.selectedBooking;" {
    param($o) $o + "`n    final logoBytes1 = await rootBundle.load(_getProjectLogoAsset(booking?.projectName));`n    final logoImage = pw.MemoryImage(logoBytes1.buffer.asUint8List());"
} "receipt_booking_line" ([ref]$fail)

# Edit 4: wrap single-receipt header with logo image
$content = Apply-Edit $content 'pw\.Text\("A\.S HIGHTECH LLP",\s*style:\s*pw\.TextStyle\(fontSize:\s*18,\s*fontWeight:\s*pw\.FontWeight\.bold,\s*color:\s*brown\)\),\s*pw\.SizedBox\(height:\s*2\),\s*pw\.Text\("Roswalt Zaiden, Andheri West, Mumbai - 400053",\s*style:\s*pw\.TextStyle\(fontSize:\s*8,\s*color:\s*PdfColors\.grey600\)\),' {
    param($o)
@"
pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
                  pw.Image(logoImage, width: 40, height: 40),
                  pw.SizedBox(width: 10),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    $o
                  ]),
                ]),
"@
} "receipt_header" ([ref]$fail)

# Edit 5: load logo bytes in _generateLedgerPdf
$content = Apply-Edit $content "Future<void>\s+_generateLedgerPdf\(BuildContext context\)\s+async\s*\{\s*final provider = Provider\.of<BookingProvider>\(context, listen: false\);\s*final allBookings = provider\.allBookings;\s*final booking = provider\.selectedBooking;\s*if\s*\(booking == null\) return;" {
    param($o) $o + "`n    final logoBytes2 = await rootBundle.load(_getProjectLogoAsset(booking.projectName));`n    final logoImage = pw.MemoryImage(logoBytes2.buffer.asUint8List());"
} "ledger_booking_line" ([ref]$fail)

# Edit 6: wrap ledger header with logo image
$content = Apply-Edit $content "pw\.Column\(\s*crossAxisAlignment:\s*pw\.CrossAxisAlignment\.start,\s*children:\s*\[\s*pw\.Text\('A\.S HIGHTECH LLP',\s*style:\s*pw\.TextStyle\(fontSize:\s*17,.*?RERA: P51700049358',\s*style:\s*pw\.TextStyle\(fontSize:\s*8,\s*color:\s*PdfColors\.grey600\)\),\s*\],\s*\)," {
    param($o)
@"
pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Image(logoImage, width: 36, height: 36),
                    pw.SizedBox(width: 8),
                    $o
                  ]),
"@
} "ledger_header" ([ref]$fail)

if ($fail.Count -gt 0) {
    Write-Host "FAILED steps: $($fail -join ', ')"
} else {
    Set-Content $path -Value $content -Encoding UTF8 -NoNewline
    Write-Host "All 6 edits applied successfully."
}
