$path = "lib\screens\client\client_shell.dart"
$content = Get-Content $path -Raw

$old = @"
Text(clientName, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFFF0F0F0), fontSize: 15, fontWeight: FontWeight.bold)),
"@

$new = @"
FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(clientName, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFFF0F0F0), fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
"@

$matches = ([regex]::Matches($content, [regex]::Escape($old))).Count
if ($matches -ne 1) {
    Write-Host "WARNING: found $matches matches, expected 1. Aborting."
} else {
    $content = $content -replace [regex]::Escape($old), $new
    Set-Content $path -Value $content -Encoding UTF8 -NoNewline
    Write-Host "Done."
}
