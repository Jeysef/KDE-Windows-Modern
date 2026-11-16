#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-deps.sh — everything the other components need, in one go
#
#  Kvantum (widget style), Flatpak (Mission Center), and the build
#  dependencies of the two C++ applets (System Tray, Icon Tasks). Only
#  missing packages are installed; one password prompt.
# ───────────────────────────────────────────────────────────────────
# shellcheck source=scripts/install-lib.sh
source "$(dirname "$0")/install-lib.sh"

if command -v dnf &>/dev/null; then
    pkgs=(kvantum flatpak gcc-c++ cmake extra-cmake-modules
          qt6-qtbase-devel qt6-qtdeclarative-devel
          kf6-kpackage-devel kf6-kconfig-devel kf6-ki18n-devel kf6-kcoreaddons-devel
          kf6-kwindowsystem-devel kf6-kio-devel kf6-kiconthemes-devel kf6-kitemmodels-devel
          kf6-kservice-devel kf6-kxmlgui-devel kf6-kjobwidgets-devel kf6-kcmutils-devel
          kf6-knotifications-devel
          libplasma-devel plasma-workspace-devel plasma-activities-devel plasma-activities-stats-devel
          libksysguard-devel)
elif command -v pacman &>/dev/null; then
    pkgs=(kvantum flatpak gcc cmake extra-cmake-modules qt6-base qt6-declarative
          kpackage kconfig ki18n kwindowsystem kio kiconthemes kitemmodels kservice kxmlgui
          kjobwidgets kcmutils knotifications plasma-activities plasma-activities-stats
          libplasma plasma-workspace libksysguard dbusmenu-qt6)
elif command -v apt-get &>/dev/null; then
    pkgs=(qt6-style-kvantum flatpak g++ cmake extra-cmake-modules qt6-base-dev qt6-declarative-dev
          libkf6package-dev libkf6config-dev libkf6i18n-dev libkf6windowsystem-dev libkf6kio-dev
          libkf6iconthemes-dev libkf6itemmodels-dev libkf6service-dev libkf6xmlgui-dev
          libkf6jobwidgets-dev libkf6kcmutils-dev libkf6notifications-dev
          libplasma-dev plasma-workspace-dev libplasmaactivities-dev libplasmaactivitiesstats-dev
          libksysguard-dev)
else
    warn "Unknown package manager: install Kvantum, Flatpak and the build dependencies"
    warn "listed in the README (System Tray, Icon Tasks) yourself."
    exit 0
fi

if prebuilt_available; then
    # This release has the C++ plugins prebuilt for this system: no compiler.
    info "Dependencies (Kvantum, Flatpak; prebuilt plugins, no build tools)..."
    install_packages "${pkgs[@]:0:2}" || warn "Some dependencies are missing."
else
    info "Dependencies (Kvantum, Flatpak, C++ applet build tools)..."
    install_packages "${pkgs[@]}" || warn "Some dependencies are missing; the C++ applets may not build."
fi
