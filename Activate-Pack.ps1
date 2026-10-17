param(
    [switch]$Server,
    [switch]$NoCopy
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

$data      = Get-PZWorkshopManifest -ScriptRoot $PSScriptRoot
$order     = Get-PackOrder
$modsDir   = Join-Path (Get-ZomboidDir) 'mods'
$default   = Join-Path $modsDir 'default.txt'
$backupDir = Join-Path (Get-ZomboidDir) 'backups'

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

$selected = $order

if (Test-Path -LiteralPath $default) {
    Copy-Item -LiteralPath $default -Destination (Join-Path $backupDir 'default.txt.bak') -Force
}

if (-not $NoCopy) {
    Assert-GameClosed
    $selectedFolders = @()
    foreach ($packName in $selected) {
        foreach ($m in $data.$packName) { $selectedFolders += $m.Folder }
    }
    $selectedFolders = $selectedFolders | Select-Object -Unique
    $totalMods = 0
    foreach ($packName in $selected) { $totalMods += $data.$packName.Count }
    $modIndex = 0

    foreach ($folder in $managed) {
        if ($selectedFolders -contains $folder) { continue }
        $p = Join-Path $modsDir $folder
        if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Recurse -Force }
    }

    foreach ($packName in $selected) {
        Write-Host "Ativando $packName ..." -ForegroundColor Cyan
        foreach ($m in $data.$packName) {
            $modIndex++
            Write-Host ("  [{0}/{1}] {2}" -f $modIndex, $totalMods, $m.Folder) -ForegroundColor DarkGray
            $src = Get-ModSourcePath -Workshop $m.Workshop -Folder $m.Folder
            $dst = Join-Path $modsDir $m.Folder
            if (-not $src) {
                if (Test-Path -LiteralPath $dst) {
                    Write-Warning "Fonte de $($m.Folder) ausente; mantendo a copia local ja ativa."
                    continue
                }
                throw "Mod nao encontrado: $($m.Folder) (Workshop $($m.Workshop)). Rode Install.ps1 primeiro."
            }
            if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Recurse -Force }
            robocopy $src $dst /E /MT:8 /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
            if ($LASTEXITCODE -ge 8) { throw "Falha ao copiar $($m.Folder) (robocopy $LASTEXITCODE)." }
        }
    }
}

$ids = New-Object System.Collections.Generic.List[string]
foreach ($packName in $selected) {
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
Write-Host "Ativado: $($selected -join ', ')" -ForegroundColor Green
Write-Host "Modulos de servidor: $([bool]$Server)" -ForegroundColor Cyan
Write-Host "Mods escritos no default.txt: $($ids.Count)" -ForegroundColor Cyan
Write-Host "Backup: $backupDir\default.txt.bak" -ForegroundColor DarkGray
