$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

$data      = Get-PZWorkshopManifest -ScriptRoot $PSScriptRoot
$order     = Get-PackOrder
$modsDir   = Join-Path (Get-ZomboidDir) 'mods'
$default   = Join-Path $modsDir 'default.txt'
$backupDir = Join-Path (Get-ZomboidDir) 'backups'

Assert-GameClosed
New-Item -ItemType Directory -Path $modsDir -Force | Out-Null
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

$reset = Join-Path $modsDir 'reset-mods-42_00.txt'
if (-not (Test-Path -LiteralPath $reset)) {
    Set-Content -LiteralPath $reset -Value 'If this file does not exist, default.txt will be reset to empty (no mods active).' -Encoding ASCII
}

$managed = @()
foreach ($p in $order) {
    foreach ($m in $data.$p) { $managed += $m.Folder }
}
$managed = $managed | Select-Object -Unique

if (Test-Path -LiteralPath $default) {
    Copy-Item -LiteralPath $default -Destination (Join-Path $backupDir 'default.txt.bak') -Force
}

foreach ($folder in $managed) {
    $p = Join-Path $modsDir $folder
    if (Test-Path -LiteralPath $p) {
        Remove-Item -LiteralPath $p -Recurse -Force
        Write-Host "Removido: $folder"
    }
}

Set-Content -LiteralPath $default -Value @('VERSION = 1,', '', 'mods', '{', '}', '', 'maps', '{', '}', '') -Encoding ASCII
Write-Host "Todos os mods do pack foram desativados." -ForegroundColor Yellow
