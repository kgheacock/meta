#!/usr/bin/env bash
# Idempotent installer for the Claude Code iTerm2 status indicator.
#
# Copies the hook scripts into ~/.claude/hooks/ and merges the hook config into
# ~/.claude/settings.json (preserving any existing settings; our four events
# overwrite same-named events). Safe to re-run. Requires jq.
#
# Usage:  ./install.sh

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DEST="$HOME/.claude/hooks"
SETTINGS="$HOME/.claude/settings.json"
HOOKS_JSON="$SRC/settings.hooks.json"

command -v jq >/dev/null 2>&1 || { echo "error: jq is required (brew install jq)" >&2; exit 1; }

echo "==> Installing hook scripts into $HOOKS_DEST"
mkdir -p "$HOOKS_DEST"
cp "$SRC/hooks/claude-iterm-badge.sh" "$HOOKS_DEST/"
cp "$SRC/hooks/claude-iterm-reset.sh" "$HOOKS_DEST/"
cp "$SRC/hooks/ctab.sh"               "$HOOKS_DEST/"
cp "$SRC/hooks/TERMINAL-PLAYBOOK.md"  "$HOOKS_DEST/"
chmod +x "$HOOKS_DEST/claude-iterm-badge.sh" "$HOOKS_DEST/claude-iterm-reset.sh" "$HOOKS_DEST/ctab.sh"

echo "==> Merging hook config into $SETTINGS"
mkdir -p "$(dirname "$SETTINGS")"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

# Validate existing settings before touching them.
jq empty "$SETTINGS" 2>/dev/null || { echo "error: $SETTINGS is not valid JSON; aborting" >&2; exit 1; }

backup="$SETTINGS.bak.$(date +%Y%m%d%H%M%S)"
cp "$SETTINGS" "$backup"

tmp="$(mktemp)"
jq --slurpfile h "$HOOKS_JSON" '.hooks = ((.hooks // {}) + $h[0].hooks)' "$SETTINGS" > "$tmp"
jq empty "$tmp"                       # sanity-check the result
mv "$tmp" "$SETTINGS"

echo "==> Done."
echo "    Backup of previous settings: $backup"
echo "    Restart Claude Code (or open /hooks once) to load the hooks."
echo "    Note: the indicator only renders in iTerm2 — see TERMINAL-PLAYBOOK.md."
