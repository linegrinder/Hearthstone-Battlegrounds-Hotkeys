# Hearthstone Battlegrounds Hotkeys

A lightweight hotkey overlay for Hearthstone Battlegrounds.   
Press customizable keys to instantly __Level Up__, __Reroll__, __Freeze__ or __sell__ without clicking.

![Screenshot](assets/screenshot%20Hearthstone%20BGs%20Hotkeys.jpg) <!-- Add a screenshot if you want -->

## Download

**[Download Latest Release](../../releases/latest)** (Windows only)   
Just click the .exe file on the release window. That contains everything you need for it to work.

> **Note:** Windows may show a SmartScreen warning since this is unsigned. Click "More info" → "Run anyway". All source code is available for review.

## Features

- 🎮 Customizable hotkeys (keyboard + mouse buttons)
- 📊 Clean overlay showing active keys
- 🎯 Advanced: Capture exact positions for any resolution
- ⚙️ Settings persist across sessions
- 🔧 Enable/disable individual hotkeys
- 💰 Quick-sell hotkey for dragging minions to Bob

## Quick Start

1. Run `HearthstoneHotkeys.exe`
2. Configure your preferred hotkeys
3. Select your resolution
4. Click "Save & Minimize"
5. Hotkeys work when Hearthstone is active!

## Usage Tips

- **Change hotkeys:** Click the button next to each action
- **Resolution:** Select your monitor resolution to automatically scales click positions
- **Custom positions:** Select "Custom" radio button and use "Capture" buttons for exact positioning
- **Disable hotkeys:** Each hotkey can be individually disabled/enabled with the × button
- **Access settings:** Click the system tray icon
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

## Changelog

### v1.1.0 (January 17th 2026)
- ✨ Added ability to disable/enable individual keybinds with × buttons
- ✨ Resolution selection now persists on startup
- ✨ Added full mouse button support (Mouse4, Mouse5, Middle Mouse Button)
- ✨ Added quick-sell hotkey functionality (drag minions to Bob)
- 🎨 Completely redesigned settings GUI with radio buttons for resolutions
- 🎨 Improved layout and visual hierarchy

### v1.0.0 (January 13th 2026)
- Initial release
- Customizable hotkeys for Level Up, Reroll, Freeze
- Resolution-specific positioning
- Settings overlay

## Credits

- Created by **linegrinder**
- Bob the Innkeeper artwork © Blizzard Entertainment

## License

MIT License - Free to use and modify
