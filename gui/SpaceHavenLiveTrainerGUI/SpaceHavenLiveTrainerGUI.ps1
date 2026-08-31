# Space Haven Live Trainer GUI
# Author: Luca Cococcioni
# License: MIT

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$script:HostName = "127.0.0.1"
$script:Port = 17840
$script:Connected = $false
$script:WorldLoaded = $false
$script:UpdatingUI = $false
$script:UpdatingCrewList = $false
$script:InitialDataLoaded = $false
$script:LastCrewId = 0

$clrHeader = [System.Drawing.Color]::FromArgb(31, 36, 46)
$clrAccent = [System.Drawing.Color]::FromArgb(42, 116, 196)
$clrBack = [System.Drawing.Color]::FromArgb(245, 247, 250)
$clrPanel = [System.Drawing.Color]::White
$clrMuted = [System.Drawing.Color]::DimGray
$clrGood = [System.Drawing.Color]::DarkGreen
$clrWarn = [System.Drawing.Color]::DarkOrange
$clrBad = [System.Drawing.Color]::Firebrick

function Send-TrainerRequest {
    param([string]$Request, [int]$TimeoutMs = 800)

    $client = $null
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $ar = $client.BeginConnect($script:HostName, $script:Port, $null, $null)
        if (-not $ar.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) {
            $client.Close()
            return $null
        }
        $client.EndConnect($ar)
        $client.ReceiveTimeout = $TimeoutMs
        $client.SendTimeout = $TimeoutMs

        $stream = $client.GetStream()
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        $writer = New-Object System.IO.StreamWriter($stream, $utf8NoBom)
        $writer.NewLine = "`n"
        $writer.AutoFlush = $true
        $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)

        $writer.WriteLine($Request)
        $response = $reader.ReadLine()

        $reader.Dispose()
        $writer.Dispose()
        $stream.Dispose()
        $client.Close()
        return $response
    } catch {
        if ($null -ne $client) {
            try { $client.Close() } catch {}
        }
        return $null
    }
}

function Parse-Fields {
    param([string]$Response)
    $map = @{}
    if ([string]::IsNullOrEmpty($Response)) { return $map }
    $parts = $Response -split '\|'
    foreach ($part in $parts) {
        $eq = $part.IndexOf("=")
        if ($eq -gt 0) {
            $map[$part.Substring(0, $eq)] = $part.Substring($eq + 1)
        }
    }
    return $map
}

function Decode-B64 {
    param([string]$Value)
    if ([string]::IsNullOrEmpty($Value)) { return "" }
    try {
        return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Value))
    } catch {
        return $Value
    }
}

function Set-ActionStatus {
    param([string]$Message, [bool]$Error = $false)
    $lblBottomStatus.Text = $Message
    $lblBottomStatus.ForeColor = $(if ($Error) { $clrBad } else { $clrGood })
}

function New-FlatButton {
    param([string]$Text, [int]$X, [int]$Y, [int]$W, [int]$H)
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $Text
    $b.Location = New-Object System.Drawing.Point($X, $Y)
    $b.Size = New-Object System.Drawing.Size($W, $H)
    $b.FlatStyle = "Flat"
    $b.FlatAppearance.BorderSize = 0
    $b.BackColor = $clrAccent
    $b.ForeColor = [System.Drawing.Color]::White
    $b.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
    return $b
}

function Configure-Grid {
    param([System.Windows.Forms.DataGridView]$Grid)
    $Grid.AllowUserToAddRows = $false
    $Grid.AllowUserToDeleteRows = $false
    $Grid.AllowUserToResizeRows = $false
    $Grid.RowHeadersVisible = $false
    $Grid.SelectionMode = "FullRowSelect"
    $Grid.MultiSelect = $false
    $Grid.BackgroundColor = [System.Drawing.Color]::White
    $Grid.BorderStyle = "FixedSingle"
    $Grid.AutoSizeColumnsMode = "Fill"
    $Grid.EnableHeadersVisualStyles = $false
    $Grid.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(232, 236, 242)
    $Grid.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
}

function Set-ConnectedState {
    param([bool]$Connected, [bool]$WorldLoaded)

    $wasReady = ($script:Connected -and $script:WorldLoaded)
    $script:Connected = $Connected
    $script:WorldLoaded = $WorldLoaded
    $ready = ($Connected -and $WorldLoaded)

    if (-not $Connected) {
        $lblConnection.Text = "MOD: NON CONNESSO"
        $lblConnection.ForeColor = $clrBad
        $lblSubStatus.Text = "Avvia Space Haven dal Mod Loader."
    } elseif (-not $WorldLoaded) {
        $lblConnection.Text = "MOD: CONNESSO"
        $lblConnection.ForeColor = $clrWarn
        $lblSubStatus.Text = "Mod rilevato. Carica una partita."
    } else {
        $lblConnection.Text = "MOD: CONNESSO / LIVE"
        $lblConnection.ForeColor = $clrGood
        $lblSubStatus.Text = "Comunicazione locale 127.0.0.1:17840"
    }

    foreach ($ctrl in @(
        $btnCredits, $btnAddResource, $chkInfiniteResources,
        $chkHealth, $chkOxygen, $chkFood, $chkRest, $chkMood, $chkComfort,
        $btnCrewRefresh, $cmbCrew, $btnCrewApply, $btnMaxSkills, $btnMaxAttrs, $btnCure,
        $btnTechRefresh, $gridTech, $btnCompleteTech, $btnCompleteAllTech, $chkInstantResearch
    )) {
        if ($null -ne $ctrl) { $ctrl.Enabled = $ready }
    }

    if ($ready -and -not $wasReady) {
        $script:InitialDataLoaded = $false
    }
}

function Refresh-Status {
    $response = Send-TrainerRequest "STATUS" 550
    if ([string]::IsNullOrEmpty($response) -or -not $response.StartsWith("STATUS|")) {
        Set-ConnectedState $false $false
        $lblShipValue.Text = "-"
        $lblCreditsValue.Text = "-"
        $lblHyperfuelValue.Text = "-"
        $lblCrewValue.Text = "-"
        $lblResearchValue.Text = "-"
        return
    }

    $s = Parse-Fields $response
    $world = ($s.ContainsKey("world") -and $s["world"] -eq "1")
    Set-ConnectedState $true $world

    if ($s.ContainsKey("version")) { $lblVersion.Text = "Mod v" + $s["version"] }
    if ($s.ContainsKey("ship")) { $lblShipValue.Text = $s["ship"] }
    if ($s.ContainsKey("credits")) { $lblCreditsValue.Text = $s["credits"] }
    if ($s.ContainsKey("hyperfuel")) { $lblHyperfuelValue.Text = $s["hyperfuel"] }
    if ($s.ContainsKey("crew")) { $lblCrewValue.Text = $s["crew"] }
    if ($s.ContainsKey("researchDone") -and $s.ContainsKey("researchTotal")) {
        $lblResearchValue.Text = $s["researchDone"] + " / " + $s["researchTotal"]
        $lblResearchProgress.Text = "Ricerca completata: " + $s["researchDone"] + " / " + $s["researchTotal"]
    }

    $script:UpdatingUI = $true
    try {
        if ($s.ContainsKey("infiniteResources")) { $chkInfiniteResources.Checked = ($s["infiniteResources"] -eq "1") }
        if ($s.ContainsKey("infiniteHealth")) { $chkHealth.Checked = ($s["infiniteHealth"] -eq "1") }
        if ($s.ContainsKey("infiniteOxygen")) { $chkOxygen.Checked = ($s["infiniteOxygen"] -eq "1") }
        if ($s.ContainsKey("stableFood")) { $chkFood.Checked = ($s["stableFood"] -eq "1") }
        if ($s.ContainsKey("stableRest")) { $chkRest.Checked = ($s["stableRest"] -eq "1") }
        if ($s.ContainsKey("stableMood")) { $chkMood.Checked = ($s["stableMood"] -eq "1") }
        if ($s.ContainsKey("stableComfort")) { $chkComfort.Checked = ($s["stableComfort"] -eq "1") }
        if ($s.ContainsKey("instantResearch")) { $chkInstantResearch.Checked = ($s["instantResearch"] -eq "1") }
    } finally {
        $script:UpdatingUI = $false
    }

    if ($world -and -not $script:InitialDataLoaded) {
        $script:InitialDataLoaded = $true
        Refresh-CrewList
        Refresh-TechList
    }
}

function Send-Action {
    param([string]$Request, [string]$SuccessMessage)
    $r = Send-TrainerRequest $Request 900
    if ([string]::IsNullOrEmpty($r)) {
        Set-ActionStatus "Connessione al mod persa." $true
        Set-ConnectedState $false $false
        return $false
    }
    if (-not $r.StartsWith("OK|")) {
        Set-ActionStatus ("Errore mod: " + $r) $true
        return $false
    }
    Set-ActionStatus $SuccessMessage $false
    return $true
}

function Get-SelectedCrewId {
    if ($null -eq $cmbCrew.SelectedItem) { return 0 }
    try { return [int]$cmbCrew.SelectedItem.Id } catch { return 0 }
}

function Refresh-CrewList {
    if (-not $script:Connected -or -not $script:WorldLoaded) { return }
    $r = Send-TrainerRequest "LIST_CREW" 900
    if ([string]::IsNullOrEmpty($r) -or -not $r.StartsWith("CREWLIST|")) { return }

    $oldId = Get-SelectedCrewId
    if ($oldId -le 0) { $oldId = $script:LastCrewId }

    $payload = $r.Substring(9)
    $items = New-Object System.Collections.ArrayList
    if (-not [string]::IsNullOrEmpty($payload)) {
        foreach ($entry in ($payload -split ';')) {
            if ([string]::IsNullOrEmpty($entry)) { continue }
            $parts = $entry -split '~', 2
            if ($parts.Count -lt 2) { continue }
            [void]$items.Add([pscustomobject]@{ Id = [int]$parts[0]; Display = (Decode-B64 $parts[1]) })
        }
    }

    $script:UpdatingCrewList = $true
    try {
        $cmbCrew.DataSource = $null
        $cmbCrew.DisplayMember = "Display"
        $cmbCrew.ValueMember = "Id"
        $cmbCrew.DataSource = $items

        $targetIndex = 0
        for ($i = 0; $i -lt $items.Count; $i++) {
            if ([int]$items[$i].Id -eq $oldId) { $targetIndex = $i; break }
        }
        if ($items.Count -gt 0) { $cmbCrew.SelectedIndex = $targetIndex }
    } finally {
        $script:UpdatingCrewList = $false
    }

    if ($items.Count -gt 0) { Load-CrewDetail }
}

function Load-CrewDetail {
    if ($script:UpdatingCrewList) { return }
    $crewId = Get-SelectedCrewId
    if ($crewId -le 0) { return }
    $script:LastCrewId = $crewId

    $r = Send-TrainerRequest ("GET_CREW|" + $crewId) 900
    if ([string]::IsNullOrEmpty($r) -or -not $r.StartsWith("CREWDETAIL|")) { return }
    $d = Parse-Fields $r

    $gridSkills.Rows.Clear()
    $gridAttrs.Rows.Clear()

    if ($d.ContainsKey("skills") -and -not [string]::IsNullOrEmpty($d["skills"])) {
        foreach ($entry in ($d["skills"] -split ';')) {
            $p = $entry -split ',', 4
            if ($p.Count -lt 4) { continue }
            [void]$gridSkills.Rows.Add([int]$p[0], (Decode-B64 $p[3]), [int]$p[1], [int]$p[2])
        }
    }

    if ($d.ContainsKey("attrs") -and -not [string]::IsNullOrEmpty($d["attrs"])) {
        foreach ($entry in ($d["attrs"] -split ';')) {
            $p = $entry -split ',', 3
            if ($p.Count -lt 3) { continue }
            [void]$gridAttrs.Rows.Add([int]$p[0], (Decode-B64 $p[2]), [int]$p[1])
        }
    }

    $conditionNames = @()
    if ($d.ContainsKey("negativeNames") -and -not [string]::IsNullOrEmpty($d["negativeNames"])) {
        foreach ($name64 in ($d["negativeNames"] -split ';')) {
            if (-not [string]::IsNullOrEmpty($name64)) { $conditionNames += (Decode-B64 $name64) }
        }
    }
    $count = $(if ($d.ContainsKey("negativeCount")) { [int]$d["negativeCount"] } else { 0 })
    if ($count -eq 0) {
        $lblConditions.Text = "Condizioni negative: nessuna"
        $lblConditions.ForeColor = $clrGood
    } else {
        $lblConditions.Text = "Condizioni negative: " + $count + " - " + ($conditionNames -join ", ")
        $lblConditions.ForeColor = $clrBad
    }
}

function Refresh-TechList {
    if (-not $script:Connected -or -not $script:WorldLoaded) { return }
    $r = Send-TrainerRequest "LIST_TECHS" 1200
    if ([string]::IsNullOrEmpty($r) -or -not $r.StartsWith("TECHLIST|")) { return }

    $selectedId = 0
    if ($gridTech.SelectedRows.Count -gt 0) {
        try { $selectedId = [int]$gridTech.SelectedRows[0].Cells["TechId"].Value } catch {}
    }

    $gridTech.Rows.Clear()
    $payload = $r.Substring(9)
    if (-not [string]::IsNullOrEmpty($payload)) {
        foreach ($entry in ($payload -split ';')) {
            $p = $entry -split '~', 4
            if ($p.Count -lt 4) { continue }
            $state = switch ($p[1]) {
                "DONE" { "Completata" }
                "QUEUED" { "In coda" }
                "AVAILABLE" { "Disponibile" }
                default { "Bloccata" }
            }
            $rowIndex = $gridTech.Rows.Add([int]$p[0], (Decode-B64 $p[3]), $state, $(if ($p[2] -eq "1") { "Si" } else { "No" }))
            if ([int]$p[0] -eq $selectedId) { $gridTech.Rows[$rowIndex].Selected = $true }
        }
    }
}

function Toggle-Setting {
    param([System.Windows.Forms.CheckBox]$CheckBox, [string]$Command, [string]$Label)
    if ($script:UpdatingUI -or -not $script:Connected -or -not $script:WorldLoaded) { return }
    $state = $(if ($CheckBox.Checked) { "1" } else { "0" })
    if (-not (Send-Action ($Command + "|" + $state) ($Label + $(if ($CheckBox.Checked) { ": ON" } else { ": OFF" })))) {
        Refresh-Status
    }
}

# Form and header
$form = New-Object System.Windows.Forms.Form
$form.Text = "Space Haven Live Trainer GUI v0.7.2"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(960, 800)
$form.MinimumSize = New-Object System.Drawing.Size(900, 720)
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.BackColor = $clrBack

$header = New-Object System.Windows.Forms.Panel
$header.Dock = "Top"
$header.Height = 92
$header.BackColor = $clrHeader
$form.Controls.Add($header)

$title = New-Object System.Windows.Forms.Label
$title.Text = "SPACE HAVEN LIVE TRAINER"
$title.ForeColor = [System.Drawing.Color]::White
$title.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 18)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(20, 12)
$header.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = "External GUI - nessun overlay in-game"
$subtitle.ForeColor = [System.Drawing.Color]::Gainsboro
$subtitle.AutoSize = $true
$subtitle.Location = New-Object System.Drawing.Point(22, 51)
$header.Controls.Add($subtitle)

$lblVersion = New-Object System.Windows.Forms.Label
$lblVersion.Text = "Mod v0.7.0"
$lblVersion.ForeColor = [System.Drawing.Color]::Gainsboro
$lblVersion.AutoSize = $true
$lblVersion.Location = New-Object System.Drawing.Point(830, 18)
$header.Controls.Add($lblVersion)

$chkTopMost = New-Object System.Windows.Forms.CheckBox
$chkTopMost.Text = "Sempre in primo piano"
$chkTopMost.ForeColor = [System.Drawing.Color]::White
$chkTopMost.AutoSize = $true
$chkTopMost.Location = New-Object System.Drawing.Point(775, 50)
$header.Controls.Add($chkTopMost)

# Live status strip
$statusPanel = New-Object System.Windows.Forms.Panel
$statusPanel.Dock = "Top"
$statusPanel.Height = 92
$statusPanel.BackColor = $clrPanel
$form.Controls.Add($statusPanel)
$statusPanel.BringToFront()

$lblConnection = New-Object System.Windows.Forms.Label
$lblConnection.Text = "MOD: NON CONNESSO"
$lblConnection.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
$lblConnection.AutoSize = $true
$lblConnection.Location = New-Object System.Drawing.Point(20, 10)
$statusPanel.Controls.Add($lblConnection)

$lblSubStatus = New-Object System.Windows.Forms.Label
$lblSubStatus.Text = "Avvia Space Haven dal Mod Loader."
$lblSubStatus.ForeColor = $clrMuted
$lblSubStatus.AutoSize = $true
$lblSubStatus.Location = New-Object System.Drawing.Point(20, 34)
$statusPanel.Controls.Add($lblSubStatus)

function Add-StatusPair {
    param([string]$Caption, [int]$X)
    $cap = New-Object System.Windows.Forms.Label
    $cap.Text = $Caption
    $cap.ForeColor = $clrMuted
    $cap.AutoSize = $true
    $cap.Location = New-Object System.Drawing.Point($X, 60)
    $statusPanel.Controls.Add($cap)

    $val = New-Object System.Windows.Forms.Label
    $val.Text = "-"
    $val.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
    $val.AutoSize = $true
    $val.Location = New-Object System.Drawing.Point(($X + 72), 60)
    $statusPanel.Controls.Add($val)
    return $val
}

$lblShipValue = Add-StatusPair "Nave:" 20
$lblCreditsValue = Add-StatusPair "Crediti:" 300
$lblHyperfuelValue = Add-StatusPair "Hyperfuel:" 475
$lblCrewValue = Add-StatusPair "Crew:" 655
$lblResearchValue = Add-StatusPair "Ricerca:" 770

$btnManualRefresh = New-FlatButton "AGGIORNA" 805 9 120 34
$statusPanel.Controls.Add($btnManualRefresh)

# Tabs
$tabs = New-Object System.Windows.Forms.TabControl
$tabs.Dock = "Fill"
$tabs.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
$form.Controls.Add($tabs)
$tabs.BringToFront()

$tabDashboard = New-Object System.Windows.Forms.TabPage
$tabDashboard.Text = "Dashboard"
$tabDashboard.BackColor = $clrBack
$tabs.TabPages.Add($tabDashboard)

$tabResources = New-Object System.Windows.Forms.TabPage
$tabResources.Text = "Risorse"
$tabResources.BackColor = $clrBack
$tabs.TabPages.Add($tabResources)

$tabCrew = New-Object System.Windows.Forms.TabPage
$tabCrew.Text = "Equipaggio"
$tabCrew.BackColor = $clrBack
$tabs.TabPages.Add($tabCrew)

$tabResearch = New-Object System.Windows.Forms.TabPage
$tabResearch.Text = "Ricerca"
$tabResearch.BackColor = $clrBack
$tabs.TabPages.Add($tabResearch)

# Dashboard
$dashTitle = New-Object System.Windows.Forms.Label
$dashTitle.Text = "Controllo live"
$dashTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 16)
$dashTitle.AutoSize = $true
$dashTitle.Location = New-Object System.Drawing.Point(24, 24)
$tabDashboard.Controls.Add($dashTitle)

$dashText = New-Object System.Windows.Forms.Label
$dashText.Text = "Le funzioni sono divise in schede per evitare comandi accidentali. Le hotkey F1-F10 restano attive e i toggle della GUI si sincronizzano automaticamente."
$dashText.Size = New-Object System.Drawing.Size(820, 48)
$dashText.Location = New-Object System.Drawing.Point(26, 62)
$dashText.ForeColor = $clrMuted
$tabDashboard.Controls.Add($dashText)

$dashHotkeys = New-Object System.Windows.Forms.GroupBox
$dashHotkeys.Text = "Hotkey"
$dashHotkeys.Location = New-Object System.Drawing.Point(24, 125)
$dashHotkeys.Size = New-Object System.Drawing.Size(855, 220)
$tabDashboard.Controls.Add($dashHotkeys)

$hotkeyText = New-Object System.Windows.Forms.Label
$hotkeyText.Text = "F1  +100.000 crediti`r`nF2  +50 Hyperfuel`r`nF3  Infinite Resources`r`nF4  Salute infinita`r`nF5  Ossigeno infinito`r`nF6  Fame stabile`r`nF7  Riposo stabile`r`nF8  Umore stabile`r`nF9  Comfort stabile`r`nF10 Ricerca istantanea"
$hotkeyText.Location = New-Object System.Drawing.Point(22, 28)
$hotkeyText.Size = New-Object System.Drawing.Size(330, 175)
$hotkeyText.Font = New-Object System.Drawing.Font("Consolas", 10)
$dashHotkeys.Controls.Add($hotkeyText)

$architectureText = New-Object System.Windows.Forms.Label
$architectureText.Text = "La finestra comunica solo con 127.0.0.1:17840. I comandi vengono accodati e applicati dal thread di aggiornamento del gioco."
$architectureText.Location = New-Object System.Drawing.Point(420, 40)
$architectureText.Size = New-Object System.Drawing.Size(380, 90)
$architectureText.ForeColor = $clrMuted
$dashHotkeys.Controls.Add($architectureText)

# Resources tab
$grpEconomy = New-Object System.Windows.Forms.GroupBox
$grpEconomy.Text = "Economia"
$grpEconomy.Location = New-Object System.Drawing.Point(20, 20)
$grpEconomy.Size = New-Object System.Drawing.Size(880, 95)
$tabResources.Controls.Add($grpEconomy)

$labCreditsAmount = New-Object System.Windows.Forms.Label
$labCreditsAmount.Text = "Crediti da aggiungere:"
$labCreditsAmount.AutoSize = $true
$labCreditsAmount.Location = New-Object System.Drawing.Point(20, 32)
$grpEconomy.Controls.Add($labCreditsAmount)

$numCredits = New-Object System.Windows.Forms.NumericUpDown
$numCredits.Minimum = 1
$numCredits.Maximum = 2000000000
$numCredits.Value = 100000
$numCredits.Increment = 10000
$numCredits.Location = New-Object System.Drawing.Point(165, 28)
$numCredits.Size = New-Object System.Drawing.Size(155, 28)
$grpEconomy.Controls.Add($numCredits)

$btnCredits = New-FlatButton "AGGIUNGI CREDITI" 340 24 175 36
$grpEconomy.Controls.Add($btnCredits)

$labF1 = New-Object System.Windows.Forms.Label
$labF1.Text = "F1 = +100.000"
$labF1.AutoSize = $true
$labF1.ForeColor = $clrMuted
$labF1.Location = New-Object System.Drawing.Point(540, 34)
$grpEconomy.Controls.Add($labF1)

$grpRes = New-Object System.Windows.Forms.GroupBox
$grpRes.Text = "Risorse"
$grpRes.Location = New-Object System.Drawing.Point(20, 130)
$grpRes.Size = New-Object System.Drawing.Size(880, 220)
$tabResources.Controls.Add($grpRes)

$labResource = New-Object System.Windows.Forms.Label
$labResource.Text = "Risorsa:"
$labResource.AutoSize = $true
$labResource.Location = New-Object System.Drawing.Point(20, 34)
$grpRes.Controls.Add($labResource)

$cmbResource = New-Object System.Windows.Forms.ComboBox
$cmbResource.DropDownStyle = "DropDownList"
$cmbResource.DisplayMember = "Display"
$cmbResource.Location = New-Object System.Drawing.Point(95, 30)
$cmbResource.Size = New-Object System.Drawing.Size(330, 28)
$grpRes.Controls.Add($cmbResource)

$resources = @(
    [pscustomobject]@{ Id=16; Display="Water [16]" },
    [pscustomobject]@{ Id=158; Display="Energium [158]" },
    [pscustomobject]@{ Id=172; Display="Hyperium [172]" },
    [pscustomobject]@{ Id=178; Display="Hyperfuel [178]" },
    [pscustomobject]@{ Id=162; Display="Infrablock [162]" },
    [pscustomobject]@{ Id=1759; Display="Hull Block [1759]" },
    [pscustomobject]@{ Id=1919; Display="Energy Block [1919]" },
    [pscustomobject]@{ Id=1921; Display="Soft Block [1921]" },
    [pscustomobject]@{ Id=930; Display="Techblock [930]" },
    [pscustomobject]@{ Id=712; Display="Space Food [712]" },
    [pscustomobject]@{ Id=707; Display="Artificial Meat [707]" },
    [pscustomobject]@{ Id=2475; Display="Fertilizer [2475]" },
    [pscustomobject]@{ Id=2053; Display="Medical Supplies [2053]" },
    [pscustomobject]@{ Id=2058; Display="IV Fluid [2058]" },
    [pscustomobject]@{ Id=157; Display="Base Metals [157]" },
    [pscustomobject]@{ Id=169; Display="Noble Metals [169]" },
    [pscustomobject]@{ Id=170; Display="Carbon [170]" },
    [pscustomobject]@{ Id=171; Display="Raw Chemicals [171]" },
    [pscustomobject]@{ Id=173; Display="Electronic Component [173]" },
    [pscustomobject]@{ Id=174; Display="Energy Rod [174]" },
    [pscustomobject]@{ Id=175; Display="Plastics [175]" },
    [pscustomobject]@{ Id=176; Display="Chemicals [176]" },
    [pscustomobject]@{ Id=177; Display="Fabrics [177]" },
    [pscustomobject]@{ Id=179; Display="Processed Food [179]" },
    [pscustomobject]@{ Id=1922; Display="Steel Plates [1922]" },
    [pscustomobject]@{ Id=1924; Display="Optronics Component [1924]" },
    [pscustomobject]@{ Id=1925; Display="Quantronics Component [1925]" },
    [pscustomobject]@{ Id=1926; Display="Energy Cell [1926]" },
    [pscustomobject]@{ Id=1932; Display="Fibers [1932]" },
    [pscustomobject]@{ Id=3196; Display="High Capacity Power [3196]" }
)
foreach ($r in $resources) { [void]$cmbResource.Items.Add($r) }
$cmbResource.SelectedIndex = 3

$labQty = New-Object System.Windows.Forms.Label
$labQty.Text = "Quantita:"
$labQty.AutoSize = $true
$labQty.Location = New-Object System.Drawing.Point(450, 34)
$grpRes.Controls.Add($labQty)

$numQty = New-Object System.Windows.Forms.NumericUpDown
$numQty.Minimum = 1
$numQty.Maximum = 1000000
$numQty.Value = 50
$numQty.Location = New-Object System.Drawing.Point(520, 30)
$numQty.Size = New-Object System.Drawing.Size(120, 28)
$grpRes.Controls.Add($numQty)

$btnAddResource = New-FlatButton "AGGIUNGI LIVE" 660 26 165 36
$grpRes.Controls.Add($btnAddResource)

$labPreset = New-Object System.Windows.Forms.Label
$labPreset.Text = "Preset:"
$labPreset.AutoSize = $true
$labPreset.Location = New-Object System.Drawing.Point(20, 83)
$grpRes.Controls.Add($labPreset)

$x = 95
foreach ($v in @(50,100,500,999,5000)) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = [string]$v
    $b.Tag = $v
    $b.Location = New-Object System.Drawing.Point($x, 75)
    $b.Size = New-Object System.Drawing.Size(70, 32)
    $b.Add_Click({ $numQty.Value = [decimal]$this.Tag })
    $grpRes.Controls.Add($b)
    $x += 78
}

$chkInfiniteResources = New-Object System.Windows.Forms.CheckBox
$chkInfiniteResources.Text = "Infinite Resources - reintegro fluido"
$chkInfiniteResources.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
$chkInfiniteResources.AutoSize = $true
$chkInfiniteResources.Location = New-Object System.Drawing.Point(22, 140)
$grpRes.Controls.Add($chkInfiniteResources)

$labF23 = New-Object System.Windows.Forms.Label
$labF23.Text = "F2 = +50 Hyperfuel     F3 = Infinite Resources"
$labF23.AutoSize = $true
$labF23.ForeColor = $clrMuted
$labF23.Location = New-Object System.Drawing.Point(22, 173)
$grpRes.Controls.Add($labF23)

# Crew tab
$grpCrewSelect = New-Object System.Windows.Forms.GroupBox
$grpCrewSelect.Text = "Membro equipaggio"
$grpCrewSelect.Location = New-Object System.Drawing.Point(18, 16)
$grpCrewSelect.Size = New-Object System.Drawing.Size(884, 76)
$tabCrew.Controls.Add($grpCrewSelect)

$cmbCrew = New-Object System.Windows.Forms.ComboBox
$cmbCrew.DropDownStyle = "DropDownList"
$cmbCrew.Location = New-Object System.Drawing.Point(18, 28)
$cmbCrew.Size = New-Object System.Drawing.Size(360, 28)
$grpCrewSelect.Controls.Add($cmbCrew)

$btnCrewRefresh = New-FlatButton "AGGIORNA CREW" 395 24 150 34
$grpCrewSelect.Controls.Add($btnCrewRefresh)

$lblConditions = New-Object System.Windows.Forms.Label
$lblConditions.Text = "Condizioni negative: -"
$lblConditions.Location = New-Object System.Drawing.Point(565, 27)
$lblConditions.Size = New-Object System.Drawing.Size(300, 38)
$lblConditions.ForeColor = $clrMuted
$grpCrewSelect.Controls.Add($lblConditions)

$grpCrewToggles = New-Object System.Windows.Forms.GroupBox
$grpCrewToggles.Text = "Sostentamento live"
$grpCrewToggles.Location = New-Object System.Drawing.Point(18, 102)
$grpCrewToggles.Size = New-Object System.Drawing.Size(884, 105)
$tabCrew.Controls.Add($grpCrewToggles)

function Add-CrewCheck {
    param([string]$Text, [string]$Hotkey, [int]$X, [int]$Y)
    $c = New-Object System.Windows.Forms.CheckBox
    $c.Text = $Text + "  [" + $Hotkey + "]"
    $c.AutoSize = $true
    $c.Location = New-Object System.Drawing.Point($X, $Y)
    $grpCrewToggles.Controls.Add($c)
    return $c
}

$chkHealth = Add-CrewCheck "Salute infinita" "F4" 20 28
$chkOxygen = Add-CrewCheck "Ossigeno infinito" "F5" 300 28
$chkFood = Add-CrewCheck "Fame stabile" "F6" 590 28
$chkRest = Add-CrewCheck "Riposo stabile" "F7" 20 65
$chkMood = Add-CrewCheck "Umore stabile" "F8" 300 65
$chkComfort = Add-CrewCheck "Comfort stabile" "F9" 590 65

$grpAdvanced = New-Object System.Windows.Forms.GroupBox
$grpAdvanced.Text = "Editor avanzato live"
$grpAdvanced.Location = New-Object System.Drawing.Point(18, 218)
$grpAdvanced.Size = New-Object System.Drawing.Size(884, 380)
$tabCrew.Controls.Add($grpAdvanced)

$gridSkills = New-Object System.Windows.Forms.DataGridView
$gridSkills.Location = New-Object System.Drawing.Point(16, 28)
$gridSkills.Size = New-Object System.Drawing.Size(525, 255)
Configure-Grid $gridSkills
[void]$gridSkills.Columns.Add("SkillId", "ID")
$gridSkills.Columns["SkillId"].Visible = $false
[void]$gridSkills.Columns.Add("SkillName", "Skill")
$gridSkills.Columns["SkillName"].ReadOnly = $true
[void]$gridSkills.Columns.Add("SkillLevel", "Livello")
[void]$gridSkills.Columns.Add("SkillMax", "Massimo")
$gridSkills.Columns["SkillName"].FillWeight = 180
$gridSkills.Columns["SkillLevel"].FillWeight = 55
$gridSkills.Columns["SkillMax"].FillWeight = 55
$grpAdvanced.Controls.Add($gridSkills)

$gridAttrs = New-Object System.Windows.Forms.DataGridView
$gridAttrs.Location = New-Object System.Drawing.Point(555, 28)
$gridAttrs.Size = New-Object System.Drawing.Size(310, 255)
Configure-Grid $gridAttrs
[void]$gridAttrs.Columns.Add("AttrId", "ID")
$gridAttrs.Columns["AttrId"].Visible = $false
[void]$gridAttrs.Columns.Add("AttrName", "Attributo")
$gridAttrs.Columns["AttrName"].ReadOnly = $true
[void]$gridAttrs.Columns.Add("AttrPoints", "Punti")
$gridAttrs.Columns["AttrName"].FillWeight = 160
$gridAttrs.Columns["AttrPoints"].FillWeight = 60
$grpAdvanced.Controls.Add($gridAttrs)

$btnCrewApply = New-FlatButton "APPLICA MODIFICHE" 16 305 170 38
$grpAdvanced.Controls.Add($btnCrewApply)
$btnMaxSkills = New-FlatButton "SKILL 10/10" 200 305 130 38
$grpAdvanced.Controls.Add($btnMaxSkills)
$btnMaxAttrs = New-FlatButton "ATTRIBUTI 5/5" 345 305 140 38
$grpAdvanced.Controls.Add($btnMaxAttrs)
$btnCure = New-FlatButton "CURA NEGATIVE" 500 305 145 38
$grpAdvanced.Controls.Add($btnCure)
$btnMaxCharacter = New-FlatButton "MAX PERSONAGGIO" 660 305 190 38
$grpAdvanced.Controls.Add($btnMaxCharacter)

$labCrewEditorNote = New-Object System.Windows.Forms.Label
$labCrewEditorNote.Text = "MAX PERSONAGGIO porta tutte le skill a 10/10 e tutti gli attributi a 5/5, che e il limite reale della build."
$labCrewEditorNote.Location = New-Object System.Drawing.Point(16, 350)
$labCrewEditorNote.Size = New-Object System.Drawing.Size(835, 24)
$labCrewEditorNote.ForeColor = $clrMuted
$grpAdvanced.Controls.Add($labCrewEditorNote)

# Research tab
$grpResearchTop = New-Object System.Windows.Forms.GroupBox
$grpResearchTop.Text = "Ricerca live"
$grpResearchTop.Location = New-Object System.Drawing.Point(18, 16)
$grpResearchTop.Size = New-Object System.Drawing.Size(884, 85)
$tabResearch.Controls.Add($grpResearchTop)

$chkInstantResearch = New-Object System.Windows.Forms.CheckBox
$chkInstantResearch.Text = "Ricerca istantanea  [F10]"
$chkInstantResearch.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
$chkInstantResearch.AutoSize = $true
$chkInstantResearch.Location = New-Object System.Drawing.Point(20, 31)
$grpResearchTop.Controls.Add($chkInstantResearch)

$lblResearchProgress = New-Object System.Windows.Forms.Label
$lblResearchProgress.Text = "Ricerca completata: -"
$lblResearchProgress.AutoSize = $true
$lblResearchProgress.Location = New-Object System.Drawing.Point(320, 34)
$grpResearchTop.Controls.Add($lblResearchProgress)

$btnTechRefresh = New-FlatButton "AGGIORNA" 720 24 135 36
$grpResearchTop.Controls.Add($btnTechRefresh)

$gridTech = New-Object System.Windows.Forms.DataGridView
$gridTech.Location = New-Object System.Drawing.Point(18, 115)
$gridTech.Size = New-Object System.Drawing.Size(884, 430)
Configure-Grid $gridTech
[void]$gridTech.Columns.Add("TechId", "ID")
$gridTech.Columns["TechId"].FillWeight = 35
[void]$gridTech.Columns.Add("TechName", "Tecnologia")
$gridTech.Columns["TechName"].FillWeight = 230
[void]$gridTech.Columns.Add("TechState", "Stato")
$gridTech.Columns["TechState"].FillWeight = 85
[void]$gridTech.Columns.Add("TechQueued", "In coda")
$gridTech.Columns["TechQueued"].FillWeight = 55
foreach ($col in $gridTech.Columns) { $col.ReadOnly = $true }
$tabResearch.Controls.Add($gridTech)

$btnCompleteTech = New-FlatButton "COMPLETA SELEZIONATA" 18 560 195 40
$tabResearch.Controls.Add($btnCompleteTech)
$btnCompleteAllTech = New-FlatButton "COMPLETA TUTTO" 230 560 165 40
$tabResearch.Controls.Add($btnCompleteAllTech)

$labResearchNote = New-Object System.Windows.Forms.Label
$labResearchNote.Text = "Completa Tutto ignora le tecnologie hidden/interne per non toccare sblocchi riservati a eventi o script."
$labResearchNote.Location = New-Object System.Drawing.Point(420, 565)
$labResearchNote.Size = New-Object System.Drawing.Size(470, 40)
$labResearchNote.ForeColor = $clrMuted
$tabResearch.Controls.Add($labResearchNote)

# Bottom status
$bottom = New-Object System.Windows.Forms.Panel
$bottom.Dock = "Bottom"
$bottom.Height = 34
$bottom.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($bottom)
$bottom.BringToFront()

$lblBottomStatus = New-Object System.Windows.Forms.Label
$lblBottomStatus.Text = "Pronto."
$lblBottomStatus.AutoSize = $true
$lblBottomStatus.Location = New-Object System.Drawing.Point(14, 9)
$lblBottomStatus.ForeColor = $clrMuted
$bottom.Controls.Add($lblBottomStatus)

# Events
$chkTopMost.Add_CheckedChanged({ $form.TopMost = $chkTopMost.Checked })
$btnManualRefresh.Add_Click({ Refresh-Status; Refresh-CrewList; Refresh-TechList })

$btnCredits.Add_Click({
    [void](Send-Action ("ADD_CREDITS|" + [int]$numCredits.Value) ("Aggiunti " + [int]$numCredits.Value + " crediti."))
})

$btnAddResource.Add_Click({
    if ($null -eq $cmbResource.SelectedItem) { return }
    $rid = [int]$cmbResource.SelectedItem.Id
    $qty = [int]$numQty.Value
    [void](Send-Action ("ADD_RESOURCE|" + $rid + "|" + $qty) ("Aggiunta risorsa ID " + $rid + ": +" + $qty))
})

$chkInfiniteResources.Add_CheckedChanged({ Toggle-Setting $chkInfiniteResources "SET_INFINITE_RESOURCES" "Infinite Resources" })
$chkHealth.Add_CheckedChanged({ Toggle-Setting $chkHealth "SET_INFINITE_HEALTH" "Salute infinita" })
$chkOxygen.Add_CheckedChanged({ Toggle-Setting $chkOxygen "SET_INFINITE_OXYGEN" "Ossigeno infinito" })
$chkFood.Add_CheckedChanged({ Toggle-Setting $chkFood "SET_STABLE_FOOD" "Fame stabile" })
$chkRest.Add_CheckedChanged({ Toggle-Setting $chkRest "SET_STABLE_REST" "Riposo stabile" })
$chkMood.Add_CheckedChanged({ Toggle-Setting $chkMood "SET_STABLE_MOOD" "Umore stabile" })
$chkComfort.Add_CheckedChanged({ Toggle-Setting $chkComfort "SET_STABLE_COMFORT" "Comfort stabile" })
$chkInstantResearch.Add_CheckedChanged({ Toggle-Setting $chkInstantResearch "SET_INSTANT_RESEARCH" "Ricerca istantanea" })

$btnCrewRefresh.Add_Click({ Refresh-CrewList })
$cmbCrew.Add_SelectedIndexChanged({ if (-not $script:UpdatingCrewList) { Load-CrewDetail } })

$btnCrewApply.Add_Click({
    $crewId = Get-SelectedCrewId
    if ($crewId -le 0) { return }
    $skills = @()
    foreach ($row in $gridSkills.Rows) {
        try {
            $sid = [int]$row.Cells["SkillId"].Value
            $lvl = [int]$row.Cells["SkillLevel"].Value
            $max = [int]$row.Cells["SkillMax"].Value
            if ($lvl -lt 0) { $lvl = 0 }
            if ($max -lt $lvl) { $max = $lvl }
            $skills += ($sid.ToString() + "," + $lvl.ToString() + "," + $max.ToString())
        } catch {}
    }
    $attrs = @()
    foreach ($row in $gridAttrs.Rows) {
        try {
            $aid = [int]$row.Cells["AttrId"].Value
            $pts = [int]$row.Cells["AttrPoints"].Value
            if ($pts -lt 1) { $pts = 1 }
            $attrs += ($aid.ToString() + "," + $pts.ToString())
        } catch {}
    }
    $sp = $(if ($skills.Count -gt 0) { $skills -join ";" } else { "-" })
    $ap = $(if ($attrs.Count -gt 0) { $attrs -join ";" } else { "-" })
    if (Send-Action ("APPLY_CREW|" + $crewId + "|" + $sp + "|" + $ap) "Skill e attributi inviati al gioco.") {
        Start-Sleep -Milliseconds 350
        Load-CrewDetail
    }
})

$btnMaxSkills.Add_Click({
    $crewId = Get-SelectedCrewId
    if ($crewId -le 0) { return }
    if (Send-Action ("MAX_CREW_SKILLS|" + $crewId) "Max Skills applicato.") {
        Start-Sleep -Milliseconds 350
        Load-CrewDetail
    }
})

$btnMaxAttrs.Add_Click({
    $crewId = Get-SelectedCrewId
    if ($crewId -le 0) { return }
    if (Send-Action ("MAX_CREW_ATTRS|" + $crewId) "Max Attributi applicato.") {
        Start-Sleep -Milliseconds 350
        Load-CrewDetail
    }
})

$btnMaxCharacter.Add_Click({
    $crewId = Get-SelectedCrewId
    if ($crewId -le 0) { return }

    $okSkills = Send-Action ("MAX_CREW_SKILLS|" + $crewId) "Skill del personaggio portate a 10/10."
    if (-not $okSkills) { return }

    Start-Sleep -Milliseconds 120

    $okAttrs = Send-Action ("MAX_CREW_ATTRS|" + $crewId) "Personaggio maxato: skill 10/10, attributi 5/5."
    if ($okAttrs) {
        Start-Sleep -Milliseconds 400
        Load-CrewDetail
    }
})

$btnCure.Add_Click({
    $crewId = Get-SelectedCrewId
    if ($crewId -le 0) { return }
    if (Send-Action ("CURE_CREW_NEGATIVE|" + $crewId) "Rimozione condizioni negative richiesta.") {
        Start-Sleep -Milliseconds 350
        Load-CrewDetail
    }
})

$btnTechRefresh.Add_Click({ Refresh-TechList })
$btnCompleteTech.Add_Click({
    if ($gridTech.SelectedRows.Count -eq 0) {
        Set-ActionStatus "Seleziona prima una tecnologia." $true
        return
    }
    $techId = [int]$gridTech.SelectedRows[0].Cells["TechId"].Value
    $techName = [string]$gridTech.SelectedRows[0].Cells["TechName"].Value
    if (Send-Action ("COMPLETE_TECH|" + $techId) ("Ricerca completata: " + $techName)) {
        Start-Sleep -Milliseconds 400
        Refresh-TechList
        Refresh-Status
    }
})

$btnCompleteAllTech.Add_Click({
    $answer = [System.Windows.Forms.MessageBox]::Show(
        "Completare tutte le tecnologie visibili della ricerca? Le tecnologie hidden/interne verranno ignorate.",
        "Space Haven Live Trainer",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) { return }
    if (Send-Action "COMPLETE_ALL_TECH" "Completamento di tutte le ricerche visibili richiesto.") {
        Start-Sleep -Milliseconds 600
        Refresh-TechList
        Refresh-Status
    }
})

$tabs.Add_SelectedIndexChanged({
    if (-not $script:Connected -or -not $script:WorldLoaded) { return }
    if ($tabs.SelectedTab -eq $tabCrew) { Refresh-CrewList }
    if ($tabs.SelectedTab -eq $tabResearch) { Refresh-TechList }
})

$refreshTimer = New-Object System.Windows.Forms.Timer
$refreshTimer.Interval = 1100
$refreshTimer.Add_Tick({ Refresh-Status })

$form.Add_Shown({
    Set-ConnectedState $false $false
    Refresh-Status
    $refreshTimer.Start()
})

$form.Add_FormClosed({ $refreshTimer.Stop() })

[void]$form.ShowDialog()
