# juce-plugin-template

Starting point for kyle95wm's JUCE 8 audio plugins (VODucker, ADCompressor, ...).
It is a working plugin with placeholder names: one Gain knob, a Bypass pill, the
shared update-checker footer, headless tests, a screenshot tool, install scripts
and a GitHub Actions release pipeline. The rules it encodes are in
[CONVENTIONS.md](CONVENTIONS.md).

## Start a new plugin

```bash
~/Plugins/juce-plugin-template/scripts/new-plugin.sh ADLimiter Adlm 0xff59d18c \
  --description "True-peak limiter for AD mixes"
```

That copies the template to `~/Plugins/ad-limiter` (next to the template), replaces every placeholder, and makes
the first commit. Then add the plugin to the registry in `CONVENTIONS.md`.

(On GitHub you can also press **Use this template**, then run the same script on a
clone, or do the replacements below by hand.)

### Placeholders

| Placeholder | Becomes | Example |
|-------------|---------|---------|
| `PluginName` | product name, CMake target, class prefix, bundle file names | `ADCompressor` |
| `PLUGIN_NAME` | CMake variable / option prefix | `AD_COMPRESSOR` |
| `pluginname` | bundle ID suffix | `com.kyle95wm.adcompressor` |
| `plugin-name` | GitHub repo slug | `kyle95wm/ad-compressor` |
| `Xxxx` | 4-char plugin code (CMakeLists.txt only) | `Adcp` |
| accent `0xff4fb3ff` | the plugin's accent colour (CMakeLists.txt) | `0xffffb238` |
| description | host-visible description (CMakeLists.txt) | |
| `README.plugin.md` | renamed to `README.md` (this file is dropped) | |

All per-plugin identity is in the block at the top of `CMakeLists.txt`.

## What's shared (keep identical across plugins)

- `Source/UpdateChecker.h/.cpp`: GitHub Releases check; repo from `PLUGIN_GITHUB_REPO`.
- `Source/UpdateFooter.h`: version status, Check for updates / Download, Check automatically.
- `Source/BrandLookAndFeel.h`: family palette, knob and pill drawing, header helper.
- `scripts/install.sh`, `scripts/install.ps1`, `.github/workflows/build.yml` (apart from the names).

When one of these improves, copy it to every plugin repo.

## Checking the template itself

```bash
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build && ctest --test-dir build --output-on-failure
```

## License

AGPL-3.0 (see [LICENSE](LICENSE)), as JUCE's free licence requires for plugins
built from it.
