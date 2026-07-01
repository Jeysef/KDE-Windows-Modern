 #!/bin/bash

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
  LAYOUT_DIR="/usr/share/plasma/layout-templates"
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

SRC_DIR=$(cd $(dirname $0) && pwd)

THEME_NAME=Windows-modern

uninstall() {
  local name=${1}

  local AURORAE_THEME="${AURORAE_DIR}/${name}"
  local PLASMA_THEME="${PLASMA_DIR}/${name}"
  local LOOKFEEL_THEME="${LOOKFEEL_DIR}/com.github.yeyushengfan258.${name}"

  [[ -d ${AURORAE_THEME} ]] && rm -rfv ${AURORAE_THEME}
  [[ -d ${PLASMA_THEME} ]] && rm -rfv ${PLASMA_THEME}
  [[ -d ${LOOKFEEL_THEME} ]] && rm -rfv ${LOOKFEEL_THEME}
  [[ -d ${KVANTUM_DIR}/${name} ]] && rm -rfv ${KVANTUM_DIR}/${name}
  [[ -d ${WALLPAPER_DIR}/${name} ]] && rm -rfv ${WALLPAPER_DIR}/${name}
  [[ -d ${ICONS_DIR}/windows-modern ]] && rm -rfv ${ICONS_DIR}/windows-modern
  [[ -d ${LAYOUT_DIR}/org.kde.windowsmodern.panel ]] && rm -rfv ${LAYOUT_DIR}/org.kde.windowsmodern.panel
  [[ -d ${APPLETS_DIR}/org.kde.windowsmodern.showdesktop ]] && rm -rfv ${APPLETS_DIR}/org.kde.windowsmodern.showdesktop
  [[ -d ${APPLETS_DIR}/org.kde.windowsmodern.quicksettings ]] && rm -rfv ${APPLETS_DIR}/org.kde.windowsmodern.quicksettings
  [[ -d ${APPLETS_DIR}/org.kde.windowsmodern.systemtray ]] && rm -rfv ${APPLETS_DIR}/org.kde.windowsmodern.systemtray
  [[ -d ${APPLETS_DIR}/org.kde.windowsmodern.startmenu ]] && rm -rfv ${APPLETS_DIR}/org.kde.windowsmodern.startmenu
}

echo "Uninstalling '${THEME_NAME} kde themes'..."

uninstall "${name:-${THEME_NAME}-light}"
uninstall "${name:-${THEME_NAME}-dark}"
uninstall "${THEME_NAME}-lightDark"

# Remove color schemes (current and legacy hyphenated names)
rm -f ${SCHEMES_DIR}/WindowsModernLight.colors
rm -f ${SCHEMES_DIR}/WindowsModernDark.colors
rm -f ${SCHEMES_DIR}/Windows-modernLight.colors
rm -f ${SCHEMES_DIR}/Windows-modernDark.colors

# Reset window decoration border size to default
if command -v kwriteconfig6 &>/dev/null; then
  kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "BorderSize" "Normal"
  kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "BorderSizeAuto" "true"
  dbus-send --session --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null
fi

echo "Uninstall finished..."
