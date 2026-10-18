param(
    [ValidateSet('Medium', 'Advanced')]
    [string]$Profile
)

$ErrorActionPreference = 'Continue'
. (Join-Path $PSScriptRoot 'Common.ps1')

$data     = Get-PZWorkshopManifest -ScriptRoot $PSScriptRoot
if (-not $Profile) { $Profile = Get-SavedProfile }
$order    = Get-PackOrder -Profile $Profile
$modsDir  = Join-Path (Get-ZomboidDir) 'mods'
$rows     = @()

foreach ($packName in $order) {
    foreach ($m in $data.$packName) {
        $active = Join-Path $modsDir $m.Folder
        $info = $null
        if (Test-Path -LiteralPath $active) {
            $info = Get-ChildItem -LiteralPath $active -Recurse -Filter 'mod.info' -ErrorAction SilentlyContinue | Select-Object -First 1
        }
        $rows += [pscustomobject]@{
            Pack      = $packName
            Folder    = $m.Folder
            ModID     = $m.ModID
            Workshop  = $m.Workshop
            Instalado = (Test-Path -LiteralPath $active)
            ModInfo   = [bool]$info
        }
    }
}

$rows | Format-Table -AutoSize

$default = Join-Path $modsDir 'default.txt'
$marker = Join-Path $modsDir '.pz-viewpoint-installed'
Write-Host ""
Write-Host "Perfil: $Profile" -ForegroundColor Cyan
Write-Host "Marcador de instalacao: $(Test-Path -LiteralPath $marker)" -ForegroundColor Cyan
Write-Host "default.txt:" -ForegroundColor Cyan
if (Test-Path -LiteralPath $default) { Get-Content -LiteralPath $default } else { Write-Host 'MISSING' -ForegroundColor Red }
