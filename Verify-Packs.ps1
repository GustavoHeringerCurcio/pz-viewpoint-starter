$ErrorActionPreference = 'Continue'
. (Join-Path $PSScriptRoot 'Common.ps1')

$data     = Get-PZWorkshopManifest -ScriptRoot $PSScriptRoot
$order    = Get-PackOrder
$modsDir  = Join-Path (Get-ZomboidDir) 'mods'
$rows     = @()

foreach ($packName in $order) {
    foreach ($m in $data.$packName) {
        $source = Get-ModSourcePath -Workshop $m.Workshop -Folder $m.Folder
        $active = Join-Path $modsDir $m.Folder
        $info = $null
        if ($source) {
            $info = Get-ChildItem -LiteralPath $source -Recurse -Filter 'mod.info' -ErrorAction SilentlyContinue | Select-Object -First 1
        }
        $rows += [pscustomobject]@{
            Pack       = $packName
            Folder     = $m.Folder
            ModID      = $m.ModID
            Workshop   = $m.Workshop
            Baixado    = [bool]$source
            ModInfo    = [bool]$info
            Ativo      = (Test-Path -LiteralPath $active)
        }
    }
}

$rows | Format-Table -AutoSize

$default = Join-Path $modsDir 'default.txt'
Write-Host ""
Write-Host "default.txt:" -ForegroundColor Cyan
if (Test-Path -LiteralPath $default) { Get-Content -LiteralPath $default } else { Write-Host 'MISSING' -ForegroundColor Red }
