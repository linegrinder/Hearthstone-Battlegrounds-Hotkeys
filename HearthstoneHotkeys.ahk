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
global LevelUpKey, RerollKey, FreezeKey, SellKey
global PrevLevelUpKey, PrevRerollKey, PrevFreezeKey, PrevSellKey
global FreezeX_Base, FreezeY_Base, RerollX_Base, RerollY_Base, LevelUpX_Base, LevelUpY_Base, SellX_Base, SellY_Base
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
IniRead, SellKey, %ConfigFile%, Hotkeys, Sell, e
IniRead, FreezeX_Base, %ConfigFile%, Positions, FreezeX, 1665
IniRead, FreezeY_Base, %ConfigFile%, Positions, FreezeY, 243
IniRead, RerollX_Base, %ConfigFile%, Positions, RerollX, 1509
IniRead, RerollY_Base, %ConfigFile%, Positions, RerollY, 271
IniRead, LevelUpX_Base, %ConfigFile%, Positions, LevelUpX, 1058
IniRead, LevelUpY_Base, %ConfigFile%, Positions, LevelUpY, 273
IniRead, SellX_Base, %ConfigFile%, Positions, SellX, 1280
IniRead, SellY_Base, %ConfigFile%, Positions, SellY, 250
IniRead, ResolutionSelect, %ConfigFile%, Settings, ResolutionSelect, 2

; Convert loaded text/index to mode number (1=2160p, 2=1440p, 3=1080p, 4=Custom)
if (ResolutionSelect = "3840x2160 (150% Scaling)" || ResolutionSelect = 1) {
    ResolutionMode := 1
} else if (ResolutionSelect = "2560x1440 (125% Scaling)" || ResolutionSelect = 2) {
    ResolutionMode := 2
} else if (ResolutionSelect = "1920x1080 (100% Scaling)" || ResolutionSelect = 3) {
    ResolutionMode := 3
} else if (ResolutionSelect = 4) {
    ResolutionMode := 4  ; Custom mode
} else {
    ResolutionMode := 2  ; Default to 1440p
}

IniRead, CustomPositions, %ConfigFile%, Settings, CustomPositions, 0


; =========================
; HELPER FUNCTIONS
; =========================
GetGUIDisplayName(key) {
    ; Convert key codes to friendly GUI display names
    if (key = "Space")
        return "Space"
    if (key = "MButton")
        return "MMB"
    if (key = "XButton1")
        return "Mouse4"
    if (key = "XButton2")
        return "Mouse5"
    ; For regular keys, just uppercase
    StringUpper, displayKey, key
    return displayKey
}

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
Gui, Settings:Add, GroupBox, x20 y20 w270 h167, Hotkey Configuration

; Add Bob image in top right corner
Gui, Settings:Add, Picture, x308 y24 w146 h162, %A_Temp%\Bob_Hotkey.png

Gui, Settings:Font, s9 Norm
Gui, Settings:Add, Text, x40 y43, Level Up Key:
LevelUpDisplay := GetGUIDisplayName(LevelUpKey)
Gui, Settings:Add, Button, x140 y41 w100 h25 gCaptureLevelUp vLvlBtn, %LevelUpDisplay%
Gui, Settings:Add, Button, x245 y41 w20 h25 gClearLevelUpKey vClearLvlKeyBtn, ×

Gui, Settings:Add, Text, x40 y73, Reroll Key:
RerollDisplay := GetGUIDisplayName(RerollKey)
Gui, Settings:Add, Button, x140 y70 w100 h25 gCaptureReroll vRRBtn, %RerollDisplay%
Gui, Settings:Add, Button, x245 y70 w20 h25 gClearRerollKey vClearRRKeyBtn, ×

Gui, Settings:Add, Text, x40 y103, Freeze Key:
FreezeDisplay := GetGUIDisplayName(FreezeKey)
Gui, Settings:Add, Button, x140 y100 w100 h25 gCaptureFreeze vFrzBtn, %FreezeDisplay%
Gui, Settings:Add, Button, x245 y100 w20 h25 gClearFreezeKey vClearFrzKeyBtn, ×

; Separator line (shorter now)
Gui, Settings:Add, Text, x40 y137 w227 h1 0x10

; Sell Key
Gui, Settings:Add, Text, x40 y154, Sell Key:
SellDisplay := GetGUIDisplayName(SellKey)
Gui, Settings:Add, Button, x140 y149 w100 h25 gCaptureSell vSellBtn, %SellDisplay%
Gui, Settings:Add, Button, x245 y149 w20 h25 gClearSellKey vClearSellKeyBtn, ×

; Screen Resolution with Radio Buttons
Gui, Settings:Font, s9 Norm
Gui, Settings:Add, GroupBox, x20 y206 w434 h201, Screen Resolution && Windows Scaling

; Radio buttons on one horizontal line (tightened spacing)
Gui, Settings:Font, s8 Norm
Gui, Settings:Add, Radio, x35 y231 vRes2160 gResolutionChanged, 3840x2160 (150`%)
Gui, Settings:Add, Radio, x157 y231 vRes1440 gResolutionChanged, 2560x1440 (125`%)
Gui, Settings:Add, Radio, x279 y231 vRes1080 gResolutionChanged, 1920x1080 (100`%)

; Custom radio button on second line
Gui, Settings:Add, Radio, x35 y256 vResCustom gResolutionChanged, Custom

; Position capture section (initially disabled except for Custom mode)
Gui, Settings:Font, s9
Gui, Settings:Add, Button, x35 y278 w110 h25 gCaptureFreezePos Disabled vCapFreBtn, Capture Freeze
Gui, Settings:Add, Text, x155 y282 Disabled vLblFrzX, X:
Gui, Settings:Add, Edit, x170 y280 w50 vFreezeXInput Disabled Number, %FreezeX_Base%
Gui, Settings:Add, Text, x230 y282 Disabled vLblFrzY, Y:
Gui, Settings:Add, Edit, x245 y280 w50 vFreezeYInput Disabled Number, %FreezeY_Base%

Gui, Settings:Add, Button, x35 y308 w110 h25 gCaptureRerollPos Disabled vCapRRBtn, Capture Reroll
Gui, Settings:Add, Text, x155 y312 Disabled vLblRRX, X:
Gui, Settings:Add, Edit, x170 y310 w50 vRerollXInput Disabled Number, %RerollX_Base%
Gui, Settings:Add, Text, x230 y312 Disabled vLblRRY, Y:
Gui, Settings:Add, Edit, x245 y310 w50 vRerollYInput Disabled Number, %RerollY_Base%

Gui, Settings:Add, Button, x35 y338 w110 h25 gCaptureLevelPos Disabled vCapLvlBtn, Capture Level Up
Gui, Settings:Add, Text, x155 y342 Disabled vLblLvlX, X:
Gui, Settings:Add, Edit, x170 y340 w50 vLevelUpXInput Disabled Number, %LevelUpX_Base%
Gui, Settings:Add, Text, x230 y342 Disabled vLblLvlY, Y:
Gui, Settings:Add, Edit, x245 y340 w50 vLevelUpYInput Disabled Number, %LevelUpY_Base%

Gui, Settings:Add, Button, x35 y368 w110 h25 gCaptureSellPos Disabled vCapSellBtn, Capture Sell
Gui, Settings:Add, Text, x155 y372 Disabled vLblSellX, X:
Gui, Settings:Add, Edit, x170 y370 w50 vSellXInput Disabled Number, %SellX_Base%
Gui, Settings:Add, Text, x230 y372 Disabled vLblSellY, Y:
Gui, Settings:Add, Edit, x245 y370 w50 vSellYInput Disabled Number, %SellY_Base%

; Buttons
Gui, Settings:Font, s10
Gui, Settings:Add, Button, x20 y425 w150 h35 Default gSaveAndMinimize, Save && Minimize
Gui, Settings:Add, Button, x190 y425 w150 h35 gExitApp, Exit

Gui, Settings:Show, w470 h479, Hearthstone BGs Hotkeys Settings

; Set the correct radio button based on loaded ResolutionMode
if (ResolutionMode = 1) {
    GuiControl, Settings:, Res2160, 1
} else if (ResolutionMode = 2) {
    GuiControl, Settings:, Res1440, 1
} else if (ResolutionMode = 3) {
    GuiControl, Settings:, Res1080, 1
} else if (ResolutionMode = 4) {
    GuiControl, Settings:, ResCustom, 1
}

; Trigger resolution changed handler to update all position fields with correct values
Gosub, ResolutionChanged

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
WaitForKeyOrMouse() {
    ; Unified polling for both mouse and keyboard - no Input command
    StartTime := A_TickCount
    
    Loop {
        if (A_TickCount - StartTime > 5000)
            return ""
        
        ; Check mouse buttons first - return immediately
        if GetKeyState("MButton", "P") {
            return "MButton"
        }
        if GetKeyState("XButton1", "P") {
            return "XButton1"
        }
        if GetKeyState("XButton2", "P") {
            return "XButton2"
        }
        
        ; Check Space key - wait for release
        if GetKeyState("Space", "P") {
            KeyWait, Space
            return "Space"
        }
        
        ; Check letter keys (a-z) - wait for release
        Loop, 26 {
            key := Chr(96 + A_Index)  ; a=97, z=122
            if GetKeyState(key, "P") {
                KeyWait, %key%
                StringUpper, key, key
                return key
            }
        }
        
        ; Check number keys (0-9) - wait for release
        Loop, 10 {
            key := A_Index - 1
            if GetKeyState(key, "P") {
                KeyWait, %key%
                return key
            }
        }
        
        ; Check F-keys (F1-F12) - wait for release
        Loop, 12 {
            fKey := "F" . A_Index
            if GetKeyState(fKey, "P") {
                KeyWait, %fKey%
                return fKey
            }
        }
        
        Sleep, 10
    }
}

CaptureLevelUp:
    ; Disable other buttons while listening
    GuiControl, Settings:Disable, RRBtn
    GuiControl, Settings:Disable, FrzBtn
    GuiControl, Settings:Disable, SellBtn
    
    ; Save the current display before capture
    GuiControlGet, PrevDisplay, Settings:, LvlBtn
    
    GuiControl, Settings:, LvlBtn, Press any key...
    
    ; Unified input capture for both mouse and keyboard
    CapturedKey := WaitForKeyOrMouse()
    
    if (CapturedKey = "") {
        GuiControl, Settings:, LvlBtn, %PrevDisplay%
    } else if (CapturedKey != "") {
        ; Check for duplicates
        if (CapturedKey = RerollKey) {
            Gui, Settings:+OwnDialogs
            MsgBox, 48, Duplicate Key, This key is already assigned to Reroll!
            GuiControl, Settings:, LvlBtn, %PrevDisplay%
        } else if (CapturedKey = FreezeKey) {
            Gui, Settings:+OwnDialogs
            MsgBox, 48, Duplicate Key, This key is already assigned to Freeze!
            GuiControl, Settings:, LvlBtn, %PrevDisplay%
        } else if (CapturedKey = SellKey) {
            Gui, Settings:+OwnDialogs
            MsgBox, 48, Duplicate Key, This key is already assigned to Sell!
            GuiControl, Settings:, LvlBtn, %PrevDisplay%
        } else {
            LevelUpKey := CapturedKey
            DisplayName := GetGUIDisplayName(CapturedKey)
            GuiControl, Settings:, LvlBtn, %DisplayName%
        }
    }
    
    ; Re-enable buttons
    GuiControl, Settings:Enable, RRBtn
    GuiControl, Settings:Enable, FrzBtn
    GuiControl, Settings:Enable, SellBtn
    return

CaptureReroll:
    ; Disable other buttons while listening
    GuiControl, Settings:Disable, LvlBtn
    GuiControl, Settings:Disable, FrzBtn
    GuiControl, Settings:Disable, SellBtn
    
    ; Save the current display before capture
    GuiControlGet, PrevDisplay, Settings:, RRBtn
    
    GuiControl, Settings:, RRBtn, Press any key...
    
    ; Unified input capture for both mouse and keyboard
    CapturedKey := WaitForKeyOrMouse()
    
    if (CapturedKey = "") {
        GuiControl, Settings:, RRBtn, %PrevDisplay%
    } else if (CapturedKey != "") {
        if (CapturedKey = LevelUpKey) {
            Gui, Settings:+OwnDialogs
            MsgBox, 48, Duplicate Key, This key is already assigned to Level Up!
            GuiControl, Settings:, RRBtn, %PrevDisplay%
        } else if (CapturedKey = FreezeKey) {
            Gui, Settings:+OwnDialogs
            MsgBox, 48, Duplicate Key, This key is already assigned to Freeze!
            GuiControl, Settings:, RRBtn, %PrevDisplay%
        } else if (CapturedKey = SellKey) {
            Gui, Settings:+OwnDialogs
            MsgBox, 48, Duplicate Key, This key is already assigned to Sell!
            GuiControl, Settings:, RRBtn, %PrevDisplay%
        } else {
            RerollKey := CapturedKey
            DisplayName := GetGUIDisplayName(CapturedKey)
            GuiControl, Settings:, RRBtn, %DisplayName%
        }
    }
    
    ; Re-enable buttons
    GuiControl, Settings:Enable, LvlBtn
    GuiControl, Settings:Enable, FrzBtn
    GuiControl, Settings:Enable, SellBtn
    return

CaptureFreeze:
    ; Disable other buttons while listening
    GuiControl, Settings:Disable, LvlBtn
    GuiControl, Settings:Disable, RRBtn
    GuiControl, Settings:Disable, SellBtn
    
    ; Save the current display before capture
    GuiControlGet, PrevDisplay, Settings:, FrzBtn
    
    GuiControl, Settings:, FrzBtn, Press any key...
    
    ; Unified input capture for both mouse and keyboard
    CapturedKey := WaitForKeyOrMouse()
    
    if (CapturedKey = "") {
        GuiControl, Settings:, FrzBtn, %PrevDisplay%
    } else if (CapturedKey != "") {
        if (CapturedKey = LevelUpKey) {
            Gui, Settings:+OwnDialogs
            MsgBox, 48, Duplicate Key, This key is already assigned to Level Up!
            GuiControl, Settings:, FrzBtn, %PrevDisplay%
        } else if (CapturedKey = RerollKey) {
            Gui, Settings:+OwnDialogs
            MsgBox, 48, Duplicate Key, This key is already assigned to Reroll!
            GuiControl, Settings:, FrzBtn, %PrevDisplay%
        } else if (CapturedKey = SellKey) {
            Gui, Settings:+OwnDialogs
            MsgBox, 48, Duplicate Key, This key is already assigned to Sell!
            GuiControl, Settings:, FrzBtn, %PrevDisplay%
        } else {
            FreezeKey := CapturedKey
            DisplayName := GetGUIDisplayName(CapturedKey)
            GuiControl, Settings:, FrzBtn, %DisplayName%
        }
    }
    
    ; Re-enable buttons
    GuiControl, Settings:Enable, LvlBtn
    GuiControl, Settings:Enable, RRBtn
    GuiControl, Settings:Enable, SellBtn
    return

CaptureSell:
    ; Disable other buttons while listening
    GuiControl, Settings:Disable, LvlBtn
    GuiControl, Settings:Disable, RRBtn
    GuiControl, Settings:Disable, FrzBtn
    
    ; Save the current display before capture
    GuiControlGet, PrevDisplay, Settings:, SellBtn
    
    GuiControl, Settings:, SellBtn, Press any key...
    
    ; Unified input capture for both mouse and keyboard
    CapturedKey := WaitForKeyOrMouse()
    
    if (CapturedKey = "") {
        GuiControl, Settings:, SellBtn, %PrevDisplay%
    } else if (CapturedKey != "") {
        if (CapturedKey = LevelUpKey) {
            Gui, Settings:+OwnDialogs
            MsgBox, 48, Duplicate Key, This key is already assigned to Level Up!
            GuiControl, Settings:, SellBtn, %PrevDisplay%
        } else if (CapturedKey = RerollKey) {
            Gui, Settings:+OwnDialogs
            MsgBox, 48, Duplicate Key, This key is already assigned to Reroll!
            GuiControl, Settings:, SellBtn, %PrevDisplay%
        } else if (CapturedKey = FreezeKey) {
            Gui, Settings:+OwnDialogs
            MsgBox, 48, Duplicate Key, This key is already assigned to Freeze!
            GuiControl, Settings:, SellBtn, %PrevDisplay%
        } else {
            SellKey := CapturedKey
            DisplayName := GetGUIDisplayName(CapturedKey)
            GuiControl, Settings:, SellBtn, %DisplayName%
        }
    }
    
    ; Re-enable buttons
    GuiControl, Settings:Enable, LvlBtn
    GuiControl, Settings:Enable, RRBtn
    GuiControl, Settings:Enable, FrzBtn
    return

; =========================
; CLEAR HOTKEY FUNCTIONS
; =========================
ClearLevelUpKey:
    LevelUpKey := ""
    GuiControl, Settings:, LvlBtn, Not Set
    return

ClearRerollKey:
    RerollKey := ""
    GuiControl, Settings:, RRBtn, Not Set
    return

ClearFreezeKey:
    FreezeKey := ""
    GuiControl, Settings:, FrzBtn, Not Set
    return

ClearSellKey:
    SellKey := ""
    GuiControl, Settings:, SellBtn, Not Set
    return

; =========================
; RESOLUTION HANDLER
; =========================
ResolutionChanged:
    Gui, Settings:Submit, NoHide
    
    ; Determine which radio button is selected
    GuiControlGet, Res2160
    GuiControlGet, Res1440
    GuiControlGet, Res1080
    GuiControlGet, ResCustom
    
    ; Set positions based on which radio button is checked
    if (Res2160) {
        ; 3840x2160 (150% Scaling)
        FreezeX_Base := Round(1665 * 1.8)
        FreezeY_Base := Round(243 * 1.8)
        RerollX_Base := Round(1509 * 1.8)
        RerollY_Base := Round(271 * 1.8)
        LevelUpX_Base := Round(1058 * 1.8)
        LevelUpY_Base := Round(273 * 1.8)
        SellX_Base := Round(1280 * 1.8)
        SellY_Base := Round(250 * 1.8)
        
        ; Disable capture buttons and fields
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
        GuiControl, Settings:Disable, CapSellBtn
        GuiControl, Settings:Disable, SellXInput
        GuiControl, Settings:Disable, SellYInput
        GuiControl, Settings:Disable, LblSellX
        GuiControl, Settings:Disable, LblSellY
    } else if (Res1440) {
        ; 2560x1440 (125% Scaling) - Base values
        FreezeX_Base := 1665
        FreezeY_Base := 243
        RerollX_Base := 1509
        RerollY_Base := 271
        LevelUpX_Base := 1058
        LevelUpY_Base := 273
        SellX_Base := 1280
        SellY_Base := 250
        
        ; Disable capture buttons and fields
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
        GuiControl, Settings:Disable, CapSellBtn
        GuiControl, Settings:Disable, SellXInput
        GuiControl, Settings:Disable, SellYInput
        GuiControl, Settings:Disable, LblSellX
        GuiControl, Settings:Disable, LblSellY
    } else if (Res1080) {
        ; 1920x1080 (100% Scaling)
        FreezeX_Base := Round(1665 * 1.25 * 1920 / 2560)
        FreezeY_Base := Round(243 * 1.25 * 1080 / 1440)
        RerollX_Base := Round(1509 * 1.25 * 1920 / 2560)
        RerollY_Base := Round(271 * 1.25 * 1080 / 1440)
        LevelUpX_Base := Round(1058 * 1.25 * 1920 / 2560)
        LevelUpY_Base := Round(273 * 1.25 * 1080 / 1440)
        SellX_Base := Round(1280 * 1.25 * 1920 / 2560)
        SellY_Base := Round(250 * 1.25 * 1080 / 1440)
        
        ; Disable capture buttons and fields
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
        GuiControl, Settings:Disable, CapSellBtn
        GuiControl, Settings:Disable, SellXInput
        GuiControl, Settings:Disable, SellYInput
        GuiControl, Settings:Disable, LblSellX
        GuiControl, Settings:Disable, LblSellY
    } else if (ResCustom) {
        ; Custom mode - enable capture buttons and fields
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
        GuiControl, Settings:Enable, CapSellBtn
        GuiControl, Settings:Enable, SellXInput
        GuiControl, Settings:Enable, SellYInput
        GuiControl, Settings:Enable, LblSellX
        GuiControl, Settings:Enable, LblSellY
    }
    
    ; Update display fields
    GuiControl, Settings:, FreezeXInput, %FreezeX_Base%
    GuiControl, Settings:, FreezeYInput, %FreezeY_Base%
    GuiControl, Settings:, RerollXInput, %RerollX_Base%
    GuiControl, Settings:, RerollYInput, %RerollY_Base%
    GuiControl, Settings:, LevelUpXInput, %LevelUpX_Base%
    GuiControl, Settings:, LevelUpYInput, %LevelUpY_Base%
    GuiControl, Settings:, SellXInput, %SellX_Base%
    GuiControl, Settings:, SellYInput, %SellY_Base%
    return

; =========================
; CREATE OVERLAY FUNCTION
; =========================
CreateOverlay() {
    global
    
    ; Destroy existing overlay
    Gui, HSBadge:Destroy
    
    ; Get display strings directly from variables
    if (LevelUpKey = "")
        LevelDisplay := "-"
    else if (LevelUpKey = "Space")
        LevelDisplay := "Space"
    else if (LevelUpKey = "MButton")
        LevelDisplay := "MMB"
    else if (LevelUpKey = "XButton1")
        LevelDisplay := "M4"
    else if (LevelUpKey = "XButton2")
        LevelDisplay := "M5"
    else {
        LevelDisplay := LevelUpKey
        StringUpper, LevelDisplay, LevelDisplay
    }
    
    if (RerollKey = "")
        RerollDisplay := "-"
    else if (RerollKey = "Space")
        RerollDisplay := "Space"
    else if (RerollKey = "MButton")
        RerollDisplay := "MMB"
    else if (RerollKey = "XButton1")
        RerollDisplay := "M4"
    else if (RerollKey = "XButton2")
        RerollDisplay := "M5"
    else {
        RerollDisplay := RerollKey
        StringUpper, RerollDisplay, RerollDisplay
    }
    
    if (FreezeKey = "")
        FreezeDisplay := "-"
    else if (FreezeKey = "Space")
        FreezeDisplay := "Space"
    else if (FreezeKey = "MButton")
        FreezeDisplay := "MMB"
    else if (FreezeKey = "XButton1")
        FreezeDisplay := "M4"
    else if (FreezeKey = "XButton2")
        FreezeDisplay := "M5"
    else {
        FreezeDisplay := FreezeKey
        StringUpper, FreezeDisplay, FreezeDisplay
    }
    
    if (SellKey = "")
        SellDisplay := "-"
    else if (SellKey = "Space")
        SellDisplay := "Space"
    else if (SellKey = "MButton")
        SellDisplay := "MMB"
    else if (SellKey = "XButton1")
        SellDisplay := "M4"
    else if (SellKey = "XButton2")
        SellDisplay := "M5"
    else {
        SellDisplay := SellKey
        StringUpper, SellDisplay, SellDisplay
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
    
    ; Bottom text with dynamic keys
    Gui, HSBadge:Font, s8 Bold, Segoe UI
    HotkeyText :="⏫: " . LevelDisplay . "  |  🔄: " . RerollDisplay . "  |  ❄️: " . FreezeDisplay . "  |  💲: " . SellDisplay
    
    ; Use fixed width - 300px is a good balance
    GuiWidth := 223
    
    ; Add dividers
    Gui, HSBadge:Add, Progress, x0 y+5 w%GuiWidth% h1 Background474f52 Disabled
    Gui, HSBadge:Add, Progress, x0 y+0 w%GuiWidth% h27 Background2e3235 Disabled
    
    ; Add the hotkey text
    Gui, HSBadge:Margin, 8, 0
    Gui, HSBadge:Font, s8 Bold, Segoe UI
    Gui, HSBadge:Add, Text, x8 yp+6 cFFFFFF BackgroundTrans, %HotkeyText%
    
    ; Borders
    Gui, HSBadge:Margin, 0, 0
    Gui, HSBadge:Add, Progress, x0 y0 w%GuiWidth% h1 Background474f52 Disabled
    Gui, HSBadge:Add, Progress, x0 y55 w%GuiWidth% h1 Background474f52 Disabled
    Gui, HSBadge:Add, Progress, x0 y0 w1 h56 Background474f52 Disabled
    RightBorderX := GuiWidth - 1
    Gui, HSBadge:Add, Progress, x%RightBorderX% y0 w1 h56 Background474f52 Disabled
    
    HSBadgeHWND := WinExist()
    WinSet, Transparent, 190, ahk_id %HSBadgeHWND%
    ; Set the size but keep hidden
    Gui, HSBadge:Show, w%GuiWidth% h56 Hide, HSBadge
    Gui, HSBadge:Hide
}

; =========================
; SAVE SETTINGS
; =========================
SaveAndMinimize:
    Gui, Settings:Submit, NoHide
    
    ; Read the currently-active (previously saved) hotkeys from config BEFORE overwriting it
    ; This ensures we turn off the OLD hotkeys (including mouse buttons) and not the new ones
    IniRead, PrevLevelUpKey, %ConfigFile%, Hotkeys, LevelUp, f
    IniRead, PrevRerollKey,  %ConfigFile%, Hotkeys, Reroll, d
    IniRead, PrevFreezeKey,  %ConfigFile%, Hotkeys, Freeze, Space
    IniRead, PrevSellKey,    %ConfigFile%, Hotkeys, Sell, e
    
    ; Get position values
    GuiControlGet, FreezeXVal, Settings:, FreezeXInput
    GuiControlGet, FreezeYVal, Settings:, FreezeYInput
    GuiControlGet, RerollXVal, Settings:, RerollXInput
    GuiControlGet, RerollYVal, Settings:, RerollYInput
    GuiControlGet, LevelUpXVal, Settings:, LevelUpXInput
    GuiControlGet, LevelUpYVal, Settings:, LevelUpYInput
    GuiControlGet, SellXVal, Settings:, SellXInput
    GuiControlGet, SellYVal, Settings:, SellYInput
    
    ; Get resolution selection based on which radio button is checked
    GuiControlGet, Res2160
    GuiControlGet, Res1440
    GuiControlGet, Res1080
    GuiControlGet, ResCustom
    
    if (Res2160) {
        ResolutionMode := 1
    } else if (Res1440) {
        ResolutionMode := 2
    } else if (Res1080) {
        ResolutionMode := 3
    } else if (ResCustom) {
        ResolutionMode := 4
    } else {
        ResolutionMode := 2  ; Default to 1440p
    }
    
    ; Save to config
    IniWrite, %LevelUpKey%, %ConfigFile%, Hotkeys, LevelUp
    IniWrite, %RerollKey%, %ConfigFile%, Hotkeys, Reroll
    IniWrite, %FreezeKey%, %ConfigFile%, Hotkeys, Freeze
    IniWrite, %SellKey%, %ConfigFile%, Hotkeys, Sell
    IniWrite, %FreezeXVal%, %ConfigFile%, Positions, FreezeX
    IniWrite, %FreezeYVal%, %ConfigFile%, Positions, FreezeY
    IniWrite, %RerollXVal%, %ConfigFile%, Positions, RerollX
    IniWrite, %RerollYVal%, %ConfigFile%, Positions, RerollY
    IniWrite, %LevelUpXVal%, %ConfigFile%, Positions, LevelUpX
    IniWrite, %LevelUpYVal%, %ConfigFile%, Positions, LevelUpY
    IniWrite, %SellXVal%, %ConfigFile%, Positions, SellX
    IniWrite, %SellYVal%, %ConfigFile%, Positions, SellY
    IniWrite, %ResolutionMode%, %ConfigFile%, Settings, ResolutionSelect
    
    ; Update globals
    FreezeX_Base := FreezeXVal
    FreezeY_Base := FreezeYVal
    RerollX_Base := RerollXVal
    RerollY_Base := RerollYVal
    LevelUpX_Base := LevelUpXVal
    LevelUpY_Base := LevelUpYVal
    SellX_Base := SellXVal
    SellY_Base := SellYVal
    
    ; Recreate overlay and hotkeys
    ; SetupHotkeys() will now correctly turn off the OLD hotkeys (read from config above)
    ; and turn on the NEW hotkeys (from the current variables)
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
    
    ; Remove old hotkeys with SAME context they were registered with (Hearthstone)
    Hotkey, IfWinActive, ahk_exe Hearthstone.exe
    if (PrevLevelUpKey != "")
        Hotkey, ~%PrevLevelUpKey%, Off, UseErrorLevel
    if (PrevRerollKey != "")
        Hotkey, ~%PrevRerollKey%, Off, UseErrorLevel
    if (PrevFreezeKey != "")
        Hotkey, ~%PrevFreezeKey%, Off, UseErrorLevel
    if (PrevSellKey != "")
        Hotkey, ~%PrevSellKey%, Off, UseErrorLevel
    
    ; Set new hotkeys (only active in Hearthstone)
    if (LevelUpKey != "")
        Hotkey, ~%LevelUpKey%, LevelUpAction, On
    if (RerollKey != "")
        Hotkey, ~%RerollKey%, RerollAction, On
    if (FreezeKey != "")
        Hotkey, ~%FreezeKey%, FreezeAction, On
    if (SellKey != "")
        Hotkey, %SellKey%, SellAction, On
    Hotkey, IfWinActive
    
    ; Update previous keys for next time
    PrevLevelUpKey := LevelUpKey
    PrevRerollKey := RerollKey
    PrevFreezeKey := FreezeKey
    PrevSellKey := SellKey
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

SellAction:
    ; Get current cursor position (where the minion is)
    MouseGetPos, startX, startY
    
    ; Calculate target position (Bob the bartender) based on current window size
    GetHSPos(targetX, targetY, SellX_Base, SellY_Base, BaseW, BaseH)
    
    ; Click and hold at current position
    Click, Down
    Sleep, 0
    
    ; Smooth drag to target (speed 5 = fast but not instant, like an FPS flick)
    MouseMove, targetX, targetY, 1
    Sleep, 0
    
    ; Release at target
    Click, Up
    Sleep, 0
    
    ; Return to original position
    MouseMove, startX, startY, 0
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
        Gui, HSBadge:Show, x%OverlayX% y%OverlayY% NoActivate
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

CaptureSellPos:
    ; Check if Hearthstone is running
    IfWinNotExist, ahk_exe Hearthstone.exe
    {
        Gui, Settings:+OwnDialogs
        MsgBox, 48, Hearthstone Not Found, Please open Hearthstone before capturing positions.
        return
    }
    
    Gui, Settings:+OwnDialogs
    MsgBox, 64, Capture Sell Position, Click OK, then click on Bob the bartender in Hearthstone.`n`nYou have 5 seconds after clicking OK.
    Sleep, 500
    KeyWait, LButton, D T5
    if (!ErrorLevel) {
        MouseGetPos, mx, my
        WinGetPos, wx, wy, ww, wh, ahk_exe Hearthstone.exe
        relX := mx - wx
        relY := my - wy
        SellX_Base := Round(relX * 2560 / ww)
        SellY_Base := Round(relY * 1440 / wh)
        GuiControl, Settings:, SellXInput, %SellX_Base%
        GuiControl, Settings:, SellYInput, %SellY_Base%
    } else {
        Gui, Settings:+OwnDialogs
        MsgBox, 48, Timeout, No click detected. Please try again.
    }
    return

; =========================
; CLEAR POSITION BUTTON FUNCTIONS
; =========================

