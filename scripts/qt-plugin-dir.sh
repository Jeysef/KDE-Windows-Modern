#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  qt-plugin-dir.sh — print the system's Qt 6 plugin directory, where
#  Plasma loads compiled applets from (<dir>/plasma/applets/*.so).
#
#  Fedora/openSUSE: /usr/lib64/qt6/plugins; Arch: /usr/lib/qt6/plugins;
#  Debian/Ubuntu: /usr/lib/<multiarch>/qt6/plugins (issue #26).
#  Used by both C++ applets' dev.sh and verify.sh, and by uninstall.sh.
#  Exits 1 (prints nothing) when no Qt 6 plugin directory is found.
#
#  pkg-config cannot answer this: Qt 6's Qt6Core.pc has no plugindir.
# ───────────────────────────────────────────────────────────────────

# 1. Ask Qt (as KDE's own build tools do). Debian keeps qtpaths6 out of
#    PATH, under /usr/lib/qt6/bin.
for tool in qtpaths6 qtpaths-qt6 /usr/lib/qt6/bin/qtpaths6 /usr/lib/qt6/bin/qtpaths \
            /usr/lib64/qt6/bin/qtpaths6 /usr/lib64/qt6/bin/qtpaths qmake6 qmake-qt6; do
    command -v "$tool" &>/dev/null || continue
    dir="$("$tool" -query QT_INSTALL_PLUGINS 2>/dev/null)"
    # A Qt 5 qtpaths/qmake answers with Qt 5's directory: only take a qt6 one.
    case "$dir" in
        */qt6/*|*/qt6) [ -d "$dir" ] && { echo "$dir"; exit 0; } ;;
    esac
done

# 2. No Qt tools installed: the directory where Plasma's own applets are.
for dir in /usr/lib64/qt6/plugins /usr/lib/qt6/plugins /usr/lib/*-linux-gnu*/qt6/plugins; do
    [ -d "$dir/plasma/applets" ] && { echo "$dir"; exit 0; }
done
exit 1
