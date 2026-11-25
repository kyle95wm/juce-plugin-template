# kyle95wm plugin conventions

Every kyle95wm audio plugin (new or existing) follows these rules, so they look,
install and update the same way and sit together in one menu in Logic. New
plugins start from this template with `scripts/new-plugin.sh`; existing ones are
brought in line when they're next touched.

## Plugin registry

Add a row here **before** releasing a new plugin. Codes are permanent.

| Product | Plugin code | Bundle ID | Repo | Accent | AU type |
|---------|-------------|-----------|------|--------|---------|
| VODucker | `VoDk` | `com.kyle95wm.voducker` | [kyle95wm/VO-Ducker](https://github.com/kyle95wm/VO-Ducker) | blue `#4fb3ff` | `aufx` |
| ADCompressor | `Adcp` | `com.kyle95wm.adcompressor` | [kyle95wm/ad-compressor](https://github.com/kyle95wm/ad-compressor) | amber `#ffb238` | `aufx` |
| VODeclicker | `VoDc` | `com.kyle95wm.vodeclicker` | [kyle95wm/vo-declicker](https://github.com/kyle95wm/vo-declicker) | violet `#a78bfa` | `aufx` |
| VOMeter | `VoMt` | `com.kyle95wm.vometer` | [kyle95wm/vo-meter](https://github.com/kyle95wm/vo-meter) | indigo `#818cf8` | `aufx` |
| ~~VOEQ~~ (retired 2026-11-24, do not reuse) | `VoEq` | `com.kyle95wm.voeq` | kyle95wm/vo-eq (deleted) | teal `#2dd4bf` | `aufx` |

## Naming

- **Product name:** CamelCase, no spaces or punctuation: `VODucker`, `ADCompressor`.
  Keep established acronyms in capitals (`VO`, `AD`). It's used for the plugin
  name in hosts, the bundle file names (`ADCompressor.vst3`, `.component`), the
  zips (`ADCompressor-1.2.0-macOS.zip`), the settings folder and the window title.
- **Repo:** `kyle95wm/<kebab-case>` for new plugins (`ad-compressor`).
  VODucker's `VO-Ducker` predates this and stays as is.
- **CMake prefix:** UPPER_SNAKE of the product name (`AD_COMPRESSOR_VERSION`,
  `AD_COMPRESSOR_BUILD_AU`, ...). The CMake target and C++ classes use the
  product name (`ADCompressorProcessor`, `ADCompressorEditor`).
- **Bundle ID:** `com.kyle95wm.<product name in lowercase>`.
- **Vendor:** `COMPANY_NAME "kyle95wm"` and `PLUGIN_MANUFACTURER_CODE Ky95` for
  every plugin. This is what puts them all under **Audio Units → kyle95wm**.
- **Plugin code:** a unique 4-character code per plugin with at least one
  uppercase letter (Apple requires it), recorded in the registry above.
  `AU_EXPORT_PREFIX` is `<ProductName>AU`.

### Never rename a released plugin's identity

Once a version is out, these are frozen: `PLUGIN_CODE`, `PLUGIN_MANUFACTURER_CODE`,
`BUNDLE_ID`, `PRODUCT_NAME`, and every parameter ID. Hosts use them to find the
plugin in saved sessions and to restore automation; changing any of them makes
existing projects lose the plugin or its settings. Fix a display name with the
parameter's *name*, never its ID. Add new parameters with new IDs. (ADCompressor
was renamed from "AD Compressor" before anyone depended on the old name; don't
repeat that after a release.)

## Build and packaging

- **JUCE** `8.0.17-security`, fetched by CMake (pinned tag), overridable with
  `-D<PREFIX>_JUCE_PATH`. Bump it in every plugin at once, not one at a time.
- **macOS deployment target** `10.13`, set *before* `project()` (after it, the
  setting is ignored for the first configure). Both released plugins ship 10.13.
- **Formats:** VST3 everywhere, plus AU on macOS. Standalone only as a local
  debugging option.
- **C++17**, `JUCE_WEB_BROWSER=0`,
  `JUCE_VST3_CAN_REPLACE_VST2=0`, `NEEDS_CURL TRUE` (update checker on Linux).
  No `JUCE_DISPLAY_SPLASH_SCREEN` (JUCE 8 has no splash screen and warns about the flag).
- **CMake options**, all prefixed: `_BUILD_AU` (ON), `_BUILD_STANDALONE` (OFF),
  `_BUILD_TESTS` (ON), `_BUILD_SCREENSHOT_TOOL` (OFF), `_COPY_AFTER_BUILD` (OFF),
  `_JUCE_PATH`, `_VERSION`.
- **Version** lives in one place, the `<PREFIX>_VERSION` cache variable. CI overrides
  it from the tag, so the binary, the zip name and the update checker always agree.
- **Tests:** a headless console app (`Tests/TestHost.cpp`) that drives the
  processor directly, registered with `ctest`. CI runs it on all three platforms.
- **Screenshot:** `Tools/RenderScreenshot.cpp` renders the editor to
  `docs/screenshot.png` for the README (built with `JUCE_MODAL_LOOPS_PERMITTED=1`
  and waits up to 5 s for the update check to settle).
- **License:** AGPL-3.0 (required by JUCE's free licence). Keep the `LICENSE` file
  and the README's VST trademark line.

## Releases

- Release by pushing a tag: `git tag v1.2.0 && git push origin v1.2.0`. Never
  upload release assets by hand.
- `.github/workflows/build.yml` builds Windows (x64), macOS (universal arm64 +
  x86_64) and Linux, runs `ctest`, ad-hoc signs the macOS bundles (`codesign -s -`;
  not notarised), and publishes zips named `<Product>-<version>-<OS>.zip` plus
  `install.sh` / `install.ps1` to a GitHub Release.
- Install scripts: `scripts/install.sh` (macOS/Linux, per-user folders, clears
  quarantine, restarts `AudioComponentRegistrar`) and `scripts/install.ps1`
  (Windows, elevates, Common Files\VST3). Both work from an extracted zip or as
  one-liners that fetch the latest release.
- Before tagging a release that changes the plugin's identity or I/O, check the
  AU locally:

  ```bash
  auval -v aufx <PluginCode> Ky95      # e.g. auval -v aufx Adcp Ky95
  ```

## Update checker

`Source/UpdateChecker.*` and `Source/UpdateFooter.h` are shared and must stay
**byte-identical** across plugins (copy them over when one changes). The checker
reads `repos/<repo>/releases/latest` from `api.github.com`: one anonymous request,
at most once a day per machine, shared by every instance, never on the audio
thread. The footer always offers *Check for updates* (→ *Download* when newer),
*Check automatically* (on by default), and the status text. The README's
"Updates" section states what is sent.

## Look and feel

`Source/BrandLookAndFeel.h` is shared and byte-identical across plugins. It holds:

| Token | Colour | Use |
|-------|--------|-----|
| `bg` | `#16181d` | window background |
| `panel` | `#1f232b` | header strips, meter panels |
| `track` | `#2d323c` | knob tracks, dividers, off pills, buttons |
| `textMain` | `#e8eaf0` | values, titles |
| `textDim` | `#8a91a0` | labels, captions, version, update status |
| `good` | `#59d18c` | "Up to date", healthy |
| `warn` | `#ff5f5f` | errors, limiting, clipping |
| `accent` | per plugin | knob arcs, "on" pills, "Update available" |

- **One accent colour per plugin**, set once in `CMakeLists.txt`
  (`<PREFIX>_ACCENT`), different from every other plugin's (see the registry).
  Secondary meter colours are fine, but the accent is the plugin's identity.
- **Window layout:** fixed size, dark `bg` with a `16` px margin.
  - Header: product name top-left (bold 22), `v<version>` top-right (dim 12),
    a one-line subtitle under it (dim 12). Use `brand::drawHeader`.
  - Body: the controls. Rotary knobs use the shared knob (track arc + accent
    value arc + gradient body + pointer), value text box below.
  - Switches: pill toggles (`brand::makePill`) in a centred row above the footer,
    `ACTIVE` / `BYPASSED` for Bypass. On = filled with the accent (or a stated colour).
  - Footer: `UpdateFooter` across the bottom (`brand::footerHeight` = 58).
- **Bypass:** an internal, automatable `bypass` parameter that is also returned
  from `getBypassParameter()`, click-free and latency-compensated.
- **Non-ASCII text:** a plain literal is read as Latin-1, so `·`, `–`, `→`, `µ`
  come out garbled. Always write
  `juce::String (juce::CharPointer_UTF8 ("A \xc2\xb7 B"))`.
- **Fonts:** JUCE default sans; 22 bold titles, 13 bold pills/labels, 12 captions.

## README

Same section order in every plugin: title + one-line summary + screenshot,
what it does, controls, (optional how-it-works / usage tips), **Install** (table,
one-liners, Logic note, macOS quarantine note), **Updates**, **Building from
source**, **Releasing**, **License**. `README.plugin.md` in the template is the
skeleton.
