/*
    SPDX-FileCopyrightText: 2026 Windows Modern contributors
    SPDX-License-Identifier: GPL-2.0-or-later
*/

// Stand-in for the qtwaylandscanner-generated header that
// <PlasmaQuick/PlasmaShellWaylandIntegration> includes.
//
// The floating task tooltip needs PlasmaShellWaylandIntegration::setRole()
// and setTakesFocus(), as libplasma's own ToolTipDialog uses, so KWin treats
// it as a tooltip that never takes keyboard focus (#14). The only thing that
// API needs from this header is the role/panel_behavior enum types. The real
// header is generated at build time from plasma-wayland-protocols, which
// would add three build dependencies for two enums.
//
// Values are org_kde_plasma_surface's enums from plasma-shell.xml
// (plasma-wayland-protocols, interface version 8). Wire values are part of
// the protocol and never change.

#pragma once

namespace QtWayland
{
class org_kde_plasma_surface
{
public:
    enum role {
        role_normal = 0,
        role_desktop = 1,
        role_panel = 2,
        role_onscreendisplay = 3,
        role_notification = 4,
        role_tooltip = 5,
        role_criticalnotification = 6,
        role_appletpopup = 7,
    };
    enum panel_behavior {
        panel_behavior_always_visible = 1,
        panel_behavior_auto_hide = 2,
        panel_behavior_windows_can_cover = 3,
        panel_behavior_windows_go_below = 4,
    };
};
}
