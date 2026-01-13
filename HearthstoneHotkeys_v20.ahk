#SingleInstance Force
#Persistent
#NoEnv
SetWorkingDir %A_ScriptDir%
CoordMode, Mouse, Screen
SetTitleMatchMode, 2
DllCall("SetProcessDPIAware")

; =========================
; GLOBAL VARIABLES
; =========================
global ConfigFile := A_AppData . "\HearthstoneHotkeys\config.ini"
global LevelUpKey, RerollKey, FreezeKey
global FreezeX_Base, FreezeY_Base, RerollX_Base, RerollY_Base, LevelUpX_Base, LevelUpY_Base
global BaseW := 2560
global BaseH := 1440
global WinGreen := "7CFF5B"
global HSBadgeHWND
global OverlayX, OverlayY

; Create config directory if it doesn't exist
FileCreateDir, %A_AppData%\HearthstoneHotkeys

; Load settings or use defaults
IniRead, LevelUpKey, %ConfigFile%, Hotkeys, LevelUp, f
IniRead, RerollKey, %ConfigFile%, Hotkeys, Reroll, d
IniRead, FreezeKey, %ConfigFile%, Hotkeys, Freeze, Space
IniRead, FreezeX_Base, %ConfigFile%, Positions, FreezeX, 1665
IniRead, FreezeY_Base, %ConfigFile%, Positions, FreezeY, 243
IniRead, RerollX_Base, %ConfigFile%, Positions, RerollX, 1509
IniRead, RerollY_Base, %ConfigFile%, Positions, RerollY, 271
IniRead, LevelUpX_Base, %ConfigFile%, Positions, LevelUpX, 1058
IniRead, LevelUpY_Base, %ConfigFile%, Positions, LevelUpY, 273

; Overlay positioning
RightOffsetPx := Round((5/2.54) * A_ScreenDPI)
OverlayX := 20 + RightOffsetPx
OverlayY := 2

; =========================
; CREATE SETTINGS GUI
; =========================
Gui, Settings:New, +AlwaysOnTop
Gui, Settings:Color, FFFFFF

; Embed and extract Bob image (Bob_Hotkey.png must be in same folder as .ahk when compiling)
FileInstall, Bob_Hotkey.png, %A_Temp%\Bob_Hotkey.png, 1

; Hotkey Configuration
Gui, Settings:Font, s9 Norm
Gui, Settings:Add, GroupBox, x20 y20 w360 h118, Hotkey Configuration

; Add Bob image in top right corner
Gui, Settings:Add, Picture, x280 y35 w80 h90, %A_Temp%\Bob_Hotkey.png

Gui, Settings:Font, s9 Norm
Gui, Settings:Add, Text, x40 y43, Level Up Key:
Gui, Settings:Add, Button, x150 y41 w100 h25 gCaptureLevelUp vLvlBtn, %LevelUpKey%

Gui, Settings:Add, Text, x40 y73, Reroll Key:
Gui, Settings:Add, Button, x150 y70 w100 h25 gCaptureReroll vRRBtn, %RerollKey%

Gui, Settings:Add, Text, x40 y103, Freeze Key:
Gui, Settings:Add, Button, x150 y100 w100 h25 gCaptureFreeze vFrzBtn, %FreezeKey%

; Resolution Selection
Gui, Settings:Font, s9 Norm
Gui, Settings:Add, GroupBox, x20 y165 w360 h52, Screen Resolution
Gui, Settings:Add, Text, x40 y187, Select Resolution:
Gui, Settings:Add, DropDownList, x150 y184 w200 vResolutionSelect gResolutionChanged, 3840x2160 (150`% Scaling)|2560x1440 (125`% Scaling)|1920x1080 (100`% Scaling)||

; Advanced Custom Positions Section
Gui, Settings:Font, s9 Norm
Gui, Settings:Add, GroupBox, x20 y240 w360 h145, Advanced: Custom Positions
Gui, Settings:Add, Checkbox, x40 y262 vCustomPositions gToggleCustom, Use Custom Click Positions

; Position capture section (initially disabled) - cleaner layout with s9 font for X/Y labels
Gui, Settings:Font, s9
Gui, Settings:Add, Button, x40 y287 w110 h25 gCaptureFreezePos Disabled vCapFreBtn, Capture Freeze
Gui, Settings:Add, Text, x160 y292 Disabled vLblFrzX, X:
Gui, Settings:Add, Edit, x175 y289 w50 vFreezeXInput Disabled Number, %FreezeX_Base%
Gui, Settings:Add, Text, x235 y292 Disabled vLblFrzY, Y:
Gui, Settings:Add, Edit, x250 y289 w50 vFreezeYInput Disabled Number, %FreezeY_Base%

Gui, Settings:Add, Button, x40 y317 w110 h25 gCaptureRerollPos Disabled vCapRRBtn, Capture Reroll
Gui, Settings:Add, Text, x160 y322 Disabled vLblRRX, X:
Gui, Settings:Add, Edit, x175 y319 w50 vRerollXInput Disabled Number, %RerollX_Base%
Gui, Settings:Add, Text, x235 y322 Disabled vLblRRY, Y:
Gui, Settings:Add, Edit, x250 y319 w50 vRerollYInput Disabled Number, %RerollY_Base%

Gui, Settings:Add, Button, x40 y347 w110 h25 gCaptureLevelPos Disabled vCapLvlBtn, Capture Level Up
Gui, Settings:Add, Text, x160 y352 Disabled vLblLvlX, X:
Gui, Settings:Add, Edit, x175 y349 w50 vLevelUpXInput Disabled Number, %LevelUpX_Base%
Gui, Settings:Add, Text, x235 y352 Disabled vLblLvlY, Y:
Gui, Settings:Add, Edit, x250 y349 w50 vLevelUpYInput Disabled Number, %LevelUpY_Base%

; Buttons
Gui, Settings:Font, s10
Gui, Settings:Add, Button, x40 y400 w150 h35 gSaveAndMinimize, Save && Minimize
Gui, Settings:Add, Button, x210 y400 w150 h35 gExitApp, Exit

Gui, Settings:Show, w400 h455, Hearthstone BGs Hotkeys Settings

; =========================
; CREATE OVERLAY
; =========================
CreateOverlay()

; =========================
; SYSTEM TRAY MENU
; =========================
Menu, Tray, NoStandard
Menu, Tray, Add, Show Settings, ShowSettings
Menu, Tray, Add, Exit, ExitApp
Menu, Tray, Default, Show Settings
Menu, Tray, Tip, Hearthstone Hotkeys
Menu, Tray, Click, 1  ; Single left-click opens settings
OnMessage(0x404, "AHK_NOTIFYICON")  ; Handle tray icon clicks

AHK_NOTIFYICON(wParam, lParam) {
    if (lParam = 0x202) ; WM_LBUTTONUP (left click released)
        Gosub, ShowSettings
    return
}

; =========================
; TIMER FOR OVERLAY VISIBILITY
; =========================
SetTimer, CheckHearthstone, 250

; Initial hotkey setup
SetupHotkeys()

return

; =========================
; HOTKEY CAPTURE FUNCTIONS
; =========================
CaptureLevelUp:
    ; Disable only the other buttons
    GuiControl, Settings:Disable, RRBtn
    GuiControl, Settings:Disable, FrzBtn
    
    GuiControl, Settings:, LvlBtn, Press any key...
    Input, CapturedKey, L1 T5
    if (ErrorLevel = "Timeout") {
        GuiControl, Settings:, LvlBtn, %LevelUpKey%
    } else if (CapturedKey = " ") {
        CapturedKey := "Space"
    }
    
    ; Check for duplicates
    if (CapturedKey != "" && ErrorLevel != "Timeout") {
        if (CapturedKey = RerollKey) {
            Gui, Settings:+OwnDialogs
            MsgBox, 48, Duplicate Key, This key is already assigned to Reroll!
            GuiControl, Settings:, LvlBtn, %LevelUpKey%
        } else if (CapturedKey = FreezeKey) {
            Gui, Settings:+OwnDialogs
            MsgBox, 48, Duplicate Key, This key is already assigned to Freeze!
            GuiControl, Settings:, LvlBtn, %LevelUpKey%
        } else {
            LevelUpKey := CapturedKey
            GuiControl, Settings:, LvlBtn, %CapturedKey%
        }
    }
    
    ; Re-enable all buttons
    GuiControl, Settings:Enable, RRBtn
    GuiControl, Settings:Enable, FrzBtn
    return

CaptureReroll:
    ; Disable only the other buttons
    GuiControl, Settings:Disable, LvlBtn
    GuiControl, Settings:Disable, FrzBtn
    
    GuiControl, Settings:, RRBtn, Press any key...
    Input, CapturedKey, L1 T5
    if (ErrorLevel = "Timeout") {
        GuiControl, Settings:, RRBtn, %RerollKey%
    } else if (CapturedKey = " ") {
        CapturedKey := "Space"
    }
    
    ; Check for duplicates
    if (CapturedKey != "" && ErrorLevel != "Timeout") {
        if (CapturedKey = LevelUpKey) {
            Gui, Settings:+OwnDialogs
            MsgBox, 48, Duplicate Key, This key is already assigned to Level Up!
            GuiControl, Settings:, RRBtn, %RerollKey%
        } else if (CapturedKey = FreezeKey) {
            Gui, Settings:+OwnDialogs
            MsgBox, 48, Duplicate Key, This key is already assigned to Freeze!
            GuiControl, Settings:, RRBtn, %RerollKey%
        } else {
            RerollKey := CapturedKey
            GuiControl, Settings:, RRBtn, %CapturedKey%
        }
    }
    
    ; Re-enable all buttons
    GuiControl, Settings:Enable, LvlBtn
    GuiControl, Settings:Enable, FrzBtn
    return

CaptureFreeze:
    ; Disable only the other buttons
    GuiControl, Settings:Disable, LvlBtn
    GuiControl, Settings:Disable, RRBtn
    
    GuiControl, Settings:, FrzBtn, Press any key...
    Input, CapturedKey, L1 T5
    if (ErrorLevel = "Timeout") {
        GuiControl, Settings:, FrzBtn, %FreezeKey%
    } else if (CapturedKey = " ") {
        CapturedKey := "Space"
    }
    
    ; Check for duplicates
    if (CapturedKey != "" && ErrorLevel != "Timeout") {
        if (CapturedKey = LevelUpKey) {
            Gui, Settings:+OwnDialogs
            MsgBox, 48, Duplicate Key, This key is already assigned to Level Up!
            GuiControl, Settings:, FrzBtn, %FreezeKey%
        } else if (CapturedKey = RerollKey) {
            Gui, Settings:+OwnDialogs
            MsgBox, 48, Duplicate Key, This key is already assigned to Reroll!
            GuiControl, Settings:, FrzBtn, %FreezeKey%
        } else {
            FreezeKey := CapturedKey
            GuiControl, Settings:, FrzBtn, %CapturedKey%
        }
    }
    
    ; Re-enable all buttons
    GuiControl, Settings:Enable, LvlBtn
    GuiControl, Settings:Enable, RRBtn
    return

; =========================
; RESOLUTION HANDLER
; =========================
ResolutionChanged:
    Gui, Settings:Submit, NoHide
    
    ; Don't do anything if custom positions is checked
    if (CustomPositions)
        return
        
    ; Calculate positions based on resolution and scaling
    ; Base values are for 2560x1440 at 125% scaling
    if (ResolutionSelect = "2560x1440 (125% Scaling)") {
        FreezeX_Base := 1665
        FreezeY_Base := 243
        RerollX_Base := 1509
        RerollY_Base := 271
        LevelUpX_Base := 1058
        LevelUpY_Base := 273
    } else if (ResolutionSelect = "3840x2160 (150% Scaling)") {
        ; 4K at 150% - scale by resolution then adjust for scaling difference (150% vs 125%)
        ; Scale factor: (3840/2560) * (150/125) = 1.5 * 1.2 = 1.8
        FreezeX_Base := Round(1665 * 1.8)
        FreezeY_Base := Round(243 * 1.8)
        RerollX_Base := Round(1509 * 1.8)
        RerollY_Base := Round(271 * 1.8)
        LevelUpX_Base := Round(1058 * 1.8)
        LevelUpY_Base := Round(273 * 1.8)
    } else if (ResolutionSelect = "1920x1080 (100% Scaling)") {
        ; Scale from 2560x1440 125% to 1920x1080 100%
        ; First convert base to 100% scaling, then scale to 1920x1080
        FreezeX_Base := Round(1665 * 1.25 * 1920 / 2560)
        FreezeY_Base := Round(243 * 1.25 * 1080 / 1440)
        RerollX_Base := Round(1509 * 1.25 * 1920 / 2560)
        RerollY_Base := Round(271 * 1.25 * 1080 / 1440)
        LevelUpX_Base := Round(1058 * 1.25 * 1920 / 2560)
        LevelUpY_Base := Round(273 * 1.25 * 1080 / 1440)
    }
    
    ; Update display fields
    GuiControl, Settings:, FreezeXInput, %FreezeX_Base%
    GuiControl, Settings:, FreezeYInput, %FreezeY_Base%
    GuiControl, Settings:, RerollXInput, %RerollX_Base%
    GuiControl, Settings:, RerollYInput, %RerollY_Base%
    GuiControl, Settings:, LevelUpXInput, %LevelUpX_Base%
    GuiControl, Settings:, LevelUpYInput, %LevelUpY_Base%
    return

; =========================
; TOGGLE CUSTOM POSITIONS
; =========================
ToggleCustom:
    Gui, Settings:Submit, NoHide
    
    if (CustomPositions) {
        ; Disable resolution dropdown when custom is checked
        GuiControl, Settings:Disable, ResolutionSelect
        
        ; Enable all custom position controls
        GuiControl, Settings:Enable, CapFreBtn
        GuiControl, Settings:Enable, FreezeXInput
        GuiControl, Settings:Enable, FreezeYInput
        GuiControl, Settings:Enable, LblFrzX
        GuiControl, Settings:Enable, LblFrzY
        
        GuiControl, Settings:Enable, CapRRBtn
        GuiControl, Settings:Enable, RerollXInput
        GuiControl, Settings:Enable, RerollYInput
        GuiControl, Settings:Enable, LblRRX
        GuiControl, Settings:Enable, LblRRY
        
        GuiControl, Settings:Enable, CapLvlBtn
        GuiControl, Settings:Enable, LevelUpXInput
        GuiControl, Settings:Enable, LevelUpYInput
        GuiControl, Settings:Enable, LblLvlX
        GuiControl, Settings:Enable, LblLvlY
    } else {
        ; Enable resolution dropdown when custom is unchecked
        GuiControl, Settings:Enable, ResolutionSelect
        
        ; Disable all custom position controls
        GuiControl, Settings:Disable, CapFreBtn
        GuiControl, Settings:Disable, FreezeXInput
        GuiControl, Settings:Disable, FreezeYInput
        GuiControl, Settings:Disable, LblFrzX
        GuiControl, Settings:Disable, LblFrzY
        
        GuiControl, Settings:Disable, CapRRBtn
        GuiControl, Settings:Disable, RerollXInput
        GuiControl, Settings:Disable, RerollYInput
        GuiControl, Settings:Disable, LblRRX
        GuiControl, Settings:Disable, LblRRY
        
        GuiControl, Settings:Disable, CapLvlBtn
        GuiControl, Settings:Disable, LevelUpXInput
        GuiControl, Settings:Disable, LevelUpYInput
        GuiControl, Settings:Disable, LblLvlX
        GuiControl, Settings:Disable, LblLvlY
    }
    return

; =========================
; CREATE OVERLAY FUNCTION
; =========================
CreateOverlay() {
    global
    
    ; Destroy existing overlay
    Gui, HSBadge:Destroy
    
    ; Get display strings directly from variables
    if (LevelUpKey = "Space")
        LevelDisplay := "Space"
    else if (LevelUpKey = "")
        LevelDisplay := "F"
    else {
        LevelDisplay := LevelUpKey
        StringUpper, LevelDisplay, LevelDisplay
    }
    
    if (RerollKey = "Space")
        RerollDisplay := "Space"
    else if (RerollKey = "")
        RerollDisplay := "D"
    else {
        RerollDisplay := RerollKey
        StringUpper, RerollDisplay, RerollDisplay
    }
    
    if (FreezeKey = "Space")
        FreezeDisplay := "Space"
    else if (FreezeKey = "")
        FreezeDisplay := "Space"
    else {
        FreezeDisplay := FreezeKey
        StringUpper, FreezeDisplay, FreezeDisplay
    }
    
    Gui, HSBadge:New, +AlwaysOnTop -Caption +ToolWindow +E0x20 +LastFound
    Gui, HSBadge:Color, 1c2022
    Gui, HSBadge:Margin, 8, 5
    
    ; Header
    Gui, HSBadge:Font, s10 Norm, Segoe UI
    Gui, HSBadge:Add, Text, xs y5 cFFFFFF BackgroundTrans, Hotkeys:
    Gui, HSBadge:Font, s10 Bold, Segoe UI
    Gui, HSBadge:Add, Text, x+4 yp c%WinGreen% BackgroundTrans, ON
    
    ; Divider and bottom background
    Gui, HSBadge:Margin, 0, 0
    Gui, HSBadge:Add, Progress, x0 y+5 w167 h1 Background474f52 Disabled
    Gui, HSBadge:Add, Progress, x0 y+0 w167 h27 Background2e3235 Disabled
    
    ; Bottom text with dynamic keys
    Gui, HSBadge:Margin, 8, 0
    Gui, HSBadge:Font, s9 Bold, Segoe UI
    HotkeyText := LevelDisplay . ": ⏫  |  " . RerollDisplay . ": 🔄  |  " . FreezeDisplay . ": ❄️"
    Gui, HSBadge:Add, Text, x8 yp+5 cFFFFFF BackgroundTrans, %HotkeyText%
    
    ; Borders
    Gui, HSBadge:Margin, 0, 0
    Gui, HSBadge:Add, Progress, x0 y0 w167 h1 Background474f52 Disabled
    Gui, HSBadge:Add, Progress, x0 y56 w167 h1 Background474f52 Disabled
    Gui, HSBadge:Add, Progress, x0 y0 w1 h56 Background474f52 Disabled
    Gui, HSBadge:Add, Progress, x166 y0 w1 h56 Background474f52 Disabled
    
    HSBadgeHWND := WinExist()
    WinSet, Transparent, 190, ahk_id %HSBadgeHWND%
    Gui, HSBadge:Hide
}

; =========================
; SAVE SETTINGS
; =========================
SaveAndMinimize:
    Gui, Settings:Submit, NoHide
    
    ; Get position values
    GuiControlGet, FreezeXVal, Settings:, FreezeXInput
    GuiControlGet, FreezeYVal, Settings:, FreezeYInput
    GuiControlGet, RerollXVal, Settings:, RerollXInput
    GuiControlGet, RerollYVal, Settings:, RerollYInput
    GuiControlGet, LevelUpXVal, Settings:, LevelUpXInput
    GuiControlGet, LevelUpYVal, Settings:, LevelUpYInput
    
    ; Save to config
    IniWrite, %LevelUpKey%, %ConfigFile%, Hotkeys, LevelUp
    IniWrite, %RerollKey%, %ConfigFile%, Hotkeys, Reroll
    IniWrite, %FreezeKey%, %ConfigFile%, Hotkeys, Freeze
    IniWrite, %FreezeXVal%, %ConfigFile%, Positions, FreezeX
    IniWrite, %FreezeYVal%, %ConfigFile%, Positions, FreezeY
    IniWrite, %RerollXVal%, %ConfigFile%, Positions, RerollX
    IniWrite, %RerollYVal%, %ConfigFile%, Positions, RerollY
    IniWrite, %LevelUpXVal%, %ConfigFile%, Positions, LevelUpX
    IniWrite, %LevelUpYVal%, %ConfigFile%, Positions, LevelUpY
    
    ; Update globals
    FreezeX_Base := FreezeXVal
    FreezeY_Base := FreezeYVal
    RerollX_Base := RerollXVal
    RerollY_Base := RerollYVal
    LevelUpX_Base := LevelUpXVal
    LevelUpY_Base := LevelUpYVal
    
    ; Recreate overlay and hotkeys
    CreateOverlay()
    SetupHotkeys()
    
    Gui, Settings:Hide
    return

ShowSettings:
    Gui, Settings:Show
    return

SettingsGuiClose:
    ExitApp
    return

ExitApp:
    ExitApp
    return

; =========================
; HOTKEY SETUP
; =========================
SetupHotkeys() {
    global
    
    ; Remove old hotkeys
    Hotkey, IfWinActive
    Hotkey, ~%LevelUpKey%, Off, UseErrorLevel
    Hotkey, ~%RerollKey%, Off, UseErrorLevel
    Hotkey, ~%FreezeKey%, Off, UseErrorLevel
    
    ; Set new hotkeys (only active in Hearthstone)
    Hotkey, IfWinActive, ahk_exe Hearthstone.exe
    Hotkey, ~%LevelUpKey%, LevelUpAction, On
    Hotkey, ~%RerollKey%, RerollAction, On
    Hotkey, ~%FreezeKey%, FreezeAction, On
    Hotkey, IfWinActive
}

; =========================
; HOTKEY ACTIONS
; =========================
LevelUpAction:
    MouseGetPos, ox, oy
    GetHSPos(cx, cy, LevelUpX_Base, LevelUpY_Base, BaseW, BaseH)
    MouseMove, cx, cy, 0
    Click
    MouseMove, ox, oy, 0
    return

RerollAction:
    MouseGetPos, ox, oy
    GetHSPos(cx, cy, RerollX_Base, RerollY_Base, BaseW, BaseH)
    MouseMove, cx, cy, 0
    Click
    MouseMove, ox, oy, 0
    return

FreezeAction:
    MouseGetPos, ox, oy
    GetHSPos(cx, cy, FreezeX_Base, FreezeY_Base, BaseW, BaseH)
    MouseMove, cx, cy, 0
    Click
    MouseMove, ox, oy, 0
    return

; =========================
; HELPER FUNCTIONS
; =========================
GetHSPos(ByRef outX, ByRef outY, baseX, baseY, BaseW, BaseH) {
    WinGetPos, wx, wy, ww, wh, A
    sx := ww / BaseW
    sy := wh / BaseH
    outX := wx + Round(baseX * sx)
    outY := wy + Round(baseY * sy)
}

CheckHearthstone:
    if WinActive("ahk_exe Hearthstone.exe")
        Gui, HSBadge:Show, x%OverlayX% y%OverlayY% w167 NoActivate
    else
        Gui, HSBadge:Hide
    return

; =========================
; POSITION CAPTURE FUNCTIONS
; =========================
CaptureFreezePos:
    ; Check if Hearthstone is running
    IfWinNotExist, ahk_exe Hearthstone.exe
    {
        Gui, Settings:+OwnDialogs
        MsgBox, 48, Hearthstone Not Found, Please open Hearthstone before capturing positions.
        return
    }
    
    Gui, Settings:+OwnDialogs
    MsgBox, 64, Capture Freeze Position, Click OK, then click on the FREEZE button in Hearthstone.`n`nYou have 5 seconds after clicking OK.
    Sleep, 500
    ; Wait for click
    KeyWait, LButton, D T5
    if (!ErrorLevel) {
        MouseGetPos, mx, my
        ; Convert screen coords to relative coords for 2560x1440 base
        WinGetPos, wx, wy, ww, wh, ahk_exe Hearthstone.exe
        relX := mx - wx
        relY := my - wy
        ; Scale to base resolution
        FreezeX_Base := Round(relX * 2560 / ww)
        FreezeY_Base := Round(relY * 1440 / wh)
        GuiControl, Settings:, FreezeXInput, %FreezeX_Base%
        GuiControl, Settings:, FreezeYInput, %FreezeY_Base%
    } else {
        Gui, Settings:+OwnDialogs
        MsgBox, 48, Timeout, No click detected. Please try again.
    }
    return

CaptureRerollPos:
    ; Check if Hearthstone is running
    IfWinNotExist, ahk_exe Hearthstone.exe
    {
        Gui, Settings:+OwnDialogs
        MsgBox, 48, Hearthstone Not Found, Please open Hearthstone before capturing positions.
        return
    }
    
    Gui, Settings:+OwnDialogs
    MsgBox, 64, Capture Reroll Position, Click OK, then click on the REROLL button in Hearthstone.`n`nYou have 5 seconds after clicking OK.
    Sleep, 500
    KeyWait, LButton, D T5
    if (!ErrorLevel) {
        MouseGetPos, mx, my
        WinGetPos, wx, wy, ww, wh, ahk_exe Hearthstone.exe
        relX := mx - wx
        relY := my - wy
        RerollX_Base := Round(relX * 2560 / ww)
        RerollY_Base := Round(relY * 1440 / wh)
        GuiControl, Settings:, RerollXInput, %RerollX_Base%
        GuiControl, Settings:, RerollYInput, %RerollY_Base%
    } else {
        Gui, Settings:+OwnDialogs
        MsgBox, 48, Timeout, No click detected. Please try again.
    }
    return

CaptureLevelPos:
    ; Check if Hearthstone is running
    IfWinNotExist, ahk_exe Hearthstone.exe
    {
        Gui, Settings:+OwnDialogs
        MsgBox, 48, Hearthstone Not Found, Please open Hearthstone before capturing positions.
        return
    }
    
    Gui, Settings:+OwnDialogs
    MsgBox, 64, Capture Level Up Position, Click OK, then click on the LEVEL UP button in Hearthstone.`n`nYou have 5 seconds after clicking OK.
    Sleep, 500
    KeyWait, LButton, D T5
    if (!ErrorLevel) {
        MouseGetPos, mx, my
        WinGetPos, wx, wy, ww, wh, ahk_exe Hearthstone.exe
        relX := mx - wx
        relY := my - wy
        LevelUpX_Base := Round(relX * 2560 / ww)
        LevelUpY_Base := Round(relY * 1440 / wh)
        GuiControl, Settings:, LevelUpXInput, %LevelUpX_Base%
        GuiControl, Settings:, LevelUpYInput, %LevelUpY_Base%
    } else {
        Gui, Settings:+OwnDialogs
        MsgBox, 48, Timeout, No click detected. Please try again.
    }
    return
