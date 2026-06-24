// Windows Modern Panel — Win11-style centered taskbar layout for Plasma 6
// Creates a bottom panel with:
//   [...........] [Start] [icon-only tasks] [...........] [system tray] [clock] [show desktop]
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

// Panel is docked to the screen edge (NOT floating).
// NOTE: "Applets Only" floating (panel docked + applets inset) cannot be
// set from a layout script. It requires the PanelView property
// `floatingApplets`, which is not exposed in the Plasma scripting API.
// Writing it via ConfigFile("plasmashellrc") does NOT work because
// plasmashell holds its config in memory (KSharedConfig) and won't see
// an external write — PanelView reads floatingApplets from its in-memory
// cache and gets the default (false). Users must toggle "Floating →
// Applets Only" manually in Panel Settings after adding this panel.
panel.floating = false;

// Opaque panel background: Plasma's default "adaptive" opacity toggles
// translucency when windows touch the panel, which looks inconsistent.
// Win11 keeps a stable background, so force opaque (our theme is fully
// opaque anyway). Use "translucent" instead if blur is desired later.
panel.opacity = "opaque";

// --- Widgets -------------------------------------------------------------
// Order of addWidget calls determines left-to-right order in the panel.

// 1. Left expanding spacer — pushes the centered Start + tasks group to
//    the middle of the panel, matching Win11's centered taskbar.
var spacerLeft = panel.addWidget("org.kde.plasma.panelspacer");

// 2. Start button (Application Launcher / Kickoff).
//    NOTE: the kickoff launcher icon scales with panel height by design;
//    there is no reliable per-widget config key to cap it. At 48px the
//    logo fills most of the panel; at 30-32px it looks proportionally
//    correct. To get a smaller logo on tall panels, either keep the panel
//    at ~32px or open Kickoff settings → "Icon size" after adding it.
var start = panel.addWidget("org.kde.plasma.kickoff");
start.currentConfigGroup = new Array("General");
start.writeConfig("icon", "start-here");
start.writeConfig("favoritesSystemResources", "true");

// 3. Icon-only task manager (the centered "taskbar").
var tasks = panel.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = new Array("General");
tasks.writeConfig("launchers", "");
tasks.writeConfig("showOnlyCurrentScreen", "false");
tasks.writeConfig("showOnlyCurrentDesktop", "false");
tasks.writeConfig("showOnlyCurrentActivity", "false");
tasks.writeConfig("groupingStrategy", "1");

// 4. Right expanding spacer — separates the centered Start + tasks group
//    from the system tray / clock on the far right.
var spacerRight = panel.addWidget("org.kde.plasma.panelspacer");

// 5. System tray (groups status icons, audio, network, etc.)
var tray = panel.addWidget("org.kde.plasma.systemtray");

// 6. Digital clock — Win11 puts the clock at the far right, in a small
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

// 7. Show Desktop — custom Win11-style thin sliver (minimize-all on click).
//    Uses our forked applet (org.kde.windowsmodern.showdesktop) which renders
//    as an 8px-wide bare sliver with a 1px separator line, no icon.
var peek = panel.addWidget("org.kde.windowsmodern.showdesktop");
peek.currentConfigGroup = new Array("General");
peek.writeConfig("size", "6");

// Ensure correct ordering by index.
spacerLeft.index = 0;
start.index = 1;
tasks.index = 2;
spacerRight.index = 3;
tray.index = 4;
clock.index = 5;
peek.index = 6;
