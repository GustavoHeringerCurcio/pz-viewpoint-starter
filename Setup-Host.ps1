param(
    [ValidateSet('Medium', 'Advanced')]
    [string]$Profile,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

$data  = Get-PZWorkshopManifest -ScriptRoot $PSScriptRoot
if (-not $Profile) { $Profile = Get-SavedProfile }
$order = Get-PackOrder -Profile $Profile
$ids   = New-Object System.Collections.Generic.List[string]

foreach ($packName in $order) {
    foreach ($m in $data.$packName) {
        if (-not $ids.Contains($m.ModID)) { $ids.Add($m.ModID) }
    }
}

$modsLine = 'Mods=' + ($ids -join ';')
Write-Host "Perfil: $Profile" -ForegroundColor Cyan
Write-Host "Mods para o host: $($ids.Count)" -ForegroundColor Cyan
Write-Host $modsLine

if (-not $Apply) {
    Write-Host ""
    Write-Host "Preview apenas. Rode Setup-Host.bat para aplicar." -ForegroundColor Yellow
    exit 0
}

Assert-GameClosed

$serverDir = Join-Path (Get-ZomboidDir) 'Server'
$ini = Join-Path $serverDir 'servertest.ini'
if (-not (Test-Path -LiteralPath $ini)) {
    throw 'servertest.ini nao encontrado. Abra o jogo e crie/configure um host primeiro.'
}

$backupDir = Join-Path (Get-ZomboidDir) 'backups'
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = Join-Path $backupDir "servertest-before-host-$stamp.ini"
Copy-Item -LiteralPath $ini -Destination $backup -Force

$text = [IO.File]::ReadAllText($ini)
if ($text -match '(?m)^Mods=') {
    $text = $text -replace '(?m)^Mods=.*$', $modsLine
} else {
    $text = $text.TrimEnd() + "`r`n$modsLine`r`n"
}
[IO.File]::WriteAllText($ini, $text)

Write-Host ""
Write-Host "Host configurado com $($ids.Count) mods." -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor DarkGray
Write-Host "Todos os jogadores precisam do mesmo pack e da mesma versao." -ForegroundColor Yellow
Write-Host "Teste o host; se algum mod client-only falhar, restaure o backup." -ForegroundColor Yellow
