// Windows Modern Panel — Win11-style centered taskbar layout for Plasma 6
// Creates a bottom panel with:
//   [Start] [icon-only tasks ........................] [system tray] [clock] [show desktop]
//
// Default height is 48px (authentic Win11 taskbar height). The same template
// works at 30/32px — just resize the panel after adding it.

var panel = new Panel;

// --- Panel geometry & behavior -------------------------------------------
panel.location = "bottom";
panel.height = 48;
panel.alignment = "center";
panel.hiding = "none";
panel.lengthMode = "fill";

// Floating widgets: applets get inset margins so they appear to float
// above the panel background with visible gaps around each widget. The
// panel itself stays docked to the screen edge — only the applets float.
// Matches Win11's taskbar where buttons have air around them.
panel.floating = true;

// Opaque panel background: Plasma's default "adaptive" opacity toggles
// translucency when windows touch the panel, which looks inconsistent.
// Win11 keeps a stable background, so force opaque (our theme is fully
// opaque anyway). Use "translucent" instead if blur is desired later.
panel.opacity = "opaque";

// --- Widgets -------------------------------------------------------------
// Order of addWidget calls determines left-to-right order in the panel.

// 1. Start button (Application Launcher / Kickoff).
//    NOTE: the kickoff launcher icon scales with panel height by design;
//    there is no reliable per-widget config key to cap it. At 48px the
//    logo fills most of the panel; at 30-32px it looks proportionally
//    correct. To get a smaller logo on tall panels, either keep the panel
//    at ~32px or open Kickoff settings → "Icon size" after adding it.
var start = panel.addWidget("org.kde.plasma.kickoff");
start.currentConfigGroup = new Array("General");
start.writeConfig("icon", "start-here");
start.writeConfig("favoritesSystemResources", "true");

// 2. Icon-only task manager (the centered "taskbar").
var tasks = panel.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = new Array("General");
tasks.writeConfig("launchers", "");
tasks.writeConfig("showOnlyCurrentScreen", "false");
tasks.writeConfig("showOnlyCurrentDesktop", "false");
tasks.writeConfig("showOnlyCurrentActivity", "false");
tasks.writeConfig("groupingStrategy", "1");

// 3. System tray (groups status icons, audio, network, etc.)
var tray = panel.addWidget("org.kde.plasma.systemtray");

// 4. Digital clock — Win11 puts the clock at the far right, in a small
//    Segoe UI Regular weight. Pin the font to 10pt so it stays readable
//    but does not dominate the panel at 48px.
//    IMPORTANT: autoFontAndSize must be set to false; otherwise Plasma
//    ignores fontFamily/fontSize and auto-sizes the text to the panel.
var clock = panel.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = new Array("Appearance");
clock.writeConfig("autoFontAndSize", "false");
clock.writeConfig("fontFamily", "Segoe UI");
clock.writeConfig("fontStyleName", "Regular");
clock.writeConfig("fontSize", "10");
clock.writeConfig("showDate", "false");
clock.writeConfig("showSeconds", "0");
clock.writeConfig("use24hFormat", "0");

// 5. Show Desktop — custom Win11-style thin sliver (minimize-all on click).
//    Uses our forked applet (org.kde.windowsmodern.showdesktop) which renders
//    as an 8px-wide bare sliver with a 1px separator line, no icon.
var peek = panel.addWidget("org.kde.windowsmodern.showdesktop");
peek.currentConfigGroup = new Array("General");
peek.writeConfig("size", "8");

// Ensure correct ordering by index.
start.index = 0;
tasks.index = 1;
tray.index = 2;
clock.index = 3;
peek.index = 4;
