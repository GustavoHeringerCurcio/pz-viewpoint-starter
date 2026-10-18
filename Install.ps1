param(
    [ValidateSet('Medium', 'Advanced')]
    [string]$Profile,
    [switch]$CheckOnly,
    [switch]$SkipMods,
    [switch]$SkipZombieBuddy,
    [switch]$NoActivate,
    [switch]$SkipHost,
    [switch]$ForceRedownload,
    [switch]$UseSteamCmd
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

$ArchiveCatalog = @{
    Medium = @{
        Url = 'https://github.com/GustavoHeringerCurcio/pz-viewpoint-starter/releases/download/mods-v1/PZ-Viewpoint-Mods.tar'
        FileName = 'PZ-Viewpoint-Mods.tar'
        Sha256 = 'f3999811acf25c531772e8d2faf8d20bb4bd0b760b4812dc59eb22d2818a3b5e'
        SizeLabel = '~1.1 GB'
        RequiredGB = 3
        ReleaseTag = 'mods-v1'
    }
    Advanced = @{
        Url = 'https://github.com/GustavoHeringerCurcio/pz-viewpoint-starter/releases/download/mods-v2/PZ-Viewpoint-Mods-Advanced.tar'
        FileName = 'PZ-Viewpoint-Mods-Advanced.tar'
        Sha256 = 'f5c453de44cb8642e6730ff89ebae53c40dbea4b7fa875241a9ce13ed8085c17'
        SizeLabel = '~1.3 GB'
        RequiredGB = 5
        ReleaseTag = 'mods-v2'
    }
}

$ArchiveUrl = $ArchiveCatalog.Medium.Url
$ArchiveFileName = $ArchiveCatalog.Medium.FileName
$ArchiveSha256 = $ArchiveCatalog.Medium.Sha256
$ArchiveRequiredGB = $ArchiveCatalog.Medium.RequiredGB
$ArchiveSizeLabel = $ArchiveCatalog.Medium.SizeLabel
$ArchiveReleaseTag = $ArchiveCatalog.Medium.ReleaseTag

function Select-Profile {
    param([string]$Current)

    if ($Current) { return $Current }

    Write-Host ""
    Write-Host "Escolha o modpack:" -ForegroundColor Cyan
    Write-Host "  1) Medio    - 38 mods no cliente, o pacote atual" -ForegroundColor White
    Write-Host "  2) Avancado - 57 mods no cliente, fixes + 3D + natacao + RV" -ForegroundColor White
    Write-Host ""
    Write-Host "O Medio e o mais seguro para o save atual. O Avancado adiciona mods" -ForegroundColor DarkGray
    Write-Host "sem remover os atuais." -ForegroundColor DarkGray
    Write-Host ""

    while ($true) {
        $choice = Read-Host "Digite 1 ou 2 e pressione Enter (Enter = 1)"
        switch ($choice.Trim().ToLowerInvariant()) {
            '' { return 'Medium' }
            '1' { return 'Medium' }
            '2' { return 'Advanced' }
            'medio' { return 'Medium' }
            'medium' { return 'Medium' }
            'avancado' { return 'Advanced' }
            'advanced' { return 'Advanced' }
            default { Write-Host "Opcao invalida. Digite 1 ou 2." -ForegroundColor Yellow }
        }
    }
}

function Write-Step([string]$Text) {
    Write-Host ""
    Write-Host "== $Text ==" -ForegroundColor Cyan
}

$InstallerVersion = 2

function Test-InstallerVersion {
    try {
        $url = 'https://raw.githubusercontent.com/GustavoHeringerCurcio/pz-viewpoint-starter/main/installer-version.txt'
        $value = (Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 8).Content
        if ($value -is [byte[]]) { $value = [Text.Encoding]::UTF8.GetString($value) }
        $remote = 0
        if ([int]::TryParse($value.Trim(), [ref]$remote) -and $remote -gt $InstallerVersion) {
            Write-Warning "Ha uma versao mais nova do instalador ($remote). Baixe o ZIP atualizado do GitHub (Code > Download ZIP) e rode Install.bat de dentro dele."
        }
    } catch {
        Write-Verbose "Nao foi possivel verificar a versao do instalador."
    }
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
    Write-Host "Backup de configuracao: $dst" -ForegroundColor DarkGray
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
    param(
        [string]$Uri,
        [string]$OutFile,
        [switch]$ShowProgress
    )

    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if ($curl) {
        $curlArgs = @('--fail', '--location', '--retry', '3', '--retry-delay', '2', '--output', $OutFile)
        if ($ShowProgress) { $curlArgs += '--progress-bar' } else { $curlArgs += @('--silent', '--show-error') }
        $curlArgs += $Uri
        & $curl.Source @curlArgs
        if ($LASTEXITCODE -eq 0) { return }
        Write-Warning "curl falhou ($LASTEXITCODE). Tentando outro metodo..."
    }

    if (Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue) {
        try {
            Start-BitsTransfer -Source $Uri -Destination $OutFile -ErrorAction Stop
            return
        } catch { }
    }

    if ($ShowProgress) { $ProgressPreference = 'Continue' }
    Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing
}

function Test-ModInfoFolder {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    return [bool](Get-ChildItem -LiteralPath $Path -Recurse -Filter 'mod.info' -ErrorAction SilentlyContinue | Select-Object -First 1)
}

function Test-ArchiveCacheComplete {
    param([string]$ManifestPath)
    $data = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    $cacheRoot = Get-WorkshopCacheRoot
    foreach ($p in Get-PackOrder -Profile $Profile) {
        foreach ($m in $data.$p) {
            $folder = Join-Path (Join-Path (Join-Path $cacheRoot $m.Workshop) 'mods') $m.Folder
            if (-not (Test-ModInfoFolder -Path $folder)) { return $false }
        }
    }
    return $true
}

function Test-FreeSpace {
    param([int]$RequiredGB)
    $free = $null
    try {
        $root = [IO.Path]::GetPathRoot((Get-UserProfile))
        $drive = $root.TrimEnd('\').TrimEnd(':')
        $free = (Get-PSDrive -Name $drive -ErrorAction Stop).Free
    } catch { }
    if ($null -ne $free -and $free -lt ($RequiredGB * 1GB)) {
        throw "Espaco insuficiente: $([math]::Round($free / 1GB, 1)) GB livres; necessario ~$RequiredGB GB."
    }
}

function Test-SteamLaunchOptionsAgent {
    try {
        $steam = Get-SteamPath
        $userdata = Join-Path $steam 'userdata'
        if (-not (Test-Path -LiteralPath $userdata)) { return $false }
        foreach ($file in (Get-ChildItem -LiteralPath $userdata -Recurse -Filter 'localconfig.vdf' -ErrorAction SilentlyContinue)) {
            if (Select-String -LiteralPath $file.FullName -Pattern 'agentlib:zbNative' -Quiet -ErrorAction SilentlyContinue) { return $true }
        }
    } catch { }
    return $false
}

function Test-ModsInstalled {
    param([string]$ManifestPath, [switch]$WriteMarker)

    $modsDir = Join-Path (Get-ZomboidDir) 'mods'
    $marker = Join-Path $modsDir '.pz-viewpoint-installed'
    if (Test-Path -LiteralPath $marker) {
        $value = ((Get-Content -LiteralPath $marker -Raw).Trim() -split '\s+')[0]
        if ($value -ne $ArchiveSha256) { return $false }
    }

    $data = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    foreach ($p in Get-PackOrder -Profile $Profile) {
        foreach ($m in $data.$p) {
            $folder = Join-Path $modsDir $m.Folder
            if (-not (Test-ModInfoFolder -Path $folder)) { return $false }
        }
    }

    if ($WriteMarker) {
        New-Item -ItemType Directory -Path $modsDir -Force | Out-Null
        Set-Content -LiteralPath $marker -Value $ArchiveSha256 -Encoding ASCII
    }
    return $true
}

function Move-ArchiveModsToGame {
    param([string]$ManifestPath, [switch]$Force)

    if (-not $Force -and (Test-ModsInstalled -ManifestPath $ManifestPath -WriteMarker)) {
        Write-Host "Mods ja estao instalados; movimentacao ignorada." -ForegroundColor Green
        return
    }

    $data = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    $modsDir = Join-Path (Get-ZomboidDir) 'mods'
    $cacheRoot = Get-WorkshopCacheRoot
    $backupRoot = Join-Path (Get-ZomboidDir) 'backups\mods-old'
    New-Item -ItemType Directory -Path $modsDir -Force | Out-Null
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

    $total = 0
    foreach ($p in Get-PackOrder -Profile $Profile) { $total += $data.$p.Count }
    $index = 0

    foreach ($p in Get-PackOrder -Profile $Profile) {
        foreach ($m in $data.$p) {
            $index++
            $src = Join-Path (Join-Path (Join-Path $cacheRoot $m.Workshop) 'mods') $m.Folder
            $dst = Join-Path $modsDir $m.Folder

            if (-not (Test-ModInfoFolder -Path $src)) {
                if (Test-ModInfoFolder -Path $dst) {
                    Write-Host "  [$index/$total] $($m.Folder) ja esta em mods" -ForegroundColor DarkGray
                    continue
                }
                throw "Mod ausente no cache e em mods: $($m.Folder)"
            }

            if ((Test-ModInfoFolder -Path $dst) -and -not $Force) {
                Write-Host "  [$index/$total] $($m.Folder) ja esta em mods; mantido" -ForegroundColor DarkGray
                continue
            }

            if (Test-Path -LiteralPath $dst) {
                $backup = Join-Path $backupRoot ("{0}-{1}" -f $m.Folder, $stamp)
                if (Test-Path -LiteralPath $backup) { $backup = "$backup-$index" }
                Move-Item -LiteralPath $dst -Destination $backup
                Write-Host "  [$index/$total] backup do antigo: $($m.Folder)" -ForegroundColor DarkGray
            }

            Move-Item -LiteralPath $src -Destination $dst
            Write-Host "  [$index/$total] movido: $($m.Folder)" -ForegroundColor DarkGray
        }
    }

    if (-not (Test-ModsInstalled -ManifestPath $ManifestPath -WriteMarker)) {
        throw 'Falha ao confirmar todos os mods em Zomboid\mods.'
    }
}

function Install-FromArchive {
    param([string]$ManifestPath)

    if (-not $ForceRedownload -and (Test-ModsInstalled -ManifestPath $ManifestPath -WriteMarker)) {
        Write-Host "[1/5] Mods ja instalados em Zomboid\mods; nada a fazer." -ForegroundColor Green
        return
    }

    $archiveDir = Join-Path (Get-LocalAppData) 'PZViewpoint\archive'
    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
    $tarPath = Join-Path $archiveDir $ArchiveFileName
    $shaPath = "$tarPath.sha256"

    $cacheComplete = Test-ArchiveCacheComplete -ManifestPath $ManifestPath
    if ($cacheComplete -and -not $ForceRedownload) {
        Write-Host "[1/5] Cache completo; download e extracao ignorados." -ForegroundColor Green
    } else {
        $requiredGB = $ArchiveRequiredGB
        if ((Test-Path -LiteralPath $tarPath) -and -not $ForceRedownload) { $requiredGB = [Math]::Max(2, $ArchiveRequiredGB - 1) }
        Test-FreeSpace -RequiredGB $requiredGB
        Write-Host "[1/5] Obtendo hash SHA256..." -ForegroundColor Yellow
        $expected = $ArchiveSha256
        if (Test-Path -LiteralPath $shaPath) {
            $expected = ((Get-Content -LiteralPath $shaPath -Raw).Trim() -split '\s+')[0].ToLower()
        } else {
            try {
                Get-RemoteFile -Uri "$ArchiveUrl.sha256" -OutFile $shaPath
                $expected = ((Get-Content -LiteralPath $shaPath -Raw).Trim() -split '\s+')[0].ToLower()
            } catch {
                Write-Warning 'Nao foi possivel baixar o hash; usando o hash embutido no instalador.'
            }
        }
        if ($expected -notmatch '^[0-9a-f]{64}$') { $expected = $ArchiveSha256 }

        $needDownload = $ForceRedownload -or -not (Test-Path -LiteralPath $tarPath)
        if (-not $needDownload) {
            $current = (Get-FileHash -LiteralPath $tarPath -Algorithm SHA256).Hash.ToLower()
            if ($current -ne $expected) { $needDownload = $true }
        }

        if ($needDownload) {
            if (Test-Path -LiteralPath $tarPath) { Remove-Item -LiteralPath $tarPath -Force }
            Write-Host "[2/5] Baixando pacote de mods do GitHub..." -ForegroundColor Yellow
            Write-Host "      Repo:   github.com/GustavoHeringerCurcio/pz-viewpoint-starter"
            Write-Host "      Release: $ArchiveReleaseTag"
            Write-Host "      Perfil: $Profile"
            Write-Host "      Arquivo: $ArchiveFileName ($ArchiveSizeLabel)"
            Write-Host "      Destino: $tarPath"
            $downloadTimer = [Diagnostics.Stopwatch]::StartNew()
            Get-RemoteFile -Uri $ArchiveUrl -OutFile $tarPath -ShowProgress
            $downloadTimer.Stop()
            Write-Host "Download concluido em $([math]::Round($downloadTimer.Elapsed.TotalMinutes,1)) min." -ForegroundColor Green
        } else {
            Write-Host "[2/5] Pacote ja esta no cache local; download ignorado." -ForegroundColor Green
        }

        Write-Host "[3/5] Validando SHA256..." -ForegroundColor Yellow
        $actual = (Get-FileHash -LiteralPath $tarPath -Algorithm SHA256).Hash.ToLower()
        if ($actual -ne $expected) { throw 'Hash do pacote de mods nao confere.' }

        Write-Host "[4/5] Extraindo pacote (pode levar 1-3 minutos)..." -ForegroundColor Yellow
        $cacheParent = Split-Path (Get-WorkshopCacheRoot) -Parent
        if (-not (Get-Command tar.exe -ErrorAction SilentlyContinue)) {
            throw 'tar.exe nao encontrado. Atualiza o Windows 10/11.'
        }
        $extractTimer = [Diagnostics.Stopwatch]::StartNew()
        $tarArgs = '-x -f "{0}" -C "{1}"' -f $tarPath, $cacheParent
        $tarProcess = Start-Process -FilePath 'tar.exe' -ArgumentList $tarArgs -PassThru -WindowStyle Hidden
        while (-not $tarProcess.HasExited) {
            Write-Host "`r      Extraindo... $([int]$extractTimer.Elapsed.TotalSeconds)s   " -NoNewline
            Start-Sleep -Seconds 1
            $tarProcess.Refresh()
        }
        $tarProcess.WaitForExit()
        $extractTimer.Stop()
        Write-Host ""
        if ($tarProcess.ExitCode -ne 0) { throw "Falha ao extrair o pacote (tar $($tarProcess.ExitCode))." }
        Write-Host "Extracao concluida em $([math]::Round($extractTimer.Elapsed.TotalMinutes,1)) min." -ForegroundColor Green
    }

    Write-Host "[5/5] Movendo mods do cache para Zomboid\mods..." -ForegroundColor Yellow
    Move-ArchiveModsToGame -ManifestPath $ManifestPath -Force:$ForceRedownload
    Write-Host "Mods instalados." -ForegroundColor Green
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
    foreach ($p in Get-PackOrder -Profile $Profile) {
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

function Get-ZombieBuddyLibrarySource {
    $candidates = @(
        (Join-Path (Join-Path (Join-Path (Get-WorkshopCacheRoot) '3619862853') 'mods') 'ZombieBuddy'),
        (Join-Path (Join-Path (Get-ZomboidDir) 'mods') 'ZombieBuddy')
    )
    foreach ($path in $candidates) {
        if (Test-Path -LiteralPath (Join-Path $path 'libs\ZombieBuddy.jar')) { return $path }
    }
    return $null
}

function Prepare-ZombieBuddyWorkshop {
    Write-Host "Preparando conteudo do ZombieBuddy para o instalador..." -ForegroundColor Yellow
    $source = Get-ZombieBuddyLibrarySource
    if (-not $source) { return $false }

    $workshopRoot = Ensure-WorkshopRoot
    $destination = Join-Path (Join-Path (Join-Path $workshopRoot '3619862853') 'mods') 'ZombieBuddy'
    $destinationJar = Join-Path $destination 'libs\ZombieBuddy.jar'
    $destinationDll = Join-Path $destination 'libs\zbNative.dll'
    if ((Test-Path -LiteralPath $destinationJar) -and (Test-Path -LiteralPath $destinationDll)) {
        return $true
    }

    New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
    robocopy $source $destination /E /MT:8 /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) { return $false }

    return ((Test-Path -LiteralPath $destinationJar) -and (Test-Path -LiteralPath $destinationDll))
}

function Install-ZombieBuddyManually {
    param([string]$PZ, [string]$Zomboid)

    $source = Get-ZombieBuddyLibrarySource
    if (-not $source) { throw 'Arquivos do ZombieBuddy nao encontrados no cache.' }

    Copy-Item -LiteralPath (Join-Path $source 'libs\ZombieBuddy.jar') -Destination (Join-Path $PZ 'ZombieBuddy.jar') -Force
    Copy-Item -LiteralPath (Join-Path $source 'libs\zbNative.dll') -Destination (Join-Path $PZ 'zbNative.dll') -Force
    Set-GameConfig -PZ $PZ -Zomboid $Zomboid
}

function Install-ZombieBuddy {
    param([string]$PZ, [string]$Zomboid)

    if (Test-ZombieBuddyInstalled -PZ $PZ) {
        Write-Host "ZombieBuddy ja esta instalado." -ForegroundColor Green
        return
    }

    $prepared = $false
    try {
        $prepared = Prepare-ZombieBuddyWorkshop
    } catch {
        Write-Warning "Falha ao preparar a Workshop do ZombieBuddy: $($_.Exception.Message)"
    }
    if (-not $prepared) {
        Write-Warning 'Nao consegui preparar a pasta da Workshop do ZombieBuddy; tentando o instalador mesmo assim.'
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
    Write-Host "  2) escreve 2 e Enter  (Normal Launch)" -ForegroundColor White
    Write-Host "  3) escreve 2 e Enter  (ProjectZomboid64.json)" -ForegroundColor White
    Write-Host "  4) se pedir confirmacao, escreve y e Enter" -ForegroundColor White
    Write-Host ""
    Start-Process -FilePath $installer -WorkingDirectory (Split-Path $installer -Parent) -Wait

    if (-not (Test-ZombieBuddyInstalled -PZ $PZ)) {
        Write-Warning 'Instalador do ZombieBuddy nao concluiu; aplicando instalacao manual.'
        Install-ZombieBuddyManually -PZ $PZ -Zomboid $Zomboid
    }

    if (-not (Test-ZombieBuddyInstalled -PZ $PZ)) {
        throw 'ZombieBuddy nao foi instalado nem manualmente.'
    }
    Write-Host "ZombieBuddy instalado." -ForegroundColor Green
}

function Set-GameConfig {
    param([string]$PZ, [string]$Zomboid)

    $heap = Get-RecommendedHeapMB
    $xmx = "-Xmx${heap}m"
    $agentFiles = (Test-Path -LiteralPath (Join-Path $PZ 'ZombieBuddy.jar')) -and
                  (Test-Path -LiteralPath (Join-Path $PZ 'zbNative.dll'))
    Write-Host "Memoria do jogo: ${heap} MB" -ForegroundColor DarkGray

    $jsonPath = Join-Path $PZ 'ProjectZomboid64.json'
    if (Test-Path -LiteralPath $jsonPath) {
        $json = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
        $vm = @($json.vmArgs)
        if (-not ($vm -match '^-Xmx')) { $vm += $xmx }
        else { $vm = $vm | ForEach-Object { if ($_ -match '^-Xmx') { $xmx } else { $_ } } }
        if ($agentFiles) {
            if (-not ($vm -match 'agentlib:zbNative')) { $vm = @('-agentlib:zbNative') + $vm }
        } else {
            $vm = $vm | Where-Object { $_ -notmatch 'agentlib:zbNative' }
        }
        $json.vmArgs = $vm
        $jsonText = $json | ConvertTo-Json -Depth 10
        [IO.File]::WriteAllText($jsonPath, $jsonText, (New-Object System.Text.UTF8Encoding($false)))
    }

    $batPath = Join-Path $PZ 'ProjectZomboid64.bat'
    if (Test-Path -LiteralPath $batPath) {
        $bat = Get-Content -LiteralPath $batPath -Raw
        if ($agentFiles) {
            if ($bat -notmatch 'agentlib:zbNative') {
                $bat = $bat -replace 'SET _JAVA_OPTIONS=.*', 'SET _JAVA_OPTIONS=-agentlib:zbNative'
            }
        } else {
            $bat = $bat -replace 'SET _JAVA_OPTIONS=.*', 'SET _JAVA_OPTIONS='
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

    Test-InstallerVersion

    if (-not $Profile) {
        if ($CheckOnly) {
            $Profile = Get-SavedProfile
        } else {
            $Profile = Select-Profile
        }
    }

    $archive = $ArchiveCatalog[$Profile]
    $ArchiveUrl = $archive.Url
    $ArchiveFileName = $archive.FileName
    $ArchiveSha256 = $archive.Sha256
    $ArchiveRequiredGB = $archive.RequiredGB
    $ArchiveSizeLabel = $archive.SizeLabel
    $ArchiveReleaseTag = $archive.ReleaseTag

    $data = Get-PZWorkshopManifest -ScriptRoot $PSScriptRoot
    $profileItems = @()
    foreach ($p in Get-PackOrder -Profile $Profile) { $profileItems += $data.$p }
    $clientCount = @($profileItems | Where-Object { -not $_.ServerOnly }).Count
    $allIds = @($profileItems | Select-Object -ExpandProperty Workshop -Unique)

    if ($CheckOnly) {
        Write-Host ""
        Write-Host "Perfil: $Profile"
        Write-Host "CheckOnly: $($profileItems.Count) entradas, $clientCount no cliente, $($allIds.Count) itens Workshop unicos."
        Write-Host "ZombieBuddy instalado: $(Test-ZombieBuddyInstalled -PZ $pz)"
        $archiveCache = Join-Path (Join-Path (Get-LocalAppData) 'PZViewpoint\archive') $ArchiveFileName
        Write-Host "Pacote $Profile em cache: $(Test-Path -LiteralPath $archiveCache)"
        Write-Host "Mods ja instalados: $(Test-ModsInstalled -ManifestPath (Join-Path $PSScriptRoot 'pack-manifest.json'))"
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
    Set-SavedProfile -Profile $Profile

    Write-Host "Perfil selecionado: $Profile ($clientCount mods no cliente)." -ForegroundColor Cyan
    Backup-GameFiles -PZ $pz -Zomboid $zomboid

    if (-not $SkipMods) {
        if ($UseSteamCmd) {
            Write-Step 'Baixando mods do Workshop'
            $steamcmd = Get-SteamCmd
            Install-WorkshopItems -ManifestPath (Join-Path $PSScriptRoot 'pack-manifest.json') -SteamCmd $steamcmd -Force:$ForceRedownload
            Move-ArchiveModsToGame -ManifestPath (Join-Path $PSScriptRoot 'pack-manifest.json') -Force:$ForceRedownload
        } else {
            Write-Step 'Baixando pacote do GitHub'
            try {
                Install-FromArchive -ManifestPath (Join-Path $PSScriptRoot 'pack-manifest.json')
            } catch {
                Write-Warning "Pacote do GitHub falhou: $($_.Exception.Message)"
                Write-Step 'Fallback: SteamCMD'
                $steamcmd = Get-SteamCmd
                Install-WorkshopItems -ManifestPath (Join-Path $PSScriptRoot 'pack-manifest.json') -SteamCmd $steamcmd -Force:$ForceRedownload
                Move-ArchiveModsToGame -ManifestPath (Join-Path $PSScriptRoot 'pack-manifest.json') -Force:$ForceRedownload
            }
        }
    } else {
        Write-Host "Download de mods ignorado." -ForegroundColor Yellow
    }

    $zbFailed = $false
    $hostUpdated = $false
    if (-not $SkipZombieBuddy) {
        Write-Step 'Instalando ZombieBuddy'
        try {
            Install-ZombieBuddy -PZ $pz -Zomboid $zomboid
        } catch {
            $zbFailed = $true
            Write-Warning "ZombieBuddy falhou: $($_.Exception.Message)"
        }
    } else {
        Write-Host "ZombieBuddy ignorado." -ForegroundColor Yellow
    }

    Write-Step 'Ajustando o jogo'
    Set-GameConfig -PZ $pz -Zomboid $zomboid
    if (Test-SteamLaunchOptionsAgent) {
        Write-Warning 'As Steam Launch Options ainda contem -agentlib:zbNative. Remova para nao carregar o agente duas vezes; use Normal Launch -> JSON.'
    }

    if (-not $NoActivate) {
        Write-Step "Ativando mods do perfil $Profile"
        & (Join-Path $PSScriptRoot 'Activate-Pack.ps1') -Profile $Profile

        if (-not $SkipHost) {
            $hostIni = Join-Path $zomboid 'Server\servertest.ini'
            if (Test-Path -LiteralPath $hostIni) {
                Write-Step "Atualizando host para $Profile"
                try {
                    & (Join-Path $PSScriptRoot 'Setup-Host.ps1') -Apply -Profile $Profile -Quiet
                    $hostUpdated = $true
                } catch {
                    Write-Warning "Nao foi possivel atualizar o servertest.ini: $($_.Exception.Message)"
                }
            } else {
                Write-Host "Host nao encontrado; servertest.ini nao foi alterado." -ForegroundColor DarkGray
            }
        } else {
            Write-Host "Atualizacao do host ignorada (-SkipHost)." -ForegroundColor DarkGray
        }
    }

    Write-Host ""
    if ($zbFailed) {
        Write-Host "MODS ATIVADOS, MAS O ZOMBIEBUDDY FALHOU." -ForegroundColor Yellow
        Write-Host "Os mods Java (Viewpoint) podem nao carregar. Rode Install.bat de novo ou faca a instalacao manual indicada no README." -ForegroundColor Yellow
    } else {
        Write-Host "TUDO PRONTO." -ForegroundColor Green
    }
    Write-Host "Perfil ativo: $Profile." -ForegroundColor White
    if ($SkipHost) {
        Write-Host "Host nao foi atualizado por causa de -SkipHost. Rode Setup-Host.bat." -ForegroundColor Yellow
    } elseif ($hostUpdated) {
        Write-Host "Host atualizado para este perfil com backup do servertest.ini." -ForegroundColor White
    }
    if ($Profile -eq 'Advanced') {
        Write-Host "Para continuar o save atual, abra o host normalmente. Nao troque para Medio" -ForegroundColor Yellow
        Write-Host "depois de usar o RV no mesmo save sem restaurar o backup manual." -ForegroundColor Yellow
    } else {
        Write-Host "Abra o Project Zomboid. Para um mundo novo, crie o mundo; para o save atual, continue." -ForegroundColor White
    }
    Write-Host "Controles: O = primeira pessoa, Shift+O = terceira, MMB = cursor, I = inventario, V = ADS, G = arremessar." -ForegroundColor White
    Write-Host "Se algo falhar, leia o README.txt ou o console.txt em $zomboid." -ForegroundColor White
} catch {
    Write-Host ""
    Write-Host "ERRO: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Leia o README.txt e tente de novo." -ForegroundColor Yellow
    exit 1
}
