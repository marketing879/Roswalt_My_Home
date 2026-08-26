$path = "lib\screens\client\payments_screen.dart"
$content = Get-Content $path -Raw

$newFunc = @"
  Widget _buildDemands(bool isDark) {
    final demands = List<Map<String, dynamic>>.from(Provider.of<BookingProvider>(context, listen: false).demands);
    demands.sort((a, b) {
      final da = DateTime.tryParse((a["date"] ?? "").toString()) ?? DateTime(2100);
      final db = DateTime.tryParse((b["date"] ?? "").toString()) ?? DateTime(2100);
      return da.compareTo(db);
    });
    if (demands.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.description_outlined, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text("No demands available", style: TextStyle(color: Colors.grey[500])),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: demands.length,
      itemBuilder: (context, index) {
        final d = demands[index];
        return GestureDetector(
          onTap: () => _openDemandLink(context, d),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryMaroon.withOpacity(0.1)),
                child: Icon(Icons.attach_file, size: 18, color: AppTheme.primaryMaroon),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Demand " + (index + 1).toString(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
                const SizedBox(height: 4),
                Text("Due: " + _formatDate(d["date"]), style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey[500])),
              ])),
              Icon(Icons.open_in_new, size: 16, color: AppTheme.primaryMaroon),
            ]),
          ),
        );
      },
    );
  }

"@

$startMarker = [regex]::Escape("  Widget _buildDemands(bool isDark) {")
$endMarker = [regex]::Escape("  Widget _buildMilestone(Map<String, dynamic> milestone, int index, bool isDark) {")
$pattern = "(?s)$startMarker.*?(?=$endMarker)"

$matches = [regex]::Matches($content, $pattern)
if ($matches.Count -ne 1) {
    Write-Host "WARNING: found $($matches.Count) matches, expected 1. Aborting to avoid corrupting the file."
} else {
    $content = [regex]::Replace($content, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $newFunc })
    Set-Content $path -Value $content -Encoding UTF8 -NoNewline
    Write-Host "Done."
}
