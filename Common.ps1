$ErrorActionPreference = 'Stop'

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-GameRunning {
    return [bool](Get-Process -Name 'ProjectZomboid64' -ErrorAction SilentlyContinue)
}

function Assert-GameClosed {
    if (Test-GameRunning) {
        throw 'Feche o Project Zomboid antes de continuar e rode de novo.'
    }
}

function Get-UserProfile {
    if ($env:USERPROFILE) { return $env:USERPROFILE }
    return [Environment]::GetFolderPath('UserProfile')
}

function Get-LocalAppData {
    if ($env:LOCALAPPDATA) { return $env:LOCALAPPDATA }
    return [Environment]::GetFolderPath('LocalApplicationData')
}

function Get-TotalRamMB {
    try {
        $system = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        if ($system.TotalPhysicalMemory) { return [int]($system.TotalPhysicalMemory / 1MB) }
    } catch { }
    try {
        $system = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction Stop
        if ($system.TotalPhysicalMemory) { return [int]($system.TotalPhysicalMemory / 1MB) }
    } catch { }
    return 0
}

function Get-RecommendedHeapMB {
    $ram = Get-TotalRamMB
    if ($ram -le 0) { return 8192 }
    $half = [int]($ram / 2)
    $heap = [Math]::Min(8192, [Math]::Max(4096, $half))
    return [int]([Math]::Floor($heap / 512) * 512)
}

function Get-SteamLibraries {
    $libraries = New-Object System.Collections.Generic.List[string]

    foreach ($key in @('HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam', 'HKLM:\SOFTWARE\Valve\Steam')) {
        try {
            $item = Get-ItemProperty -Path $key -ErrorAction Stop
            if ($item.SteamPath) { $libraries.Add($item.SteamPath) }
            if ($item.InstallPath) { $libraries.Add($item.InstallPath) }
        } catch { }
    }

    $libraries.Add('C:\Program Files (x86)\Steam')
    $libraries.Add('C:\Program Files\Steam')

    $seen = @{}
    $result = New-Object System.Collections.Generic.List[string]
    foreach ($lib in $libraries) {
        if (-not $lib) { continue }
        $lib = $lib -replace '/', '\'
        if ($seen.ContainsKey($lib)) { continue }
        $seen[$lib] = $true
        if (Test-Path -LiteralPath (Join-Path $lib 'steamapps')) { $result.Add($lib) }
    }

    foreach ($lib in @($result)) {
        $vdf = Join-Path $lib 'steamapps\libraryfolders.vdf'
        if (-not (Test-Path -LiteralPath $vdf)) { continue }
        $text = Get-Content -LiteralPath $vdf -Raw
        foreach ($match in [regex]::Matches($text, '"path"\s+"([^"]+)"')) {
            $p = $match.Groups[1].Value -replace '\\\\', '\'
            if (-not $seen.ContainsKey($p) -and (Test-Path -LiteralPath (Join-Path $p 'steamapps'))) {
                $seen[$p] = $true
                $result.Add($p)
            }
        }
    }

    return $result
}

function Get-SteamPath {
    $libraries = Get-SteamLibraries
    if ($libraries.Count -eq 0) { throw 'Steam nao encontrado. Instala o Steam primeiro.' }
    return $libraries[0]
}

function Get-PZPath {
    foreach ($lib in Get-SteamLibraries) {
        $pz = Join-Path $lib 'steamapps\common\ProjectZomboid'
        if (Test-Path -LiteralPath (Join-Path $pz 'ProjectZomboid64.exe')) { return $pz }
    }
    throw 'Project Zomboid nao encontrado. Instala o jogo pela Steam primeiro.'
}

function Get-ZomboidDir {
    $profile = Get-UserProfile
    if (-not $profile) { throw 'Pasta do usuario nao encontrada.' }
    $dir = Join-Path $profile 'Zomboid'
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    return $dir
}

function Get-WorkshopRoot {
    $pz = Get-PZPath
    $lib = Split-Path (Split-Path (Split-Path $pz -Parent) -Parent) -Parent
    return Join-Path $lib 'steamapps\workshop\content\108600'
}

function Ensure-WorkshopRoot {
    $root = Get-WorkshopRoot
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    return $root
}

function Get-WorkshopCacheRoot {
    $root = Join-Path (Get-ZomboidDir) 'ViewpointPacks\_cache\108600'
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    return $root
}

function Test-ModInfoFolder {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    return [bool](Get-ChildItem -LiteralPath $Path -Recurse -Filter 'mod.info' -ErrorAction SilentlyContinue | Select-Object -First 1)
}

function Get-ModSourcePath {
    param(
        [string]$Workshop,
        [string]$Folder
    )
    $cache = Get-WorkshopCacheRoot
    $path = Join-Path (Join-Path (Join-Path $cache $Workshop) 'mods') $Folder
    if (Test-Path -LiteralPath $path) { return $path }

    $workshopRoot = Get-WorkshopRoot
    $path = Join-Path (Join-Path (Join-Path $workshopRoot $Workshop) 'mods') $Folder
    if (Test-Path -LiteralPath $path) { return $path }
    return $null
}

function Get-PZWorkshopManifest {
    param([string]$ScriptRoot)
    $path = Join-Path $ScriptRoot 'pack-manifest.json'
    if (-not (Test-Path -LiteralPath $path)) { throw "Manifest nao encontrado: $path" }
    return Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
}

$script:BaseProfilePacks = @(
    'Pack1_Core',
    'Pack2_Tactical',
    'Pack3_Atmosphere',
    'Pack4_Survival',
    'Pack5_QoL',
    'Pack6_Extras',
    'Pack7_Immersion'
)

$script:AdvancedProfilePacks = @(
    'Pack8_AdvancedFixes',
    'Pack9_AdvancedWorld',
    'Pack10_AdvancedRealism',
    'Pack11_AdvancedVehicles'
)

function Get-PackOrder {
    param(
        [ValidateSet('Medium', 'Advanced')]
        [string]$Profile = 'Medium'
    )

    $packs = @($script:BaseProfilePacks)
    if ($Profile -eq 'Advanced') {
        $packs += $script:AdvancedProfilePacks
    }
    return $packs
}

function Get-ProfilePath {
    $dir = Join-Path (Get-ZomboidDir) 'ViewpointPacks'
    return Join-Path $dir 'profile.txt'
}

function Get-SavedProfile {
    $path = Get-ProfilePath
    if (Test-Path -LiteralPath $path) {
        $value = (Get-Content -LiteralPath $path -Raw).Trim()
        if ($value -in @('Medium', 'Advanced')) { return $value }
    }
    return 'Medium'
}

function Set-SavedProfile {
    param(
        [ValidateSet('Medium', 'Advanced')]
        [string]$Profile
    )

    $path = Get-ProfilePath
    $dir = Split-Path $path -Parent
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Set-Content -LiteralPath $path -Value $Profile -Encoding ASCII
}
