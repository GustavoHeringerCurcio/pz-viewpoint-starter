param(
    [switch]$CheckOnly,
    [switch]$SkipMods,
    [switch]$SkipZombieBuddy,
    [switch]$NoActivate,
    [switch]$ForceRedownload,
    [switch]$UseSteamCmd
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

$ArchiveUrl = 'https://github.com/GustavoHeringerCurcio/pz-viewpoint-starter/releases/download/mods-v1/PZ-Viewpoint-Mods.tar'
$ArchiveFileName = 'PZ-Viewpoint-Mods.tar'

function Write-Step([string]$Text) {
    Write-Host ""
    Write-Host "== $Text ==" -ForegroundColor Cyan
}

function Backup-GameFiles([string]$PZ, [string]$Zomboid) {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $dst = Join-Path $Zomboid "backups\setup-$stamp"
    New-Item -ItemType Directory -Path $dst -Force | Out-Null
    foreach ($name in @('ProjectZomboid64.json','ProjectZomboid64.bat','options.ini')) {
        $src = Join-Path $PZ $name
        if (Test-Path -LiteralPath $src) { Copy-Item -LiteralPath $src -Destination (Join-Path $dst $name) -Force }
    }
    $default = Join-Path $Zomboid 'mods\default.txt'
    if (Test-Path -LiteralPath $default) { Copy-Item -LiteralPath $default -Destination (Join-Path $dst 'default.txt') -Force }
    Write-Host "Backup: $dst" -ForegroundColor DarkGray
}

function Get-SteamCmd {
    $tools = Join-Path (Get-LocalAppData) 'PZViewpoint\steamcmd'
    $exe = Join-Path $tools 'steamcmd.exe'
    if (Test-Path -LiteralPath $exe) { return $exe }

    Write-Host "Baixando SteamCMD..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $tools -Force | Out-Null
    $zip = Join-Path $tools 'steamcmd.zip'
    Invoke-WebRequest -Uri 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip' -OutFile $zip -UseBasicParsing
    Expand-Archive -LiteralPath $zip -DestinationPath $tools -Force
    if (-not (Test-Path -LiteralPath $exe)) { throw 'Nao foi possivel instalar o SteamCMD.' }
    return $exe
}

function Get-RemoteFile {
    param([string]$Uri, [string]$OutFile)
    if (Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue) {
        try {
            Start-BitsTransfer -Source $Uri -Destination $OutFile -ErrorAction Stop
            return
        } catch { }
    }
    Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing
}

function Test-ModInfoFolder {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    return [bool](Get-ChildItem -LiteralPath $Path -Recurse -Filter 'mod.info' -ErrorAction SilentlyContinue | Select-Object -First 1)
}

function Install-FromArchive {
    param([string]$ManifestPath)

    $archiveDir = Join-Path (Get-LocalAppData) 'PZViewpoint\archive'
    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
    $tarPath = Join-Path $archiveDir $ArchiveFileName
    $shaPath = "$tarPath.sha256"

    Write-Host "Baixando verificacao do pacote..." -ForegroundColor Yellow
    Get-RemoteFile -Uri "$ArchiveUrl.sha256" -OutFile $shaPath
    $expected = ((Get-Content -LiteralPath $shaPath -Raw).Trim() -split '\s+')[0].ToLower()

    $needDownload = $ForceRedownload -or -not (Test-Path -LiteralPath $tarPath)
    if (-not $needDownload) {
        $current = (Get-FileHash -LiteralPath $tarPath -Algorithm SHA256).Hash.ToLower()
        if ($current -ne $expected) { $needDownload = $true }
    }

    if ($needDownload) {
        if (Test-Path -LiteralPath $tarPath) { Remove-Item -LiteralPath $tarPath -Force }
        Write-Host "Baixando pacote de mods (~1.1 GB) do GitHub..." -ForegroundColor Yellow
        Get-RemoteFile -Uri $ArchiveUrl -OutFile $tarPath
    }

    $actual = (Get-FileHash -LiteralPath $tarPath -Algorithm SHA256).Hash.ToLower()
    if ($actual -ne $expected) { throw 'Hash do pacote de mods nao confere.' }

    Write-Host "Extraindo pacote..." -ForegroundColor Yellow
    $cacheParent = Split-Path (Get-WorkshopCacheRoot) -Parent
    if (-not (Get-Command tar.exe -ErrorAction SilentlyContinue)) {
        throw 'tar.exe nao encontrado. Atualiza o Windows 10/11.'
    }
    & tar.exe -x -f $tarPath -C $cacheParent
    if ($LASTEXITCODE -ne 0) { throw "Falha ao extrair o pacote (tar $LASTEXITCODE)." }

    $data = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    $cacheRoot = Get-WorkshopCacheRoot
    $missing = @()
    foreach ($p in Get-PackOrder) {
        foreach ($m in $data.$p) {
            $folder = Join-Path (Join-Path (Join-Path $cacheRoot $m.Workshop) 'mods') $m.Folder
            if (-not (Test-ModInfoFolder -Path $folder)) { $missing += $m.Folder }
        }
    }
    if ($missing.Count -gt 0) {
        throw "Pacote incompleto: $($missing -join ', ')"
    }
    Write-Host "Pacote de mods pronto." -ForegroundColor Green
}

function Test-CachedWorkshopItem {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $mods = Join-Path $Path 'mods'
    if (-not (Test-Path -LiteralPath $mods)) { return $false }
    $info = Get-ChildItem -LiteralPath $mods -Recurse -Filter 'mod.info' -ErrorAction SilentlyContinue | Select-Object -First 1
    return [bool]$info
}

function Install-WorkshopItems {
    param(
        [string]$ManifestPath,
        [string]$SteamCmd,
        [switch]$Force
    )

    $data = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    $ids = @()
    foreach ($p in Get-PackOrder) {
        foreach ($m in $data.$p) {
            if ($ids -notcontains $m.Workshop) { $ids += $m.Workshop }
        }
    }

    $cacheRoot = Get-WorkshopCacheRoot
    $gameRoot = Get-WorkshopRoot
    $srcRoot = Join-Path (Split-Path $SteamCmd -Parent) 'steamapps\workshop\content\108600'
    $missing = @()

    foreach ($id in $ids) {
        $cache = Join-Path $cacheRoot $id
        if (-not $Force -and (Test-CachedWorkshopItem -Path $cache)) { continue }

        $source = $null
        foreach ($candidate in @((Join-Path $srcRoot $id), (Join-Path $gameRoot $id))) {
            if (Test-Path -LiteralPath $candidate) { $source = $candidate; break }
        }
        if (-not $source) { $missing += $id; continue }

        if (Test-Path -LiteralPath $cache) { Remove-Item -LiteralPath $cache -Recurse -Force }
        robocopy $source $cache /E /MT:8 /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
        if ($LASTEXITCODE -ge 8 -or -not (Test-CachedWorkshopItem -Path $cache)) { $missing += $id }
    }

    if ($missing.Count -gt 0) {
        Write-Host "Baixando $($missing.Count) itens do Workshop. Isso pode demorar." -ForegroundColor Yellow
        $cmdArgs = @('+login','anonymous')
        foreach ($id in $missing) { $cmdArgs += @('+workshop_download_item','108600',$id) }
        $cmdArgs += '+quit'
        & $SteamCmd @cmdArgs

        $failed = @()
        foreach ($id in $missing) {
            $src = Join-Path $srcRoot $id
            $cache = Join-Path $cacheRoot $id
            if (-not (Test-Path -LiteralPath $src)) { $failed += $id; continue }
            if (Test-Path -LiteralPath $cache) { Remove-Item -LiteralPath $cache -Recurse -Force }
            robocopy $src $cache /E /MT:8 /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
            if ($LASTEXITCODE -ge 8 -or -not (Test-CachedWorkshopItem -Path $cache)) { $failed += $id }
        }

        if ($failed.Count -gt 0) {
            Write-Warning "Itens que falharam: $($failed -join ', ')"
            Write-Warning "Rode Install.bat de novo. Se continuar, assine esses itens na Steam."
        } else {
            Write-Host "Workshop concluido." -ForegroundColor Green
        }
    } else {
        Write-Host "Todos os $($ids.Count) itens Workshop ja estao no cache local." -ForegroundColor Green
    }
}

function Test-ZombieBuddyInstalled {
    param([string]$PZ)
    $hasJar = Test-Path -LiteralPath (Join-Path $PZ 'ZombieBuddy.jar')
    $hasDll = Test-Path -LiteralPath (Join-Path $PZ 'zbNative.dll')
    $json = Join-Path $PZ 'ProjectZomboid64.json'
    $hasAgent = $false
    if (Test-Path -LiteralPath $json) {
        $hasAgent = (Get-Content -LiteralPath $json -Raw) -match 'agentlib:zbNative'
    }
    return ($hasJar -and $hasDll -and $hasAgent)
}

function Install-ZombieBuddy {
    param([string]$PZ)

    if (Test-ZombieBuddyInstalled -PZ $PZ) {
        Write-Host "ZombieBuddy ja esta instalado." -ForegroundColor Green
        return
    }

    Write-Host "Baixando o instalador do ZombieBuddy..." -ForegroundColor Yellow
    $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/zed-0xff/ZombieBuddy/releases/latest' -Headers @{ 'User-Agent' = 'pz-viewpoint-starter' }
    $asset = $release.assets | Where-Object { $_.name -like 'ZombieBuddyInstaller_*.exe' } | Select-Object -First 1
    if (-not $asset) { throw 'Instalador do ZombieBuddy nao encontrado no GitHub.' }

    $installer = Join-Path ([IO.Path]::GetTempPath()) $asset.name
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $installer -UseBasicParsing
    if ($asset.digest) {
        $expected = $asset.digest -replace '^sha256:', ''
        $actual = (Get-FileHash -LiteralPath $installer -Algorithm SHA256).Hash.ToLower()
        if ($actual -ne $expected.ToLower()) { throw 'Hash do instalador do ZombieBuddy nao confere.' }
    }

    Write-Host ""
    Write-Host "O instalador do ZombieBuddy vai abrir." -ForegroundColor Cyan
    Write-Host "No terminal dele:" -ForegroundColor Cyan
    Write-Host "  1) escreve 1 e Enter  (Install ZombieBuddy)" -ForegroundColor White
    Write-Host "  2) escreve 1 e Enter  (Both)" -ForegroundColor White
    Write-Host "  3) se pedir confirmacao, escreve y e Enter" -ForegroundColor White
    Write-Host ""
    Start-Process -FilePath $installer -WorkingDirectory (Split-Path $installer -Parent) -Wait

    if (-not (Test-ZombieBuddyInstalled -PZ $PZ)) {
        throw 'ZombieBuddy nao foi instalado. Rode Install.bat de novo e escolha 1 e depois 1.'
    }
    Write-Host "ZombieBuddy instalado." -ForegroundColor Green
}

function Set-GameConfig {
    param([string]$PZ, [string]$Zomboid)

    $heap = Get-RecommendedHeapMB
    $xmx = "-Xmx${heap}m"
    Write-Host "Memoria do jogo: ${heap} MB" -ForegroundColor DarkGray

    $jsonPath = Join-Path $PZ 'ProjectZomboid64.json'
    if (Test-Path -LiteralPath $jsonPath) {
        $json = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
        $vm = @($json.vmArgs)
        if (-not ($vm -match '^-Xmx')) { $vm += $xmx }
        else { $vm = $vm | ForEach-Object { if ($_ -match '^-Xmx') { $xmx } else { $_ } } }
        if (-not ($vm -match 'agentlib:zbNative')) { $vm = @('-agentlib:zbNative') + $vm }
        $json.vmArgs = $vm
        $jsonText = $json | ConvertTo-Json -Depth 10
        [IO.File]::WriteAllText($jsonPath, $jsonText, (New-Object System.Text.UTF8Encoding($false)))
    }

    $batPath = Join-Path $PZ 'ProjectZomboid64.bat'
    if (Test-Path -LiteralPath $batPath) {
        $bat = Get-Content -LiteralPath $batPath -Raw
        if ($bat -notmatch 'agentlib:zbNative') {
            $bat = $bat -replace 'SET _JAVA_OPTIONS=.*', 'SET _JAVA_OPTIONS=-agentlib:zbNative'
        }
        $bat = $bat -replace '-Xmx\d+[mMgG]?', $xmx
        Set-Content -LiteralPath $batPath -Value $bat -Encoding ASCII -NoNewline
    }

    $options = Join-Path $Zomboid 'options.ini'
    if (Test-Path -LiteralPath $options) {
        $ini = Get-Content -LiteralPath $options -Raw
        if ($ini -match 'textureCompression=') { $ini = $ini -replace 'textureCompression=false', 'textureCompression=true' }
        else { $ini = $ini.TrimEnd() + "`r`ntextureCompression=true`r`n" }
        Set-Content -LiteralPath $options -Value $ini -Encoding ASCII -NoNewline
    }
}

try {
    $pz = Get-PZPath
    $zomboid = Get-ZomboidDir
    $workshop = Get-WorkshopRoot

    Write-Step 'Project Zomboid'
    Write-Host "Jogo: $pz"
    Write-Host "Dados: $zomboid"
    Write-Host "Workshop: $workshop"
    $ram = Get-TotalRamMB
    $heap = Get-RecommendedHeapMB
    Write-Host "RAM detectada: $ram MB; heap do jogo: ${heap} MB"
    if ($ram -gt 0 -and $ram -lt 8192) {
        Write-Warning 'Pouca RAM detectada. 16 GB e o recomendado para este pack.'
    }

    $versionFile = Join-Path $zomboid 'version.txt'
    if (Test-Path -LiteralPath $versionFile) {
        $version = (Get-Content -LiteralPath $versionFile -TotalCount 1).Trim()
        if ($version -and $version -notmatch '^42\.21') {
            Write-Warning "Versao do jogo detectada: $version. Este pack foi feito para 42.21."
        }
    }

    $data = Get-PZWorkshopManifest -ScriptRoot $PSScriptRoot
    $allIds = @()
    foreach ($p in Get-PackOrder) { foreach ($m in $data.$p) { if ($allIds -notcontains $m.Workshop) { $allIds += $m.Workshop } } }

    if ($CheckOnly) {
        Write-Host ""
        Write-Host "CheckOnly: $($allIds.Count) itens no manifesto."
        Write-Host "ZombieBuddy instalado: $(Test-ZombieBuddyInstalled -PZ $pz)"
        $archiveCache = Join-Path (Join-Path (Get-LocalAppData) 'PZViewpoint\archive') $ArchiveFileName
        Write-Host "Pacote GitHub em cache: $(Test-Path -LiteralPath $archiveCache)"
        $default = Join-Path $zomboid 'mods\default.txt'
        if (Test-Path -LiteralPath $default) {
            Write-Host "Mods no default.txt: $((Select-String -LiteralPath $default -Pattern '^\s*mod\s*=').Count)"
        } else {
            Write-Host "default.txt ainda nao existe."
        }
        exit 0
    }

    if (-not (Test-IsAdmin)) { throw 'Abre o Install.bat e aceita o pedido de administrador.' }
    Assert-GameClosed
    $workshop = Ensure-WorkshopRoot

    Backup-GameFiles -PZ $pz -Zomboid $zomboid

    if (-not $SkipMods) {
        if ($UseSteamCmd) {
            Write-Step 'Baixando mods do Workshop'
            $steamcmd = Get-SteamCmd
            Install-WorkshopItems -ManifestPath (Join-Path $PSScriptRoot 'pack-manifest.json') -SteamCmd $steamcmd -Force:$ForceRedownload
        } else {
            Write-Step 'Baixando pacote do GitHub'
            try {
                Install-FromArchive -ManifestPath (Join-Path $PSScriptRoot 'pack-manifest.json')
            } catch {
                Write-Warning "Pacote do GitHub falhou: $($_.Exception.Message)"
                Write-Step 'Fallback: SteamCMD'
                $steamcmd = Get-SteamCmd
                Install-WorkshopItems -ManifestPath (Join-Path $PSScriptRoot 'pack-manifest.json') -SteamCmd $steamcmd -Force:$ForceRedownload
            }
        }
    } else {
        Write-Host "Download de mods ignorado." -ForegroundColor Yellow
    }

    if (-not $SkipZombieBuddy) {
        Write-Step 'Instalando ZombieBuddy'
        Install-ZombieBuddy -PZ $pz
    } else {
        Write-Host "ZombieBuddy ignorado." -ForegroundColor Yellow
    }

    Write-Step 'Ajustando o jogo'
    Set-GameConfig -PZ $pz -Zomboid $zomboid

    if (-not $NoActivate) {
        Write-Step 'Ativando todos os mods'
        & (Join-Path $PSScriptRoot 'Activate-Pack.ps1')
    }

    Write-Host ""
    Write-Host "TUDO PRONTO." -ForegroundColor Green
    Write-Host "Abre o Project Zomboid e cria um mundo novo." -ForegroundColor White
    Write-Host "Controles: O = primeira pessoa, Shift+O = terceira, MMB = cursor, I = inventario, V = ADS, G = arremessar." -ForegroundColor White
    Write-Host "Se algo falhar, leia o README.txt ou o console.txt em $zomboid." -ForegroundColor White
} catch {
    Write-Host ""
    Write-Host "ERRO: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Leia o README.txt e tente de novo." -ForegroundColor Yellow
    exit 1
}
