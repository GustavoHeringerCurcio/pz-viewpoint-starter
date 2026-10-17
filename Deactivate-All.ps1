param(
    [switch]$Purge
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

$data      = Get-PZWorkshopManifest -ScriptRoot $PSScriptRoot
$order     = Get-PackOrder
$modsDir   = Join-Path (Get-ZomboidDir) 'mods'
$default   = Join-Path $modsDir 'default.txt'
$backupDir = Join-Path (Get-ZomboidDir) 'backups'
$removedDir = Join-Path $backupDir 'mods-removed'
$stamp     = Get-Date -Format 'yyyyMMdd-HHmmss'

Assert-GameClosed
New-Item -ItemType Directory -Path $modsDir -Force | Out-Null
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
New-Item -ItemType Directory -Path $removedDir -Force | Out-Null

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

$index = 0
foreach ($folder in $managed) {
    $index++
    $path = Join-Path $modsDir $folder
    if (-not (Test-Path -LiteralPath $path)) { continue }

    if ($Purge) {
        Remove-Item -LiteralPath $path -Recurse -Force
        Write-Host "Apagado: $folder"
    } else {
        $destination = Join-Path $removedDir ("{0}-{1}" -f $folder, $stamp)
        if (Test-Path -LiteralPath $destination) { $destination = "$destination-$index" }
        Move-Item -LiteralPath $path -Destination $destination
        Write-Host "Movido para backup: $folder"
    }
}

Set-Content -LiteralPath $default -Value @('VERSION = 1,', '', 'mods', '{', '}', '', 'maps', '{', '}', '') -Encoding ASCII
$marker = Join-Path $modsDir '.pz-viewpoint-installed'
if (Test-Path -LiteralPath $marker) { Remove-Item -LiteralPath $marker -Force }

if ($Purge) {
    Write-Host "Mods removidos do PC." -ForegroundColor Yellow
} else {
    Write-Host "Mods desativados e movidos para: $removedDir" -ForegroundColor Yellow
    Write-Host "Para apagar de vez: powershell -ExecutionPolicy Bypass -File .\Deactivate-All.ps1 -Purge" -ForegroundColor DarkGray
}
