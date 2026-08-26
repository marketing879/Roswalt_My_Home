$files = @("lib\screens\client\payments_screen.dart", "lib\screens\partner\cp_payouts_screen.dart")
foreach ($f in $files) {
    $content = Get-Content $f -Raw
    $before = ([regex]::Matches($content, [regex]::Escape("ROSWALT REALTY"))).Count
    $content = $content -replace [regex]::Escape("ROSWALT REALTY"), "A.S HIGHTECH LLP"
    Set-Content $f -Value $content -Encoding UTF8 -NoNewline
    Write-Host "$f -> replaced $before occurrence(s)"
}
