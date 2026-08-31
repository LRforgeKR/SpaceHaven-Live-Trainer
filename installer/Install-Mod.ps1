param(
    [string]$GamePath
)

$ErrorActionPreference = "Stop"
$ProjectName = "Space Haven Live Trainer"
$Version = "0.7.2"
$ModFolderName = "SpaceHavenLiveTrainer"

function Test-SpaceHavenPath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    return (Test-Path (Join-Path $Path "spacehaven.jar"))
}

function Add-UniquePath {
    param(
        [System.Collections.Generic.List[string]]$List,
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    $normalized = $Path.Trim().TrimEnd('\')
    if (-not $List.Contains($normalized)) {
        $List.Add($normalized)
    }
}

function Get-SteamRoots {
    $roots = New-Object 'System.Collections.Generic.List[string]'

    if ($env:ProgramFiles) {
        Add-UniquePath $roots (Join-Path $env:ProgramFiles "Steam")
    }

    ${
        env:ProgramFiles(x86)
    }Value = [Environment]::GetEnvironmentVariable("ProgramFiles(x86)")
    if (-not [string]::IsNullOrWhiteSpace(${env:ProgramFiles(x86)}Value)) {
        Add-UniquePath $roots (Join-Path ${env:ProgramFiles(x86)}Value "Steam")
    }

    $registryPaths = @(
        "HKCU:\Software\Valve\Steam",
        "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
        "HKLM:\SOFTWARE\Valve\Steam"
    )

    foreach ($reg in $registryPaths) {
        try {
            $item = Get-ItemProperty -Path $reg -ErrorAction Stop
            if ($item.SteamPath) { Add-UniquePath $roots $item.SteamPath }
            if ($item.InstallPath) { Add-UniquePath $roots $item.InstallPath }
        } catch {}
    }

    return $roots
}

function Get-SteamLibraries {
    param([string]$SteamRoot)

    $libs = New-Object 'System.Collections.Generic.List[string]'
    Add-UniquePath $libs $SteamRoot

    $vdf = Join-Path $SteamRoot "steamapps\libraryfolders.vdf"
    if (-not (Test-Path $vdf)) {
        return $libs
    }

    try {
        $content = Get-Content -LiteralPath $vdf -Raw

        $matches = [regex]::Matches($content, '"path"\s*"([^"]+)"')
        foreach ($m in $matches) {
            $p = $m.Groups[1].Value -replace '\\\\','\'
            Add-UniquePath $libs $p
        }

        $legacy = [regex]::Matches($content, '(?m)^\s*"\d+"\s*"([^"]+)"')
        foreach ($m in $legacy) {
            $p = $m.Groups[1].Value -replace '\\\\','\'
            if ($p -notmatch '^\d+$') {
                Add-UniquePath $libs $p
            }
        }
    } catch {}

    return $libs
}

function Find-SpaceHaven {
    $candidates = New-Object 'System.Collections.Generic.List[string]'

    foreach ($root in (Get-SteamRoots)) {
        foreach ($library in (Get-SteamLibraries $root)) {
            Add-UniquePath $candidates (Join-Path $library "steamapps\common\SpaceHaven")
        }
    }

    foreach ($candidate in $candidates) {
        if (Test-SpaceHavenPath $candidate) {
            return $candidate
        }
    }

    return $null
}

function Choose-SpaceHavenFolder {
    Add-Type -AssemblyName System.Windows.Forms
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Seleziona la cartella di Space Haven (deve contenere spacehaven.jar)"
    $dlg.ShowNewFolderButton = $false

    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dlg.SelectedPath
    }
    return $null
}

Write-Host ""
Write-Host "$ProjectName - Installer v$Version"
Write-Host "----------------------------------------"

if (-not (Test-SpaceHavenPath $GamePath)) {
    $GamePath = Find-SpaceHaven
}

if (-not (Test-SpaceHavenPath $GamePath)) {
    Write-Host "Space Haven non trovato automaticamente."
    $GamePath = Choose-SpaceHavenFolder
}

if (-not (Test-SpaceHavenPath $GamePath)) {
    throw "Cartella Space Haven non valida o spacehaven.jar non trovato."
}

Write-Host "Space Haven trovato:"
Write-Host "  $GamePath"

$modsPath = Join-Path $GamePath "mods"
if (-not (Test-Path $modsPath)) {
    throw "La cartella 'mods' non esiste. Installa prima Space Haven Mod Loader e riprova."
}

$sourceMod = Join-Path (Split-Path $PSScriptRoot -Parent) $ModFolderName
if (-not (Test-Path $sourceMod)) {
    throw "Cartella del mod non trovata nel pacchetto: $sourceMod"
}

$targetMod = Join-Path $modsPath $ModFolderName

if (Test-Path $targetMod) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backup = Join-Path $modsPath ($ModFolderName + "_backup_" + $stamp)
    Write-Host "Backup versione precedente:"
    Write-Host "  $backup"
    Move-Item -LiteralPath $targetMod -Destination $backup
}

try {
    Copy-Item -LiteralPath $sourceMod -Destination $targetMod -Recurse -Force
} catch {
    Write-Host ""
    Write-Host "Windows ha impedito la scrittura nella cartella del gioco."
    Write-Host "In questo caso esegui INSTALLA_MOD.bat come amministratore."
    throw
}

Write-Host ""
Write-Host "Installazione completata."
Write-Host "Mod:"
Write-Host "  $targetMod"
Write-Host ""
Write-Host "Passi successivi:"
Write-Host "1. Apri Space Haven Mod Loader."
Write-Host "2. Verifica che il mod mostri v$Version."
Write-Host "3. Esegui Clear QuickLaunch cache."
Write-Host "4. Avvia Space Haven e carica una partita."
Write-Host "5. Avvia AVVIA_GUI.bat."
Write-Host ""
