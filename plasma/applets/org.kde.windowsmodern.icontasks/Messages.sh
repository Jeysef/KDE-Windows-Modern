#! /usr/bin/env bash
# Upstream KDE i18n extraction script: $XGETTEXT and $podir are provided by
# KDE's translation tooling (scripty), and the word splitting is intended.
# shellcheck disable=SC2046,SC2006,SC2154,SC2086
$XGETTEXT `find . -name \*.js -o -name \*.qml -o -name \*.cpp` -o $podir/plasma_applet_org.kde.plasma.taskmanager.pot
