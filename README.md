# Hearthstone Battlegrounds Hotkeys

A lightweight hotkey overlay for Hearthstone Battlegrounds. Press customizable keys to instantly Level Up, Reroll, or Freeze without clicking.

![Screenshot](screenshot%20HS%20BG%20Hotkeys.jpg) <!-- Add a screenshot if you want -->

## Download

**[Download Latest Release](../../releases/latest)** (Windows only) 
Just click the .exe file on the release window. That contains everything you need for it to work.

> **Note:** Windows may show a SmartScreen warning since this is unsigned. Click "More info" → "Run anyway". All source code is available for review.

## Features

- 🎮 Customizable hotkeys (default: F, D, Space)
- 📊 Clean overlay showing active keys
- 🎯 Advanced: Capture exact positions for any resolution
- ⚙️ Settings persist across sessions

## Quick Start

1. Run `HearthstoneHotkeys.exe`
2. Configure your preferred hotkeys
3. Select your resolution
4. Click "Save & Minimize"
5. Hotkeys work when Hearthstone is active!

## Usage Tips

- **Change hotkeys:** Click the button next to each action
- **Custom positions:** Check "Use Custom Click Positions" and click "Capture" buttons
- **Access settings:** Right-click the system tray icon
- **One-click actions:** Press your hotkey and the action happens instantly

## Compiling from Source (instead of using .exe)

Requires [AutoHotkey v1.1.37+](https://www.autohotkey.com/):

1. Save `.ahk` file as **UTF-8 with BOM** encoding (use Notepad++)
2. Place `Bob_Hotkey.png` and `icon.ico` in same folder
3. Compile using **Unicode 32-bit** base file
4. See [BUILDING.md](BUILDING.md) for detailed instructions

## Troubleshooting

**Hotkeys don't work:**
- Ensure Hearthstone is running
- Check that hotkeys aren't conflicting with other apps

**Clicks in wrong position:**
- Use "Capture" buttons for custom positions
- Make sure Hearthstone resolution matches your selection

## Credits

- Created by **linegrinder**
- Bob the Innkeeper artwork © Blizzard Entertainment

## License

MIT License - Free to use and modify
