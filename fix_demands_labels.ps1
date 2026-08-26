$path = "lib\screens\client\payments_screen.dart"
$content = Get-Content $path -Raw

# 1. Clean up milestone name spacing in the Demands tab
$oldName = @"
                Text(d["name"] ?? "--", maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
"@
$newName = @"
                Text((d["name"] ?? "--").toString().replaceAll(RegExp(r"\s+"), " "), maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
"@
$content = $content -replace [regex]::Escape($oldName), $newName

# 2. Replace "Rs. 0" amount display with a "Not Raised" badge when nothing's due yet
$oldAmt = @"
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text("Rs. " + (d["netAmount"] ?? "0").toString(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
                const SizedBox(height: 4),
                Text("+ Tax: Rs. " + (d["tax"] ?? "0").toString(), style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                const SizedBox(height: 4),
                Icon(Icons.open_in_new, size: 14, color: AppTheme.primaryMaroon),
              ]),
"@
$newAmt = @"
              const SizedBox(width: 8),
              Builder(builder: (_) {
                final netVal = double.tryParse((d["netAmount"] ?? "0").toString()) ?? 0;
                final taxVal = double.tryParse((d["tax"] ?? "0").toString()) ?? 0;
                if (netVal <= 0 && taxVal <= 0) {
                  return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                      child: Text("Not Raised", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.orange[800])),
                    ),
                    const SizedBox(height: 4),
                    Icon(Icons.open_in_new, size: 14, color: AppTheme.primaryMaroon),
                  ]);
                }
                return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text("Rs. " + (d["netAmount"] ?? "0").toString(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
                  const SizedBox(height: 4),
                  Text("+ Tax: Rs. " + (d["tax"] ?? "0").toString(), style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                  const SizedBox(height: 4),
                  Icon(Icons.open_in_new, size: 14, color: AppTheme.primaryMaroon),
                ]);
              }),
"@
$content = $content -replace [regex]::Escape($oldAmt), $newAmt

Set-Content $path -Value $content -Encoding UTF8 -NoNewline
Write-Host "Done."
