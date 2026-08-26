$fixes = @(
  @{ path = "lib\screens\client\documents_screen.dart"; bad = "import ''notifications_screen.dart'';"; good = "import 'notifications_screen.dart';" },
  @{ path = "lib\screens\partner\partner_shell.dart"; bad = "import ''../client/notifications_screen.dart'';"; good = "import '../client/notifications_screen.dart';" },
  @{ path = "lib\screens\tenant\tenant_assistance_screen.dart"; bad = "import ''../client/notifications_screen.dart'';"; good = "import '../client/notifications_screen.dart';" },
  @{ path = "lib\screens\tenant\tenant_compensation_screen.dart"; bad = "import ''../client/notifications_screen.dart'';"; good = "import '../client/notifications_screen.dart';" },
  @{ path = "lib\screens\tenant\tenant_documents_screen.dart"; bad = "import ''../client/notifications_screen.dart'';"; good = "import '../client/notifications_screen.dart';" },
  @{ path = "lib\screens\tenant\tenant_home_screen.dart"; bad = "import ''../client/notifications_screen.dart'';"; good = "import '../client/notifications_screen.dart';" }
)

foreach ($f in $fixes) {
    $content = Get-Content $f.path -Raw
    $count = ([regex]::Matches($content, [regex]::Escape($f.bad))).Count
    if ($count -ne 1) {
        Write-Host "$($f.path) -> WARNING found $count matches, expected 1. Skipped."
        continue
    }
    $content = $content -replace [regex]::Escape($f.bad), $f.good
    Set-Content $f.path -Value $content -Encoding UTF8 -NoNewline
    Write-Host "$($f.path) -> fixed."
}
