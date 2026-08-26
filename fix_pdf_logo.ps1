$path = "lib\screens\client\payments_screen.dart"
$content = Get-Content $path -Raw
$fail = @()

# --- Edit 1: add rootBundle import ---
$oldImport = "import 'package:flutter/material.dart';"
$newImport = "import 'package:flutter/material.dart';`nimport 'package:flutter/services.dart' show rootBundle;"
if (([regex]::Matches($content, [regex]::Escape($oldImport))).Count -eq 1) {
    $content = $content -replace [regex]::Escape($oldImport), $newImport
} else { $fail += "import" }

# --- Edit 2: insert logo-mapping helper before _downloadSingleReceipt ---
$anchorFn = "  Future<void> _downloadSingleReceipt(BuildContext context, Map<String, dynamic> r) async {"
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

$anchorFn
"@
if (([regex]::Matches($content, [regex]::Escape($anchorFn))).Count -eq 1) {
    $content = $content -replace [regex]::Escape($anchorFn), $helper
} else { $fail += "helper_anchor" }

# --- Edit 3: load logo bytes inside _downloadSingleReceipt, right after booking is fetched ---
$oldBookingLine1 = @"
  Future<void> _downloadSingleReceipt(BuildContext context, Map<String, dynamic> r) async {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final booking = provider.selectedBooking;
"@
$newBookingLine1 = @"
  Future<void> _downloadSingleReceipt(BuildContext context, Map<String, dynamic> r) async {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final booking = provider.selectedBooking;
    final logoBytes1 = await rootBundle.load(_getProjectLogoAsset(booking?.projectName));
    final logoImage = pw.MemoryImage(logoBytes1.buffer.asUint8List());
"@
if (([regex]::Matches($content, [regex]::Escape($oldBookingLine1))).Count -eq 1) {
    $content = $content -replace [regex]::Escape($oldBookingLine1), $newBookingLine1
} else { $fail += "receipt_booking_line" }

# --- Edit 4: wrap single-receipt header with logo image ---
$oldHeader1 = @"
                pw.Text("A.S HIGHTECH LLP", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: brown)),
                pw.SizedBox(height: 2),
                pw.Text("Roswalt Zaiden, Andheri West, Mumbai - 400053", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
"@
$newHeader1 = @"
                pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
                  pw.Image(logoImage, width: 40, height: 40),
                  pw.SizedBox(width: 10),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text("A.S HIGHTECH LLP", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: brown)),
                    pw.SizedBox(height: 2),
                    pw.Text("Roswalt Zaiden, Andheri West, Mumbai - 400053", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ]),
                ]),
"@
if (([regex]::Matches($content, [regex]::Escape($oldHeader1))).Count -eq 1) {
    $content = $content -replace [regex]::Escape($oldHeader1), $newHeader1
} else { $fail += "receipt_header" }

# --- Edit 5: load logo bytes inside _generateLedgerPdf ---
$oldBookingLine2 = @"
  Future<void> _generateLedgerPdf(BuildContext context) async {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final allBookings = provider.allBookings;
    final booking = provider.selectedBooking;
    if (booking == null) return;
"@
$newBookingLine2 = @"
  Future<void> _generateLedgerPdf(BuildContext context) async {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final allBookings = provider.allBookings;
    final booking = provider.selectedBooking;
    if (booking == null) return;
    final logoBytes2 = await rootBundle.load(_getProjectLogoAsset(booking.projectName));
    final logoImage = pw.MemoryImage(logoBytes2.buffer.asUint8List());
"@
if (([regex]::Matches($content, [regex]::Escape($oldBookingLine2))).Count -eq 1) {
    $content = $content -replace [regex]::Escape($oldBookingLine2), $newBookingLine2
} else { $fail += "ledger_booking_line" }

# --- Edit 6: wrap ledger header with logo image ---
$oldHeader2 = @"
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('A.S HIGHTECH LLP', style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: brown)),
                      pw.SizedBox(height: 2),
                      pw.Text('Roswalt Zaiden, Andheri West, Mumbai - 400053', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      pw.Text('CIN: U45200MH2010PTC208765  .  RERA: P51700049358', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
"@
$newHeader2 = @"
                  pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Image(logoImage, width: 36, height: 36),
                    pw.SizedBox(width: 8),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('A.S HIGHTECH LLP', style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: brown)),
                        pw.SizedBox(height: 2),
                        pw.Text('Roswalt Zaiden, Andheri West, Mumbai - 400053', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                        pw.Text('CIN: U45200MH2010PTC208765  .  RERA: P51700049358', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      ],
                    ),
                  ]),
"@
if (([regex]::Matches($content, [regex]::Escape($oldHeader2))).Count -eq 1) {
    $content = $content -replace [regex]::Escape($oldHeader2), $newHeader2
} else { $fail += "ledger_header" }

if ($fail.Count -gt 0) {
    Write-Host "FAILED steps (0 or multiple matches, nothing written): $($fail -join ', ')"
} else {
    Set-Content $path -Value $content -Encoding UTF8 -NoNewline
    Write-Host "All 6 edits applied successfully."
}
