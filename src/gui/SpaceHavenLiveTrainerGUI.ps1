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
$script:TechCache = New-Object System.Collections.ArrayList
$script:Language = "it"
$script:SettingsPath = Join-Path $PSScriptRoot "settings.ini"

# Modern dark palette
$clrBack = [System.Drawing.Color]::FromArgb(16, 19, 26)
$clrHeader = [System.Drawing.Color]::FromArgb(20, 24, 32)
$clrSidebar = [System.Drawing.Color]::FromArgb(23, 28, 37)
$clrPanel = [System.Drawing.Color]::FromArgb(29, 35, 46)
$clrPanelAlt = [System.Drawing.Color]::FromArgb(35, 42, 54)
$clrBorder = [System.Drawing.Color]::FromArgb(53, 62, 78)
$clrAccent = [System.Drawing.Color]::FromArgb(72, 126, 255)
$clrAccentHover = [System.Drawing.Color]::FromArgb(91, 142, 255)
$clrText = [System.Drawing.Color]::FromArgb(238, 242, 248)
$clrMuted = [System.Drawing.Color]::FromArgb(151, 162, 179)
$clrGood = [System.Drawing.Color]::FromArgb(67, 190, 126)
$clrWarn = [System.Drawing.Color]::FromArgb(244, 177, 80)
$clrBad = [System.Drawing.Color]::FromArgb(232, 92, 103)
$clrToggleOff = [System.Drawing.Color]::FromArgb(42, 49, 62)
$clrGridHeader = [System.Drawing.Color]::FromArgb(40, 48, 62)
$clrGridSelection = [System.Drawing.Color]::FromArgb(53, 85, 151)

$script:Strings = @{
    it = @{
        app_title = "SPACE HAVEN LIVE TRAINER"
        subtitle = "Pannello esterno - nessun overlay in-game"
        language = "Lingua"
        topmost = "Sempre in primo piano"
        nav_dashboard = "Dashboard"
        nav_resources = "Risorse"
        nav_crew = "Equipaggio"
        nav_research = "Ricerca"
        author = "Autore: Luca Cococcioni"

        conn_off = "MOD NON CONNESSO"
        conn_wait = "MOD CONNESSO"
        conn_live = "MOD CONNESSO / LIVE"
        conn_off_sub = "Avvia Space Haven dal Mod Loader."
        conn_wait_sub = "Mod rilevato. Carica una partita."
        conn_live_sub = "Collegamento locale sicuro: 127.0.0.1:17840"
        ready = "Pronto."
        connection_lost = "Connessione al mod persa."
        mod_error = "Errore mod: "

        stat_ship = "Nave"
        stat_credits = "Crediti"
        stat_hyperfuel = "Hyperfuel"
        stat_crew = "Equipaggio"
        stat_research = "Ricerca"

        dashboard_title = "Panoramica live"
        dashboard_desc = "Controlla lo stato della partita e accedi rapidamente alle funzioni principali. Hotkey e GUI rimangono sincronizzate."
        active_title = "Funzioni attive"
        active_none = "Nessun toggle attivo."
        quick_title = "Azioni rapide"
        quick_refresh = "AGGIORNA TUTTO"
        quick_credits = "+100.000 CREDITI"
        quick_resources = "APRI RISORSE"
        architecture_title = "Come lavora il trainer"
        architecture_text = "La GUI comunica solamente con il mod su localhost. I comandi vengono messi in coda e applicati durante il normale aggiornamento di Space Haven."
        hotkeys_title = "Hotkey"
        hk_resources = "F3  Risorse infinite"
        hk_health = "F4  Salute infinita"
        hk_oxygen = "F5  Ossigeno infinito"
        hk_food = "F6  Fame stabile"
        hk_rest = "F7  Riposo stabile"
        hk_mood = "F8  Umore stabile"
        hk_comfort = "F9  Comfort stabile"
        hk_research = "F10 Ricerca istantanea"

        resources_title = "Economia e risorse"
        resources_desc = "Aggiungi crediti o materiali senza modificare manualmente il salvataggio."
        economy = "Economia"
        credits_amount = "Crediti da aggiungere"
        add_credits = "AGGIUNGI CREDITI"
        f1_hint = "F1 = +100.000"
        resource_card = "Materiali"
        resource = "Risorsa"
        quantity = "Quantità"
        add_live = "AGGIUNGI LIVE"
        preset = "Preset"
        infinite_resources = "Risorse infinite"
        infinite_resources_desc = "Reintegro fluido senza bloccare la logistica del gioco."
        f2_f3_hint = "F2 = +50 Hyperfuel   |   F3 = Risorse infinite"

        crew_title = "Gestione equipaggio"
        crew_desc = "Sostentamento, skill e attributi del membro selezionato."
        crew_member = "Membro equipaggio"
        refresh_crew = "AGGIORNA"
        conditions_none = "Condizioni negative: nessuna"
        conditions = "Condizioni negative: {0} - {1}"
        conditions_unknown = "Condizioni negative: -"
        sustain = "Sostentamento live"
        health = "Salute infinita"
        oxygen = "Ossigeno infinito"
        food = "Fame stabile"
        rest = "Riposo stabile"
        mood = "Umore stabile"
        comfort = "Comfort stabile"
        advanced = "Editor avanzato"
        skill = "Skill"
        level = "Livello"
        maximum = "Massimo"
        attribute = "Attributo"
        points = "Punti"
        apply_changes = "APPLICA MODIFICHE"
        max_skills = "SKILL 10/10"
        max_attrs = "ATTRIBUTI 5/5"
        cure_negative = "CURA NEGATIVE"
        max_character = "MAX PERSONAGGIO"
        crew_note = "MAX PERSONAGGIO porta tutte le skill a 10/10 e gli attributi al limite reale 5/5."

        research_title = "Ricerca"
        research_desc = "Gestisci l'albero tecnologico live usando la logica di sblocco interna del gioco."
        instant_research = "Ricerca istantanea"
        research_progress = "Completata: {0} / {1}"
        research_progress_empty = "Completata: -"
        search_tech = "Cerca tecnologia..."
        refresh = "AGGIORNA"
        tech_id = "ID"
        technology = "Tecnologia"
        state = "Stato"
        queued = "In coda"
        yes = "Sì"
        no = "No"
        state_done = "Completata"
        state_queued = "In coda"
        state_available = "Disponibile"
        state_locked = "Bloccata"
        complete_selected = "COMPLETA SELEZIONATA"
        complete_all = "COMPLETA TUTTO"
        research_note = "Completa Tutto ignora le tecnologie hidden/interne per non alterare contenuti riservati a eventi o script."
        select_tech_first = "Seleziona prima una tecnologia."
        confirm_all_title = "Conferma ricerca"
        confirm_all = "Completare tutte le tecnologie visibili? Le tecnologie hidden/interne verranno ignorate."

        credits_added = "Aggiunti {0} crediti."
        resource_added = "Risorsa ID {0}: +{1}"
        crew_applied = "Skill e attributi inviati al gioco."
        max_skills_done = "Skill portate a 10/10."
        max_attrs_done = "Attributi portati a 5/5."
        max_character_done = "Personaggio maxato: skill 10/10, attributi 5/5."
        cure_requested = "Rimozione condizioni negative richiesta."
        tech_completed = "Ricerca completata: {0}"
        all_tech_requested = "Completamento di tutte le ricerche visibili richiesto."
        lang_changed = "Lingua impostata: Italiano"
    }

    en = @{
        app_title = "SPACE HAVEN LIVE TRAINER"
        subtitle = "External control panel - no in-game overlay"
        language = "Language"
        topmost = "Always on top"
        nav_dashboard = "Dashboard"
        nav_resources = "Resources"
        nav_crew = "Crew"
        nav_research = "Research"
        author = "Author: Luca Cococcioni"

        conn_off = "MOD NOT CONNECTED"
        conn_wait = "MOD CONNECTED"
        conn_live = "MOD CONNECTED / LIVE"
        conn_off_sub = "Start Space Haven through the Mod Loader."
        conn_wait_sub = "Mod detected. Load a game."
        conn_live_sub = "Secure local link: 127.0.0.1:17840"
        ready = "Ready."
        connection_lost = "Connection to the mod was lost."
        mod_error = "Mod error: "

        stat_ship = "Ship"
        stat_credits = "Credits"
        stat_hyperfuel = "Hyperfuel"
        stat_crew = "Crew"
        stat_research = "Research"

        dashboard_title = "Live overview"
        dashboard_desc = "Monitor the current game and quickly access the main trainer functions. Hotkeys and GUI stay synchronized."
        active_title = "Active features"
        active_none = "No toggle is currently active."
        quick_title = "Quick actions"
        quick_refresh = "REFRESH ALL"
        quick_credits = "+100,000 CREDITS"
        quick_resources = "OPEN RESOURCES"
        architecture_title = "How the trainer works"
        architecture_text = "The GUI talks only to the local mod through localhost. Commands are queued and applied during Space Haven's normal update cycle."
        hotkeys_title = "Hotkeys"
        hk_resources = "F3  Infinite Resources"
        hk_health = "F4  Infinite Health"
        hk_oxygen = "F5  Infinite Oxygen"
        hk_food = "F6  Stable Food"
        hk_rest = "F7  Stable Rest"
        hk_mood = "F8  Stable Mood"
        hk_comfort = "F9  Stable Comfort"
        hk_research = "F10 Instant Research"

        resources_title = "Economy and resources"
        resources_desc = "Add credits or materials live without manually editing the save file."
        economy = "Economy"
        credits_amount = "Credits to add"
        add_credits = "ADD CREDITS"
        f1_hint = "F1 = +100,000"
        resource_card = "Materials"
        resource = "Resource"
        quantity = "Quantity"
        add_live = "ADD LIVE"
        preset = "Presets"
        infinite_resources = "Infinite Resources"
        infinite_resources_desc = "Smooth replenishment without blocking the game's logistics."
        f2_f3_hint = "F2 = +50 Hyperfuel   |   F3 = Infinite Resources"

        crew_title = "Crew management"
        crew_desc = "Sustain, skills and attributes for the selected crew member."
        crew_member = "Crew member"
        refresh_crew = "REFRESH"
        conditions_none = "Negative conditions: none"
        conditions = "Negative conditions: {0} - {1}"
        conditions_unknown = "Negative conditions: -"
        sustain = "Live sustain"
        health = "Infinite Health"
        oxygen = "Infinite Oxygen"
        food = "Stable Food"
        rest = "Stable Rest"
        mood = "Stable Mood"
        comfort = "Stable Comfort"
        advanced = "Advanced editor"
        skill = "Skill"
        level = "Level"
        maximum = "Maximum"
        attribute = "Attribute"
        points = "Points"
        apply_changes = "APPLY CHANGES"
        max_skills = "SKILLS 10/10"
        max_attrs = "ATTRIBUTES 5/5"
        cure_negative = "CURE NEGATIVE"
        max_character = "MAX CHARACTER"
        crew_note = "MAX CHARACTER sets all skills to 10/10 and attributes to the game's real 5/5 limit."

        research_title = "Research"
        research_desc = "Manage the technology tree live using the game's own unlock logic."
        instant_research = "Instant Research"
        research_progress = "Completed: {0} / {1}"
        research_progress_empty = "Completed: -"
        search_tech = "Search technology..."
        refresh = "REFRESH"
        tech_id = "ID"
        technology = "Technology"
        state = "State"
        queued = "Queued"
        yes = "Yes"
        no = "No"
        state_done = "Completed"
        state_queued = "Queued"
        state_available = "Available"
        state_locked = "Locked"
        complete_selected = "COMPLETE SELECTED"
        complete_all = "COMPLETE ALL"
        research_note = "Complete All ignores hidden/internal technologies to avoid touching content reserved for events or scripts."
        select_tech_first = "Select a technology first."
        confirm_all_title = "Confirm research"
        confirm_all = "Complete all visible technologies? Hidden/internal technologies will be ignored."

        credits_added = "Added {0} credits."
        resource_added = "Resource ID {0}: +{1}"
        crew_applied = "Skills and attributes sent to the game."
        max_skills_done = "Skills set to 10/10."
        max_attrs_done = "Attributes set to 5/5."
        max_character_done = "Character maxed: skills 10/10, attributes 5/5."
        cure_requested = "Negative-condition removal requested."
        tech_completed = "Research completed: {0}"
        all_tech_requested = "Completion of all visible research requested."
        lang_changed = "Language set to English"
    }
}

function Get-Text {
    param([string]$Key)
    if ($script:Strings.ContainsKey($script:Language)) {
        $langMap = $script:Strings[$script:Language]
        if ($langMap.ContainsKey($Key)) { return [string]$langMap[$Key] }
    }
    return $Key
}

function Format-Text {
    param([string]$Key, [object[]]$Values)
    $format = Get-Text $Key
    try { return [string]::Format($format, $Values) } catch { return $format }
}

function Load-GuiSettings {
    if (-not (Test-Path $script:SettingsPath)) { return }
    try {
        foreach ($line in (Get-Content -LiteralPath $script:SettingsPath)) {
            if ($line -match '^\s*Language\s*=\s*(it|en)\s*$') {
                $script:Language = $Matches[1]
            }
        }
    } catch {}
}

function Save-GuiSettings {
    try {
        ("Language=" + $script:Language) | Set-Content -LiteralPath $script:SettingsPath -Encoding ASCII
    } catch {}
}

Load-GuiSettings

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

        # Windows PowerShell 5.1's Encoding.UTF8 emits a BOM.
        # Use UTF-8 without BOM on the TCP protocol.
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

    foreach ($part in ($Response -split '\|')) {
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
        return [System.Text.Encoding]::UTF8.GetString(
            [System.Convert]::FromBase64String($Value)
        )
    } catch {
        return $Value
    }
}

function New-Panel {
    param([System.Windows.Forms.Control]$Parent, [int]$X, [int]$Y, [int]$W, [int]$H)

    $p = New-Object System.Windows.Forms.Panel
    $p.Location = New-Object System.Drawing.Point($X, $Y)
    $p.Size = New-Object System.Drawing.Size($W, $H)
    $p.BackColor = $clrPanel
    $Parent.Controls.Add($p)
    return $p
}

function New-PrimaryButton {
    param([string]$Text, [int]$X, [int]$Y, [int]$W, [int]$H)

    $b = New-Object System.Windows.Forms.Button
    $b.Text = $Text
    $b.Location = New-Object System.Drawing.Point($X, $Y)
    $b.Size = New-Object System.Drawing.Size($W, $H)
    $b.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $b.FlatAppearance.BorderSize = 0
    $b.BackColor = $clrAccent
    $b.ForeColor = [System.Drawing.Color]::White
    $b.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    $b.Add_MouseEnter({ if ($this.Enabled) { $this.BackColor = $clrAccentHover } })
    $b.Add_MouseLeave({ if ($this.Enabled) { $this.BackColor = $clrAccent } })
    return $b
}

function New-SecondaryButton {
    param([string]$Text, [int]$X, [int]$Y, [int]$W, [int]$H)

    $b = New-Object System.Windows.Forms.Button
    $b.Text = $Text
    $b.Location = New-Object System.Drawing.Point($X, $Y)
    $b.Size = New-Object System.Drawing.Size($W, $H)
    $b.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $b.FlatAppearance.BorderColor = $clrBorder
    $b.FlatAppearance.BorderSize = 1
    $b.BackColor = $clrPanelAlt
    $b.ForeColor = $clrText
    $b.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    return $b
}

function New-ToggleButton {
    param([string]$Text, [int]$X, [int]$Y, [int]$W, [int]$H)

    $c = New-Object System.Windows.Forms.CheckBox
    $c.Appearance = [System.Windows.Forms.Appearance]::Button
    $c.Text = $Text
    $c.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $c.Location = New-Object System.Drawing.Point($X, $Y)
    $c.Size = New-Object System.Drawing.Size($W, $H)
    $c.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $c.FlatAppearance.BorderColor = $clrBorder
    $c.FlatAppearance.BorderSize = 1
    $c.BackColor = $clrToggleOff
    $c.ForeColor = $clrText
    $c.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
    $c.Cursor = [System.Windows.Forms.Cursors]::Hand
    $c.UseVisualStyleBackColor = $false
    return $c
}

function Update-ToggleVisual {
    param([System.Windows.Forms.CheckBox]$Toggle)

    if ($null -eq $Toggle) { return }

    if ($Toggle.Checked) {
        $Toggle.BackColor = $clrAccent
        $Toggle.FlatAppearance.BorderColor = $clrAccent
        $Toggle.ForeColor = [System.Drawing.Color]::White
    } else {
        $Toggle.BackColor = $clrToggleOff
        $Toggle.FlatAppearance.BorderColor = $clrBorder
        $Toggle.ForeColor = $clrText
    }
}

function Configure-Grid {
    param([System.Windows.Forms.DataGridView]$Grid)

    $Grid.AllowUserToAddRows = $false
    $Grid.AllowUserToDeleteRows = $false
    $Grid.AllowUserToResizeRows = $false
    $Grid.RowHeadersVisible = $false
    $Grid.SelectionMode = [System.Windows.Forms.DataGridViewSelectionMode]::FullRowSelect
    $Grid.MultiSelect = $false
    $Grid.BackgroundColor = $clrPanel
    $Grid.GridColor = $clrBorder
    $Grid.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $Grid.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
    $Grid.EnableHeadersVisualStyles = $false
    $Grid.ColumnHeadersHeight = 34
    $Grid.RowTemplate.Height = 30
    $Grid.DefaultCellStyle.BackColor = $clrPanel
    $Grid.DefaultCellStyle.ForeColor = $clrText
    $Grid.DefaultCellStyle.SelectionBackColor = $clrGridSelection
    $Grid.DefaultCellStyle.SelectionForeColor = [System.Drawing.Color]::White
    $Grid.DefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $Grid.ColumnHeadersDefaultCellStyle.BackColor = $clrGridHeader
    $Grid.ColumnHeadersDefaultCellStyle.ForeColor = $clrText
    $Grid.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
}

function New-SectionTitle {
    param([System.Windows.Forms.Control]$Parent, [int]$X, [int]$Y)

    $l = New-Object System.Windows.Forms.Label
    $l.Location = New-Object System.Drawing.Point($X, $Y)
    $l.AutoSize = $true
    $l.ForeColor = $clrText
    $l.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 17)
    $Parent.Controls.Add($l)
    return $l
}

function New-SectionDescription {
    param([System.Windows.Forms.Control]$Parent, [int]$X, [int]$Y, [int]$W)

    $l = New-Object System.Windows.Forms.Label
    $l.Location = New-Object System.Drawing.Point($X, $Y)
    $l.Size = New-Object System.Drawing.Size($W, 38)
    $l.ForeColor = $clrMuted
    $l.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $Parent.Controls.Add($l)
    return $l
}

function New-CardCaption {
    param([System.Windows.Forms.Control]$Parent, [int]$X, [int]$Y)

    $l = New-Object System.Windows.Forms.Label
    $l.Location = New-Object System.Drawing.Point($X, $Y)
    $l.AutoSize = $true
    $l.ForeColor = $clrMuted
    $l.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
    $Parent.Controls.Add($l)
    return $l
}

function New-CardValue {
    param([System.Windows.Forms.Control]$Parent, [int]$X, [int]$Y)

    $l = New-Object System.Windows.Forms.Label
    $l.Location = New-Object System.Drawing.Point($X, $Y)
    $l.AutoSize = $true
    $l.Text = "-"
    $l.ForeColor = $clrText
    $l.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 15)
    $Parent.Controls.Add($l)
    return $l
}

function Set-ActionStatus {
    param([string]$Message, [bool]$Error = $false)

    $lblBottomStatus.Text = $Message
    $lblBottomStatus.ForeColor = $(if ($Error) { $clrBad } else { $clrGood })
}

function Show-Page {
    param([string]$Name)

    foreach ($entry in $script:Pages.GetEnumerator()) {
        $entry.Value.Visible = ($entry.Key -eq $Name)
    }

    foreach ($entry in $script:NavButtons.GetEnumerator()) {
        if ($entry.Key -eq $Name) {
            $entry.Value.BackColor = $clrAccent
            $entry.Value.ForeColor = [System.Drawing.Color]::White
        } else {
            $entry.Value.BackColor = $clrSidebar
            $entry.Value.ForeColor = $clrMuted
        }
    }

    if ($Name -eq "crew" -and $script:Connected -and $script:WorldLoaded) {
        Refresh-CrewList
    }

    if ($Name -eq "research" -and $script:Connected -and $script:WorldLoaded) {
        Refresh-TechList
    }
}

function Set-ConnectedState {
    param([bool]$Connected, [bool]$WorldLoaded)

    $wasReady = ($script:Connected -and $script:WorldLoaded)
    $script:Connected = $Connected
    $script:WorldLoaded = $WorldLoaded
    $ready = ($Connected -and $WorldLoaded)

    if (-not $Connected) {
        $lblConnection.Text = Get-Text "conn_off"
        $lblConnection.ForeColor = $clrBad
        $lblSubStatus.Text = Get-Text "conn_off_sub"
        $connDot.BackColor = $clrBad
    } elseif (-not $WorldLoaded) {
        $lblConnection.Text = Get-Text "conn_wait"
        $lblConnection.ForeColor = $clrWarn
        $lblSubStatus.Text = Get-Text "conn_wait_sub"
        $connDot.BackColor = $clrWarn
    } else {
        $lblConnection.Text = Get-Text "conn_live"
        $lblConnection.ForeColor = $clrGood
        $lblSubStatus.Text = Get-Text "conn_live_sub"
        $connDot.BackColor = $clrGood
    }

    foreach ($ctrl in @(
        $btnCredits, $btnDashCredits, $btnAddResource, $chkInfiniteResources,
        $chkHealth, $chkOxygen, $chkFood, $chkRest, $chkMood, $chkComfort,
        $btnCrewRefresh, $cmbCrew, $btnCrewApply, $btnMaxSkills, $btnMaxAttrs,
        $btnCure, $btnMaxCharacter, $btnTechRefresh, $gridTech,
        $btnCompleteTech, $btnCompleteAllTech, $chkInstantResearch, $txtTechSearch
    )) {
        if ($null -ne $ctrl) { $ctrl.Enabled = $ready }
    }

    if ($ready -and -not $wasReady) {
        $script:InitialDataLoaded = $false
    }
}

function Update-ActiveFeatures {
    $items = @()

    if ($chkInfiniteResources.Checked) { $items += (Get-Text "infinite_resources") }
    if ($chkHealth.Checked) { $items += (Get-Text "health") }
    if ($chkOxygen.Checked) { $items += (Get-Text "oxygen") }
    if ($chkFood.Checked) { $items += (Get-Text "food") }
    if ($chkRest.Checked) { $items += (Get-Text "rest") }
    if ($chkMood.Checked) { $items += (Get-Text "mood") }
    if ($chkComfort.Checked) { $items += (Get-Text "comfort") }
    if ($chkInstantResearch.Checked) { $items += (Get-Text "instant_research") }

    if ($items.Count -eq 0) {
        $lblActiveFeatures.Text = Get-Text "active_none"
        $lblActiveFeatures.ForeColor = $clrMuted
    } else {
        $lblActiveFeatures.Text = ($items -join "   |   ")
        $lblActiveFeatures.ForeColor = $clrGood
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
        $lblResearchProgress.Text = Get-Text "research_progress_empty"
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
        $lblResearchProgress.Text = Format-Text "research_progress" @($s["researchDone"], $s["researchTotal"])
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

    Update-ActiveFeatures

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
        Set-ActionStatus (Get-Text "connection_lost") $true
        Set-ConnectedState $false $false
        return $false
    }

    if (-not $r.StartsWith("OK|")) {
        Set-ActionStatus ((Get-Text "mod_error") + $r) $true
        return $false
    }

    Set-ActionStatus $SuccessMessage $false
    return $true
}

function Toggle-Setting {
    param(
        [System.Windows.Forms.CheckBox]$CheckBox,
        [string]$Command,
        [string]$LabelKey
    )

    Update-ToggleVisual $CheckBox
    Update-ActiveFeatures

    if ($script:UpdatingUI -or -not $script:Connected -or -not $script:WorldLoaded) {
        return
    }

    $state = $(if ($CheckBox.Checked) { "1" } else { "0" })
    $suffix = $(if ($CheckBox.Checked) { ": ON" } else { ": OFF" })
    $label = Get-Text $LabelKey

    if (-not (Send-Action ($Command + "|" + $state) ($label + $suffix))) {
        Refresh-Status
    }
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

            [void]$items.Add(
                [pscustomobject]@{
                    Id = [int]$parts[0]
                    Display = (Decode-B64 $parts[1])
                }
            )
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
            if ([int]$items[$i].Id -eq $oldId) {
                $targetIndex = $i
                break
            }
        }

        if ($items.Count -gt 0) {
            $cmbCrew.SelectedIndex = $targetIndex
        }
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

            [void]$gridSkills.Rows.Add(
                [int]$p[0],
                (Decode-B64 $p[3]),
                [int]$p[1],
                [int]$p[2]
            )
        }
    }

    if ($d.ContainsKey("attrs") -and -not [string]::IsNullOrEmpty($d["attrs"])) {
        foreach ($entry in ($d["attrs"] -split ';')) {
            $p = $entry -split ',', 3
            if ($p.Count -lt 3) { continue }

            [void]$gridAttrs.Rows.Add(
                [int]$p[0],
                (Decode-B64 $p[2]),
                [int]$p[1]
            )
        }
    }

    $conditionNames = @()

    if ($d.ContainsKey("negativeNames") -and -not [string]::IsNullOrEmpty($d["negativeNames"])) {
        foreach ($name64 in ($d["negativeNames"] -split ';')) {
            if (-not [string]::IsNullOrEmpty($name64)) {
                $conditionNames += (Decode-B64 $name64)
            }
        }
    }

    $count = $(if ($d.ContainsKey("negativeCount")) { [int]$d["negativeCount"] } else { 0 })

    if ($count -eq 0) {
        $lblConditions.Text = Get-Text "conditions_none"
        $lblConditions.ForeColor = $clrGood
    } else {
        $lblConditions.Text = Format-Text "conditions" @($count, ($conditionNames -join ", "))
        $lblConditions.ForeColor = $clrBad
    }
}

function Get-TechStateText {
    param([string]$RawState)

    switch ($RawState) {
        "DONE" { return Get-Text "state_done" }
        "QUEUED" { return Get-Text "state_queued" }
        "AVAILABLE" { return Get-Text "state_available" }
        default { return Get-Text "state_locked" }
    }
}

function Render-TechGrid {
    $selectedId = 0

    if ($gridTech.SelectedRows.Count -gt 0) {
        try { $selectedId = [int]$gridTech.SelectedRows[0].Cells["TechId"].Value } catch {}
    }

    $filter = $txtTechSearch.Text.Trim()
    if ($txtTechSearch.ForeColor -eq $clrMuted -or $filter -eq [string]$txtTechSearch.Tag) {
        $filter = ""
    }
    $gridTech.Rows.Clear()

    foreach ($tech in $script:TechCache) {
        if (-not [string]::IsNullOrEmpty($filter)) {
            if ($tech.Name.IndexOf($filter, [System.StringComparison]::CurrentCultureIgnoreCase) -lt 0) {
                continue
            }
        }

        $queuedText = $(if ($tech.Queued) { Get-Text "yes" } else { Get-Text "no" })

        $rowIndex = $gridTech.Rows.Add(
            $tech.Id,
            $tech.Name,
            (Get-TechStateText $tech.State),
            $queuedText
        )

        if ($tech.Id -eq $selectedId) {
            $gridTech.Rows[$rowIndex].Selected = $true
        }
    }
}

function Refresh-TechList {
    if (-not $script:Connected -or -not $script:WorldLoaded) { return }

    $r = Send-TrainerRequest "LIST_TECHS" 1200
    if ([string]::IsNullOrEmpty($r) -or -not $r.StartsWith("TECHLIST|")) { return }

    $script:TechCache.Clear()
    $payload = $r.Substring(9)

    if (-not [string]::IsNullOrEmpty($payload)) {
        foreach ($entry in ($payload -split ';')) {
            $p = $entry -split '~', 4
            if ($p.Count -lt 4) { continue }

            [void]$script:TechCache.Add(
                [pscustomobject]@{
                    Id = [int]$p[0]
                    State = [string]$p[1]
                    Queued = ($p[2] -eq "1")
                    Name = (Decode-B64 $p[3])
                }
            )
        }
    }

    Render-TechGrid
}

# --------------------------------------------------------------------
# Form shell
# --------------------------------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Space Haven Live Trainer v0.8.1"
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.Size = New-Object System.Drawing.Size(1180, 820)
$form.MinimumSize = New-Object System.Drawing.Size(1080, 760)
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.BackColor = $clrBack
$form.ForeColor = $clrText
$form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi

$header = New-Object System.Windows.Forms.Panel
$header.Dock = [System.Windows.Forms.DockStyle]::Top
$header.Height = 72
$header.BackColor = $clrHeader
$form.Controls.Add($header)

$title = New-Object System.Windows.Forms.Label
$title.Location = New-Object System.Drawing.Point(22, 12)
$title.AutoSize = $true
$title.ForeColor = $clrText
$title.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 17)
$header.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Location = New-Object System.Drawing.Point(24, 43)
$subtitle.AutoSize = $true
$subtitle.ForeColor = $clrMuted
$header.Controls.Add($subtitle)

$lblLanguage = New-Object System.Windows.Forms.Label
$lblLanguage.Location = New-Object System.Drawing.Point(810, 26)
$lblLanguage.AutoSize = $true
$lblLanguage.ForeColor = $clrMuted
$header.Controls.Add($lblLanguage)

$cmbLanguage = New-Object System.Windows.Forms.ComboBox
$cmbLanguage.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$cmbLanguage.Items.Add("Italiano") | Out-Null
$cmbLanguage.Items.Add("English") | Out-Null
$cmbLanguage.Location = New-Object System.Drawing.Point(870, 21)
$cmbLanguage.Size = New-Object System.Drawing.Size(120, 28)
$header.Controls.Add($cmbLanguage)

$chkTopMost = New-Object System.Windows.Forms.CheckBox
$chkTopMost.Location = New-Object System.Drawing.Point(1005, 24)
$chkTopMost.AutoSize = $true
$chkTopMost.ForeColor = $clrText
$header.Controls.Add($chkTopMost)

$bottom = New-Object System.Windows.Forms.Panel
$bottom.Dock = [System.Windows.Forms.DockStyle]::Bottom
$bottom.Height = 38
$bottom.BackColor = $clrHeader
$form.Controls.Add($bottom)

$lblBottomStatus = New-Object System.Windows.Forms.Label
$lblBottomStatus.Location = New-Object System.Drawing.Point(16, 11)
$lblBottomStatus.AutoSize = $true
$lblBottomStatus.ForeColor = $clrMuted
$bottom.Controls.Add($lblBottomStatus)

$lblVersion = New-Object System.Windows.Forms.Label
$lblVersion.Text = "Mod v0.8.1"
$lblVersion.AutoSize = $true
$lblVersion.ForeColor = $clrMuted
$lblVersion.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$lblVersion.Location = New-Object System.Drawing.Point(1060, 11)
$bottom.Controls.Add($lblVersion)

$sidebar = New-Object System.Windows.Forms.Panel
$sidebar.Dock = [System.Windows.Forms.DockStyle]::Left
$sidebar.Width = 190
$sidebar.BackColor = $clrSidebar
$form.Controls.Add($sidebar)

$connectionPanel = New-Object System.Windows.Forms.Panel
$connectionPanel.Location = New-Object System.Drawing.Point(14, 18)
$connectionPanel.Size = New-Object System.Drawing.Size(162, 92)
$connectionPanel.BackColor = $clrPanel
$sidebar.Controls.Add($connectionPanel)

$connDot = New-Object System.Windows.Forms.Panel
$connDot.Location = New-Object System.Drawing.Point(12, 14)
$connDot.Size = New-Object System.Drawing.Size(10, 10)
$connDot.BackColor = $clrBad
$connectionPanel.Controls.Add($connDot)

$lblConnection = New-Object System.Windows.Forms.Label
$lblConnection.Location = New-Object System.Drawing.Point(29, 10)
$lblConnection.Size = New-Object System.Drawing.Size(123, 20)
$lblConnection.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 8)
$connectionPanel.Controls.Add($lblConnection)

$lblSubStatus = New-Object System.Windows.Forms.Label
$lblSubStatus.Location = New-Object System.Drawing.Point(12, 36)
$lblSubStatus.Size = New-Object System.Drawing.Size(138, 46)
$lblSubStatus.ForeColor = $clrMuted
$lblSubStatus.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$connectionPanel.Controls.Add($lblSubStatus)

function New-NavButton {
    param([int]$Y)

    $b = New-Object System.Windows.Forms.Button
    $b.Location = New-Object System.Drawing.Point(0, $Y)
    $b.Size = New-Object System.Drawing.Size(190, 48)
    $b.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $b.FlatAppearance.BorderSize = 0
    $b.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $b.Padding = New-Object System.Windows.Forms.Padding(18, 0, 0, 0)
    $b.BackColor = $clrSidebar
    $b.ForeColor = $clrMuted
    $b.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    $sidebar.Controls.Add($b)
    return $b
}

$btnNavDashboard = New-NavButton 132
$btnNavResources = New-NavButton 182
$btnNavCrew = New-NavButton 232
$btnNavResearch = New-NavButton 282

$lblAuthor = New-Object System.Windows.Forms.Label
$lblAuthor.Location = New-Object System.Drawing.Point(16, 625)
$lblAuthor.Size = New-Object System.Drawing.Size(160, 40)
$lblAuthor.ForeColor = $clrMuted
$lblAuthor.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$sidebar.Controls.Add($lblAuthor)

$contentHost = New-Object System.Windows.Forms.Panel
$contentHost.Dock = [System.Windows.Forms.DockStyle]::Fill
$contentHost.BackColor = $clrBack
$form.Controls.Add($contentHost)
$contentHost.BringToFront()

function New-Page {
    $p = New-Object System.Windows.Forms.Panel
    $p.Dock = [System.Windows.Forms.DockStyle]::Fill
    $p.BackColor = $clrBack
    $p.AutoScroll = $true
    $p.Visible = $false
    $contentHost.Controls.Add($p)
    return $p
}

$pageDashboard = New-Page
$pageResources = New-Page
$pageCrew = New-Page
$pageResearch = New-Page

$script:Pages = @{
    dashboard = $pageDashboard
    resources = $pageResources
    crew = $pageCrew
    research = $pageResearch
}

$script:NavButtons = @{
    dashboard = $btnNavDashboard
    resources = $btnNavResources
    crew = $btnNavCrew
    research = $btnNavResearch
}

# --------------------------------------------------------------------
# Dashboard page
# --------------------------------------------------------------------
$dashTitle = New-SectionTitle $pageDashboard 28 24
$dashDesc = New-SectionDescription $pageDashboard 30 58 850

$statCards = @()
$cardX = 28
foreach ($i in 0..4) {
    $p = New-Panel $pageDashboard $cardX 110 170 96
    $statCards += $p
    $cardX += 182
}

$lblShipCaption = New-CardCaption $statCards[0] 14 15
$lblShipValue = New-CardValue $statCards[0] 14 43
$lblShipValue.MaximumSize = New-Object System.Drawing.Size(145, 42)

$lblCreditsCaption = New-CardCaption $statCards[1] 14 15
$lblCreditsValue = New-CardValue $statCards[1] 14 43

$lblHyperfuelCaption = New-CardCaption $statCards[2] 14 15
$lblHyperfuelValue = New-CardValue $statCards[2] 14 43

$lblCrewCaption = New-CardCaption $statCards[3] 14 15
$lblCrewValue = New-CardValue $statCards[3] 14 43

$lblResearchCaption = New-CardCaption $statCards[4] 14 15
$lblResearchValue = New-CardValue $statCards[4] 14 43

$activeCard = New-Panel $pageDashboard 28 226 898 92
$lblActiveTitle = New-CardCaption $activeCard 16 14
$lblActiveFeatures = New-Object System.Windows.Forms.Label
$lblActiveFeatures.Location = New-Object System.Drawing.Point(16, 42)
$lblActiveFeatures.Size = New-Object System.Drawing.Size(860, 38)
$lblActiveFeatures.ForeColor = $clrMuted
$activeCard.Controls.Add($lblActiveFeatures)

$quickCard = New-Panel $pageDashboard 28 338 430 182
$lblQuickTitle = New-CardCaption $quickCard 16 14
$btnDashRefresh = New-SecondaryButton "" 16 48 120 40
$quickCard.Controls.Add($btnDashRefresh)
$btnDashCredits = New-PrimaryButton "" 148 48 142 40
$quickCard.Controls.Add($btnDashCredits)
$btnDashResources = New-SecondaryButton "" 302 48 112 40
$quickCard.Controls.Add($btnDashResources)

$lblHotkeysTitle = New-CardCaption $quickCard 16 108
$lblHotkeys = New-Object System.Windows.Forms.Label
$lblHotkeys.Location = New-Object System.Drawing.Point(16, 130)
$lblHotkeys.Size = New-Object System.Drawing.Size(395, 45)
$lblHotkeys.ForeColor = $clrMuted
$lblHotkeys.Font = New-Object System.Drawing.Font("Consolas", 8)
$quickCard.Controls.Add($lblHotkeys)

$archCard = New-Panel $pageDashboard 476 338 450 182
$lblArchitectureTitle = New-CardCaption $archCard 16 14
$lblArchitecture = New-Object System.Windows.Forms.Label
$lblArchitecture.Location = New-Object System.Drawing.Point(16, 48)
$lblArchitecture.Size = New-Object System.Drawing.Size(412, 78)
$lblArchitecture.ForeColor = $clrMuted
$archCard.Controls.Add($lblArchitecture)

$lblHotkeys2 = New-Object System.Windows.Forms.Label
$lblHotkeys2.Location = New-Object System.Drawing.Point(16, 126)
$lblHotkeys2.Size = New-Object System.Drawing.Size(412, 44)
$lblHotkeys2.ForeColor = $clrMuted
$lblHotkeys2.Font = New-Object System.Drawing.Font("Consolas", 8)
$archCard.Controls.Add($lblHotkeys2)

# --------------------------------------------------------------------
# Resources page
# --------------------------------------------------------------------
$resTitle = New-SectionTitle $pageResources 28 24
$resDesc = New-SectionDescription $pageResources 30 58 850

$economyCard = New-Panel $pageResources 28 108 898 122
$lblEconomyTitle = New-CardCaption $economyCard 16 14

$lblCreditsAmount = New-Object System.Windows.Forms.Label
$lblCreditsAmount.Location = New-Object System.Drawing.Point(16, 52)
$lblCreditsAmount.AutoSize = $true
$lblCreditsAmount.ForeColor = $clrMuted
$economyCard.Controls.Add($lblCreditsAmount)

$numCredits = New-Object System.Windows.Forms.NumericUpDown
$numCredits.Minimum = 1
$numCredits.Maximum = 2000000000
$numCredits.Value = 100000
$numCredits.Increment = 10000
$numCredits.Location = New-Object System.Drawing.Point(170, 47)
$numCredits.Size = New-Object System.Drawing.Size(175, 28)
$numCredits.BackColor = $clrPanelAlt
$numCredits.ForeColor = $clrText
$economyCard.Controls.Add($numCredits)

$btnCredits = New-PrimaryButton "" 365 43 180 36
$economyCard.Controls.Add($btnCredits)

$lblF1 = New-Object System.Windows.Forms.Label
$lblF1.Location = New-Object System.Drawing.Point(570, 53)
$lblF1.AutoSize = $true
$lblF1.ForeColor = $clrMuted
$economyCard.Controls.Add($lblF1)

$resourceCard = New-Panel $pageResources 28 248 898 290
$lblResourceCardTitle = New-CardCaption $resourceCard 16 14

$lblResource = New-Object System.Windows.Forms.Label
$lblResource.Location = New-Object System.Drawing.Point(16, 54)
$lblResource.AutoSize = $true
$lblResource.ForeColor = $clrMuted
$resourceCard.Controls.Add($lblResource)

$cmbResource = New-Object System.Windows.Forms.ComboBox
$cmbResource.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$cmbResource.Location = New-Object System.Drawing.Point(90, 49)
$cmbResource.Size = New-Object System.Drawing.Size(340, 28)
$resourceCard.Controls.Add($cmbResource)

$lblQty = New-Object System.Windows.Forms.Label
$lblQty.Location = New-Object System.Drawing.Point(455, 54)
$lblQty.AutoSize = $true
$lblQty.ForeColor = $clrMuted
$resourceCard.Controls.Add($lblQty)

$numQty = New-Object System.Windows.Forms.NumericUpDown
$numQty.Minimum = 1
$numQty.Maximum = 1000000
$numQty.Value = 50
$numQty.Location = New-Object System.Drawing.Point(530, 49)
$numQty.Size = New-Object System.Drawing.Size(120, 28)
$numQty.BackColor = $clrPanelAlt
$numQty.ForeColor = $clrText
$resourceCard.Controls.Add($numQty)

$btnAddResource = New-PrimaryButton "" 674 45 190 36
$resourceCard.Controls.Add($btnAddResource)

$lblPreset = New-Object System.Windows.Forms.Label
$lblPreset.Location = New-Object System.Drawing.Point(16, 105)
$lblPreset.AutoSize = $true
$lblPreset.ForeColor = $clrMuted
$resourceCard.Controls.Add($lblPreset)

$presetButtons = @()
$x = 90
foreach ($v in @(50, 100, 500, 999, 5000)) {
    $b = New-SecondaryButton ([string]$v) $x 96 72 34
    $b.Tag = $v
    $b.Add_Click({ $numQty.Value = [decimal]$this.Tag })
    $resourceCard.Controls.Add($b)
    $presetButtons += $b
    $x += 82
}

$chkInfiniteResources = New-ToggleButton "" 16 158 260 48
$resourceCard.Controls.Add($chkInfiniteResources)

$lblInfiniteResourcesDesc = New-Object System.Windows.Forms.Label
$lblInfiniteResourcesDesc.Location = New-Object System.Drawing.Point(298, 164)
$lblInfiniteResourcesDesc.Size = New-Object System.Drawing.Size(530, 38)
$lblInfiniteResourcesDesc.ForeColor = $clrMuted
$resourceCard.Controls.Add($lblInfiniteResourcesDesc)

$lblF23 = New-Object System.Windows.Forms.Label
$lblF23.Location = New-Object System.Drawing.Point(16, 226)
$lblF23.AutoSize = $true
$lblF23.ForeColor = $clrMuted
$resourceCard.Controls.Add($lblF23)

$resourceData = @(
    [pscustomobject]@{ Id=16; It="Acqua"; En="Water" },
    [pscustomobject]@{ Id=158; It="Energium"; En="Energium" },
    [pscustomobject]@{ Id=172; It="Hyperium"; En="Hyperium" },
    [pscustomobject]@{ Id=178; It="Ipercarburante"; En="Hyperfuel" },
    [pscustomobject]@{ Id=162; It="Infrablock"; En="Infrablock" },
    [pscustomobject]@{ Id=1759; It="Blocco scafo"; En="Hull Block" },
    [pscustomobject]@{ Id=1919; It="Blocco energia"; En="Energy Block" },
    [pscustomobject]@{ Id=1921; It="Blocco morbido"; En="Soft Block" },
    [pscustomobject]@{ Id=930; It="Techblock"; En="Techblock" },
    [pscustomobject]@{ Id=712; It="Cibo spaziale"; En="Space Food" },
    [pscustomobject]@{ Id=707; It="Carne artificiale"; En="Artificial Meat" },
    [pscustomobject]@{ Id=2475; It="Fertilizzante"; En="Fertilizer" },
    [pscustomobject]@{ Id=2053; It="Forniture mediche"; En="Medical Supplies" },
    [pscustomobject]@{ Id=2058; It="Fluido IV"; En="IV Fluid" },
    [pscustomobject]@{ Id=157; It="Metalli di base"; En="Base Metals" },
    [pscustomobject]@{ Id=169; It="Metalli nobili"; En="Noble Metals" },
    [pscustomobject]@{ Id=170; It="Carbonio"; En="Carbon" },
    [pscustomobject]@{ Id=171; It="Chimici grezzi"; En="Raw Chemicals" },
    [pscustomobject]@{ Id=173; It="Componente elettronico"; En="Electronic Component" },
    [pscustomobject]@{ Id=174; It="Barra energetica"; En="Energy Rod" },
    [pscustomobject]@{ Id=175; It="Plastiche"; En="Plastics" },
    [pscustomobject]@{ Id=176; It="Prodotti chimici"; En="Chemicals" },
    [pscustomobject]@{ Id=177; It="Tessuti"; En="Fabrics" },
    [pscustomobject]@{ Id=179; It="Cibo processato"; En="Processed Food" },
    [pscustomobject]@{ Id=1922; It="Piastre d'acciaio"; En="Steel Plates" },
    [pscustomobject]@{ Id=1924; It="Componente optronico"; En="Optronics Component" },
    [pscustomobject]@{ Id=1925; It="Componente quantronico"; En="Quantronics Component" },
    [pscustomobject]@{ Id=1926; It="Cella energetica"; En="Energy Cell" },
    [pscustomobject]@{ Id=1932; It="Fibre"; En="Fibers" },
    [pscustomobject]@{ Id=3196; It="Energia ad alta capacità"; En="High Capacity Power" }
)

function Refresh-ResourceList {
    $selectedId = 178

    if ($null -ne $cmbResource.SelectedItem) {
        try { $selectedId = [int]$cmbResource.SelectedItem.Id } catch {}
    }

    $items = New-Object System.Collections.ArrayList

    foreach ($r in $resourceData) {
        $name = $(if ($script:Language -eq "it") { $r.It } else { $r.En })

        [void]$items.Add(
            [pscustomobject]@{
                Id = $r.Id
                Display = ($name + " [" + $r.Id + "]")
            }
        )
    }

    $cmbResource.DataSource = $null
    $cmbResource.DisplayMember = "Display"
    $cmbResource.ValueMember = "Id"
    $cmbResource.DataSource = $items

    for ($i = 0; $i -lt $items.Count; $i++) {
        if ([int]$items[$i].Id -eq $selectedId) {
            $cmbResource.SelectedIndex = $i
            break
        }
    }
}

# --------------------------------------------------------------------
# Crew page
# --------------------------------------------------------------------
$crewTitle = New-SectionTitle $pageCrew 28 20
$crewDesc = New-SectionDescription $pageCrew 30 54 850

$crewSelectCard = New-Panel $pageCrew 28 96 898 86
$lblCrewMember = New-CardCaption $crewSelectCard 16 14

$cmbCrew = New-Object System.Windows.Forms.ComboBox
$cmbCrew.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$cmbCrew.Location = New-Object System.Drawing.Point(16, 42)
$cmbCrew.Size = New-Object System.Drawing.Size(330, 28)
$crewSelectCard.Controls.Add($cmbCrew)

$btnCrewRefresh = New-SecondaryButton "" 360 39 120 34
$crewSelectCard.Controls.Add($btnCrewRefresh)

$lblConditions = New-Object System.Windows.Forms.Label
$lblConditions.Location = New-Object System.Drawing.Point(505, 42)
$lblConditions.Size = New-Object System.Drawing.Size(370, 34)
$lblConditions.ForeColor = $clrMuted
$crewSelectCard.Controls.Add($lblConditions)

$sustainCard = New-Panel $pageCrew 28 198 898 126
$lblSustainTitle = New-CardCaption $sustainCard 16 14

$chkHealth = New-ToggleButton "" 16 46 132 48
$sustainCard.Controls.Add($chkHealth)
$chkOxygen = New-ToggleButton "" 160 46 132 48
$sustainCard.Controls.Add($chkOxygen)
$chkFood = New-ToggleButton "" 304 46 132 48
$sustainCard.Controls.Add($chkFood)
$chkRest = New-ToggleButton "" 448 46 132 48
$sustainCard.Controls.Add($chkRest)
$chkMood = New-ToggleButton "" 592 46 132 48
$sustainCard.Controls.Add($chkMood)
$chkComfort = New-ToggleButton "" 736 46 146 48
$sustainCard.Controls.Add($chkComfort)

$advancedCard = New-Panel $pageCrew 28 340 898 330
$lblAdvancedTitle = New-CardCaption $advancedCard 16 12

$gridSkills = New-Object System.Windows.Forms.DataGridView
$gridSkills.Location = New-Object System.Drawing.Point(16, 38)
$gridSkills.Size = New-Object System.Drawing.Size(510, 205)
Configure-Grid $gridSkills
[void]$gridSkills.Columns.Add("SkillId", "ID")
$gridSkills.Columns["SkillId"].Visible = $false
[void]$gridSkills.Columns.Add("SkillName", "Skill")
$gridSkills.Columns["SkillName"].ReadOnly = $true
[void]$gridSkills.Columns.Add("SkillLevel", "Level")
[void]$gridSkills.Columns.Add("SkillMax", "Maximum")
$gridSkills.Columns["SkillName"].FillWeight = 180
$gridSkills.Columns["SkillLevel"].FillWeight = 55
$gridSkills.Columns["SkillMax"].FillWeight = 55
$advancedCard.Controls.Add($gridSkills)

$gridAttrs = New-Object System.Windows.Forms.DataGridView
$gridAttrs.Location = New-Object System.Drawing.Point(540, 38)
$gridAttrs.Size = New-Object System.Drawing.Size(342, 205)
Configure-Grid $gridAttrs
[void]$gridAttrs.Columns.Add("AttrId", "ID")
$gridAttrs.Columns["AttrId"].Visible = $false
[void]$gridAttrs.Columns.Add("AttrName", "Attribute")
$gridAttrs.Columns["AttrName"].ReadOnly = $true
[void]$gridAttrs.Columns.Add("AttrPoints", "Points")
$gridAttrs.Columns["AttrName"].FillWeight = 165
$gridAttrs.Columns["AttrPoints"].FillWeight = 60
$advancedCard.Controls.Add($gridAttrs)

$btnCrewApply = New-PrimaryButton "" 16 258 155 38
$advancedCard.Controls.Add($btnCrewApply)
$btnMaxSkills = New-SecondaryButton "" 181 258 130 38
$advancedCard.Controls.Add($btnMaxSkills)
$btnMaxAttrs = New-SecondaryButton "" 321 258 140 38
$advancedCard.Controls.Add($btnMaxAttrs)
$btnCure = New-SecondaryButton "" 471 258 145 38
$advancedCard.Controls.Add($btnCure)
$btnMaxCharacter = New-PrimaryButton "" 626 258 256 38
$advancedCard.Controls.Add($btnMaxCharacter)

$lblCrewNote = New-Object System.Windows.Forms.Label
$lblCrewNote.Location = New-Object System.Drawing.Point(16, 303)
$lblCrewNote.Size = New-Object System.Drawing.Size(860, 22)
$lblCrewNote.ForeColor = $clrMuted
$advancedCard.Controls.Add($lblCrewNote)

# --------------------------------------------------------------------
# Research page
# --------------------------------------------------------------------
$researchTitle = New-SectionTitle $pageResearch 28 20
$researchDesc = New-SectionDescription $pageResearch 30 54 850

$researchTop = New-Panel $pageResearch 28 96 898 100

$chkInstantResearch = New-ToggleButton "" 16 28 190 48
$researchTop.Controls.Add($chkInstantResearch)

$lblResearchProgress = New-Object System.Windows.Forms.Label
$lblResearchProgress.Location = New-Object System.Drawing.Point(225, 43)
$lblResearchProgress.AutoSize = $true
$lblResearchProgress.ForeColor = $clrText
$lblResearchProgress.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
$researchTop.Controls.Add($lblResearchProgress)

$txtTechSearch = New-Object System.Windows.Forms.TextBox
$txtTechSearch.Location = New-Object System.Drawing.Point(510, 38)
$txtTechSearch.Size = New-Object System.Drawing.Size(225, 28)
$txtTechSearch.BackColor = $clrPanelAlt
$txtTechSearch.ForeColor = $clrText
$txtTechSearch.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$researchTop.Controls.Add($txtTechSearch)

$btnTechRefresh = New-SecondaryButton "" 748 34 134 36
$researchTop.Controls.Add($btnTechRefresh)

$gridTech = New-Object System.Windows.Forms.DataGridView
$gridTech.Location = New-Object System.Drawing.Point(28, 214)
$gridTech.Size = New-Object System.Drawing.Size(898, 370)
Configure-Grid $gridTech
[void]$gridTech.Columns.Add("TechId", "ID")
$gridTech.Columns["TechId"].FillWeight = 35
[void]$gridTech.Columns.Add("TechName", "Technology")
$gridTech.Columns["TechName"].FillWeight = 230
[void]$gridTech.Columns.Add("TechState", "State")
$gridTech.Columns["TechState"].FillWeight = 85
[void]$gridTech.Columns.Add("TechQueued", "Queued")
$gridTech.Columns["TechQueued"].FillWeight = 55
foreach ($col in $gridTech.Columns) { $col.ReadOnly = $true }
$pageResearch.Controls.Add($gridTech)

$btnCompleteTech = New-PrimaryButton "" 28 602 205 40
$pageResearch.Controls.Add($btnCompleteTech)

$btnCompleteAllTech = New-SecondaryButton "" 245 602 175 40
$pageResearch.Controls.Add($btnCompleteAllTech)

$lblResearchNote = New-Object System.Windows.Forms.Label
$lblResearchNote.Location = New-Object System.Drawing.Point(440, 604)
$lblResearchNote.Size = New-Object System.Drawing.Size(475, 42)
$lblResearchNote.ForeColor = $clrMuted
$pageResearch.Controls.Add($lblResearchNote)

# --------------------------------------------------------------------
# Localization
# --------------------------------------------------------------------
function Apply-Language {
    $title.Text = Get-Text "app_title"
    $subtitle.Text = Get-Text "subtitle"
    $lblLanguage.Text = Get-Text "language"
    $chkTopMost.Text = Get-Text "topmost"
    $lblAuthor.Text = Get-Text "author"

    $btnNavDashboard.Text = "   " + (Get-Text "nav_dashboard")
    $btnNavResources.Text = "   " + (Get-Text "nav_resources")
    $btnNavCrew.Text = "   " + (Get-Text "nav_crew")
    $btnNavResearch.Text = "   " + (Get-Text "nav_research")

    $dashTitle.Text = Get-Text "dashboard_title"
    $dashDesc.Text = Get-Text "dashboard_desc"
    $lblShipCaption.Text = Get-Text "stat_ship"
    $lblCreditsCaption.Text = Get-Text "stat_credits"
    $lblHyperfuelCaption.Text = Get-Text "stat_hyperfuel"
    $lblCrewCaption.Text = Get-Text "stat_crew"
    $lblResearchCaption.Text = Get-Text "stat_research"
    $lblActiveTitle.Text = Get-Text "active_title"
    $lblQuickTitle.Text = Get-Text "quick_title"
    $btnDashRefresh.Text = Get-Text "quick_refresh"
    $btnDashCredits.Text = Get-Text "quick_credits"
    $btnDashResources.Text = Get-Text "quick_resources"
    $lblHotkeysTitle.Text = Get-Text "hotkeys_title"
    $lblArchitectureTitle.Text = Get-Text "architecture_title"
    $lblArchitecture.Text = Get-Text "architecture_text"
    $lblHotkeys.Text = (Get-Text "hk_resources") + "`r`n" + (Get-Text "hk_health") + "`r`n" + (Get-Text "hk_oxygen")
    $lblHotkeys2.Text = (Get-Text "hk_food") + "`r`n" + (Get-Text "hk_rest") + "`r`n" + (Get-Text "hk_mood") + "`r`n" + (Get-Text "hk_comfort") + "`r`n" + (Get-Text "hk_research")

    $resTitle.Text = Get-Text "resources_title"
    $resDesc.Text = Get-Text "resources_desc"
    $lblEconomyTitle.Text = Get-Text "economy"
    $lblCreditsAmount.Text = Get-Text "credits_amount"
    $btnCredits.Text = Get-Text "add_credits"
    $lblF1.Text = Get-Text "f1_hint"
    $lblResourceCardTitle.Text = Get-Text "resource_card"
    $lblResource.Text = Get-Text "resource"
    $lblQty.Text = Get-Text "quantity"
    $btnAddResource.Text = Get-Text "add_live"
    $lblPreset.Text = Get-Text "preset"
    $chkInfiniteResources.Text = (Get-Text "infinite_resources") + "  [F3]"
    $lblInfiniteResourcesDesc.Text = Get-Text "infinite_resources_desc"
    $lblF23.Text = Get-Text "f2_f3_hint"

    $crewTitle.Text = Get-Text "crew_title"
    $crewDesc.Text = Get-Text "crew_desc"
    $lblCrewMember.Text = Get-Text "crew_member"
    $btnCrewRefresh.Text = Get-Text "refresh_crew"
    if ($lblConditions.Text -eq "-" -or [string]::IsNullOrEmpty($lblConditions.Text)) {
        $lblConditions.Text = Get-Text "conditions_unknown"
    }
    $lblSustainTitle.Text = Get-Text "sustain"
    $chkHealth.Text = (Get-Text "health") + "  [F4]"
    $chkOxygen.Text = (Get-Text "oxygen") + "  [F5]"
    $chkFood.Text = (Get-Text "food") + "  [F6]"
    $chkRest.Text = (Get-Text "rest") + "  [F7]"
    $chkMood.Text = (Get-Text "mood") + "  [F8]"
    $chkComfort.Text = (Get-Text "comfort") + "  [F9]"
    $lblAdvancedTitle.Text = Get-Text "advanced"
    $gridSkills.Columns["SkillName"].HeaderText = Get-Text "skill"
    $gridSkills.Columns["SkillLevel"].HeaderText = Get-Text "level"
    $gridSkills.Columns["SkillMax"].HeaderText = Get-Text "maximum"
    $gridAttrs.Columns["AttrName"].HeaderText = Get-Text "attribute"
    $gridAttrs.Columns["AttrPoints"].HeaderText = Get-Text "points"
    $btnCrewApply.Text = Get-Text "apply_changes"
    $btnMaxSkills.Text = Get-Text "max_skills"
    $btnMaxAttrs.Text = Get-Text "max_attrs"
    $btnCure.Text = Get-Text "cure_negative"
    $btnMaxCharacter.Text = Get-Text "max_character"
    $lblCrewNote.Text = Get-Text "crew_note"

    $researchTitle.Text = Get-Text "research_title"
    $researchDesc.Text = Get-Text "research_desc"
    $chkInstantResearch.Text = (Get-Text "instant_research") + "  [F10]"
    if ($lblResearchProgress.Text -eq "-" -or [string]::IsNullOrEmpty($lblResearchProgress.Text)) {
        $lblResearchProgress.Text = Get-Text "research_progress_empty"
    }
    $txtTechSearch.Tag = Get-Text "search_tech"
    $btnTechRefresh.Text = Get-Text "refresh"
    $gridTech.Columns["TechId"].HeaderText = Get-Text "tech_id"
    $gridTech.Columns["TechName"].HeaderText = Get-Text "technology"
    $gridTech.Columns["TechState"].HeaderText = Get-Text "state"
    $gridTech.Columns["TechQueued"].HeaderText = Get-Text "queued"
    $btnCompleteTech.Text = Get-Text "complete_selected"
    $btnCompleteAllTech.Text = Get-Text "complete_all"
    $lblResearchNote.Text = Get-Text "research_note"

    if ([string]::IsNullOrEmpty($lblBottomStatus.Text)) {
        $lblBottomStatus.Text = Get-Text "ready"
    }

    Refresh-ResourceList
    Render-TechGrid
    Update-ActiveFeatures
    Set-ConnectedState $script:Connected $script:WorldLoaded
}

function Set-Language {
    param([string]$Language)

    if ($Language -ne "it" -and $Language -ne "en") { return }

    $placeholderWasVisible = (
        $txtTechSearch.ForeColor -eq $clrMuted -or
        [string]::IsNullOrWhiteSpace($txtTechSearch.Text) -or
        $txtTechSearch.Text -eq [string]$txtTechSearch.Tag
    )

    $script:Language = $Language
    Save-GuiSettings
    Apply-Language

    if ($placeholderWasVisible) {
        $txtTechSearch.ForeColor = $clrMuted
        $txtTechSearch.Text = Get-Text "search_tech"
    }

    if ($script:Connected -and $script:WorldLoaded) {
        Refresh-Status
        if ((Get-SelectedCrewId) -gt 0) {
            Load-CrewDetail
        }
    }

    Set-ActionStatus (Get-Text "lang_changed") $false
}

# --------------------------------------------------------------------
# Events
# --------------------------------------------------------------------
$btnNavDashboard.Add_Click({ Show-Page "dashboard" })
$btnNavResources.Add_Click({ Show-Page "resources" })
$btnNavCrew.Add_Click({ Show-Page "crew" })
$btnNavResearch.Add_Click({ Show-Page "research" })

$chkTopMost.Add_CheckedChanged({ $form.TopMost = $chkTopMost.Checked })

$cmbLanguage.Add_SelectedIndexChanged({
    if ($script:UpdatingUI) { return }

    if ($cmbLanguage.SelectedIndex -eq 0) {
        Set-Language "it"
    } elseif ($cmbLanguage.SelectedIndex -eq 1) {
        Set-Language "en"
    }
})

$btnDashRefresh.Add_Click({
    Refresh-Status
    Refresh-CrewList
    Refresh-TechList
})

$btnDashCredits.Add_Click({
    [void](Send-Action "ADD_CREDITS|100000" (Format-Text "credits_added" @(100000)))
})

$btnDashResources.Add_Click({ Show-Page "resources" })

$btnCredits.Add_Click({
    $amount = [int]$numCredits.Value
    [void](Send-Action ("ADD_CREDITS|" + $amount) (Format-Text "credits_added" @($amount)))
})

$btnAddResource.Add_Click({
    if ($null -eq $cmbResource.SelectedItem) { return }

    $rid = [int]$cmbResource.SelectedItem.Id
    $qty = [int]$numQty.Value

    [void](Send-Action ("ADD_RESOURCE|" + $rid + "|" + $qty) (Format-Text "resource_added" @($rid, $qty)))
})

$chkInfiniteResources.Add_CheckedChanged({
    Toggle-Setting $chkInfiniteResources "SET_INFINITE_RESOURCES" "infinite_resources"
})

$chkHealth.Add_CheckedChanged({
    Toggle-Setting $chkHealth "SET_INFINITE_HEALTH" "health"
})

$chkOxygen.Add_CheckedChanged({
    Toggle-Setting $chkOxygen "SET_INFINITE_OXYGEN" "oxygen"
})

$chkFood.Add_CheckedChanged({
    Toggle-Setting $chkFood "SET_STABLE_FOOD" "food"
})

$chkRest.Add_CheckedChanged({
    Toggle-Setting $chkRest "SET_STABLE_REST" "rest"
})

$chkMood.Add_CheckedChanged({
    Toggle-Setting $chkMood "SET_STABLE_MOOD" "mood"
})

$chkComfort.Add_CheckedChanged({
    Toggle-Setting $chkComfort "SET_STABLE_COMFORT" "comfort"
})

$chkInstantResearch.Add_CheckedChanged({
    Toggle-Setting $chkInstantResearch "SET_INSTANT_RESEARCH" "instant_research"
})

$btnCrewRefresh.Add_Click({ Refresh-CrewList })

$cmbCrew.Add_SelectedIndexChanged({
    if (-not $script:UpdatingCrewList) { Load-CrewDetail }
})

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

    if (Send-Action ("APPLY_CREW|" + $crewId + "|" + $sp + "|" + $ap) (Get-Text "crew_applied")) {
        Start-Sleep -Milliseconds 350
        Load-CrewDetail
    }
})

$btnMaxSkills.Add_Click({
    $crewId = Get-SelectedCrewId
    if ($crewId -le 0) { return }

    if (Send-Action ("MAX_CREW_SKILLS|" + $crewId) (Get-Text "max_skills_done")) {
        Start-Sleep -Milliseconds 350
        Load-CrewDetail
    }
})

$btnMaxAttrs.Add_Click({
    $crewId = Get-SelectedCrewId
    if ($crewId -le 0) { return }

    if (Send-Action ("MAX_CREW_ATTRS|" + $crewId) (Get-Text "max_attrs_done")) {
        Start-Sleep -Milliseconds 350
        Load-CrewDetail
    }
})

$btnMaxCharacter.Add_Click({
    $crewId = Get-SelectedCrewId
    if ($crewId -le 0) { return }

    $okSkills = Send-Action ("MAX_CREW_SKILLS|" + $crewId) (Get-Text "max_skills_done")
    if (-not $okSkills) { return }

    Start-Sleep -Milliseconds 120

    $okAttrs = Send-Action ("MAX_CREW_ATTRS|" + $crewId) (Get-Text "max_character_done")

    if ($okAttrs) {
        Start-Sleep -Milliseconds 400
        Load-CrewDetail
    }
})

$btnCure.Add_Click({
    $crewId = Get-SelectedCrewId
    if ($crewId -le 0) { return }

    if (Send-Action ("CURE_CREW_NEGATIVE|" + $crewId) (Get-Text "cure_requested")) {
        Start-Sleep -Milliseconds 350
        Load-CrewDetail
    }
})

$btnTechRefresh.Add_Click({ Refresh-TechList })

$txtTechSearch.Add_TextChanged({ Render-TechGrid })

$txtTechSearch.Add_Enter({
    if ($txtTechSearch.ForeColor -eq $clrMuted) {
        $txtTechSearch.Text = ""
        $txtTechSearch.ForeColor = $clrText
    }
})

$txtTechSearch.Add_Leave({
    if ([string]::IsNullOrWhiteSpace($txtTechSearch.Text)) {
        $txtTechSearch.ForeColor = $clrMuted
        $txtTechSearch.Text = [string]$txtTechSearch.Tag
    }
})

$btnCompleteTech.Add_Click({
    if ($gridTech.SelectedRows.Count -eq 0) {
        Set-ActionStatus (Get-Text "select_tech_first") $true
        return
    }

    $techId = [int]$gridTech.SelectedRows[0].Cells["TechId"].Value
    $techName = [string]$gridTech.SelectedRows[0].Cells["TechName"].Value

    if (Send-Action ("COMPLETE_TECH|" + $techId) (Format-Text "tech_completed" @($techName))) {
        Start-Sleep -Milliseconds 400
        Refresh-TechList
        Refresh-Status
    }
})

$btnCompleteAllTech.Add_Click({
    $answer = [System.Windows.Forms.MessageBox]::Show(
        (Get-Text "confirm_all"),
        (Get-Text "confirm_all_title"),
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    if (Send-Action "COMPLETE_ALL_TECH" (Get-Text "all_tech_requested")) {
        Start-Sleep -Milliseconds 600
        Refresh-TechList
        Refresh-Status
    }
})

$refreshTimer = New-Object System.Windows.Forms.Timer
$refreshTimer.Interval = 1100
$refreshTimer.Add_Tick({ Refresh-Status })

$form.Add_Shown({
    $script:UpdatingUI = $true

    try {
        if ($script:Language -eq "it") {
            $cmbLanguage.SelectedIndex = 0
        } else {
            $cmbLanguage.SelectedIndex = 1
        }
    } finally {
        $script:UpdatingUI = $false
    }

    Apply-Language

    $lblBottomStatus.Text = Get-Text "ready"
    $txtTechSearch.ForeColor = $clrMuted
    $txtTechSearch.Text = Get-Text "search_tech"

    foreach ($toggle in @(
        $chkInfiniteResources, $chkHealth, $chkOxygen, $chkFood,
        $chkRest, $chkMood, $chkComfort, $chkInstantResearch
    )) {
        Update-ToggleVisual $toggle
    }

    Show-Page "dashboard"
    Set-ConnectedState $false $false
    Refresh-Status
    $refreshTimer.Start()
})

$form.Add_FormClosed({
    $refreshTimer.Stop()
    Save-GuiSettings
})

[void]$form.ShowDialog()
