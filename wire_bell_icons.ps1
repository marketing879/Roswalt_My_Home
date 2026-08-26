$targets = @(
  @{ path = "lib\screens\client\documents_screen.dart"; import = "import ''notifications_screen.dart'';" },
  @{ path = "lib\screens\client\assistance_screen.dart"; import = "import ''notifications_screen.dart'';" },
  @{ path = "lib\screens\partner\partner_shell.dart"; import = "import ''../client/notifications_screen.dart'';" },
  @{ path = "lib\screens\tenant\tenant_assistance_screen.dart"; import = "import ''../client/notifications_screen.dart'';" },
  @{ path = "lib\screens\tenant\tenant_compensation_screen.dart"; import = "import ''../client/notifications_screen.dart'';" },
  @{ path = "lib\screens\tenant\tenant_documents_screen.dart"; import = "import ''../client/notifications_screen.dart'';" },
  @{ path = "lib\screens\tenant\tenant_home_screen.dart"; import = "import ''../client/notifications_screen.dart'';" }
)

$pattern = "(IconButton\(\s*icon:\s*const Icon\(Icons\.notifications_outlined,[^)]*\))\s*,\s*onPressed:\s*\(\)\s*\{\}\)"

foreach ($t in $targets) {
    $path = $t.path
    $content = Get-Content $path -Raw
    $rx = New-Object System.Text.RegularExpressions.Regex($pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $matches = $rx.Matches($content)
    if ($matches.Count -lt 1) {
        Write-Host "$path -> NO MATCH FOUND, skipped"
        continue
    }
    $newContent = $rx.Replace($content, { param($m) $m.Groups[1].Value + ', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))' + ')' })
    $newContent = $t.import + "`n" + $newContent
    Set-Content $path -Value $newContent -Encoding UTF8 -NoNewline
    Write-Host "$path -> replaced $($matches.Count) occurrence(s), import added"
}
