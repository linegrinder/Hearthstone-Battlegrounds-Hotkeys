#Requires AutoHotkey v2.0
#SingleInstance Force

; CRITICAL: Set coordinate mode for Mouse to Screen coordinates
; This ensures MouseGetPos() returns screen coordinates, not window-relative
CoordMode("Mouse", "Screen")
CoordMode("Pixel", "Screen")

; ============================================================
; VERSION AND UPDATE CHECKER
; ============================================================
global CurrentVersion := "1.4"  ; Current app version

#Include ColorButton.ahk

; ============================================================
; HEARTHSTONE BATTLEGROUNDS HOTKEY OVERLAY - v2.0
; Clean build from functional specification only
; ============================================================

; Global variables
global ConfigDir := A_AppData . "\HearthstoneHotkeys"
global ConfigFile := ConfigDir . "\config.ini"

; Hotkey Assignments (Defaults)
global LevelUpKey := "f"
global RerollKey := "d"
global FreezeKey := "Space"
global BuyKey := ""       ; Not set by default - user must configure
global SellKey := ""       ; Not set by default - user must configure
global SendToDuoMateKey := ""  ; Not set by default - user must configure

; Temporary hotkey assignments (used while settings dialog is open)
global TempLevelUpKey := "f"
global TempRerollKey := "d"
global TempFreezeKey := "Space"
global TempBuyKey := ""       ; Not set by default - user must configure
global TempSellKey := ""       ; Not set by default - user must configure
global TempSendToDuoMateKey := ""  ; Not set by default - user must configure

; Overlay display mode (0=Full default, 1=Compact)
global OverlayCompactMode := 1  ; Default to Compact mode

; Temporary overlay settings (used while settings dialog is open, not applied until Save & Minimize)
global TempOverlayCompactMode := 1  ; Default to Compact mode

; Flag to track if overlay display text has been initialized
global OverlayDisplayInitialized := 0

; Hearthstone running state tracking (to detect when it exits)
global HearthstoneWasRunning := 0

; Auto-launch state tracking (to detect changes)
global AutoLaunchWithHearthstone_Previous := 0

; Overlay status text control reference
global OverlayStatusText := ""

; Button references for key capture
global lvlBtnRef := ""
global rrBtnRef := ""
global frzBtnRef := ""
global buyBtnRef := ""
global sellBtnRef := ""
global duoBtnRef := ""

; Button references for keybind buttons in settings
global lvlKeybindBtn := ""
global rrKeybindBtn := ""
global frzKeybindBtn := ""
global buyKeybindBtn := ""
global sellKeybindBtn := ""
global duoKeybindBtn := ""

; Tooltip tracking
; (OnMessage handlers defined below in TOOLTIP TRACKING section)

; ============================================================
; DPI-AWARE CLICK POSITION OFFSETS (from window center)
; Calculated from 2560x1440 baseline coordinates
; These are pixel distances, NOT percentages
; Format: offset from window center in pixels
; ============================================================

; Base reference resolution (2560x1440 at 125% DPI scaling / 144 DPI)
global ReferenceWidth := 2560
global ReferenceHeight := 1440

; ============================================================
; PERCENTAGE-BASED CLICK POSITION OFFSETS (from window center)
; These are percentages of window dimensions, not pixels
; This ensures clicks work across all resolutions and aspect ratios
; ============================================================

; Reference: Based on measurements across multiple resolutions
; Level Up button is at approximately -8.8% of window width from center
; and -30.5% of window height from center

global LevelUpOffsetXPercent := -0.088
global LevelUpOffsetYPercent := -0.305

global RerollOffsetXPercent := 0.088   ; 8.8% right
global RerollOffsetYPercent := -0.306  ; 30.6% up

global FreezeOffsetXPercent := 0.146   ; 14.6% right
global FreezeOffsetYPercent := -0.338  ; 33.8% up

global BuyOffsetXPercent := 0.002      ; 0.2% right (basically center)
global BuyOffsetYPercent := 0.266      ; 26.6% down

global SellOffsetXPercent := 0.002     ; 0.2% right (basically center)
global SellOffsetYPercent := -0.322    ; 32.2% up

global SendToDuoMateOffsetXPercent := 0.348   ; 34.8% right
global SendToDuoMateOffsetYPercent := 0.091   ; 9.1% down

; Custom coordinate storage (exact pixel positions when user captures them)
global CustomLevelUpX := 0, CustomLevelUpY := 0, UseLevelUpCustom := 0
global CustomRerollX := 0, CustomRerollY := 0, UseRerollCustom := 0
global CustomFreezeX := 0, CustomFreezeY := 0, UseFreezeCustom := 0
global CustomBuyX := 0, CustomBuyY := 0, UseBuyCustom := 0
global CustomSellX := 0, CustomSellY := 0, UseSellCustom := 0
global CustomDuoX := 0, CustomDuoY := 0, UseDuoCustom := 0

; Temporary capture variables (stores captures until user clicks Save)

; Resolution and DPI settings
global BaseW := 2560  ; Reference width for scaling calculations
global BaseH := 1440  ; Reference height for scaling calculations
global ResolutionMode := 4  ; Always use custom mode (percentage-based system doesn't need preset resolutions)
global CloseOnHearthstoneExit := 0  ; Close app when Hearthstone closes
global SkipSettingsGUIOnStartup := 0  ; Skip showing settings GUI on next startup
global AutoLaunchWithHearthstone := 0  ; Auto-launch app when Hearthstone starts
global ShowBaseHotkeysClickLocations := 0  ; Show click location indicators for base hotkeys (Level Up, Reroll, Freeze)
global ShowAdditionalHotkeysClickLocations := 0  ; Show click location indicators for additional hotkeys (Buy, Sell, Duo Mate)
global HotkeysEnabled := 1  ; Hotkeys are enabled by default

; Legacy coordinate variables for settings GUI (kept for compatibility with custom capture mode)
global LevelUpX_Base := 1058
global LevelUpY_Base := 273
global RerollX_Base := 1509
global RerollY_Base := 271
global FreezeX_Base := 1665
global FreezeY_Base := 243
global BuyX_Base := 1280
global BuyY_Base := 1105
global SellX_Base := 1280
global SellY_Base := 250
global DuoMateX_Base := 2160
global DuoMateY_Base := 830

; Overlay Control
global OverlayX := 20
global OverlayY := 40
global OverlayLocked := 1
global OverlayDragging := 0
global DragStartX := 0
global DragStartY := 0
global DragOffsetX := 0
global DragOffsetY := 0
global KeybindIndicatorsVisible := 0  ; Toggle for showing keybind location indicators
global KeybindIndicatorsGuiObj := []  ; GUI objects for keybind indicator overlays
global GlobalOverlayScreenX := 0  ; The actual screen X position of both overlays
global GlobalOverlayScreenY := 0  ; The actual screen Y position of both overlays

; Cache for Hearthstone window position - used by both MonitorHearthstone and UpdateOverlay
; REMOVED - not needed

; Window Handles
global SettingsGuiObj := 0
global OverlayGuiObj := 0
global ClickableOverlayGuiObj := 0  ; Invisible clickable overlay that mirrors OverlayGuiObj
global KeybindIndicatorsGuiObj := []
global indicatorGUIs := []
global CapturedKey := ""

; ============================================================
; STARTUP
; ============================================================

if (!DirExist(ConfigDir))
    DirCreate(ConfigDir)

; Extract embedded image files from compiled .exe to temp folder
FileInstall("Bob_Hotkey.png", A_Temp "\Bob_Hotkey.png", 1)
FileInstall("chatbubblnew.png", A_Temp "\chatbubblnew.png", 1)
FileInstall("chatbubblenew1080p.png", A_Temp "\chatbubblenew1080p.png", 1)

; Load config early to check admin requirement
LoadConfig()

; Detect monitor resolution for overlay font scaling
; 1080p monitors need larger fonts (s10, s11, s12), others use default (s8, s9, s10)
global OverlayFontSize_Small, OverlayFontSize_Medium, OverlayFontSize_Large, OverlayFontSize_EmojiDisplay, OverlayFontSize_ButtonEmoji, monitorWidth
MonitorGetWorkArea(1, &left, &top, &right, &bottom)
monitorWidth := right - left
if (monitorWidth <= 1920) {
    ; 1080p or smaller - use larger fonts
    OverlayFontSize_Small := 10
    OverlayFontSize_Medium := 11
    OverlayFontSize_Large := 12
    OverlayFontSize_EmojiDisplay := 10  ; s10 (increased by 1)
    OverlayFontSize_ButtonEmoji := 10  ; Button emojis on right side
} else {
    ; 2K, 4K, or larger - use normal fonts
    OverlayFontSize_Small := 8
    OverlayFontSize_Medium := 9
    OverlayFontSize_Large := 10
    OverlayFontSize_EmojiDisplay := 8  ; Keep same as before for 2K
    OverlayFontSize_ButtonEmoji := 9  ; Button emojis on right side (same as original)
}

; CHECK ADMIN REQUIREMENT IMMEDIATELY - BEFORE CREATING ANY GUI
; If auto-launch is enabled and we're not running as admin, relaunch as admin NOW
if (AutoLaunchWithHearthstone = 1 && !A_IsAdmin) {
    ; Relaunch as admin - this closes the current instance immediately
    Run("*RunAs " A_ScriptFullPath)
    ExitApp()  ; Exit before any GUI is created
}

; From here on, we're either:
; 1. Running in admin mode (because auto-launch is enabled)
; 2. Running in normal mode (because auto-launch is disabled)
; Either way, continue with normal initialization

; Initialize tracking variable for auto-launch state changes
global AutoLaunchWithHearthstone_Previous
AutoLaunchWithHearthstone_Previous := AutoLaunchWithHearthstone

; If we're running as admin and auto-launch is enabled, create the task immediately
; This happens when user enabled auto-launch and app relaunched as admin
if (A_IsAdmin && AutoLaunchWithHearthstone = 1) {
    SetupAutoLaunchScheduledTask()
}

; Only show settings GUI if SkipSettingsGUIOnStartup is not checked
if (SkipSettingsGUIOnStartup = 0) {
    CreateSettingsWindow()
}

CreateOverlayWindow()
CreateClickableOverlayWindow()
RegisterHotkeys()

; Check for updates on startup after a short delay (so GUI appears first)
SetTimer(CheckForUpdates, -100)

SetupTrayMenu()

; Initialize timers - v2 requires function references, not strings
SetTimer(MonitorHearthstone, 100)
SetTimer(UpdateOverlay, 16)  ; 16ms ≈ 60fps for smooth dragging
SetTimer(UpdateKeybindIndicatorPositions, 100)  ; Update indicator positions at same rate as MonitorHearthstone
SetTimer(DetectChatWindow, 500)  ; Check for chat window every 500ms

; Register OnExit callback for proper cleanup on any exit
OnExit(CleanupOnExit)

return

; ============================================================
; CONFIG MANAGEMENT
; ============================================================

LoadConfig() {
    global LevelUpKey, RerollKey, FreezeKey, BuyKey, SellKey, SendToDuoMateKey
    global FreezeX_Base, FreezeY_Base, RerollX_Base, RerollY_Base
    global LevelUpX_Base, LevelUpY_Base, BuyX_Base, BuyY_Base, SellX_Base, SellY_Base
    global SendToDuoMateX, SendToDuoMateY
    global FreezeX_1080p, FreezeY_1080p, RerollX_1080p, RerollY_1080p
    global LevelUpX_1080p, LevelUpY_1080p, BuyX_1080p, BuyY_1080p, SellX_1080p, SellY_1080p
    global FreezeX_1440p, FreezeY_1440p, RerollX_1440p, RerollY_1440p
    global LevelUpX_1440p, LevelUpY_1440p, BuyX_1440p, BuyY_1440p, SellX_1440p, SellY_1440p
    global FreezeX_4k, FreezeY_4k, RerollX_4k, RerollY_4k
    global LevelUpX_4k, LevelUpY_4k, BuyX_4k, BuyY_4k, SellX_4k, SellY_4k
    global ResolutionMode, OverlayX, OverlayY, ConfigFile, CloseOnHearthstoneExit, OverlayCompactMode, SkipSettingsGUIOnStartup, AutoLaunchWithHearthstone

    LevelUpKey := IniRead(ConfigFile, "Hotkeys", "LevelUp", "f")
    RerollKey := IniRead(ConfigFile, "Hotkeys", "Reroll", "d")
    FreezeKey := IniRead(ConfigFile, "Hotkeys", "Freeze", "Space")
    BuyKey := IniRead(ConfigFile, "Hotkeys", "Buy", "")
    SellKey := IniRead(ConfigFile, "Hotkeys", "Sell", "")
    SendToDuoMateKey := IniRead(ConfigFile, "Hotkeys", "SendToDuoMate", "")
    
    ; Load overlay compact mode (0=Full default, 1=Compact)
    OverlayCompactMode := Number(IniRead(ConfigFile, "Settings", "CompactMode", 0))

    ; Load 1080p coordinates
    FreezeX_1080p := Number(IniRead(ConfigFile, "Positions", "FreezeX_1080p", 1239))
    FreezeY_1080p := Number(IniRead(ConfigFile, "Positions", "FreezeY_1080p", 175))
    RerollX_1080p := Number(IniRead(ConfigFile, "Positions", "RerollX_1080p", 1127))
    RerollY_1080p := Number(IniRead(ConfigFile, "Positions", "RerollY_1080p", 208))
    LevelUpX_1080p := Number(IniRead(ConfigFile, "Positions", "LevelUpX_1080p", 791))
    LevelUpY_1080p := Number(IniRead(ConfigFile, "Positions", "LevelUpY_1080p", 208))
    SellX_1080p := Number(IniRead(ConfigFile, "Positions", "SellX_1080p", 979))
    SellY_1080p := Number(IniRead(ConfigFile, "Positions", "SellY_1080p", 160))

    ; Load 1440p coordinates
    FreezeX_1440p := Number(IniRead(ConfigFile, "Positions", "FreezeX_1440p", 1652))
    FreezeY_1440p := Number(IniRead(ConfigFile, "Positions", "FreezeY_1440p", 233))
    RerollX_1440p := Number(IniRead(ConfigFile, "Positions", "RerollX_1440p", 1503))
    RerollY_1440p := Number(IniRead(ConfigFile, "Positions", "RerollY_1440p", 277))
    LevelUpX_1440p := Number(IniRead(ConfigFile, "Positions", "LevelUpX_1440p", 1054))
    LevelUpY_1440p := Number(IniRead(ConfigFile, "Positions", "LevelUpY_1440p", 277))
    SellX_1440p := Number(IniRead(ConfigFile, "Positions", "SellX_1440p", 1305))
    SellY_1440p := Number(IniRead(ConfigFile, "Positions", "SellY_1440p", 213))

    ; Load 4K coordinates
    FreezeX_4k := Number(IniRead(ConfigFile, "Positions", "FreezeX_4k", 1858))
    FreezeY_4k := Number(IniRead(ConfigFile, "Positions", "FreezeY_4k", 262))
    RerollX_4k := Number(IniRead(ConfigFile, "Positions", "RerollX_4k", 1691))
    RerollY_4k := Number(IniRead(ConfigFile, "Positions", "RerollY_4k", 312))
    LevelUpX_4k := Number(IniRead(ConfigFile, "Positions", "LevelUpX_4k", 1186))
    LevelUpY_4k := Number(IniRead(ConfigFile, "Positions", "LevelUpY_4k", 312))
    SellX_4k := Number(IniRead(ConfigFile, "Positions", "SellX_4k", 1458))
    SellY_4k := Number(IniRead(ConfigFile, "Positions", "SellY_4k", 240))


    OverlayX := Number(IniRead(ConfigFile, "Overlay", "OverlayX", 20))
    OverlayY := Number(IniRead(ConfigFile, "Overlay", "OverlayY", 40))
    ResolutionMode := 4  ; Always custom mode (percentage-based offsets don't need presets)
    CloseOnHearthstoneExit := Number(IniRead(ConfigFile, "Settings", "CloseOnHearthstoneExit", 0))
    SkipSettingsGUIOnStartup := Number(IniRead(ConfigFile, "Settings", "SkipSettingsGUIOnStartup", 0))
    AutoLaunchWithHearthstone := Number(IniRead(ConfigFile, "Settings", "AutoLaunchWithHearthstone", 0))
    ShowBaseHotkeysClickLocations := Number(IniRead(ConfigFile, "Settings", "ShowBaseHotkeysClickLocations", 0))
    ShowAdditionalHotkeysClickLocations := Number(IniRead(ConfigFile, "Settings", "ShowAdditionalHotkeysClickLocations", 0))
}

CheckForUpdates() {
    global CurrentVersion, SettingsGuiObj
    
    try {
        ; Try to download the releases page HTML
        url := "https://api.github.com/repos/linegrinder/Hearthstone-Battlegrounds-Hotkeys/releases/latest"
        
        ; Use a temp file for the download
        tempFile := A_Temp . "\release.txt"
        
        if FileExist(tempFile)
            FileDelete(tempFile)
        
        ; Download with error handling
        Download(url, tempFile)
        
        if !FileExist(tempFile)
            return
        
        ; Read the content
        content := FileRead(tempFile)
        
        if (content = "")
            return
        
        ; Look for tag_name field in JSON response
        ; The pattern is: "tag_name":"v1.1" or similar
        pattern := "tag_name"
        pos := InStr(content, pattern)
        
        if !pos {
            FileDelete(tempFile)
            return
        }
        
        ; Extract everything after tag_name
        remainder := SubStr(content, pos + StrLen(pattern))
        
        ; Find the version number - look for the quoted value after the colon
        ; Skip to the colon first
        colonPos := InStr(remainder, ":")
        if !colonPos {
            FileDelete(tempFile)
            return
        }
        
        afterColon := SubStr(remainder, colonPos + 1)
        
        ; Find the opening quote
        quotePos := InStr(afterColon, Chr(34))
        if !quotePos {
            FileDelete(tempFile)
            return
        }
        
        ; Get text after opening quote
        afterQuote := SubStr(afterColon, quotePos + 1)
        
        ; Find closing quote
        closeQuotePos := InStr(afterQuote, Chr(34))
        if !closeQuotePos {
            FileDelete(tempFile)
            return
        }
        
        ; Extract the version tag (e.g., "v1.1")
        versionTag := SubStr(afterQuote, 1, closeQuotePos - 1)
        
        ; Remove 'v' prefix
        latestVersion := StrReplace(versionTag, "v", "")
        
        FileDelete(tempFile)
        
        ; Now compare versions
        if (latestVersion != "" && latestVersion != CurrentVersion) {
            ; Check if latest is actually newer
            if (CompareVersions(latestVersion, CurrentVersion) > 0) {
                ; Show the update notification
                SettingsGuiObj.Opt("-AlwaysOnTop")
                result := MsgBox("A new update is available!`n`nCurrent: v" . CurrentVersion . "`nLatest: v" . latestVersion . "`n`nDownload the newest update now?", "Update Available", 4)
                SettingsGuiObj.Opt("+AlwaysOnTop")
                if (result = "Yes") {
                    Run("https://github.com/linegrinder/Hearthstone-Battlegrounds-Hotkeys/releases/latest")
                }
            }
        }
        
    } catch as err {
        ; Silently fail - don't bother user with update check errors
        return
    }
}

CompareVersions(version1, version2) {
    ; Compares two version strings (e.g., "1.1" vs "1.0")
    ; Returns: 1 if version1 > version2, -1 if version1 < version2, 0 if equal
    ; (Currently unused, but kept for future version checker implementation)
    
    parts1 := StrSplit(version1, ".")
    parts2 := StrSplit(version2, ".")
    
    ; Compare each part
    maxParts := (parts1.Length > parts2.Length) ? parts1.Length : parts2.Length
    
    Loop maxParts {
        v1 := (A_Index <= parts1.Length) ? Number(parts1[A_Index]) : 0
        v2 := (A_Index <= parts2.Length) ? Number(parts2[A_Index]) : 0
        
        if (v1 > v2)
            return 1
        else if (v1 < v2)
            return -1
    }
    
    return 0  ; Equal
}

SaveConfig() {
    global LevelUpKey, RerollKey, FreezeKey, BuyKey, SellKey, SendToDuoMateKey
    global FreezeX_1080p, FreezeY_1080p, RerollX_1080p, RerollY_1080p
    global LevelUpX_1080p, LevelUpY_1080p, BuyX_1080p, BuyY_1080p, SellX_1080p, SellY_1080p
    global FreezeX_1440p, FreezeY_1440p, RerollX_1440p, RerollY_1440p
    global LevelUpX_1440p, LevelUpY_1440p, BuyX_1440p, BuyY_1440p, SellX_1440p, SellY_1440p
    global FreezeX_4k, FreezeY_4k, RerollX_4k, RerollY_4k
    global LevelUpX_4k, LevelUpY_4k, BuyX_4k, BuyY_4k, SellX_4k, SellY_4k
    global ResolutionMode, OverlayX, OverlayY, ConfigFile, CloseOnHearthstoneExit, OverlayCompactMode, SkipSettingsGUIOnStartup, AutoLaunchWithHearthstone

    IniWrite(LevelUpKey, ConfigFile, "Hotkeys", "LevelUp")
    IniWrite(RerollKey, ConfigFile, "Hotkeys", "Reroll")
    IniWrite(FreezeKey, ConfigFile, "Hotkeys", "Freeze")
    IniWrite(BuyKey, ConfigFile, "Hotkeys", "Buy")
    IniWrite(SellKey, ConfigFile, "Hotkeys", "Sell")
    IniWrite(SendToDuoMateKey, ConfigFile, "Hotkeys", "SendToDuoMate")

    ; Save 1080p coordinates
    IniWrite(FreezeX_1080p, ConfigFile, "Positions", "FreezeX_1080p")
    IniWrite(FreezeY_1080p, ConfigFile, "Positions", "FreezeY_1080p")
    IniWrite(RerollX_1080p, ConfigFile, "Positions", "RerollX_1080p")
    IniWrite(RerollY_1080p, ConfigFile, "Positions", "RerollY_1080p")
    IniWrite(LevelUpX_1080p, ConfigFile, "Positions", "LevelUpX_1080p")
    IniWrite(LevelUpY_1080p, ConfigFile, "Positions", "LevelUpY_1080p")
    IniWrite(SellX_1080p, ConfigFile, "Positions", "SellX_1080p")
    IniWrite(SellY_1080p, ConfigFile, "Positions", "SellY_1080p")

    ; Save 1440p coordinates
    IniWrite(FreezeX_1440p, ConfigFile, "Positions", "FreezeX_1440p")
    IniWrite(FreezeY_1440p, ConfigFile, "Positions", "FreezeY_1440p")
    IniWrite(RerollX_1440p, ConfigFile, "Positions", "RerollX_1440p")
    IniWrite(RerollY_1440p, ConfigFile, "Positions", "RerollY_1440p")
    IniWrite(LevelUpX_1440p, ConfigFile, "Positions", "LevelUpX_1440p")
    IniWrite(LevelUpY_1440p, ConfigFile, "Positions", "LevelUpY_1440p")
    IniWrite(SellX_1440p, ConfigFile, "Positions", "SellX_1440p")
    IniWrite(SellY_1440p, ConfigFile, "Positions", "SellY_1440p")

    ; Save 4K coordinates
    IniWrite(FreezeX_4k, ConfigFile, "Positions", "FreezeX_4k")
    IniWrite(FreezeY_4k, ConfigFile, "Positions", "FreezeY_4k")
    IniWrite(RerollX_4k, ConfigFile, "Positions", "RerollX_4k")
    IniWrite(RerollY_4k, ConfigFile, "Positions", "RerollY_4k")
    IniWrite(LevelUpX_4k, ConfigFile, "Positions", "LevelUpX_4k")
    IniWrite(LevelUpY_4k, ConfigFile, "Positions", "LevelUpY_4k")
    IniWrite(SellX_4k, ConfigFile, "Positions", "SellX_4k")
    IniWrite(SellY_4k, ConfigFile, "Positions", "SellY_4k")

    IniWrite(OverlayX, ConfigFile, "Overlay", "OverlayX")
    IniWrite(OverlayY, ConfigFile, "Overlay", "OverlayY")
    
    IniWrite(CloseOnHearthstoneExit, ConfigFile, "Settings", "CloseOnHearthstoneExit")
    IniWrite(OverlayCompactMode, ConfigFile, "Settings", "CompactMode")
    IniWrite(SkipSettingsGUIOnStartup, ConfigFile, "Settings", "SkipSettingsGUIOnStartup")
    IniWrite(AutoLaunchWithHearthstone, ConfigFile, "Settings", "AutoLaunchWithHearthstone")
    IniWrite(ShowBaseHotkeysClickLocations, ConfigFile, "Settings", "ShowBaseHotkeysClickLocations")
    IniWrite(ShowAdditionalHotkeysClickLocations, ConfigFile, "Settings", "ShowAdditionalHotkeysClickLocations")
}

; ============================================================
; HELPERS
; ============================================================

GetKeyDisplayName(key) {
    if (key = "")
        return "-"
    if (key = "Space")
        return "Space"
    if (key = "MButton")
        return "MMB"
    if (key = "XButton1")
        return "M4"
    if (key = "XButton2")
        return "M5"
    if (key = "WheelUp")
        return "MWU"
    if (key = "WheelDown")
        return "MWD"
    return StrUpper(key)
}

IsHearthstoneActive() {
    return WinActive("ahk_exe Hearthstone.exe")
}

GetHearthstoneWindowInfo(&x, &y, &w, &h) {
    if (WinExist("ahk_exe Hearthstone.exe")) {
        ; Use WinGetClientPos to get the client area (excludes title bar and borders)
        ; This works correctly in both fullscreen and windowed modes
        WinGetClientPos(&x, &y, &w, &h, "ahk_exe Hearthstone.exe")
        return true
    }
    return false
}

; ============================================================
; SETTINGS WINDOW
; ============================================================

; Button references for updating keybind displays
global lvlKeybindBtn, rrKeybindBtn, frzKeybindBtn, buyKeybindBtn, sellKeybindBtn, duoKeybindBtn

; ============================================================
; OVERLAY MODE MANAGEMENT
; ============================================================

OnCompactModeChange(newMode) {
    global TempOverlayCompactMode
    ; Only update the temporary variable, don't change the actual overlay yet
    TempOverlayCompactMode := newMode
}

ToggleCustomCapture() {
    global EnableCustomCapture
    
    ; Update the global variable
    EnableCustomCapture := !EnableCustomCapture
}

RecreateOverlay() {
    global OverlayGuiObj, ClickableOverlayGuiObj, OverlayDisplayInitialized
    
    ; Safely destroy existing overlays if they exist
    try {
        if (OverlayGuiObj && IsObject(OverlayGuiObj)) {
            try {
                OverlayGuiObj.Destroy()
            }
        }
    }
    try {
        if (ClickableOverlayGuiObj && IsObject(ClickableOverlayGuiObj)) {
            try {
                ClickableOverlayGuiObj.Destroy()
            }
        }
    }
    
    ; Reset display initialization flag since we're creating a new overlay
    OverlayDisplayInitialized := 0
    
    ; Recreate them with new dimensions
    CreateOverlayWindow()
    CreateClickableOverlayWindow()
}

CreateSettingsWindow() {
    global SettingsGuiObj, LevelUpKey, RerollKey, FreezeKey, BuyKey, SellKey, SendToDuoMateKey
    global TempLevelUpKey, TempRerollKey, TempFreezeKey, TempBuyKey, TempSellKey, TempSendToDuoMateKey
    global lvlKeybindBtn, rrKeybindBtn, frzKeybindBtn, buyKeybindBtn, sellKeybindBtn, duoKeybindBtn
    global FreezeX_Base, FreezeY_Base, RerollX_Base, RerollY_Base
    global LevelUpX_Base, LevelUpY_Base, BuyX_Base, BuyY_Base, SellX_Base, SellY_Base
    global ResolutionMode
    global OverlayCompactMode, TempOverlayCompactMode, CloseOnHearthstoneExit, SkipSettingsGUIOnStartup, AutoLaunchWithHearthstone
    
    ; Initialize temp settings to current saved values
    TempLevelUpKey := LevelUpKey
    TempRerollKey := RerollKey
    TempFreezeKey := FreezeKey
    TempBuyKey := BuyKey
    TempSellKey := SellKey
    TempSendToDuoMateKey := SendToDuoMateKey
    TempOverlayCompactMode := OverlayCompactMode

    SettingsGuiObj := Gui()
    SettingsGuiObj.Opt("+AlwaysOnTop")
    SettingsGuiObj.BackColor := "FFFFFF"

    ; ===== BASE HOTKEY CONFIGURATION =====
	SettingsGuiObj.Add("GroupBox", "x20 y13 w271 h153", "Base Hotkey Configuration")

    ; Try to load Bob image, but don't fail if it's missing
    try {
        bobPath := A_Temp . "\Bob_Hotkey.png"
        if (FileExist(bobPath))
            SettingsGuiObj.Add("Picture", "x315 y24 w184 h200", bobPath)
    }

    ; Level Up Key
    SettingsGuiObj.Add("Text", "x40 y39", "Level Up Key:")
    lvlKeybindBtn := SettingsGuiObj.Add("Button", "x140 y36 w100 h25", GetKeyDisplayName(LevelUpKey))
    lvlKeybindBtn.OnEvent("Click", CaptureLvlKey)
    lvlClearBtn := SettingsGuiObj.Add("Button", "x245 y36 w20 h25", "×")
    lvlClearBtn.OnEvent("Click", ClearLvlKey)

    ; Reroll Key
    SettingsGuiObj.Add("Text", "x40 y69", "Reroll Key:")
    rrKeybindBtn := SettingsGuiObj.Add("Button", "x140 y66 w100 h25", GetKeyDisplayName(RerollKey))
    rrKeybindBtn.OnEvent("Click", CaptureRRKey)
    rrClearBtn := SettingsGuiObj.Add("Button", "x245 y66 w20 h25", "×")
    rrClearBtn.OnEvent("Click", ClearRRKey)

    ; Freeze Key
    SettingsGuiObj.Add("Text", "x40 y99", "Freeze Key:")
    frzKeybindBtn := SettingsGuiObj.Add("Button", "x140 y96 w100 h25", GetKeyDisplayName(FreezeKey))
    frzKeybindBtn.OnEvent("Click", CaptureFrzKey)
    frzClearBtn := SettingsGuiObj.Add("Button", "x245 y96 w20 h25", "×")
    frzClearBtn.OnEvent("Click", ClearFrzKey)
    
    ; Show base hotkeys click locations checkbox
    showBaseClickLocationsCheckbox := SettingsGuiObj.Add("Checkbox", "x30 y132 w260 h20 vShowBaseHotkeysClickLocations", "Show base hotkeys click locations in-game")
    showBaseClickLocationsCheckbox.Value := ShowBaseHotkeysClickLocations

    ; ===== ADDITIONAL HOTKEY CONFIGURATION =====
    SettingsGuiObj.Add("GroupBox", "x20 y181 w271 h155", "Additional Hotkey Configuration")

    ; Buy Key
    buyKeyLabel := SettingsGuiObj.Add("Text", "x40 y207 w100 h20", "Buy Key:")
    buyKeyLabel.ToolTip := "Hover over a minion and press this hotkey to buy"
    buyKeybindBtn := SettingsGuiObj.Add("Button", "x140 y204 w100 h25", GetKeyDisplayName(BuyKey))
    buyKeybindBtn.OnEvent("Click", CaptureBuyKey)
    buyKeybindBtn.ToolTip := "Hover over a minion and press this hotkey to buy"
    buyClearBtn := SettingsGuiObj.Add("Button", "x245 y204 w20 h25", "×")
    buyClearBtn.OnEvent("Click", ClearBuyKey)

    ; Sell Key
    sellKeyLabel := SettingsGuiObj.Add("Text", "x40 y237 w100 h20", "Sell Key:")
    sellKeyLabel.ToolTip := "Hover over a minion and press this hotkey to sell"
    sellKeybindBtn := SettingsGuiObj.Add("Button", "x140 y234 w100 h25", GetKeyDisplayName(SellKey))
    sellKeybindBtn.OnEvent("Click", CaptureSellKey)
    sellKeybindBtn.ToolTip := "Hover over a minion and press this hotkey to sell"
    sellClearBtn := SettingsGuiObj.Add("Button", "x245 y234 w20 h25", "×")
    sellClearBtn.OnEvent("Click", ClearSellKey)


    ; Send to Duo Mate Key
    duoKeyLabel := SettingsGuiObj.Add("Text", "x40 y267 w100 h20", "Send to Duo Mate:")
    duoKeyLabel.ToolTip := "Hover over a card in your hand and press this hotkey to send it your duo mate"
    duoKeybindBtn := SettingsGuiObj.Add("Button", "x140 y264 w100 h25", GetKeyDisplayName(SendToDuoMateKey))
    duoKeybindBtn.OnEvent("Click", CaptureDuoKey)
    duoKeybindBtn.ToolTip := "Hover over a card in your hand and press this hotkey to send it your duo mate"
    duoClearBtn := SettingsGuiObj.Add("Button", "x245 y264 w20 h25", "×")
    duoClearBtn.OnEvent("Click", ClearDuoKey)
    
    ; Set up tooltip handler for Settings GUI
    OnMessage(0x0200, SettingsTooltipHandler)
    
    ; Show additional hotkeys click locations checkbox
    showAdditionalClickLocationsCheckbox := SettingsGuiObj.Add("Checkbox", "x30 y299 w260 h20 vShowAdditionalHotkeysClickLocations", "Show additional hotkeys click locations in-game")
    showAdditionalClickLocationsCheckbox.Value := ShowAdditionalHotkeysClickLocations

    ; ===== IN-GAME OVERLAY APPEARANCE =====
    SettingsGuiObj.Add("GroupBox", "x308 y255 w200 h81", "In-game Overlay Appearance")
    
    fullRadio := SettingsGuiObj.Add("Radio", "x318 y278 w180 h20 vOverlayCompactMode", "Full")
    fullRadio.Value := (OverlayCompactMode = 0 ? 1 : 0)
    fullRadio.OnEvent("Click", (*) => OnCompactModeChange(0))
    
    compactRadio := SettingsGuiObj.Add("Radio", "x318 y304 w180 h20", "Compact")
    compactRadio.Value := (OverlayCompactMode = 1 ? 1 : 0)
    compactRadio.OnEvent("Click", (*) => OnCompactModeChange(1))

    ; ===== GENERAL SETTINGS =====
    SettingsGuiObj.Add("GroupBox", "x20 y352 w488 h107", "General Settings")
    autoLaunchCheckbox := SettingsGuiObj.Add("Checkbox", "x30 y374 w468 h20 vAutoLaunchWithHearthstone", "Auto-launch when Hearthstone starts")
    autoLaunchCheckbox.Value := AutoLaunchWithHearthstone
    
    skipSettingsCheckbox := SettingsGuiObj.Add("Checkbox", "x30 y401 w468 h20 vSkipSettingsGUIOnStartup", "Skip settings GUI on next startup")
    skipSettingsCheckbox.Value := SkipSettingsGUIOnStartup
    
    closeOnExitCheckbox := SettingsGuiObj.Add("Checkbox", "x30 y425 w468 h23 vCloseOnHearthstoneExit", "Close BG Hotkeys when exiting Hearthstone")
    closeOnExitCheckbox.Value := CloseOnHearthstoneExit

    saveBtn := SettingsGuiObj.Add("Button", "x20 y480 w200 h35 Default", "Save && Minimize")
    saveBtn.OnEvent("Click", (*) => SaveAndMinimize())
    
    donateBtn := SettingsGuiObj.Add("Button", "x413 y493 w95 h22", "❤ Donate")
    donateBtn.OnEvent("Click", (*) => OpenDonateLink())
    donateBtn.SetFont("s8", "Segoe UI")

    SettingsGuiObj.Title := "Hearthstone BGs Hotkeys Settings" . (A_IsAdmin ? " [Admin Mode]" : "")
    SettingsGuiObj.OnEvent("Close", (*) => CloseApp())
    SettingsGuiObj.OnMessage(0x112, WM_SYSCOMMAND)  ; 0x112 is WM_SYSCOMMAND
    SettingsGuiObj.Show("w528 h537")
}

; ============================================================
; CALCULATE OVERLAY WIDTH BASED ON ENABLED KEYS
; ============================================================

CalculateOverlayWidth() {
    global LevelUpKey, RerollKey, FreezeKey, BuyKey, SellKey, SendToDuoMateKey
    
    ; Count how many keys are NOT empty (enabled)
    enabledKeysCount := 0
    
    if (LevelUpKey != "")
        enabledKeysCount++
    if (RerollKey != "")
        enabledKeysCount++
    if (FreezeKey != "")
        enabledKeysCount++
    if (BuyKey != "")
        enabledKeysCount++
    if (SellKey != "")
        enabledKeysCount++
    if (SendToDuoMateKey != "")
        enabledKeysCount++
    
    ; Calculate width: 319px for 6 keys, reduce by 20px per key below 6
    ; Minimum width is 179px (for 3 or fewer keys)
    if (enabledKeysCount >= 3) {
        overlayWidth := 319 - ((6 - enabledKeysCount) * 20)
    } else {
        overlayWidth := 179  ; Minimum width
    }
    
    return overlayWidth
}

; ============================================================
; UPDATE OVERLAY DIMENSIONS
; ============================================================

UpdateOverlayDimensions() {
    global OverlayGuiObj, ClickableOverlayGuiObj, GlobalOverlayScreenX, GlobalOverlayScreenY, OverlayCompactMode
    
    overlayWidth := (OverlayCompactMode = 1) ? 251 : 412
    
    ; Get current position (use global vars if available, otherwise default to current)
    if (GlobalOverlayScreenX != "" && GlobalOverlayScreenY != "") {
        OverlayGuiObj.Show("x" . GlobalOverlayScreenX . " y" . GlobalOverlayScreenY . " w" . overlayWidth . " h60 NoActivate")
        ClickableOverlayGuiObj.Show("x" . GlobalOverlayScreenX . " y" . GlobalOverlayScreenY . " w" . overlayWidth . " h60 NoActivate")
    }
}

CreateOverlayWindow() {
    global OverlayGuiObj, LevelUpKey, RerollKey, FreezeKey, BuyKey, SellKey, SendToDuoMateKey, KeybindIndicatorsVisible, OverlayCompactMode

    OverlayGuiObj := Gui()
    ; Add WS_EX_NOACTIVATE (0x08000000) to prevent the overlay from stealing focus when clicked
    ; Add -DPIScale to prevent Windows from applying DPI scaling (we handle it manually)
    OverlayGuiObj.Opt("-Caption -Border +AlwaysOnTop +ToolWindow +E0x08000000 -DPIScale")
    OverlayGuiObj.BackColor := "2e3235"
    OverlayGuiObj.MarginX := 0
    OverlayGuiObj.MarginY := 0

    ; Determine dimensions based on compact mode
    ; Compact: 190px content + 1px left padding + 19px buttons + 1px right padding = 211px total
    ; Full: 380px content + 1px left padding + 19px buttons + 1px right padding = 401px total
    contentWidth := (OverlayCompactMode = 1) ? 229 : 390
    buttonX := contentWidth + 1  ; Position buttons with 1px left padding
    textWidth := contentWidth - 16  ; Leave 8px padding on each side
    overlayFullWidth := buttonX + 19 + 1  ; Content width + 1px left padding + button width + 1px right padding

    ; CREATE BUTTONS FIRST so they render properly
    ; Set font for buttons BEFORE creating them
    global OverlayFontSize_ButtonEmoji
    OverlayGuiObj.SetFont("s" . OverlayFontSize_ButtonEmoji . " cFFFFFF", "Segoe UI")
    
    ; Pause/Play button - toggles hotkeys on/off
    pausePlayBtn := OverlayGuiObj.Add("Button", "x" . buttonX . " y3 w19 h18 -Default", HotkeysEnabled ? "⏸️" : "▶️")
    pausePlayBtn.OnEvent("Click", TogglePausePlayNoFlash)
    pausePlayBtn.SetColor(0x2e3235, 0xFFFFFF)  ; Dark grey background (GUI color) with white text
    pausePlayBtn.ShowBorder := 0
    pausePlayBtn.RoundedCorner := 0
    
    ; Lock button - below visibility button
    lockBtn := OverlayGuiObj.Add("Button", "x" . buttonX . " y24 w19 h18 -Default", OverlayLocked ? "🔒" : "🔓")
    lockBtn.OnEvent("Click", ToggleLockNoFlash)
    lockBtn.SetColor(0x2e3235, 0xFFFFFF)  ; Dark grey background (GUI color) with white text
    lockBtn.ShowBorder := 0
    lockBtn.RoundedCorner := 0

    ; Settings button - at bottom
    settingsBtn := OverlayGuiObj.Add("Button", "x" . buttonX . " y45 w19 h18 -Default", "⚙️")
    settingsBtn.OnEvent("Click", ShowSettingsNoFlash)
    settingsBtn.SetColor(0x2e3235, 0xFFFFFF)  ; Dark grey background (GUI color) with white text
    settingsBtn.ShowBorder := 0
    settingsBtn.RoundedCorner := 0
    
    ; ===== CREATE TOP DARK GREY BOX =====
    topBg := OverlayGuiObj.Add("Text", "x0 y0 w" . contentWidth . " h33", "")
    topBg.Opt("+Background1c2022")
    
    ; Top border
    topBorder := OverlayGuiObj.Add("Text", "x0 y0 w" . overlayFullWidth . " h1", "")
    topBorder.Opt("+Background4a5256")
    ; Left border (add first, will be covered but that's ok)
    leftBorder := OverlayGuiObj.Add("Text", "x0 y0 w1 h66", "")
    leftBorder.Opt("+Background4a5256")
    ; Right border
    rightBorder := OverlayGuiObj.Add("Text", "x" . (contentWidth - 1) . " y0 w1 h66", "")
    rightBorder.Opt("+Background4a5256")
    
    ; Right border for buttons area - position depends on mode
    rightBorderButtonsX := (OverlayCompactMode = 1) ? 250 : (contentWidth + 1 + 19 + 1)
    rightBorderButtons := OverlayGuiObj.Add("Text", "x" . rightBorderButtonsX . " y0 w1 h66", "")
    rightBorderButtons.Opt("+Background4a5256")

    ; "Hotkeys: " text in top box (normal white text)
    global OverlayFontSize_Large, monitorWidth
    OverlayGuiObj.SetFont("s" . OverlayFontSize_Large . " Norm", "Segoe UI")
    hotkeysWidth := 70
    hotkeysXPos := 8
    hotkeysText := OverlayGuiObj.Add("Text", "x" . hotkeysXPos . " y5 w" . hotkeysWidth . " h23 cFFFFFF", "Hotkeys:")
    hotkeysText.Opt("+Background1c2022")
    
    ; "ON" text in top box (bold, green/red, positioned right after "Hotkeys:")
    OverlayGuiObj.SetFont("s" . OverlayFontSize_Large . " Bold", "Segoe UI")
    ; Position right after "Hotkeys: " with a small gap
    onXPos := hotkeysXPos + hotkeysWidth + 2
    onText := OverlayGuiObj.Add("Text", "x" . onXPos . " y5 w50 h23 c00FF00", "ON")
    onText.Opt("+Background1c2022")
    
    ; Store reference globally so we can update it
    global OverlayStatusText := onText

    ; ===== CREATE BOTTOM LIGHT GREY BOX =====
    bottomBg := OverlayGuiObj.Add("Text", "x0 y33 w" . contentWidth . " h33", "")
    bottomBg.Opt("+Background2e3235")
    
    ; Horizontal divider line between top and bottom boxes
    dividerBorder := OverlayGuiObj.Add("Text", "x0 y33 w" . contentWidth . " h1", "")
    dividerBorder.Opt("+Background4a5256")
    
    ; Bottom border (position at y65 to be at the edge of the 66px overlay)
    bottomBorder := OverlayGuiObj.Add("Text", "x0 y65 w" . overlayFullWidth . " h1", "")
    bottomBorder.Opt("+Background4a5256")
    
    ; Left border bottom half (re-add after bottom box to ensure it's visible on the light grey section)
    leftBorderBottom := OverlayGuiObj.Add("Text", "x0 y33 w1 h32", "")
    leftBorderBottom.Opt("+Background4a5256")
    
    ; Right border bottom half (re-add after bottom box to ensure it's visible on the light grey section)
    rightBorderBottom := OverlayGuiObj.Add("Text", "x" . (contentWidth - 1) . " y33 w1 h32", "")
    rightBorderBottom.Opt("+Background4a5256")
    
    ; Bottom border segment for bottom-left corner
    bottomLeftBorder := OverlayGuiObj.Add("Text", "x0 y65 w2 h1", "")
    bottomLeftBorder.Opt("+Background4a5256")

    ; Emoji hotkeys text in bottom box
    global OverlayFontSize_EmojiDisplay
    OverlayGuiObj.SetFont("s" . OverlayFontSize_EmojiDisplay . " Bold", "Segoe UI")
    hotkeyText := OverlayGuiObj.Add("Text", "x8 y38 w" . textWidth . " h20 cFFFFFF Center VCenter -Wrap", "")
    hotkeyText.Opt("+Background2e3235")
    
    ; Build the hotkey display text based on compact mode
    ; In compact mode: only Level Up, Reroll, Freeze
    ; In full mode: all 6 keys
    if (OverlayCompactMode = 1) {
        displayText := "⏫: " . GetKeyDisplayName(LevelUpKey) . "  |  🔄: " . GetKeyDisplayName(RerollKey) . "  |  ❄️: " . GetKeyDisplayName(FreezeKey)
    } else {
        displayText := "⏫: " . GetKeyDisplayName(LevelUpKey) . "  |  🔄: " . GetKeyDisplayName(RerollKey) . "  |  ❄️: " . GetKeyDisplayName(FreezeKey) . "  |  🡻: " . GetKeyDisplayName(BuyKey) . "  |  💲: " . GetKeyDisplayName(SellKey) . "  |  ➡️: " . GetKeyDisplayName(SendToDuoMateKey)
    }
    hotkeyText.Value := displayText
    
    ; Store references globally
    global OverlayHotkeyText := hotkeyText
    global OverlayLockBtn := lockBtn
    global OverlaySettingsBtn := settingsBtn
    global OverlayPausePlayBtn := pausePlayBtn

    ; Reset font
    OverlayGuiObj.SetFont()

    ; Don't show overlay on startup - MonitorHearthstone will show it when Hearthstone is active
}

UpdateOverlayDisplay() {
    global LevelUpKey, RerollKey, FreezeKey, BuyKey, SellKey, SendToDuoMateKey
    global OverlayHotkeyText, OverlayLockBtn, OverlaySettingsBtn, OverlayVisibilityBtn, OverlayCompactMode
    
    ; Build display text with all keys (showing "-" for unset)
    displayParts := []
    
    ; Always show the 3 base keys
    displayParts.Push("⏫: " . (LevelUpKey != "" ? GetKeyDisplayName(LevelUpKey) : "-"))
    displayParts.Push("🔄: " . (RerollKey != "" ? GetKeyDisplayName(RerollKey) : "-"))
    displayParts.Push("❄️: " . (FreezeKey != "" ? GetKeyDisplayName(FreezeKey) : "-"))
    
    ; Only show additional keys if NOT in compact mode
    if (OverlayCompactMode = 0) {
        displayParts.Push("🡻: " . (BuyKey != "" ? GetKeyDisplayName(BuyKey) : "-"))
        displayParts.Push("💲: " . (SellKey != "" ? GetKeyDisplayName(SellKey) : "-"))
        displayParts.Push("➡️: " . (SendToDuoMateKey != "" ? GetKeyDisplayName(SendToDuoMateKey) : "-"))
    }
    
    ; Join with separators
    displayText := ""
    Loop displayParts.Length {
        displayText .= displayParts[A_Index]
        if (A_Index < displayParts.Length)
            displayText .= "  |  "
    }
    
    OverlayHotkeyText.Value := displayText
}

CreateClickableOverlayWindow() {
    global ClickableOverlayGuiObj, OverlayLocked, OverlayCompactMode

    ClickableOverlayGuiObj := Gui()
    ; Make it invisible but clickable - use IDENTICAL options as OverlayGuiObj
    ; Add -DPIScale to prevent Windows from applying DPI scaling (we handle it manually)
    ClickableOverlayGuiObj.Opt("-Caption -Border +AlwaysOnTop +ToolWindow +E0x08000000 -DPIScale")
    ClickableOverlayGuiObj.BackColor := "000000"  ; Black background (invisible)
    ClickableOverlayGuiObj.MarginX := 0
    ClickableOverlayGuiObj.MarginY := 0
    
    ; Add a transparent clickable area that covers the entire overlay with dynamic width
    overlayWidth := (OverlayCompactMode = 1) ? 251 : 412
    clickableArea := ClickableOverlayGuiObj.Add("Text", "x0 y0 w" . overlayWidth . " h66", "")
    clickableArea.Opt("+Background000000")
}

ShowSettingsNoFlash(GuiCtrlObj, Info) {
    ; Update button text briefly to provide feedback (like the other buttons do)
    oldText := GuiCtrlObj.Text
    GuiCtrlObj.Text := "..."
    
    ShowSettings()
    
    ; Restore the button text
    GuiCtrlObj.Text := oldText
    
    ; Re-activate Hearthstone to prevent flash
    WinActivate("ahk_exe Hearthstone.exe")
}

ToggleLockNoFlash(GuiCtrlObj, Info) {
    global OverlayLocked, OverlayGuiObj
    ToggleLock()
    
    ; Update button emoji based on new lock state
    if (OverlayLocked)
        GuiCtrlObj.Text := "🔒"
    else
        GuiCtrlObj.Text := "🔓"
    
    ; Re-activate Hearthstone to prevent flash
    WinActivate("ahk_exe Hearthstone.exe")
}

ToggleKeybindVisibilityNoFlash(GuiCtrlObj, Info) {
    global KeybindIndicatorsVisible
    KeybindIndicatorsVisible := !KeybindIndicatorsVisible
    
    ; Update button based on visibility state
    if (KeybindIndicatorsVisible)
        GuiCtrlObj.Text := "👁️"
    else
        GuiCtrlObj.Text := "🚫"
    
    ; Hide if toggled off
    if (!KeybindIndicatorsVisible)
        HideKeybindIndicators()
    
    ; Re-activate Hearthstone to prevent flash
    WinActivate("ahk_exe Hearthstone.exe")
}

TogglePausePlayNoFlash(GuiCtrlObj, Info) {
    global HotkeysEnabled, OverlayStatusText, OverlayFontSize_Large
    HotkeysEnabled := !HotkeysEnabled
    
    ; Update button emoji based on hotkey state
    if (HotkeysEnabled)
        GuiCtrlObj.Text := "⏸️"  ; Show pause icon when hotkeys are enabled
    else
        GuiCtrlObj.Text := "▶️"  ; Show play icon when hotkeys are disabled
    
    ; Update the ON/OFF status text only (Hotkeys: stays the same)
    if (HotkeysEnabled) {
        try {
            OverlayStatusText.SetFont("s" . OverlayFontSize_Large . " Bold c00FF00")  ; Green for ON
            OverlayStatusText.Value := "ON"
        }
    } else {
        try {
            OverlayStatusText.SetFont("s" . OverlayFontSize_Large . " Bold c" . "FF0000")  ; Red for OFF
            OverlayStatusText.Value := "OFF"
        }
    }
    
    ; Re-activate Hearthstone to prevent flash
    WinActivate("ahk_exe Hearthstone.exe")
}


UpdateKeybindIndicators() {
    global ShowBaseHotkeysClickLocations, ShowAdditionalHotkeysClickLocations, KeybindIndicatorsGuiObj, indicatorGUIs
    global LevelUpX_Base, LevelUpY_Base, RerollX_Base, RerollY_Base, FreezeX_Base, FreezeY_Base
    global BuyX_Base, BuyY_Base, SellX_Base, SellY_Base
    global LevelUpKey, RerollKey, FreezeKey, BuyKey, SellKey, SendToDuoMateKey, BaseW, BaseH
    
    ; Show indicators if either checkbox is enabled
    shouldShowIndicators := (ShowBaseHotkeysClickLocations || ShowAdditionalHotkeysClickLocations)
    
    if (shouldShowIndicators) {
        if (!GetHearthstoneWindowInfo(&hsX, &hsY, &hsW, &hsH))
            return
        
        ; Only create GUIs if they don't exist yet (check if empty array or not initialized)
        if (!IsObject(KeybindIndicatorsGuiObj) || KeybindIndicatorsGuiObj.Length = 0) {
            indicatorGUIs := []
            
            ; Create indicators for base hotkeys if checkbox is enabled
            if (ShowBaseHotkeysClickLocations) {
                baseIndicators := [
                    {x: LevelUpX_Base, y: LevelUpY_Base, key: LevelUpKey},
                    {x: RerollX_Base, y: RerollY_Base, key: RerollKey},
                    {x: FreezeX_Base, y: FreezeY_Base, key: FreezeKey}
                ]
                
                for indicator in baseIndicators {
                    ; Skip indicators with no key assigned
                    if (indicator.key = "")
                        continue
                    
                    ; Create individual GUI for each indicator (even if key is empty, show "-")
                    indicatorGui := Gui()
                    indicatorGui.Opt("-Caption -Border +AlwaysOnTop +ToolWindow +E0x08000000")
                    indicatorGui.BackColor := "000000"
                    
                    ; Get the key display name and determine font size based on text length
                    global OverlayFontSize_Small, OverlayFontSize_Large, monitorWidth
                    keyDisplayName := GetKeyDisplayName(indicator.key)
                    ; For 1080p: decrease by 1pt, for 2K keep original
                    if (monitorWidth <= 1920) {
                        fontSize := OverlayFontSize_Large + 3  ; 1080p: decreased by 1pt
                        if (StrLen(keyDisplayName) > 2)
                            fontSize := OverlayFontSize_Small + 1  ; 1080p: decreased by 1pt
                    } else {
                        fontSize := OverlayFontSize_Large + 4  ; 2K: keep original
                        if (StrLen(keyDisplayName) > 2)
                            fontSize := OverlayFontSize_Small + 2  ; 2K: keep original
                    }
                    
                    ; Use Text control instead of Button to avoid focus/click behavior
                    indicatorGui.SetFont("s" . fontSize . " Bold cFFFFFF", "Segoe UI")
                    txt := indicatorGui.Add("Text", "x0 y15 w50 h25 Center", keyDisplayName)
                    txt.Opt("+Background000000")
                    
                    indicatorGUIs.Push(indicatorGui)
                }
            }
            
            ; Create indicators for additional hotkeys if checkbox is enabled
            if (ShowAdditionalHotkeysClickLocations) {
                additionalIndicators := [
                    {x: BuyX_Base, y: BuyY_Base, key: BuyKey},
                    {x: SellX_Base, y: SellY_Base, key: SellKey},
                    {x: DuoMateX_Base, y: DuoMateY_Base, key: SendToDuoMateKey}
                ]
                
                for indicator in additionalIndicators {
                    ; Skip indicators with no key assigned
                    if (indicator.key = "")
                        continue
                    
                    ; Create individual GUI for each indicator (even if key is empty, show "-")
                    indicatorGui := Gui()
                    indicatorGui.Opt("-Caption -Border +AlwaysOnTop +ToolWindow +E0x08000000")
                    indicatorGui.BackColor := "000000"
                    
                    ; Get the key display name and determine font size based on text length
                    global OverlayFontSize_Small, OverlayFontSize_Large, monitorWidth
                    keyDisplayName := GetKeyDisplayName(indicator.key)
                    ; For 1080p: decrease by 1pt, for 2K keep original
                    if (monitorWidth <= 1920) {
                        fontSize := OverlayFontSize_Large + 3  ; 1080p: decreased by 1pt
                        if (StrLen(keyDisplayName) > 2)
                            fontSize := OverlayFontSize_Small + 1  ; 1080p: decreased by 1pt
                    } else {
                        fontSize := OverlayFontSize_Large + 4  ; 2K: keep original
                        if (StrLen(keyDisplayName) > 2)
                            fontSize := OverlayFontSize_Small + 2  ; 2K: keep original
                    }
                    
                    ; Use Text control instead of Button to avoid focus/click behavior
                    indicatorGui.SetFont("s" . fontSize . " Bold cFFFFFF", "Segoe UI")
                    txt := indicatorGui.Add("Text", "x0 y15 w50 h25 Center", keyDisplayName)
                    txt.Opt("+Background000000")
                    
                    indicatorGUIs.Push(indicatorGui)
                }
            }
            
            KeybindIndicatorsGuiObj := indicatorGUIs
        }
        
        ; Always update positions (whether we just created them or they already exist)
        if (!GetHearthstoneWindowInfo(&hsX, &hsY, &hsW, &hsH))
            return
        UpdateKeybindIndicatorsPositions(hsX, hsY, hsW, hsH)
    } else {
        HideKeybindIndicators()
    }
}

UpdateKeybindIndicatorPositions() {
    ; Timer callback - just updates positions of existing indicators without creating new ones
    global KeybindIndicatorsGuiObj
    
    if (!IsObject(KeybindIndicatorsGuiObj) || KeybindIndicatorsGuiObj.Length = 0)
        return
    
    ; Get current Hearthstone window info
    if (!GetHearthstoneWindowInfo(&hsX, &hsY, &hsW, &hsH))
        return
    
    ; Update positions
    UpdateKeybindIndicatorsPositions(hsX, hsY, hsW, hsH)
}

UpdateKeybindIndicatorsPositions(hsX, hsY, hsW, hsH) {
    global KeybindIndicatorsGuiObj, ShowBaseHotkeysClickLocations, ShowAdditionalHotkeysClickLocations
    global LevelUpOffsetXPercent, LevelUpOffsetYPercent
    global RerollOffsetXPercent, RerollOffsetYPercent
    global FreezeOffsetXPercent, FreezeOffsetYPercent
    global BuyOffsetXPercent, BuyOffsetYPercent
    global SellOffsetXPercent, SellOffsetYPercent
    global SendToDuoMateOffsetXPercent, SendToDuoMateOffsetYPercent
    global LevelUpKey, RerollKey, FreezeKey, BuyKey, SellKey, SendToDuoMateKey
    
    if (!IsObject(KeybindIndicatorsGuiObj) || KeybindIndicatorsGuiObj.Length = 0)
        return
    
    guiIndex := 1  ; Index into KeybindIndicatorsGuiObj array
    
    ; Position base hotkeys if their checkbox is enabled
    if (ShowBaseHotkeysClickLocations) {
        baseIndicators := [
            {offsetX: LevelUpOffsetXPercent, offsetY: LevelUpOffsetYPercent, key: LevelUpKey},
            {offsetX: RerollOffsetXPercent, offsetY: RerollOffsetYPercent, key: RerollKey},
            {offsetX: FreezeOffsetXPercent, offsetY: FreezeOffsetYPercent, key: FreezeKey}
        ]
        
        for indicator in baseIndicators {
            if (indicator.key = "")
                continue
            
            if (guiIndex <= KeybindIndicatorsGuiObj.Length) {
                ; Use the same percentage-based coordinate system as the actual clicks
                coords := GetDPIAwareClickCoordinate(hsX, hsY, hsW, hsH, indicator.offsetX, indicator.offsetY)
                
                ; Center the 50px wide and 55px tall indicator on the calculated position
                screenX := Round(coords.x - 25)  ; Center horizontally (50px width)
                screenY := Round(coords.y - 27)  ; Center vertically (55px height)
                
                indicatorGui := KeybindIndicatorsGuiObj[guiIndex]
                
                ; Safety check - make sure the GUI object still exists before using it
                if (IsObject(indicatorGui)) {
                    try {
                        indicatorGui.Show("x" . screenX . " y" . screenY . " w50 h55 NoActivate")
                        
                        ; Set transparency level (200 out of 255 = ~78% opacity / ~22% transparent)
                        WinSetTransparent(200, indicatorGui)
                    }
                }
                guiIndex++
            }
        }
    }
    
    ; Position additional hotkeys if their checkbox is enabled
    if (ShowAdditionalHotkeysClickLocations) {
        additionalIndicators := [
            {offsetX: BuyOffsetXPercent, offsetY: BuyOffsetYPercent, key: BuyKey},
            {offsetX: SellOffsetXPercent, offsetY: SellOffsetYPercent, key: SellKey},
            {offsetX: SendToDuoMateOffsetXPercent, offsetY: SendToDuoMateOffsetYPercent, key: SendToDuoMateKey}
        ]
        
        for indicator in additionalIndicators {
            if (indicator.key = "")
                continue
            
            if (guiIndex <= KeybindIndicatorsGuiObj.Length) {
                ; Use the same percentage-based coordinate system as the actual clicks
                coords := GetDPIAwareClickCoordinate(hsX, hsY, hsW, hsH, indicator.offsetX, indicator.offsetY)
                
                ; Center the 50px wide and 55px tall indicator on the calculated position
                screenX := Round(coords.x - 25)  ; Center horizontally (50px width)
                screenY := Round(coords.y - 27)  ; Center vertically (55px height)
                
                indicatorGui := KeybindIndicatorsGuiObj[guiIndex]
                
                ; Safety check - make sure the GUI object still exists before using it
                if (IsObject(indicatorGui)) {
                    try {
                        indicatorGui.Show("x" . screenX . " y" . screenY . " w50 h55 NoActivate")
                        
                        ; Set transparency level (200 out of 255 = ~78% opacity / ~22% transparent)
                        WinSetTransparent(200, indicatorGui)
                    }
                }
                guiIndex++
            }
        }
    }
}

HideKeybindIndicators() {
    global KeybindIndicatorsGuiObj
    
    if (IsObject(KeybindIndicatorsGuiObj)) {
        try {
            for guiObj in KeybindIndicatorsGuiObj {
                if (IsObject(guiObj)) {
                    try {
                        guiObj.Destroy()
                    }
                }
            }
        }
        KeybindIndicatorsGuiObj := []
    }
}

; ============================================================
; HOTKEY REGISTRATION & HANDLERS
; ============================================================

RegisterHotkeys() {
    global LevelUpKey, RerollKey, FreezeKey, BuyKey, SellKey, SendToDuoMateKey
    
    ; Check for duplicate assignments
    keys := [LevelUpKey, RerollKey, FreezeKey, BuyKey, SellKey, SendToDuoMateKey]
    labels := ["Level Up", "Reroll", "Freeze", "Buy", "Sell", "Send to Duo Mate"]
    
    for i, key in keys {
        if (key = "")
            continue
        for j, otherKey in keys {
            if (i != j && key = otherKey) {
                global SettingsGuiObj
                SettingsGuiObj.Opt("-AlwaysOnTop")
                MsgBox(labels[i] . " and " . labels[j] . " cannot use the same key!", "Duplicate Key Assignment", "48")
                SettingsGuiObj.Opt("+AlwaysOnTop")
                return
            }
        }
    }
    
    ; Set HotIf condition BEFORE unregistering/registering
    ; This ensures all hotkey operations use the correct context
    ; Hotkeys only work when Hearthstone is active AND hotkeys are enabled
    global HotkeysEnabled
    HotIf((*) => IsHearthstoneActive() && HotkeysEnabled)
    
    ; First, unregister all possible hotkeys to clear old assignments
    possibleKeys := ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"
                   , "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"
                   , "Space", "Tab", "Enter", "Escape", "Backspace", "Delete"
                   , "Left", "Right", "Up", "Down", "Home", "End", "PgUp", "PgDn"
                   , "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"
                   , "MButton", "XButton1", "XButton2", "WheelUp", "WheelDown"]
    
    for key in possibleKeys {
        try {
            Hotkey("~" . key, LevelUpAction, "Off")
        }
        try {
            Hotkey("~" . key, RerollAction, "Off")
        }
        try {
            Hotkey("~" . key, FreezeAction, "Off")
        }
        try {
            Hotkey("~" . key, BuyAction, "Off")
        }
        try {
            Hotkey("~" . key, SellAction, "Off")
        }
        try {
            Hotkey("~" . key, SendToDuoMateAction, "Off")
        }
    }
    
    ; Now register only the current valid hotkeys
    if (LevelUpKey != "") {
        try {
            Hotkey("~" . LevelUpKey, LevelUpAction, "On")
        }
    }
    if (RerollKey != "") {
        try {
            Hotkey("~" . RerollKey, RerollAction, "On")
        }
    }
    if (FreezeKey != "") {
        try {
            Hotkey("~" . FreezeKey, FreezeAction, "On")
        }
    }
    if (BuyKey != "") {
        try {
            Hotkey("~" . BuyKey, BuyAction, "On")
        }
    }
    if (SellKey != "") {
        try {
            Hotkey("~" . SellKey, SellAction, "On")
        }
    }
    if (SendToDuoMateKey != "") {
        try {
            Hotkey("~" . SendToDuoMateKey, SendToDuoMateAction, "On")
        }
    }
    
    ; Reset HotIf
    HotIf()
    
    ; Update overlay to show new hotkeys
    UpdateOverlayHotkeys()
}

UpdateOverlayHotkeys() {
    global OverlayGuiObj, LevelUpKey, RerollKey, FreezeKey, BuyKey, SellKey, SendToDuoMateKey, KeybindIndicatorsVisible
    
    ; Check if overlay GUI exists before trying to update it
    if (!IsObject(OverlayGuiObj))
        return
    
    ; Find the hotkey text control in the overlay and update it
    try {
        for control in OverlayGuiObj {
            ; Check if this is the hotkey display text control by looking for emoji patterns
            if (InStr(control.Value, "⏫") || InStr(control.Value, "🔄")) {
                displayText := "⏫: " . GetKeyDisplayName(LevelUpKey) . "  |  🔄: " . GetKeyDisplayName(RerollKey) . "  |  ❄️: " . GetKeyDisplayName(FreezeKey) . "  |  🡻: " . GetKeyDisplayName(BuyKey) . "  |  💲: " . GetKeyDisplayName(SellKey) . "  |  ➡️: " . GetKeyDisplayName(SendToDuoMateKey)
                control.Value := displayText
                break
            }
        }
    } catch {
        ; Silently ignore if overlay isn't ready yet
    }
    
    ; Keep updating indicator positions if they exist
    global KeybindIndicatorsGuiObj
    if (IsObject(KeybindIndicatorsGuiObj) && KeybindIndicatorsGuiObj.Length > 0) {
        UpdateKeybindIndicators()
    }
}

LevelUpAction(HotkeyObj) {
    global ChatWindowOpen, UseLevelUpCustom, CustomLevelUpX, CustomLevelUpY
    global LevelUpOffsetXPercent, LevelUpOffsetYPercent
    
    if (ChatWindowOpen)
        return
    if (!GetHearthstoneWindowInfo(&hsX, &hsY, &hsW, &hsH))
        return
    
    ; Use custom coordinates if user captured them, otherwise use percentage offsets
    if (UseLevelUpCustom) {
        clickX := hsX + CustomLevelUpX
        clickY := hsY + CustomLevelUpY
    } else {
        coords := GetDPIAwareClickCoordinate(hsX, hsY, hsW, hsH, LevelUpOffsetXPercent, LevelUpOffsetYPercent)
        clickX := coords.x
        clickY := coords.y
    }
    
    ClickGameButton(clickX, clickY)
}

RerollAction(HotkeyObj) {
    global ChatWindowOpen, UseRerollCustom, CustomRerollX, CustomRerollY
    global RerollOffsetXPercent, RerollOffsetYPercent
    
    if (ChatWindowOpen)
        return
    if (!GetHearthstoneWindowInfo(&hsX, &hsY, &hsW, &hsH))
        return
    
    if (UseRerollCustom) {
        clickX := hsX + CustomRerollX
        clickY := hsY + CustomRerollY
    } else {
        coords := GetDPIAwareClickCoordinate(hsX, hsY, hsW, hsH, RerollOffsetXPercent, RerollOffsetYPercent)
        clickX := coords.x
        clickY := coords.y
    }
    
    ClickGameButton(clickX, clickY)
}

FreezeAction(HotkeyObj) {
    global ChatWindowOpen, UseFreezeCustom, CustomFreezeX, CustomFreezeY
    global FreezeOffsetXPercent, FreezeOffsetYPercent
    
    if (ChatWindowOpen)
        return
    if (!GetHearthstoneWindowInfo(&hsX, &hsY, &hsW, &hsH))
        return
    
    if (UseFreezeCustom) {
        clickX := hsX + CustomFreezeX
        clickY := hsY + CustomFreezeY
    } else {
        coords := GetDPIAwareClickCoordinate(hsX, hsY, hsW, hsH, FreezeOffsetXPercent, FreezeOffsetYPercent)
        clickX := coords.x
        clickY := coords.y
    }
    
    ClickGameButton(clickX, clickY)
}

BuyAction(HotkeyObj) {
    global ChatWindowOpen, UseBuyCustom, CustomBuyX, CustomBuyY
    global BuyOffsetXPercent, BuyOffsetYPercent
    
    if (ChatWindowOpen)
        return
    if (!GetHearthstoneWindowInfo(&hsX, &hsY, &hsW, &hsH))
        return
    
    MouseGetPos(&currentX, &currentY)
    
    if (UseBuyCustom) {
        targetX := hsX + CustomBuyX
        targetY := hsY + CustomBuyY
    } else {
        coords := GetDPIAwareClickCoordinate(hsX, hsY, hsW, hsH, BuyOffsetXPercent, BuyOffsetYPercent)
        targetX := coords.x
        targetY := coords.y
    }
    
    MouseClick("Left", currentX, currentY)
    Sleep(30)
    MouseMove(targetX, targetY, 5)
    Sleep(30)
    MouseClick("Left")
    Sleep(20)
    MouseMove(currentX, currentY)
}

SendToDuoMateAction(HotkeyObj) {
    global ChatWindowOpen, UseDuoCustom, CustomDuoX, CustomDuoY
    global SendToDuoMateOffsetXPercent, SendToDuoMateOffsetYPercent
    
    if (ChatWindowOpen)
        return
    if (!GetHearthstoneWindowInfo(&hsX, &hsY, &hsW, &hsH))
        return
    
    MouseGetPos(&currentX, &currentY)
    
    if (UseDuoCustom) {
        targetX := hsX + CustomDuoX
        targetY := hsY + CustomDuoY
    } else {
        coords := GetDPIAwareClickCoordinate(hsX, hsY, hsW, hsH, SendToDuoMateOffsetXPercent, SendToDuoMateOffsetYPercent)
        targetX := coords.x
        targetY := coords.y
    }
    
    MouseClick("Left", currentX, currentY)
    Sleep(30)
    MouseMove(targetX, targetY, 5)
    Sleep(30)
    MouseClick("Left")
    Sleep(20)
    MouseMove(currentX, currentY)
}

SellAction(HotkeyObj) {
    global ChatWindowOpen, UseSellCustom, CustomSellX, CustomSellY
    global SellOffsetXPercent, SellOffsetYPercent
    
    if (ChatWindowOpen)
        return
    if (!GetHearthstoneWindowInfo(&hsX, &hsY, &hsW, &hsH))
        return
    
    MouseGetPos(&currentX, &currentY)
    
    if (UseSellCustom) {
        targetX := hsX + CustomSellX
        targetY := hsY + CustomSellY
    } else {
        coords := GetDPIAwareClickCoordinate(hsX, hsY, hsW, hsH, SellOffsetXPercent, SellOffsetYPercent)
        targetX := coords.x
        targetY := coords.y
    }
    
    MouseClick("Left", currentX, currentY)
    Sleep(30)
    MouseMove(targetX, targetY, 5)
    Sleep(30)
    MouseClick("Left")
    Sleep(20)
    MouseMove(currentX, currentY)
}

DragGameButton(screenX, screenY, dragX, dragY) {
    ; Click and drag a minion from screenX, screenY to screenX+dragX, screenY+dragY
    
    ; Save current mouse position
    MouseGetPos(&currentX, &currentY)
    
    ; Calculate drag destination (already in screen coordinates)
    destX := screenX + dragX
    destY := screenY + dragY
    
    ; Click and drag with consistent timing
    MouseClick("Left", screenX, screenY)
    Sleep(30)
    MouseMove(destX, destY, 5)
    Sleep(30)
    MouseClick("Left")
    Sleep(20)
    
    ; Restore mouse position
    MouseMove(currentX, currentY)
}

ClickGameButton(screenX, screenY) {
    ; Get current mouse position to restore later
    MouseGetPos(&currentX, &currentY)
    
    ; Click at the provided screen coordinates (already calculated with proper scaling)
    MouseClick("Left", screenX, screenY)
    
    ; Small delay to ensure click registers
    Sleep(30)
    
    ; Restore mouse position
    MouseMove(currentX, currentY)
}

; ============================================================
; KEY CAPTURE HANDLERS
; ============================================================

CaptureLvlKey(GuiCtrlObj, Info) {
    global lvlBtnRef, TempLevelUpKey
    lvlBtnRef := GuiCtrlObj
    CaptureKeyDialog("Level Up", &TempLevelUpKey, TempLevelUpKey, "level")
}

CaptureRRKey(GuiCtrlObj, Info) {
    global rrBtnRef, TempRerollKey
    rrBtnRef := GuiCtrlObj
    CaptureKeyDialog("Reroll", &TempRerollKey, TempRerollKey, "reroll")
}

CaptureFrzKey(GuiCtrlObj, Info) {
    global frzBtnRef, TempFreezeKey
    frzBtnRef := GuiCtrlObj
    CaptureKeyDialog("Freeze", &TempFreezeKey, TempFreezeKey, "freeze")
}

SettingsTooltipHandler(wParam, lParam, msg, hwnd) {
    static PrevHwnd := 0
    
    if (hwnd != PrevHwnd) {
        ToolTip()  ; Turn off any previous tooltip
        
        CurrControl := GuiCtrlFromHwnd(hwnd)
        if (CurrControl && CurrControl.HasProp("ToolTip")) {
            ToolTipText := CurrControl.ToolTip
            ; Show tooltip after 500ms delay
            SetTimer(() => ToolTip(ToolTipText), -500)
            ; Remove tooltip after 4 seconds
            SetTimer(() => ToolTip(), -4000)
        }
        
        PrevHwnd := hwnd
    }
}

CaptureBuyKey(GuiCtrlObj, Info) {
    global buyBtnRef, TempBuyKey
    buyBtnRef := GuiCtrlObj
    CaptureKeyDialog("Buy", &TempBuyKey, TempBuyKey, "buy")
}

CaptureSellKey(GuiCtrlObj, Info) {
    global sellBtnRef, TempSellKey
    sellBtnRef := GuiCtrlObj
    CaptureKeyDialog("Sell", &TempSellKey, TempSellKey, "sell")
}

CaptureDuoKey(GuiCtrlObj, Info) {
    global duoBtnRef, TempSendToDuoMateKey
    duoBtnRef := GuiCtrlObj
    CaptureKeyDialog("Send to Duo Mate", &TempSendToDuoMateKey, TempSendToDuoMateKey, "duo")
}

CaptureKeyDialog(actionName, &keyVar, oldKeyValue, editingButton) {
    global CapturedKey, lvlBtnRef, rrBtnRef, frzBtnRef, buyBtnRef, sellBtnRef, duoBtnRef
    global TempLevelUpKey, TempRerollKey, TempFreezeKey, TempBuyKey, TempSellKey, TempSendToDuoMateKey
    global LevelUpKey, RerollKey, FreezeKey, BuyKey, SellKey, SendToDuoMateKey

    CapturedKey := ""
    oldKey := oldKeyValue  ; Save the old key value

    ; Show "Press any key..." on the button being captured
    if (IsObject(lvlBtnRef))
        lvlBtnRef.Text := "Press any key..."
    if (IsObject(rrBtnRef))
        rrBtnRef.Text := "Press any key..."
    if (IsObject(frzBtnRef))
        frzBtnRef.Text := "Press any key..."
    if (IsObject(buyBtnRef))
        buyBtnRef.Text := "Press any key..."
    if (IsObject(sellBtnRef))
        sellBtnRef.Text := "Press any key..."
    if (IsObject(duoBtnRef))
        duoBtnRef.Text := "Press any key..."

    ; Register all possible hotkeys to capture (exclude LButton and RButton - used for clicking)
    keys := ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"
           , "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"
           , "Space", "Tab", "Enter", "Escape", "Backspace", "Delete"
           , "Left", "Right", "Up", "Down", "Home", "End", "PgUp", "PgDn"
           , "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"
           , "MButton", "XButton1", "XButton2", "WheelUp", "WheelDown"]
    
    for key in keys {
        try {
            Hotkey("*" . key, KeyCaptureHandler, "On")
        }
    }

    ; Wait for a key to be pressed (5 second timeout)
    startTime := A_TickCount
    while (CapturedKey = "" && A_TickCount - startTime < 5000) {
        Sleep(50)
    }

    ; Disable capture hotkeys
    for key in keys {
        try {
            Hotkey("*" . key, KeyCaptureHandler, "Off")
        }
    }

    if (CapturedKey != "") {
        ; Check if this key is already used by ANOTHER function (not the same button being edited)
        ; Check TEMP keys only - these reflect what the user currently sees in the GUI
        isDuplicate := false
        
        if (editingButton != "level" && CapturedKey = TempLevelUpKey)
            isDuplicate := true
        if (editingButton != "reroll" && CapturedKey = TempRerollKey)
            isDuplicate := true
        if (editingButton != "freeze" && CapturedKey = TempFreezeKey)
            isDuplicate := true
        if (editingButton != "buy" && CapturedKey = TempBuyKey)
            isDuplicate := true
        if (editingButton != "sell" && CapturedKey = TempSellKey)
            isDuplicate := true
        if (editingButton != "duo" && CapturedKey = TempSendToDuoMateKey)
            isDuplicate := true
            
        if (isDuplicate) {
            global SettingsGuiObj
            SettingsGuiObj.Opt("-AlwaysOnTop")
            MsgBox("This key is already assigned to another function!", "Duplicate Key", "48")
            SettingsGuiObj.Opt("+AlwaysOnTop")
            ; Restore button displays to show TEMP keys (not saved, in case user already changed something)
            if (IsObject(lvlBtnRef))
                lvlBtnRef.Text := GetKeyDisplayName(TempLevelUpKey)
            if (IsObject(rrBtnRef))
                rrBtnRef.Text := GetKeyDisplayName(TempRerollKey)
            if (IsObject(frzBtnRef))
                frzBtnRef.Text := GetKeyDisplayName(TempFreezeKey)
            if (IsObject(buyBtnRef))
                buyBtnRef.Text := GetKeyDisplayName(TempBuyKey)
            if (IsObject(sellBtnRef))
                sellBtnRef.Text := GetKeyDisplayName(TempSellKey)
            if (IsObject(duoBtnRef))
                duoBtnRef.Text := GetKeyDisplayName(TempSendToDuoMateKey)
        } else {
            ; Valid key, update ONLY the temp variable (not the actual hotkey)
            ; Do NOT update button displays - they should still show the saved value
            ; Do NOT call RegisterHotkeys() - changes only apply on Save & Minimize
            
            if (editingButton = "level") {
                TempLevelUpKey := CapturedKey
            } else if (editingButton = "reroll") {
                TempRerollKey := CapturedKey
            } else if (editingButton = "freeze") {
                TempFreezeKey := CapturedKey
            } else if (editingButton = "sell") {
                TempSellKey := CapturedKey
            } else if (editingButton = "buy") {
                TempBuyKey := CapturedKey
            } else if (editingButton = "duo") {
                TempSendToDuoMateKey := CapturedKey
            }
            
            ; Update button displays to show TEMP keys (what's waiting to be applied)
            if (IsObject(lvlBtnRef))
                lvlBtnRef.Text := GetKeyDisplayName(TempLevelUpKey)
            if (IsObject(rrBtnRef))
                rrBtnRef.Text := GetKeyDisplayName(TempRerollKey)
            if (IsObject(frzBtnRef))
                frzBtnRef.Text := GetKeyDisplayName(TempFreezeKey)
            if (IsObject(buyBtnRef))
                buyBtnRef.Text := GetKeyDisplayName(TempBuyKey)
            if (IsObject(sellBtnRef))
                sellBtnRef.Text := GetKeyDisplayName(TempSellKey)
            if (IsObject(duoBtnRef))
                duoBtnRef.Text := GetKeyDisplayName(TempSendToDuoMateKey)
        }
    } else {
        ; Timeout - restore button displays to show TEMP keys (in case user already changed something)
        if (IsObject(lvlBtnRef))
            lvlBtnRef.Text := GetKeyDisplayName(TempLevelUpKey)
        if (IsObject(rrBtnRef))
            rrBtnRef.Text := GetKeyDisplayName(TempRerollKey)
        if (IsObject(frzBtnRef))
            frzBtnRef.Text := GetKeyDisplayName(TempFreezeKey)
        if (IsObject(buyBtnRef))
            buyBtnRef.Text := GetKeyDisplayName(TempBuyKey)
        if (IsObject(sellBtnRef))
            sellBtnRef.Text := GetKeyDisplayName(TempSellKey)
        if (IsObject(duoBtnRef))
            duoBtnRef.Text := GetKeyDisplayName(TempSendToDuoMateKey)
    }
    
    ; Clear button references
    lvlBtnRef := ""
    rrBtnRef := ""
    frzBtnRef := ""
    buyBtnRef := ""
    sellBtnRef := ""
    duoBtnRef := ""
}

KeyCaptureHandler(HotkeyObj) {
    global CapturedKey
    ; In v2, we can get the key from A_ThisHotkey which is set during hotkey execution
    keyPressed := StrReplace(A_ThisHotkey, "*", "")
    
    ; Reject LButton and RButton - these are reserved for clicking
    if (keyPressed = "LButton" || keyPressed = "RButton")
        return
    
    CapturedKey := keyPressed
}

; ============================================================
; CLEAR KEY HANDLERS
; ============================================================

ClearLvlKey(GuiCtrlObj, Info) {
    global TempLevelUpKey, lvlKeybindBtn
    TempLevelUpKey := ""
    lvlKeybindBtn.Text := "not set"
}

ClearRRKey(GuiCtrlObj, Info) {
    global TempRerollKey, rrKeybindBtn
    TempRerollKey := ""
    rrKeybindBtn.Text := "not set"
}

ClearFrzKey(GuiCtrlObj, Info) {
    global TempFreezeKey, frzKeybindBtn
    TempFreezeKey := ""
    frzKeybindBtn.Text := "not set"
}

ClearBuyKey(GuiCtrlObj, Info) {
    global TempBuyKey, buyKeybindBtn
    TempBuyKey := ""
    buyKeybindBtn.Text := "not set"
}

ClearSellKey(GuiCtrlObj, Info) {
    global TempSellKey, sellKeybindBtn
    TempSellKey := ""
    sellKeybindBtn.Text := "not set"
}

ClearDuoKey(GuiCtrlObj, Info) {
    global TempSendToDuoMateKey, duoKeybindBtn
    TempSendToDuoMateKey := ""
    duoKeybindBtn.Text := "not set"
}

; ============================================================
; POSITION CAPTURE HANDLERS
; ============================================================

; ============================================================
; UI HANDLERS
; ============================================================



ToggleLock() {
    global OverlayLocked
    OverlayLocked := !OverlayLocked
}

ShowSettings() {
    global SettingsGuiObj
    if (!SettingsGuiObj || SettingsGuiObj = 0) {
        CreateSettingsWindow()
    }
    SettingsGuiObj.Show()
}

; ============================================================
; AUTO-LAUNCH SETUP (Task Scheduler)
; ============================================================

; ============================================================
; LOGGING HELPER FUNCTION
; ============================================================
LogDebug(msg) {
    debugLog := A_AppData . "\HearthstoneHotkeys\debug.log"
    
    ; Create directory if it doesn't exist
    if (!DirExist(A_AppData . "\HearthstoneHotkeys")) {
        DirCreate(A_AppData . "\HearthstoneHotkeys")
    }
    
    ; Append timestamp and message to log
    FileAppend(A_Now . " | " . msg . "`n", debugLog)
}

; ============================================================
; FIND HEARTHSTONE.EXE - AUTO-DETECTION ACROSS ALL DRIVES
; ============================================================
FindHearthstoneExe() {
    ; First check common default locations (fast)
    commonPaths := [
        "C:\Program Files (x86)\Hearthstone\Hearthstone.exe",
        "C:\Program Files\Hearthstone\Hearthstone.exe",
        "D:\Games\Hearthstone\Hearthstone.exe",
        "E:\Games\Hearthstone\Hearthstone.exe",
        "D:\Program Files (x86)\Hearthstone\Hearthstone.exe",
        "E:\Program Files (x86)\Hearthstone\Hearthstone.exe"
    ]
    
    for i, path in commonPaths {
        if (FileExist(path)) {
            return path
        }
    }
    
    ; If not found in common locations, search all drives recursively
    Loop Parse, DriveGetList() {
        drive := A_LoopField
        
        ; Search recursively on each drive for Hearthstone.exe
        Loop Files, drive ":\*.*", "R" {
            if (A_LoopFileName = "Hearthstone.exe") {
                return A_LoopFileFullPath
            }
        }
    }
    
    return ""  ; Return empty string if not found
}

; ============================================================
; CREATE EVENT TRIGGER XML - BUILD FULL TASK XML WITH HTML ENTITIES
; ============================================================
CreateEventTriggerXML(hearthstonePath, appPath) {
    dq := chr(34)  ; Double quote character
    
    ; Build the query subscription with HTML entities (&lt; instead of <, etc)
    subscription := "&lt;QueryList&gt;&lt;Query Id=" . dq . "0" . dq . " Path=" . dq . "Security" . dq . "&gt;"
    subscription := subscription . "&lt;Select Path=" . dq . "Security" . dq . "&gt;"
    subscription := subscription . "*[System[Provider[@Name=" . dq . "Microsoft-Windows-Security-Auditing" . dq . "] and Task = 13312 and (band(Keywords,9007199254740992)) and (EventID=4688)]] and *[EventData[Data[@Name=" . dq . "NewProcessName" . dq . "] and (Data=" . dq . hearthstonePath . dq . ")]]"
    subscription := subscription . "&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;"
    
    ; Build complete task XML
    xml := "<?xml version=" . dq . "1.0" . dq . " encoding=" . dq . "UTF-16" . dq . "?>" . "`r`n"
    xml := xml . "<Task version=" . dq . "1.2" . dq . " xmlns=" . dq . "http://schemas.microsoft.com/windows/2004/02/mit/task" . dq . ">" . "`r`n"
    xml := xml . "  <RegistrationInfo>" . "`r`n"
    xml := xml . "    <URI>\HearthstoneHotkeysAutoLaunch</URI>" . "`r`n"
    xml := xml . "  </RegistrationInfo>" . "`r`n"
    xml := xml . "  <Triggers>" . "`r`n"
    xml := xml . "    <EventTrigger>" . "`r`n"
    xml := xml . "      <Enabled>true</Enabled>" . "`r`n"
    xml := xml . "      <Subscription>" . subscription . "</Subscription>" . "`r`n"
    xml := xml . "    </EventTrigger>" . "`r`n"
    xml := xml . "  </Triggers>" . "`r`n"
    xml := xml . "  <Principals>" . "`r`n"
    xml := xml . "    <Principal id=" . dq . "Author" . dq . ">" . "`r`n"
    xml := xml . "      <LogonType>InteractiveToken</LogonType>" . "`r`n"
    xml := xml . "      <RunLevel>HighestAvailable</RunLevel>" . "`r`n"
    xml := xml . "    </Principal>" . "`r`n"
    xml := xml . "  </Principals>" . "`r`n"
    xml := xml . "  <Settings>" . "`r`n"
    xml := xml . "    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>" . "`r`n"
    xml := xml . "    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>" . "`r`n"
    xml := xml . "    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>" . "`r`n"
    xml := xml . "    <AllowHardTerminate>true</AllowHardTerminate>" . "`r`n"
    xml := xml . "    <StartWhenAvailable>false</StartWhenAvailable>" . "`r`n"
    xml := xml . "    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>" . "`r`n"
    xml := xml . "    <IdleSettings>" . "`r`n"
    xml := xml . "      <StopOnIdleEnd>false</StopOnIdleEnd>" . "`r`n"
    xml := xml . "      <RestartOnIdle>false</RestartOnIdle>" . "`r`n"
    xml := xml . "    </IdleSettings>" . "`r`n"
    xml := xml . "    <AllowStartOnDemand>true</AllowStartOnDemand>" . "`r`n"
    xml := xml . "    <Enabled>true</Enabled>" . "`r`n"
    xml := xml . "    <Hidden>false</Hidden>" . "`r`n"
    xml := xml . "    <RunOnlyIfIdle>false</RunOnlyIfIdle>" . "`r`n"
    xml := xml . "    <WakeToRun>false</WakeToRun>" . "`r`n"
    xml := xml . "    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>" . "`r`n"
    xml := xml . "    <Priority>7</Priority>" . "`r`n"
    xml := xml . "  </Settings>" . "`r`n"
    xml := xml . "  <Actions Context=" . dq . "Author" . dq . ">" . "`r`n"
    xml := xml . "    <Exec>" . "`r`n"
    xml := xml . "      <Command>" . dq . appPath . dq . "</Command>" . "`r`n"
    xml := xml . "    </Exec>" . "`r`n"
    xml := xml . "  </Actions>" . "`r`n"
    xml := xml . "</Task>"
    
    return xml
}

; ============================================================
; CREATE SCHEDULED TASK - USE SCHTASKS TO CREATE TASK
; ============================================================
CreateScheduledTask(hearthstonePath, appPath) {
    taskName := "HearthstoneHotkeysAutoLaunch"
    
    try {
        xml := CreateEventTriggerXML(hearthstonePath, appPath)
        
        tempXmlFile := A_Temp . "\HearthstoneAutoLaunch_Task.xml"
        
        ; Delete old XML if exists
        if (FileExist(tempXmlFile)) {
            FileDelete(tempXmlFile)
        }
        
        ; Write XML to temporary file as UTF-16 (which schtasks expects)
        f := FileOpen(tempXmlFile, "w", "UTF-16")
        f.Write(xml)
        f.Close()
        
        quote := chr(34)
        
        ; Use /XML parameter to create task from XML file
        cmd := "schtasks /create /tn " . taskName . " /xml " . quote . tempXmlFile . quote . " /f"
        
        batchFile := A_Temp . "\HearthstoneAutoLaunch_Create.bat"
        logFile := A_Temp . "\HearthstoneAutoLaunch_CreateTask.log"
        
        if (FileExist(batchFile)) {
            FileDelete(batchFile)
        }
        if (FileExist(logFile)) {
            FileDelete(logFile)
        }
        
        ; Write batch file
        batchContent := "@echo off" . "`n"
        batchContent := batchContent . cmd . " > " . quote . logFile . quote . " 2>&1" . "`n"
        batchContent := batchContent . "exit /b %ERRORLEVEL%" . "`n"
        
        FileAppend(batchContent, batchFile)
        
        Run(A_ComSpec . " /c " . batchFile,, "Hide")
        
        SetTimer(() => OpenCreateTaskLog(logFile, tempXmlFile, batchFile), 3000)
        
    } catch Error as err {
        MsgBox("Error creating scheduled task: " . err.Message)
    }
}

; ============================================================
; OPEN CREATE TASK LOG AND CLEANUP
; ============================================================
OpenCreateTaskLog(logFile, xmlFile, batchFile) {
    ; Cleanup temporary files after a delay
    SetTimer(() => CleanupTempFiles(xmlFile, batchFile), 2000)
    
    SetTimer(, 0)  ; Cancel this timer
}

; ============================================================
; CLEANUP TEMPORARY FILES
; ============================================================
CleanupTempFiles(xmlFile, batchFile) {
    try {
        if (FileExist(xmlFile)) {
            FileDelete(xmlFile)
        }
        if (FileExist(batchFile)) {
            FileDelete(batchFile)
        }
    } catch Error as err {
        ; Silently ignore cleanup errors
    }
    
    SetTimer(, 0)  ; Cancel this timer
}

SetupAutoLaunchScheduledTask() {
    try {
        hearthstonePath := FindHearthstoneExe()
        
        if (hearthstonePath = "") {
            MsgBox("Could not find Hearthstone.exe on your system.`n`nPlease ensure Hearthstone is installed.", "Error", "48")
            return
        }
        
        appPath := A_ScriptFullPath
        
        CreateScheduledTask(hearthstonePath, appPath)
        
    } catch Error as err {
        MsgBox("Error setting up auto-launch: " . err.Message)
    }
}

RemoveAutoLaunchScheduledTask() {
    taskName := "HearthstoneHotkeysAutoLaunch"
    
    ; Since we always run in admin mode when auto-launch is enabled,
    ; we should already have admin privileges here - no need to check
    
    ; Remove the scheduled task using PowerShell (non-blocking)
    try {
        psRemoveCmd := "Unregister-ScheduledTask -TaskName '" taskName "' -Confirm:`$false -ErrorAction SilentlyContinue"
        cmd := A_ComSpec " /c powershell -ExecutionPolicy Bypass -Command " . '"' . psRemoveCmd . '"'
        Run(cmd,, "Hide")  ; Use Run instead of RunWait to avoid blocking
        ; Silently complete - no message box needed
    } catch Error as err {
        ; Silently fail - no message box needed
    }
}

SaveAndMinimize() {
    global SettingsGuiObj, CloseOnHearthstoneExit, OverlayCompactMode, SkipSettingsGUIOnStartup, EnableCustomCapture, AutoLaunchWithHearthstone
    global LevelUpKey, RerollKey, FreezeKey, BuyKey, SellKey, SendToDuoMateKey
    global TempLevelUpKey, TempRerollKey, TempFreezeKey, TempBuyKey, TempSellKey, TempSendToDuoMateKey
    global CustomLevelUpX, CustomLevelUpY, UseLevelUpCustom
    global CustomRerollX, CustomRerollY, UseRerollCustom
    global CustomFreezeX, CustomFreezeY, UseFreezeCustom
    global CustomBuyX, CustomBuyY, UseBuyCustom
    global CustomSellX, CustomSellY, UseSellCustom
    global CustomDuoX, CustomDuoY, UseDuoCustom
    global AutoLaunchWithHearthstone_Previous
    global ShowBaseHotkeysClickLocations, ShowAdditionalHotkeysClickLocations
    global OverlayGuiObj, ClickableOverlayGuiObj, OverlayDisplayInitialized
    
    ; Read checkbox values
    CloseOnHearthstoneExit := Number(SettingsGuiObj["CloseOnHearthstoneExit"].Value)
    SkipSettingsGUIOnStartup := Number(SettingsGuiObj["SkipSettingsGUIOnStartup"].Value)
    AutoLaunchWithHearthstone := Number(SettingsGuiObj["AutoLaunchWithHearthstone"].Value)
    ShowBaseHotkeysClickLocations := Number(SettingsGuiObj["ShowBaseHotkeysClickLocations"].Value)
    ShowAdditionalHotkeysClickLocations := Number(SettingsGuiObj["ShowAdditionalHotkeysClickLocations"].Value)
    
    ; If auto-launch is being ENABLED and we're not admin, relaunch as admin first
    if (AutoLaunchWithHearthstone = 1 && AutoLaunchWithHearthstone_Previous = 0 && !A_IsAdmin) {
        ; Save the config NOW before relaunching, so checkbox state is persisted
        ; Write the current settings to config file
        IniWrite(AutoLaunchWithHearthstone, ConfigFile, "Settings", "AutoLaunchWithHearthstone")
        IniWrite(CloseOnHearthstoneExit, ConfigFile, "Settings", "CloseOnHearthstoneExit")
        IniWrite(SkipSettingsGUIOnStartup, ConfigFile, "Settings", "SkipSettingsGUIOnStartup")
        
        SettingsGuiObj.Opt("-AlwaysOnTop")
        MsgBox("Auto-launch requires administrator privileges.`n`nThe app will now restart in admin mode.", "Admin Mode Required", "64")
        SettingsGuiObj.Opt("+AlwaysOnTop")
        
        ; Relaunch as admin - config already saved
        Run("*RunAs " A_ScriptFullPath)
        ExitApp()
    }
    
    ; Setup or remove Task Scheduler auto-launch based on checkbox state change
    if (AutoLaunchWithHearthstone != AutoLaunchWithHearthstone_Previous) {
        if (AutoLaunchWithHearthstone = 1) {
            ; This will either setup the task or prompt for admin and exit
            SetupAutoLaunchScheduledTask()
            ; If we reach here, either admin setup worked or user was already admin
            AutoLaunchWithHearthstone_Previous := AutoLaunchWithHearthstone
        } else {
            ; This will either remove the task or prompt for admin and exit
            RemoveAutoLaunchScheduledTask()
            ; If we reach here, either admin setup worked or user was already admin
            AutoLaunchWithHearthstone_Previous := AutoLaunchWithHearthstone
        }
    }
    
    ; Apply all temp settings to actual settings
    LevelUpKey := TempLevelUpKey
    RerollKey := TempRerollKey
    FreezeKey := TempFreezeKey
    BuyKey := TempBuyKey
    SellKey := TempSellKey
    SendToDuoMateKey := TempSendToDuoMateKey
    
    ; Read compact mode radio button value
    fullRadioSelected := SettingsGuiObj["OverlayCompactMode"].Value
    OverlayCompactMode := (fullRadioSelected = 1 ? 0 : 1)
    
    ; Always use percentage-based offsets (custom coordinate capture removed)
    UseLevelUpCustom := 0
    UseRerollCustom := 0
    UseFreezeCustom := 0
    UseBuyCustom := 0
    UseSellCustom := 0
    UseDuoCustom := 0
    
    ; Now register hotkeys with the new keys
    RegisterHotkeys()
    
    SaveConfig()
    
    ; PROPER CLEANUP AND REDRAW: Explicitly hide overlays before recreating them
    ; This prevents rendering artifacts and ghost images
    try {
        OverlayGuiObj.Hide()
    }
    try {
        ClickableOverlayGuiObj.Hide()
    }
    
    ; Small delay to let Windows properly clean up the GUI windows
    Sleep(50)
    
    ; Reset the display initialization flag so overlays will be properly redrawn
    OverlayDisplayInitialized := 0
    
    ; Recreate overlay to ensure correct dimensions are applied
    RecreateOverlay()
    
    ; Simple: if either checkbox is enabled, create and show indicators
    ; If both disabled, hide them
    global KeybindIndicatorsGuiObj, ShowBaseHotkeysClickLocations, ShowAdditionalHotkeysClickLocations
    
    if (ShowBaseHotkeysClickLocations || ShowAdditionalHotkeysClickLocations) {
        ; Hide old ones first, then create new ones
        HideKeybindIndicators()
        KeybindIndicatorsGuiObj := []
        UpdateKeybindIndicators()
    } else {
        ; Both unchecked - hide everything
        HideKeybindIndicators()
        KeybindIndicatorsGuiObj := []
    }
    
    SettingsGuiObj.Hide()
}

OpenDonateLink() {
    Run("https://buymeacoffee.com/linegrinder")
}

; ============================================================
; EXIT HANDLING
; ============================================================

CleanupOnExit(ExitReason, ExitCode) {
    ; This function is called automatically before the script exits
    ; It ensures proper cleanup and resource release
    
    global SettingsGuiObj, OverlayGuiObj, ClickableOverlayGuiObj
    
    ; Save configuration
    SaveConfig()
    
    ; Destroy all GUI objects to release resources
    try {
        if (SettingsGuiObj && SettingsGuiObj != 0) {
            SettingsGuiObj.Destroy()
        }
    } catch {
        ; Ignore errors if already destroyed
    }
    
    try {
        if (OverlayGuiObj && OverlayGuiObj != 0) {
            OverlayGuiObj.Destroy()
        }
    } catch {
        ; Ignore errors if already destroyed
    }
    
    try {
        if (ClickableOverlayGuiObj && ClickableOverlayGuiObj != 0) {
            ClickableOverlayGuiObj.Destroy()
        }
    } catch {
        ; Ignore errors if already destroyed
    }
    
    ; Note: ExitApp() is called automatically after OnExit returns
}

CloseApp() {
    ; CloseApp now just needs to call ExitApp() - OnExit handles cleanup
    ExitApp()
}

WM_SYSCOMMAND(wParam, lParam, msg, hwnd) {
    ; 0xF020 is SC_MINIMIZE - when minimize button is clicked
    if (wParam = 0xF020) {
        SaveAndMinimize()
        return 0  ; Prevent default minimize behavior
    }
}

; ============================================================
; TIMERS
; ============================================================

DetectChatWindow() {
    global ChatWindowOpen, OverlayStatusText, monitorWidth, OverlayFontSize_Large
    static lastChatState := 0  ; Track the previous state
    
    ; Get Hearthstone window info
    if (!GetHearthstoneWindowInfo(&hsX, &hsY, &hsW, &hsH)) {
        ChatWindowOpen := 0
        return
    }
    
    ; Calculate chat window bounds relative to Hearthstone window
    ; Chat appears at bottom-center of the game window
    ; Positioned to avoid the blinking cursor in the input field
    chatSearchLeft := hsX + (hsW * 0.30)    ; Start 30% from left
    chatSearchTop := hsY + (hsH * 0.62)     ; Start 62% from top
    chatSearchRight := hsX + (hsW * 0.50)   ; End 50% from left
    chatSearchBottom := hsY + (hsH * 0.75)  ; End 75% from top
    
    ; Choose the correct chat bubble image based on resolution
    chatBubbleImage := (monitorWidth <= 1920) ? "chatbubblenew1080p.png" : "chatbubblnew.png"
    
    ; Search the specific region for the chat bubble image
    ; ImageSearch with moderate tolerance (*30) to handle variations without false positives
    try {
        found := ImageSearch(&foundX, &foundY, chatSearchLeft, chatSearchTop, chatSearchRight, chatSearchBottom, "*30 " . A_Temp . "\" . chatBubbleImage)
    } catch Error as err {
        ; If image file is missing, just assume chat is not open
        ; This prevents crashes when chat bubble image is not included
        found := 0
    }
    
    if (found) {
        ChatWindowOpen := 1
    } else {
        ChatWindowOpen := 0
    }
    
    ; Only update the overlay text if the state changed (not every frame)
    if (ChatWindowOpen != lastChatState) {
        lastChatState := ChatWindowOpen
        
        if (OverlayStatusText) {
            if (ChatWindowOpen) {
                ; Chat is open - show OFF in red
                OverlayStatusText.Value := "OFF"
                OverlayStatusText.SetFont("s" . OverlayFontSize_Large . " Bold c" . "FF0000")  ; Red color
            } else {
                ; Chat is closed - show ON in green
                OverlayStatusText.Value := "ON"
                OverlayStatusText.SetFont("s" . OverlayFontSize_Large . " Bold c" . "00FF00")  ; Green color
            }
        }
    }
}

MonitorHearthstone() {
    global OverlayGuiObj, ClickableOverlayGuiObj, OverlayX, OverlayY, KeybindIndicatorsVisible, KeybindIndicatorsGuiObj
    global OverlayLocked, GlobalOverlayScreenX, GlobalOverlayScreenY, CloseOnHearthstoneExit, OverlayDisplayInitialized, OverlayCompactMode
    global HearthstoneWasRunning

    if (IsHearthstoneActive()) {
        HearthstoneWasRunning := 1  ; Mark that Hearthstone is running
        if (GetHearthstoneWindowInfo(&hsX, &hsY, &hsW, &hsH)) {
            ; Calculate position ONCE
            overlayScreenX := hsX + OverlayX
            overlayScreenY := hsY + OverlayY
            
            ; STORE it globally so both overlays use the exact same position
            GlobalOverlayScreenX := overlayScreenX
            GlobalOverlayScreenY := overlayScreenY
            
            ; Get dynamic width based on compact mode
            ; NOTE: -DPIScale flag in GUI creation prevents Windows from scaling, 
            ; so we use actual pixel dimensions (not DPI-scaled)
            ; Compact: 229 (content) + 1px left + 19 (buttons) + 1px right + 2px margin = 252px (shown as 251px)
            ; Full: 390 (content) + 1px left + 19 (buttons) + 1px right + 1px border = 412px
            overlayWidth := (OverlayCompactMode = 1) ? 251 : 412
            overlayHeight := 66
            
            ; Initialize display text once on first show (not every frame)
            if (!OverlayDisplayInitialized) {
                UpdateOverlayDisplay()
                OverlayDisplayInitialized := 1
            }
            
            ; Only show overlay if it's been initialized
            if (OverlayDisplayInitialized) {
                ; Show the VISUAL overlay
                OverlayGuiObj.Show("x" . overlayScreenX . " y" . overlayScreenY . " w" . overlayWidth . " h" . overlayHeight . " NoActivate")
                
                ; Show the CLICKABLE overlay at EXACT SAME position with EXACT SAME dimensions
                if (!OverlayLocked) {
                    ClickableOverlayGuiObj.Show("x" . overlayScreenX . " y" . overlayScreenY . " w" . overlayWidth . " h" . overlayHeight . " NoActivate")
                } else {
                    ClickableOverlayGuiObj.Hide()
                }
            }
            
            ; Update keybind indicators if either checkbox is enabled
            global ShowBaseHotkeysClickLocations, ShowAdditionalHotkeysClickLocations
            if (ShowBaseHotkeysClickLocations || ShowAdditionalHotkeysClickLocations) {
                UpdateKeybindIndicators()
            }
        }
    } else {
        ; Safely hide overlays if they exist
        try {
            OverlayGuiObj.Hide()
        }
        try {
            ClickableOverlayGuiObj.Hide()
        }
        HideKeybindIndicators()
        
        ; Only close app if Hearthstone WAS running and now it's not (user quit Hearthstone)
        ; Don't close on startup if Hearthstone was never running
        if (CloseOnHearthstoneExit && HearthstoneWasRunning && !WinExist("ahk_exe Hearthstone.exe")) {
            ExitApp()
        }
    }
}

UpdateOverlay() {
    global OverlayGuiObj, ClickableOverlayGuiObj, OverlayX, OverlayY, OverlayDragging, OverlayLocked
    global DragStartX, DragStartY, DragOffsetX, DragOffsetY
    global GlobalOverlayScreenX, GlobalOverlayScreenY, OverlayCompactMode

    MouseGetPos(&currentX, &currentY)
    LeftMousePressed := GetKeyState("LButton", "P")

    ; Get current window position
    if (!GetHearthstoneWindowInfo(&hsX, &hsY, &hsW, &hsH)) {
        return
    }

    ; Use the globally stored position (set by MonitorHearthstone)
    overlayScreenX := GlobalOverlayScreenX
    overlayScreenY := GlobalOverlayScreenY
    
    ; Overlay dimensions (actual pixel dimensions, no DPI scaling needed)
    overlayWidth := (OverlayCompactMode = 1) ? 251 : 412
    overlayHeight := 66
    
    ; Check if mouse is within overlay bounds
    isMouseOverOverlay := (currentX >= overlayScreenX && currentX < overlayScreenX + overlayWidth &&
                          currentY >= overlayScreenY && currentY < overlayScreenY + overlayHeight)
    
    ; Detect when drag starts
    if (LeftMousePressed && !OverlayDragging && !OverlayLocked && isMouseOverOverlay) {
        OverlayDragging := 1
        DragStartX := currentX
        DragStartY := currentY
        DragOffsetX := OverlayX
        DragOffsetY := OverlayY
    }

    ; Update position during active drag
    if (OverlayDragging && LeftMousePressed) {
        DeltaX := currentX - DragStartX
        DeltaY := currentY - DragStartY

        OverlayX := DragOffsetX + DeltaX
        OverlayY := DragOffsetY + DeltaY
        
        ; Constrain overlay position within Hearthstone window bounds
        ; Make sure left edge doesn't go past left side of window
        if (OverlayX < 0)
            OverlayX := 0
        
        ; Make sure top edge doesn't go past top of window
        if (OverlayY < 0)
            OverlayY := 0
        
        ; Make sure right edge doesn't go past right side of window
        if (OverlayX + overlayWidth > hsW)
            OverlayX := hsW - overlayWidth
        
        ; Make sure bottom edge doesn't go past bottom of window
        if (OverlayY + overlayHeight > hsH)
            OverlayY := hsH - overlayHeight

        ; Show overlay at new position
        newOverlayScreenX := hsX + OverlayX
        newOverlayScreenY := hsY + OverlayY
        
        ; Update global position
        GlobalOverlayScreenX := newOverlayScreenX
        GlobalOverlayScreenY := newOverlayScreenY
        
        OverlayGuiObj.Show("x" . newOverlayScreenX . " y" . newOverlayScreenY . " w" . overlayWidth . " h" . overlayHeight . " NoActivate")
        ClickableOverlayGuiObj.Show("x" . newOverlayScreenX . " y" . newOverlayScreenY . " w" . overlayWidth . " h" . overlayHeight . " NoActivate")
    } else if (OverlayDragging && !LeftMousePressed) {
        OverlayDragging := 0
    }
}

; ============================================================
; SYSTEM TRAY
; ============================================================

SetupTrayMenu() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Show Settings", TrayShowSettings)
    A_TrayMenu.Add("Exit", TrayExit)
    OnMessage(0x404, TrayIconClick)  ; 0x404 is WM_USER + 4, handles tray icon clicks
}

TrayIconClick(wParam, lParam, msg, hwnd) {
    if (lParam = 0x201) {  ; 0x201 is WM_LBUTTONDOWN (single left-click)
        global SettingsGuiObj
        if (!SettingsGuiObj || SettingsGuiObj = 0) {
            CreateSettingsWindow()
        }
        SettingsGuiObj.Show()
        return 0
    }
}

TrayShowSettings(ItemName, ItemPos, MenuName) {
    global SettingsGuiObj
    if (!SettingsGuiObj || SettingsGuiObj = 0) {
        CreateSettingsWindow()
    }
    SettingsGuiObj.Show()
}

TrayExit(ItemName, ItemPos, MenuName) {
    CloseApp()
}

; ============================================================
; DEBUG OVERLAY - WINDOW DIMENSIONS
; ============================================================

; ============================================================
; DPI-AWARE CLICK COORDINATE CALCULATION
; ============================================================

GetDPIAwareClickCoordinate(hsX, hsY, hsW, hsH, baseOffsetXPercent, baseOffsetYPercent) {
    ; Calculate click position from window center using percentage-based offsets
    ; 
    ; Key insight: The Hearthstone board has a fixed size that scales with window HEIGHT,
    ; not width. On narrow windows, the board doesn't shrink (edges crop in).
    ; On wide/ultrawide windows, the board doesn't expand (empty space on sides).
    ; Therefore, use height scaling for BOTH X and Y offsets to keep clicks tied to board size.
    
    ; Calculate scaling factor based on HEIGHT only
    heightScaleFactor := hsH / 1440
    
    ; Calculate click position from window center
    centerX := hsX + (hsW / 2)
    centerY := hsY + (hsH / 2)
    
    ; Convert percentage offsets to pixels using height-based scaling
    offsetXPixels := baseOffsetXPercent * 2560 * heightScaleFactor
    offsetYPixels := baseOffsetYPercent * 1440 * heightScaleFactor
    
    ; Calculate final click position
    clickX := centerX + offsetXPixels
    clickY := centerY + offsetYPixels
    
    return {x: clickX, y: clickY}
}
