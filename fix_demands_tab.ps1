$path = "lib\screens\client\payments_screen.dart"
$content = Get-Content $path -Raw

# 1. Bump tab count 4 -> 5
$content = $content -replace [regex]::Escape("TabController(length: 4, vsync: this)"), "TabController(length: 5, vsync: this)"

# 2. Add Demands tab after Overview
$content = $content -replace [regex]::Escape("Tab(text: 'Overview'),"), "Tab(text: 'Overview'),`n                Tab(text: 'Demands'),"

# 3. Wire it into TabBarView
$content = $content -replace [regex]::Escape("_buildOverview(isDark),"), "_buildOverview(isDark),`n              _buildDemands(isDark),"

# 4. Remove tap action from Overview milestone card
$content = $content -replace [regex]::Escape("onTap: () => _openDemandLink(context, milestone),"), "onTap: null, // moved to Demands tab"

# 5. Insert the new _buildDemands function before _buildMilestone
$demandsFunc = @"
  Widget _buildDemands(bool isDark) {
    final demands = Provider.of<BookingProvider>(context, listen: false).demands;
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
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryMaroon.withOpacity(0.1)),
                child: Icon(Icons.attach_file, size: 18, color: AppTheme.primaryMaroon),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d["name"] ?? "--", maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
                const SizedBox(height: 4),
                Text("Demand No: " + (d["demandNo"] ?? "--").toString(), style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                const SizedBox(height: 2),
                Text("Due: " + _formatDate(d["date"]), style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey[500])),
              ])),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text("Rs. " + (d["netAmount"] ?? "0").toString(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
                const SizedBox(height: 4),
                Text("+ Tax: Rs. " + (d["tax"] ?? "0").toString(), style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                const SizedBox(height: 4),
                Icon(Icons.open_in_new, size: 14, color: AppTheme.primaryMaroon),
              ]),
            ]),
          ),
        );
      },
    );
  }

"@

$anchor = "  Widget _buildMilestone(Map<String, dynamic> milestone, int index, bool isDark) {"
$content = $content -replace [regex]::Escape($anchor), ($demandsFunc + $anchor)

Set-Content $path -Value $content -Encoding UTF8 -NoNewline
Write-Host "Done."
