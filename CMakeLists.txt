cmake_minimum_required(VERSION 3.22)

# =============================================================================
# Plugin identity: everything that differs between kyle95wm plugins lives in
# this block (plus the DSP/UI in Source/). scripts/new-plugin.sh fills it in.
# See CONVENTIONS.md before changing any of it, and never change PLUGIN_CODE,
# BUNDLE_ID or PRODUCT_NAME of a plugin that has been released.
# =============================================================================
set(PLUGIN_NAME_PRODUCT     "PluginName")              # CamelCase, no spaces
set(PLUGIN_NAME_CODE        "Xxxx")                    # unique 4-char code, >= 1 uppercase
set(PLUGIN_NAME_BUNDLE_ID   "com.kyle95wm.pluginname") # com.kyle95wm.<lowercase product>
set(PLUGIN_NAME_GITHUB_REPO "kyle95wm/plugin-name")    # owner/repo the update checker reads
set(PLUGIN_NAME_ACCENT      "0xff4fb3ff")              # the plugin's one accent colour (ARGB)
set(PLUGIN_NAME_DESCRIPTION "PluginName audio effect")
set(PLUGIN_NAME_VST3_CATEGORIES Fx)                     # e.g. Fx Dynamics / Fx EQ / Fx Tools

# The release workflow passes -DPLUGIN_NAME_VERSION=<tag without the leading v>,
# so the version baked into the plugin (and used by the update checker) always
# matches the GitHub Release it ships in.
set(PLUGIN_NAME_VERSION "0.1.0" CACHE STRING "Plugin version (major.minor.patch)")

# Must be set before project() to take effect. 10.13 is what both released
# plugins ship with; JUCE 8 supports it and it covers every Mac running Logic 10.4+.
if(APPLE)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "10.13" CACHE STRING "Minimum macOS version")
endif()

project(PluginName VERSION ${PLUGIN_NAME_VERSION} LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

option(PLUGIN_NAME_BUILD_AU "Build the Audio Unit as well as the VST3 (macOS only)" ON)
option(PLUGIN_NAME_BUILD_STANDALONE "Build a standalone app (handy for quick UI testing)" OFF)
option(PLUGIN_NAME_BUILD_TESTS "Build the headless test executable" ON)
option(PLUGIN_NAME_BUILD_SCREENSHOT_TOOL "Build a tool that renders the UI to docs/screenshot.png" OFF)
option(PLUGIN_NAME_COPY_AFTER_BUILD "Install the plugins into your user plug-in folders after building" OFF)

# ---------------------------------------------------------------------------
# JUCE: use a local checkout if one is given, otherwise fetch a pinned release.
# Keep the tag identical across all kyle95wm plugins (see CONVENTIONS.md).
# ---------------------------------------------------------------------------
set(PLUGIN_NAME_JUCE_PATH "" CACHE PATH "Path to an existing JUCE checkout (optional)")

if(PLUGIN_NAME_JUCE_PATH)
    add_subdirectory(${PLUGIN_NAME_JUCE_PATH} ${CMAKE_BINARY_DIR}/JUCE EXCLUDE_FROM_ALL)
else()
    include(FetchContent)
    FetchContent_Declare(JUCE
        GIT_REPOSITORY https://github.com/juce-framework/JUCE.git
        GIT_TAG        8.0.17-security
        GIT_SHALLOW    TRUE
        GIT_PROGRESS   TRUE)
    FetchContent_MakeAvailable(JUCE)
endif()

set(PLUGIN_NAME_FORMATS VST3)
if(APPLE AND PLUGIN_NAME_BUILD_AU)
    list(APPEND PLUGIN_NAME_FORMATS AU)
endif()
if(PLUGIN_NAME_BUILD_STANDALONE)
    list(APPEND PLUGIN_NAME_FORMATS Standalone)
endif()

juce_add_plugin(PluginName
    PRODUCT_NAME             "${PLUGIN_NAME_PRODUCT}"
    COMPANY_NAME             "kyle95wm"          # shared: groups every plugin in one Logic menu
    COMPANY_WEBSITE          "https://github.com/${PLUGIN_NAME_GITHUB_REPO}"
    BUNDLE_ID                "${PLUGIN_NAME_BUNDLE_ID}"
    PLUGIN_MANUFACTURER_CODE Ky95                # shared by every kyle95wm plugin
    PLUGIN_CODE              ${PLUGIN_NAME_CODE}
    FORMATS                  ${PLUGIN_NAME_FORMATS}
    IS_SYNTH                 FALSE
    NEEDS_CURL               TRUE                # update checker on Linux
    NEEDS_MIDI_INPUT         FALSE
    NEEDS_MIDI_OUTPUT        FALSE
    IS_MIDI_EFFECT           FALSE
    EDITOR_WANTS_KEYBOARD_FOCUS FALSE
    COPY_PLUGIN_AFTER_BUILD  ${PLUGIN_NAME_COPY_AFTER_BUILD}
    VST3_CATEGORIES          ${PLUGIN_NAME_VST3_CATEGORIES}
    AU_MAIN_TYPE             kAudioUnitType_Effect
    AU_EXPORT_PREFIX         PluginNameAU
    DESCRIPTION              "${PLUGIN_NAME_DESCRIPTION}")

set(PLUGIN_NAME_PLUGIN_SOURCES
    Source/PluginProcessor.cpp
    Source/PluginEditor.cpp
    Source/UpdateChecker.cpp)

target_sources(PluginName PRIVATE ${PLUGIN_NAME_PLUGIN_SOURCES})
target_include_directories(PluginName PRIVATE Source)

# Read by the shared files (UpdateChecker, BrandLookAndFeel), which stay
# byte-identical across plugins.
set(PLUGIN_NAME_SHARED_DEFINITIONS
    PLUGIN_GITHUB_REPO="${PLUGIN_NAME_GITHUB_REPO}"
    BRAND_ACCENT_ARGB=${PLUGIN_NAME_ACCENT})

target_compile_definitions(PluginName PUBLIC
    JUCE_WEB_BROWSER=0
    JUCE_VST3_CAN_REPLACE_VST2=0
    ${PLUGIN_NAME_SHARED_DEFINITIONS})

target_link_libraries(PluginName
    PRIVATE
        juce::juce_audio_utils
        juce::juce_dsp
    PUBLIC
        juce::juce_recommended_config_flags
        juce::juce_recommended_lto_flags
        juce::juce_recommended_warning_flags)

# The test and screenshot tools compile the plugin's processor/editor directly
# (no plugin host needed), so they need the macros the plugin wrapper would set.
set(PLUGIN_NAME_TOOL_DEFINITIONS
    JUCE_WEB_BROWSER=0
    JUCE_USE_CURL=0
    JucePlugin_Name="${PLUGIN_NAME_PRODUCT}"
    JucePlugin_VersionString="${PROJECT_VERSION}"
    JucePlugin_Build_Standalone=0
    ${PLUGIN_NAME_SHARED_DEFINITIONS})

# ---------------------------------------------------------------------------
# Headless tests: ctest --test-dir build -C Release
# ---------------------------------------------------------------------------
if(PLUGIN_NAME_BUILD_TESTS)
    enable_testing()
    juce_add_console_app(PluginNameTest PRODUCT_NAME "PluginNameTest")
    target_sources(PluginNameTest PRIVATE Tests/TestHost.cpp ${PLUGIN_NAME_PLUGIN_SOURCES})
    target_include_directories(PluginNameTest PRIVATE Source)
    target_compile_definitions(PluginNameTest PRIVATE ${PLUGIN_NAME_TOOL_DEFINITIONS})
    target_link_libraries(PluginNameTest PRIVATE
        juce::juce_audio_utils
        juce::juce_audio_formats
        juce::juce_dsp
        juce::juce_recommended_config_flags)
    add_test(NAME PluginNameTests COMMAND PluginNameTest)
endif()

# ---------------------------------------------------------------------------
# Optional: render the editor to a PNG for the README (see Tools/RenderScreenshot.cpp)
# ---------------------------------------------------------------------------
if(PLUGIN_NAME_BUILD_SCREENSHOT_TOOL)
    juce_add_console_app(PluginNameScreenshot PRODUCT_NAME "PluginNameScreenshot")
    target_sources(PluginNameScreenshot PRIVATE Tools/RenderScreenshot.cpp ${PLUGIN_NAME_PLUGIN_SOURCES})
    target_include_directories(PluginNameScreenshot PRIVATE Source)
    target_compile_definitions(PluginNameScreenshot PRIVATE ${PLUGIN_NAME_TOOL_DEFINITIONS}
        JUCE_MODAL_LOOPS_PERMITTED=1)   # lets the tool pump the message loop while the update check finishes
    target_link_libraries(PluginNameScreenshot PRIVATE
        juce::juce_audio_utils
        juce::juce_dsp
        juce::juce_recommended_config_flags)
endif()
