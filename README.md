# Hearthstone Battlegrounds Hotkeys

A lightweight hotkey overlay for Hearthstone Battlegrounds.   
Press customizable keys to instantly __Level Up__, __Reroll__, __Freeze__, __Buy__, __Sell__, __Send to Duo Mate__ without clicking.

![Screenshot](assets/screenshot%20HS%20BGs%20Hotkeys.png) <!-- Add a screenshot if you want -->

## Download

**[Download Latest Release](../../releases/latest)** (Windows only)   
Just click the .exe file on the release window. That contains everything you need for it to work.

> **Note:** Windows may show a SmartScreen warning since this is unsigned. Click "More info" → "Run anyway". All source code is available for review.

## Features

- 🎮 **6 Customizable Hotkeys**: Level Up, Reroll, Freeze, Buy, Sell, and Send to Duo Mate (mouse buttons + keyboard)
- 📊 **Smart Overlay**: Clean, movable overlay showing active keybinds
- 🔒 **Lock/Unlock Overlay**: Lock the overlay in place or drag it around your screen
- 👁️ **Visual Keybind Indicators**: Toggle black boxes that appear directly on the in-game buttons (Eye icon toggle)
- ⚙️ **Settings Persist**: Your hotkey configuration and preferences are saved between sessions
- 🔧 **Enable/Disable Individual Hotkeys**: Each keybind can be independently disabled/enabled with × buttons
- 🎨 **Compact & Full Display Modes**: Switch between showing only core hotkeys (Compact) or all 6 hotkeys (Full)
- 🎯 **Universal Resolution Support**: Works on any resolution/aspect ratio (1920x1080, 2560x1440, ultrawide, etc.)
- 💬 **Auto-Disable During Chat**: Hotkeys are automatically disabled when you open the in-game chat window (prevents accidental presses)
- 🚀 **Auto-Start on Login**: Optional auto-launch on Hearthstone startup (requires admin permission)

## Quick Start

1. Run `HearthstoneHotkeys.exe`
2. Configure your preferred hotkeys
4. Choose Compact or Full display mode
4. (Optional) Enable Auto-Start if you want the app to launch on login
4. Click "Save & Minimize"
5. Hotkeys work when Hearthstone is active!

## Usage Tips

- **Change hotkeys:** Click the button next to each action
- **Disable hotkeys:** Each hotkey can be individually disabled/enabled with the × button
- **Remove a hotkey:** Click the × button to disable that specific hotkey
- **Mouse buttons:** Supports Mouse4, Mouse5, and Middle Mouse Button in addition to keyboard keys
- **Access settings:** Click the settings ⚙️ button on the overlay or system tray icon
- **View click locations:** Check the show click locations see exact in-game button positions
- **One-click actions:** Press your hotkey and the action happens instantly

## Auto-Start Setup

To enable Auto-Start on Windows login:
1. Save the .exe in a windows location of your choice but __not a onedrive folder!__. Windows needs direct access to this location
2. Open the settings window
3. Check the "Auto-Start on Login" option
4. Windows will prompt for admin permission - click "Yes"
5. The app will now launch automatically when you log in

> **Note:** Admin permission is required for this feature to work properly.

## Compiling from Source (instead of using .exe)

Requires [AutoHotkey v2.0+](https://www.autohotkey.com/):

1. Save `.ahk` file as **UTF-8 with BOM** encoding (use Notepad++)
2. Place `Bob_Hotkey.png` and `icon.ico` in same folder
3. Compile using **Unicode 32-bit** base file
4. See [BUILDING.md](BUILDING.md) for detailed instructions

## Troubleshooting

**Hotkeys don't work:**
- Ensure Hearthstone is running
- Check that hotkeys aren't conflicting with other apps

**Overlay appears in wrong position:**
- The overlay should move with your Hearthstone window automatically
- If not, try locking/unlocking the overlay with the 🔒/🔓 button
- Restart the app if positioning issues persist

**Chat detection not working:**
- Make sure you are running the Game in "Fullscreen" mode
- Restart Hearthstone and the app if issues persist

**Auto-Start not working:**
- Ensure you clicked "Yes" when Windows prompted for admin permission
- Try running the app as administrator and enabling Auto-Start again
- Check that your antivirus isn't blocking Task Scheduler modifications

## Changelog

### v1.3 (February 3rd 2026)
- ✨ **FileInstall Integration**: All necessary image files are now bundled directly into the .exe - no external files needed!
- ✨ **1080p Display Optimization**: Increased font sizes and overlay width for better readability on 1080p displays
- ✨ **Improved Chat Detection**: Enhanced chat window detection now works reliably on both 1080p and 2K displays with resolution-specific image matching
- ✨ **Extended Hotkey Support**: Added support for F-keys (F1-F12) and mouse scroll wheel (WheelUp, WheelDown) as hotkey options
- ✨ **Auto-Start Function**: Added option to automatically launch the app on Windows startup (requires admin permission)
- 🎨 **Overlay UI Refinements**: Fine-tuned compact and full view widths for optimal visibility across all resolutions
- 🎨 **GUI Tooltips**: Added helpful tooltips on settings buttons explaining each hotkey's function
- 🐛 **Bug Fixes**: Improved overlay rendering on different Windows versions, better handling of edge cases

### v1.2 (January 29th 2026)
- ✨ **Buy Hotkey**: Added customizable hotkey for buying minions
- ✨ **Send to Duo Mate Hotkey**: Added hotkey to quickly send minions to your duo mate (Duos mode)
- ✨ **Window-Specific Overlay**: Overlay is now tied to the Hearthstone window instead of the monitor
- ✨ **Movable Overlay**: Overlay can now be dragged around (unlock with 🔓 button to move, lock with 🔒 to lock in place)
- ✨ **Automatic Overlay Scaling**: Overlay automatically adjusts its size based on which hotkeys are enabled
- ✨ **Visual Keybind Indicators**: Added black box overlays that appear directly on in-game buttons (toggle with 👁️)
- ✨ **Chat Window Detection**: Hotkeys are automatically disabled when the in-game chat window is open
- ✨ **Compact/Full Display Modes**: Toggle between showing only the 3 core hotkeys or all 6 hotkeys
- ✨ **Version Checker**: App automatically checks for updates on startup
- ✨ **Skip Settings on Startup**: Added option to skip the settings window on next startup
- ✨ **Auto-Close on Hearthstone Exit**: Added option to automatically close BG Hotkeys when exiting Hearthstone
- 🎨 **Code Rewrite**: Complete rewrite using AutoHotkey v2.0 for better performance and stability
- 🔧 **Improved Error Handling**: Better handling of edge cases and rapid setting changes
- 🐛 **Bug Fixes**: Fixed GUI rendering issues, improved overlay synchronization

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
