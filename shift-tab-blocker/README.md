# shift-tab-blocker

Blocks the **Shift+Tab** key combination everywhere in Windows. Shift and Tab still work on their own. Nothing happens when they're pressed together.

## Usage

Double-click `start-hidden.vbs`. An icon appears in the notification area (system tray), and no console window opens.

- **Left-click** the icon to turn blocking on or off. Both states use a gray ⇧⇥ key. ON adds a red "no" sign over it, and OFF is the plain key. Icons, the menu and notifications follow your Windows light/dark mode and switch within a few seconds of a theme change.
- **Right-click** the icon for the menu:
  - **Enabled**: turns blocking on or off.
  - **Run at startup**: starts the blocker when you log in. This adds a `ShiftTabBlocker` entry under `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`, and no admin rights are needed.
  - **Exit**: closes the blocker.

Launching it again while it's running does nothing, so you never get a second copy.

Notifications appear as "Shift+Tab blocker" with its own icon in the header. To make that work, the blocker registers itself with Windows under `HKCU\Software\Classes\AppUserModelId\ShiftTabBlocker` and stores the header icon in `%LOCALAPPDATA%\ShiftTabBlocker`. Both are removed automatically when you exit the blocker. The only thing left behind is the `Run` entry, and only if **Run at startup** is turned on (untick it before exiting to remove it).

## Limits

- Apps running as Administrator still receive Shift+Tab unless the blocker also runs as Administrator.
- Some games with anti-cheat or raw input may skip the hook.
- Windows may put the icon in the overflow (^) area. Drag it onto the taskbar to keep it visible.

## Custom icons

To use your own icons, add an `icons` folder next to the script containing `on.ico` and/or `off.ico`. PNG files (`on.png` / `off.png`) also work and get resized to 32×32. For separate dark-mode versions, add `on-dark` / `off-dark` files; these are used when the taskbar is dark. A missing file falls back to the built-in icon. Exit the blocker and start it again to pick up changes.
