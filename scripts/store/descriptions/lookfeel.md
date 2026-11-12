**Windows 11's look and feel for KDE Plasma 6**, with a few Windows 10 touches. This is the **{VARIANT}** variant; the {OTHER} one is a separate item.

### What installing it from here brings

Installing it from Discover or *Get New Global Themes* also installs, from this store: the Windows Modern color schemes, Plasma style, window decoration and icons, the Win10OS cursors, and the Start menu, clock, Show desktop and Alt+Tab widgets. When applying it, tick *Desktop and window layout* to get the Windows panel.

### For the whole desktop, use the installer

The system tray with Quick Settings and the taskbar are compiled plugins, and Snap Layouts, the Windows shortcuts, the widget style and the lock and login screens need setup too, so they come from the free installer:

    git clone https://github.com/Jeysef/KDE-Windows-Modern
    cd KDE-Windows-Modern
    ./install.sh        # press Enter to install everything

Or download the bundle from the [latest release](https://github.com/Jeysef/KDE-Windows-Modern/releases/latest). `./uninstall.sh` puts your previous setup back.

### What the full install gives you

- **Start menu:** pinned apps, All apps, and search (Enter runs the best match)
- **Taskbar** with Windows-style tooltips and window previews
- **System tray:** separate network, volume and battery icons, each with its own flyout; Quick Settings behind the chevron
- **Calendar flyout** and a Show desktop corner
- **Snap Layouts**, Windows keyboard shortcuts and an Alt+Tab switcher
- **Lock and login screens**
- Window decorations, Kvantum widget style, color schemes, icon pack, Win10OS cursors and wallpaper
- Optional: Segoe UI (or Microsoft's open Selawik) and Cascadia Mono fonts

### Requirements

KDE Plasma 6 (tested on 6.8 with Fedora 44 and 45). Kvantum for the widget style. The tray and taskbar are C++ plugins: on Fedora each release brings them prebuilt; elsewhere (Debian/Ubuntu, Arch) `./install.sh` installs the build tools and builds them.

Based on Win11OS-kde by yeyushengfan258 and Fluent-kde by vinceliuice; icons from Eleven (mjkim0727) and Fluent (vinceliuice). License: GPL-3.0.
