// Windows Modern Panel — Win11-style centered taskbar layout for Plasma 6
// Creates a 48px bottom panel with:
//   [Start] [icon-only tasks ........................] [system tray] [clock]
// The panel fills the screen width; the task manager expands to fill the
// space between the start button and the tray, producing a centered look.

var panel = new Panel;

// --- Panel geometry & behavior -------------------------------------------
panel.location = "bottom";
panel.height = 48;
panel.alignment = "center";
panel.hiding = "none";
panel.lengthMode = "fill";

// --- Widgets -------------------------------------------------------------
// Order of addWidget calls determines left-to-right order in the panel.

// 1. Start button (Application Launcher / Kickoff)
var start = panel.addWidget("org.kde.plasma.kickoff");
start.currentConfigGroup = new Array("General");
start.writeConfig("icon", "start-here");
start.writeConfig("favoritesSystemResources", "true");

// 2. Icon-only task manager (the centered "taskbar")
var tasks = panel.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = new Array("General");
tasks.writeConfig("launchers", "");
tasks.writeConfig("showOnlyCurrentScreen", "false");
tasks.writeConfig("showOnlyCurrentDesktop", "false");
tasks.writeConfig("showOnlyCurrentActivity", "false");
tasks.writeConfig("groupingStrategy", "1");

// 3. System tray (groups status icons, audio, network, etc.)
var tray = panel.addWidget("org.kde.plasma.systemtray");

// 4. Digital clock (Win11 puts the clock at the far right)
var clock = panel.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = new Array("Appearance");
clock.writeConfig("showDate", "false");
clock.writeConfig("showSeconds", "false");
clock.writeConfig("use24hFormat", "0");

// Ensure correct ordering by index.
start.index = 0;
tasks.index = 1;
tray.index = 2;
clock.index = 3;
