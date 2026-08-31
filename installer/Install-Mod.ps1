param(
    [string]$GamePath
)

$ErrorActionPreference = "Stop"
$ProjectName = "Space Haven Live Trainer"
$Version = "0.8.1"
$ModFolderName = "SpaceHavenLiveTrainer"

function Test-SpaceHavenPath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $false
    }

    return (Test-Path -LiteralPath (Join-Path $Path "spacehaven.jar"))
}

function Add-UniquePath {
    param(
        [System.Collections.Generic.List[string]]$List,
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return
    }

    $normalized = $Path.Trim().TrimEnd('\')

    if (-not $List.Contains($normalized)) {
        [void]$List.Add($normalized)
    }
}

function Get-SteamRoots {
    $roots = New-Object 'System.Collections.Generic.List[string]'

    # 64-bit Program Files
    $programFiles = [Environment]::GetEnvironmentVariable("ProgramFiles")
    if (-not [string]::IsNullOrWhiteSpace($programFiles)) {
        Add-UniquePath $roots (Join-Path $programFiles "Steam")
    }

    # 32-bit Program Files on 64-bit Windows.
    # Do NOT use $env:ProgramFiles(x86): parentheses make that invalid syntax
    # in Windows PowerShell 5.1 unless special escaping is used.
    $programFilesX86 = [Environment]::GetEnvironmentVariable("ProgramFiles(x86)")
    if (-not [string]::IsNullOrWhiteSpace($programFilesX86)) {
        Add-UniquePath $roots (Join-Path $programFilesX86 "Steam")
    }

    # Steam registry locations
    $registryPaths = @(
        "HKCU:\Software\Valve\Steam",
        "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
        "HKLM:\SOFTWARE\Valve\Steam"
    )

    foreach ($reg in $registryPaths) {
        try {
            $item = Get-ItemProperty -Path $reg -ErrorAction Stop

            if ($item.SteamPath) {
                Add-UniquePath $roots ([string]$item.SteamPath)
            }

            if ($item.InstallPath) {
                Add-UniquePath $roots ([string]$item.InstallPath)
            }
        } catch {}
    }

    return $roots
}

function Get-SteamLibraries {
    param([string]$SteamRoot)

    $libs = New-Object 'System.Collections.Generic.List[string]'
    Add-UniquePath $libs $SteamRoot

    $vdf = Join-Path $SteamRoot "steamapps\libraryfolders.vdf"

    if (-not (Test-Path -LiteralPath $vdf)) {
        return $libs
    }

    try {
        $content = Get-Content -LiteralPath $vdf -Raw

        # Current Steam VDF format
        $matches = [regex]::Matches($content, '"path"\s*"([^"]+)"')
        foreach ($m in $matches) {
            $libraryPath = $m.Groups[1].Value -replace '\\\\','\'
            Add-UniquePath $libs $libraryPath
        }

        # Legacy Steam VDF format
        $legacy = [regex]::Matches($content, '(?m)^\s*"\d+"\s*"([^"]+)"')
        foreach ($m in $legacy) {
            $libraryPath = $m.Groups[1].Value -replace '\\\\','\'
            if ($libraryPath -notmatch '^\d+$') {
                Add-UniquePath $libs $libraryPath
            }
        }
    } catch {}

    return $libs
}

function Find-SpaceHaven {
    $candidates = New-Object 'System.Collections.Generic.List[string]'

    foreach ($root in (Get-SteamRoots)) {
        if ([string]::IsNullOrWhiteSpace($root)) {
            continue
        }

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

    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Select the Space Haven folder / Seleziona la cartella di Space Haven (spacehaven.jar)"
    $dialog.ShowNewFolderButton = $false

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.SelectedPath
    }

    return $null
}

function Find-SourceMod {
    # GitHub Release layout:
    #   root\installer\Install-Mod.ps1
    #   root\SpaceHavenLiveTrainer\
    $root = Split-Path $PSScriptRoot -Parent
    $releaseCandidate = Join-Path $root $ModFolderName

    if (Test-Path -LiteralPath $releaseCandidate) {
        return $releaseCandidate
    }

    # GitHub repository layout:
    #   root\installer\Install-Mod.ps1
    #   root\mod\SpaceHavenLiveTrainer\
    $repoCandidate = Join-Path $root ("mod\" + $ModFolderName)

    if (Test-Path -LiteralPath $repoCandidate) {
        return $repoCandidate
    }

    return $null
}

Write-Host ""
Write-Host "$ProjectName - Installer v$Version"
Write-Host "----------------------------------------"

if (-not (Test-SpaceHavenPath $GamePath)) {
    Write-Host "Ricerca automatica di Space Haven..."
    $GamePath = Find-SpaceHaven
}

if (-not (Test-SpaceHavenPath $GamePath)) {
    Write-Host "Space Haven non trovato automaticamente."
    Write-Host "Apro la selezione manuale della cartella..."
    $GamePath = Choose-SpaceHavenFolder
}

if (-not (Test-SpaceHavenPath $GamePath)) {
    throw "Cartella Space Haven non valida o spacehaven.jar non trovato."
}

Write-Host ""
Write-Host "Space Haven trovato:"
Write-Host "  $GamePath"

$modsPath = Join-Path $GamePath "mods"

if (-not (Test-Path -LiteralPath $modsPath)) {
    throw "La cartella 'mods' non esiste. Installa prima Space Haven Mod Loader e riprova."
}

$sourceMod = Find-SourceMod

if ([string]::IsNullOrWhiteSpace($sourceMod) -or -not (Test-Path -LiteralPath $sourceMod)) {
    throw "Cartella SpaceHavenLiveTrainer non trovata nel pacchetto."
}

$targetMod = Join-Path $modsPath $ModFolderName

if (Test-Path -LiteralPath $targetMod) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backup = Join-Path $modsPath ($ModFolderName + "_backup_" + $stamp)

    Write-Host ""
    Write-Host "Backup della versione precedente:"
    Write-Host "  $backup"

    Move-Item -LiteralPath $targetMod -Destination $backup
}

try {
    Copy-Item -LiteralPath $sourceMod -Destination $targetMod -Recurse -Force
} catch {
    Write-Host ""
    Write-Host "Windows ha impedito la scrittura nella cartella del gioco."
    Write-Host "Esegui INSTALLA_MOD.bat come amministratore e riprova."
    throw
}

Write-Host ""
Write-Host "Installazione completata."
Write-Host ""
Write-Host "Mod installato in:"
Write-Host "  $targetMod"
Write-Host ""
Write-Host "Passi successivi:"
Write-Host "1. Apri Space Haven Mod Loader."
Write-Host "2. Verifica Space Haven Live Trainer v$Version."
Write-Host "3. Esegui Clear QuickLaunch cache."
Write-Host "4. Avvia Space Haven dal Mod Loader e carica una partita."
Write-Host "5. Avvia AVVIA_GUI.bat."
Write-Host ""
