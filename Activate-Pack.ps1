param(
    [ValidateSet('Medium', 'Advanced')]
    [string]$Profile,
    [switch]$Server
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

$data      = Get-PZWorkshopManifest -ScriptRoot $PSScriptRoot
if (-not $Profile) { $Profile = Get-SavedProfile }
$order     = Get-PackOrder -Profile $Profile
$modsDir   = Join-Path (Get-ZomboidDir) 'mods'
$default   = Join-Path $modsDir 'default.txt'
$backupDir = Join-Path (Get-ZomboidDir) 'backups'

New-Item -ItemType Directory -Path $modsDir -Force | Out-Null
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

$reset = Join-Path $modsDir 'reset-mods-42_00.txt'
if (-not (Test-Path -LiteralPath $reset)) {
    Set-Content -LiteralPath $reset -Value 'If this file does not exist, default.txt will be reset to empty (no mods active).' -Encoding ASCII
}

Assert-GameClosed

$missing = @()
foreach ($packName in $order) {
    foreach ($m in $data.$packName) {
        $path = Join-Path $modsDir $m.Folder
        if (-not (Test-ModInfoFolder -Path $path)) { $missing += $m.Folder }
    }
}
if ($missing.Count -gt 0) {
    throw "Mods faltando em Zomboid\mods: $($missing -join ', '). Rode Install.bat de novo."
}

if (Test-Path -LiteralPath $default) {
    Copy-Item -LiteralPath $default -Destination (Join-Path $backupDir 'default.txt.bak') -Force
}

$ids = New-Object System.Collections.Generic.List[string]
foreach ($packName in $order) {
    foreach ($m in $data.$packName) {
        if ($m.ServerOnly -and -not $Server) { continue }
        if (-not $ids.Contains($m.ModID)) { $ids.Add($m.ModID) }
    }
}

$lines = @('VERSION = 1,', '', 'mods', '{')
foreach ($id in $ids) { $lines += ('    mod = ' + $id + ',') }
$lines += '}'
$lines += ''
$lines += 'maps'
$lines += '{'
$lines += '}'
$lines += ''
Set-Content -LiteralPath $default -Value $lines -Encoding ASCII

Write-Host ""
Write-Host "Perfil ativado: $Profile" -ForegroundColor Green
Write-Host "Modulos de servidor: $([bool]$Server)" -ForegroundColor Cyan
Write-Host "Mods escritos no default.txt: $($ids.Count)" -ForegroundColor Cyan
Write-Host "Backup: $backupDir\default.txt.bak" -ForegroundColor DarkGray
