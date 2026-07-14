cmake_minimum_required(VERSION 3.20)

project(windowsmodern-icontasks)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(ECM REQUIRED 5.240.0)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})
include(ECMQtDeclareLoggingCategory)

find_package(Qt6 REQUIRED COMPONENTS Core Qml Quick QuickControls2)
find_package(KF6 REQUIRED COMPONENTS
    Config
    I18n
    KIO
    Service
    WindowSystem
    XmlGui
    Notifications
    Package
)
find_package(Plasma REQUIRED)
find_package(PlasmaQuick REQUIRED)
find_package(PlasmaActivities REQUIRED)
find_package(PlasmaActivitiesStats REQUIRED)
find_package(KSysGuard REQUIRED)
find_package(LibNotificationManager REQUIRED)

add_definitions(-DTRANSLATION_DOMAIN=\"plasma_applet_org.kde.windowsmodern.icontasks\")

set(CMAKE_INCLUDE_CURRENT_DIR ON)
include_directories(${CMAKE_CURRENT_BINARY_DIR})

# Ensure plugin builds to the build directory, not the install prefix
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bin)

# Generate KActivityManagerdPluginsSettings class from .kcfg
kconfig_add_kcfg_files(KCFG_SRCS
    ${CMAKE_CURRENT_SOURCE_DIR}/kactivitymanagerd_plugins_settings.kcfgc
)

# Logging category
ecm_qt_declare_logging_category(SRC_LOGGING HEADER log_settings.h
    IDENTIFIER TASKMANAGER_DEBUG
    CATEGORY_NAME org.kde.windowsmodern.icontasks
    DEFAULT_SEVERITY Info
    DESCRIPTION "plasma applet org.kde.windowsmodern.icontasks"
)

set(CPP_SRCS
    ${KCFG_SRCS}
    ${SRC_LOGGING}
    backend.cpp
    backend.h
    smartlauncherbackend.cpp
    smartlauncherbackend.h
    smartlauncheritem.cpp
    smartlauncheritem.h
)

# Main applet plugin — CPP_SOURCES and RESOURCES only.
# QML sources are registered separately via ecm_target_qml_sources
# (matching the systemtray build pattern) to preserve subdirectory layout.
# Note: generated sources (KCFG, logging) are added via target_sources after
# plasma_add_applet creates the target, to avoid empty-variable parsing issues.
plasma_add_applet(org.kde.windowsmodern.icontasks
    CPP_SOURCES
        backend.cpp
        backend.h
        floatingtooltiparea.cpp
        floatingtooltiparea.h
        floatingtooltipdialog.cpp
        floatingtooltipdialog.h
        smartlauncherbackend.cpp
        smartlauncherbackend.h
        smartlauncheritem.cpp
        smartlauncheritem.h
    RESOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/contents/config/main.xml
    GENERATE_APPLET_CLASS
)

# Add generated sources to the target
target_sources(org.kde.windowsmodern.icontasks PRIVATE ${KCFG_SRCS} ${SRC_LOGGING})

target_link_libraries(org.kde.windowsmodern.icontasks PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::Quick
    Plasma::Activities
    Plasma::ActivitiesStats
    KF6::ConfigGui
    KF6::I18n
    KF6::KIOCore
    KF6::KIOGui
    KF6::KIOFileWidgets
    KF6::Notifications
    Plasma::Plasma
    Plasma::PlasmaQuick
    KSysGuard::ProcessCore
    KF6::Service
    KF6::WindowSystem
    PW::LibNotificationManager
)

target_include_directories(org.kde.windowsmodern.icontasks PRIVATE
    ${CMAKE_CURRENT_BINARY_DIR}
)

# Register QML sources with preserved subdirectory layout so relative imports
# (import "code/LayoutMetrics.js", etc.) resolve inside the qrc.
ecm_target_qml_sources(org.kde.windowsmodern.icontasks
    SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/contents/ui/AudioStream.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/contents/ui/ConfigAppearance.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/contents/ui/ConfigBehavior.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/contents/ui/config.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/contents/ui/ContextMenu.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/contents/ui/GroupDialog.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/contents/ui/GroupExpanderOverlay.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/contents/ui/main.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/contents/ui/MouseHandler.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/contents/ui/PipeWireThumbnail.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/contents/ui/PlayerController.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/contents/ui/PulseAudio.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/contents/ui/ScrollableTextWrapper.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/contents/ui/TaskBadgeOverlay.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/contents/ui/TaskList.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/contents/ui/TaskProgressOverlay.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/contents/ui/Task.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/contents/ui/ToolTipDelegate.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/contents/ui/ToolTipInstance.qml
        ${CMAKE_CURRENT_SOURCE_DIR}/contents/ui/ToolTipWindowMouseArea.qml
)
ecm_target_qml_sources(org.kde.windowsmodern.icontasks
    PATH code
    SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/contents/ui/code/LayoutMetrics.js
        ${CMAKE_CURRENT_SOURCE_DIR}/contents/ui/code/TaskTools.js
)
