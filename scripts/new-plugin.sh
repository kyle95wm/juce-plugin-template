#!/usr/bin/env bash
# Creates a new kyle95wm JUCE plugin from this template.
#
#   scripts/new-plugin.sh <ProductName> <Code> <Accent> [options]
#
#   ProductName  CamelCase, no spaces, starts with a capital (e.g. VODucker, ADCompressor)
#   Code         unique 4-character plugin code, at least one uppercase letter (e.g. VoDk, Adcp)
#   Accent       the plugin's accent colour as 0xffRRGGBB (e.g. 0xff4fb3ff)
#
# Options:
#   --repo <slug>          GitHub repo name under kyle95wm (default: kebab-case of the name,
#                          ADCompressor -> ad-compressor)
#   --dest <dir>           where to create it: new or empty folder (default: next to the template, e.g. ~/Plugins/<repo slug>)
#   --description "<text>" one-line plugin description (shown in hosts)
#   --no-git               don't git init / commit
#
# Example:
#   scripts/new-plugin.sh ADLimiter Adlm 0xff59d18c --description "True-peak limiter for AD mixes"
set -euo pipefail

TEMPLATE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
die() { echo "error: $*" >&2; exit 1; }

[[ $# -ge 3 ]] || { sed -n '2,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 1; }
NAME="$1"; CODE="$2"; ACCENT="$3"; shift 3
REPO=""; DEST=""; DESC=""; GIT=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --dest) DEST="$2"; shift 2 ;;
    --description) DESC="$2"; shift 2 ;;
    --no-git) GIT=0; shift ;;
    *) die "unknown option $1" ;;
  esac
done

# ---- Validate -----------------------------------------------------------------
[[ "$NAME" =~ ^[A-Z][A-Za-z0-9]+$ ]] || die "product name must be CamelCase with no spaces or punctuation: '$NAME'"
[[ "$NAME" != "PluginName" ]] || die "pick a real name"
[[ "$CODE" =~ ^[A-Za-z0-9]{4}$ ]] || die "plugin code must be exactly 4 letters/digits: '$CODE'"
[[ "$CODE" =~ [A-Z] ]] || die "plugin code needs at least one uppercase letter (Apple requirement): '$CODE'"
[[ "$CODE" != "Ky95" && "$CODE" != "Xxxx" ]] || die "'$CODE' is reserved"
[[ "$ACCENT" =~ ^0x[fF][fF][0-9a-fA-F]{6}$ ]] || die "accent must look like 0xffRRGGBB: '$ACCENT'"

# Codes / accents already taken, from the registry table in CONVENTIONS.md.
if grep -Eq "^\| *[^|]+\| *\`$CODE\`" "$TEMPLATE/CONVENTIONS.md"; then
  die "plugin code $CODE is already used (see the registry in CONVENTIONS.md)"
fi
ACCENT_HEX="$(echo "${ACCENT:4}" | tr 'A-F' 'a-f')"
if grep -iq "#$ACCENT_HEX" "$TEMPLATE/CONVENTIONS.md"; then
  echo "warning: accent #$ACCENT_HEX is already used by another plugin (see CONVENTIONS.md)" >&2
fi

# ADCompressor -> AD_COMPRESSOR / ad-compressor / adcompressor
split_words() { perl -pe 's/([A-Z]+)([A-Z][a-z])/$1_$2/g; s/([a-z0-9])([A-Z])/$1_$2/g' <<<"$1"; }
MACRO="$(split_words "$NAME" | tr '[:lower:]' '[:upper:]')"
LOWER="$(tr '[:upper:]' '[:lower:]' <<<"$NAME")"
[[ -n "$REPO" ]] || REPO="$(split_words "$NAME" | tr '[:upper:]' '[:lower:]' | tr '_' '-')"
[[ -n "$DEST" ]] || DEST="$(dirname "$TEMPLATE")/$REPO"
[[ -n "$DESC" ]] || DESC="$NAME audio effect"
[[ "$DESC" != *'"'* && "$DESC" != *'\'* ]] || die "description can't contain quotes or backslashes"
if [[ -e "$DEST" ]]; then
  [[ -d "$DEST" && -z "$(ls -A "$DEST" | grep -vxE '\.DS_Store|\.claude')" ]] || die "$DEST already exists and isn't empty"
fi

# ---- Copy ---------------------------------------------------------------------
mkdir -p "$DEST"
rsync -a \
  --exclude '.git/' --exclude 'build*/' --exclude '.DS_Store' \
  --exclude 'README.md' --exclude 'CONVENTIONS.md' --exclude 'scripts/new-plugin.sh' \
  "$TEMPLATE/" "$DEST/"
mv "$DEST/README.plugin.md" "$DEST/README.md"

# ---- Replace placeholders -------------------------------------------------------
export NAME CODE ACCENT MACRO LOWER REPO DESC
find "$DEST" -type f \( -name '*.txt' -o -name '*.cpp' -o -name '*.h' -o -name '*.md' \
     -o -name '*.yml' -o -name '*.sh' -o -name '*.ps1' -o -name '.gitignore' \) -print0 |
  xargs -0 perl -pi -e '
    s/PLUGIN_NAME/$ENV{MACRO}/g;
    s/PluginName/$ENV{NAME}/g;
    s/pluginname/$ENV{LOWER}/g;
    s/plugin-name/$ENV{REPO}/g;'
perl -pi -e '
  s/^(set\(\w+_CODE\s+)"Xxxx"/$1"$ENV{CODE}"/;
  s/^(set\(\w+_ACCENT\s+)"0x[0-9a-fA-F]+"/$1"$ENV{ACCENT}"/;
  s/^(set\(\w+_DESCRIPTION\s+)"[^"]*"/$1"$ENV{DESC}"/;' "$DEST/CMakeLists.txt"

if grep -rIl 'PluginName\|PLUGIN_NAME\|pluginname\|plugin-name\|"Xxxx"' "$DEST" >/dev/null; then
  die "placeholders left behind in: $(grep -rIl 'PluginName\|PLUGIN_NAME\|pluginname\|plugin-name\|"Xxxx"' "$DEST" | tr '\n' ' ')"
fi

if [[ $GIT == 1 ]]; then
  git -C "$DEST" init -q -b main
  git -C "$DEST" add -A
  git -C "$DEST" commit -q -m "Start $NAME from juce-plugin-template"
fi

cat <<EOF

Created $NAME in $DEST
  product name : $NAME           bundle id : com.kyle95wm.$LOWER
  plugin code  : $CODE (manufacturer Ky95)
  GitHub repo  : kyle95wm/$REPO
  accent       : $ACCENT
  CMake prefix : ${MACRO}_   (e.g. -D${MACRO}_VERSION, -D${MACRO}_JUCE_PATH)

Next:
  1. Add $NAME / $CODE / accent to the registry table in $TEMPLATE/CONVENTIONS.md
  2. cd "$DEST" && cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release && cmake --build build && ctest --test-dir build
  3. Write the DSP and UI (Source/), the README, then: gh repo create kyle95wm/$REPO --public --source . --push
EOF
