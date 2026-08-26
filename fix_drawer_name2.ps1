$path = "lib\screens\client\client_shell.dart"
$content = Get-Content $path -Raw

$pattern = "(?s)Text\(clientName, maxLines: 2, overflow: TextOverflow\.ellipsis,.*?fontWeight: FontWeight\.bold\)\),"
$rx = New-Object System.Text.RegularExpressions.Regex($pattern)
$m = $rx.Matches($content)

if ($m.Count -ne 1) {
    Write-Host "WARNING: found $($m.Count) matches, expected 1. Aborting."
} else {
    $original = $m[0].Value
    $modified = $original -replace "maxLines: 2", "maxLines: 1"
    $wrapped = "FittedBox(`n                            fit: BoxFit.scaleDown,`n                            alignment: Alignment.centerLeft,`n                            child: " + $modified + "`n                          ),"
    $content = $content.Substring(0, $m[0].Index) + $wrapped + $content.Substring($m[0].Index + $m[0].Length)
    Set-Content $path -Value $content -Encoding UTF8 -NoNewline
    Write-Host "Done. Original matched text was:"
    Write-Host $original
}
