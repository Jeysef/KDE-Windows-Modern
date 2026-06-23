#!/bin/bash

SRC_DIR=$(cd $(dirname $0) && pwd)
ROOT_UID=0

# Destination directory
if [ "$UID" -eq "$ROOT_UID" ]; then
  AURORAE_DIR="/usr/share/aurorae/themes"
  SCHEMES_DIR="/usr/share/color-schemes"
  PLASMA_DIR="/usr/share/plasma/desktoptheme"
  LAYOUT_DIR="/usr/share/plasma/layout-templates"
  LOOKFEEL_DIR="/usr/share/plasma/look-and-feel"
  KVANTUM_DIR="/usr/share/Kvantum"
  WALLPAPER_DIR="/usr/share/wallpapers"
  ICONS_DIR="/usr/share/icons"
  APPLETS_DIR="/usr/share/plasma/plasmoids"
else
  AURORAE_DIR="$HOME/.local/share/aurorae/themes"
  SCHEMES_DIR="$HOME/.local/share/color-schemes"
  PLASMA_DIR="$HOME/.local/share/plasma/desktoptheme"
  LAYOUT_DIR="$HOME/.local/share/plasma/layout-templates"
  LOOKFEEL_DIR="$HOME/.local/share/plasma/look-and-feel"
  KVANTUM_DIR="$HOME/.config/Kvantum"
  WALLPAPER_DIR="$HOME/.local/share/wallpapers"
  ICONS_DIR="$HOME/.local/share/icons"
  APPLETS_DIR="$HOME/.local/share/plasma/plasmoids"
fi

THEME_NAME=Windows-modern

[[ ! -d ${AURORAE_DIR} ]] && mkdir -p ${AURORAE_DIR}
[[ ! -d ${SCHEMES_DIR} ]] && mkdir -p ${SCHEMES_DIR}
[[ ! -d ${PLASMA_DIR} ]] && mkdir -p ${PLASMA_DIR}
[[ ! -d ${LOOKFEEL_DIR} ]] && mkdir -p ${LOOKFEEL_DIR}
[[ ! -d ${KVANTUM_DIR} ]] && mkdir -p ${KVANTUM_DIR}
[[ ! -d ${WALLPAPER_DIR} ]] && mkdir -p ${WALLPAPER_DIR}
[[ ! -d ${ICONS_DIR} ]] && mkdir -p ${ICONS_DIR}
[[ ! -d ${LAYOUT_DIR} ]] && mkdir -p ${LAYOUT_DIR}
[[ ! -d ${APPLETS_DIR} ]] && mkdir -p ${APPLETS_DIR}

install() {
  local name=${1}

  cp -r ${SRC_DIR}/aurorae/*                                                         ${AURORAE_DIR}
  cp -r ${SRC_DIR}/color-schemes/*.colors                                            ${SCHEMES_DIR}
  cp -r ${SRC_DIR}/Kvantum/*                                                         ${KVANTUM_DIR}
  cp -r ${SRC_DIR}/plasma/desktoptheme/*                                             ${PLASMA_DIR}
  cp -r ${SRC_DIR}/plasma/look-and-feel/*                                            ${LOOKFEEL_DIR}
  cp -r ${SRC_DIR}/wallpaper/*                                                       ${WALLPAPER_DIR}

  # Icons (optional, may be absent if excluded from the repo)
  if [ -d "${SRC_DIR}/icons/windows-modern" ]; then
    rm -rf ${ICONS_DIR}/windows-modern
    cp -r ${SRC_DIR}/icons/windows-modern                                             ${ICONS_DIR}
    # Refresh the icon cache at the destination so it matches the install path
    if command -v gtk-update-icon-cache &>/dev/null; then
      gtk-update-icon-cache -f ${ICONS_DIR}/windows-modern &>/dev/null || true
    fi
  fi

  # Panel layout template (Win11-style centered taskbar)
  if [ -d "${SRC_DIR}/plasma/layout-templates/org.kde.windowsmodern.panel" ]; then
    rm -rf ${LAYOUT_DIR}/org.kde.windowsmodern.panel
    cp -r ${SRC_DIR}/plasma/layout-templates/org.kde.windowsmodern.panel             ${LAYOUT_DIR}
  fi

  # Custom show-desktop applet (Win11 thin sliver, minimize-all)
  if [ -d "${SRC_DIR}/plasma/applets/org.kde.windowsmodern.showdesktop" ]; then
    rm -rf ${APPLETS_DIR}/org.kde.windowsmodern.showdesktop
    cp -r ${SRC_DIR}/plasma/applets/org.kde.windowsmodern.showdesktop                 ${APPLETS_DIR}
  fi
}

echo "Installing '${THEME_NAME} kde themes'..."

install "${name:-${THEME_NAME}}"

# Set window decoration border size to Tiny (no extra padding around content)
if command -v kwriteconfig6 &>/dev/null; then
  kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "BorderSize" "Tiny"
  kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "BorderSizeAuto" "false"
  dbus-send --session --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null
fi

echo "Install finished..."
