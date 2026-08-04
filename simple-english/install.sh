#!/usr/bin/env bash
# Idempotent installer for this Claude Code skill.
#
# Symlinks ~/.claude/skills/<folder name> to this directory, so this repo stays
# the single source of truth. Safe to re-run. Refuses to replace a real
# directory unless you pass --force.
#
# Usage:  ./install.sh [--force]

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAME="$(basename "$SRC")"
DEST="$HOME/.claude/skills/$NAME"
FORCE="${1:-}"

mkdir -p "$(dirname "$DEST")"

if [ -L "$DEST" ]; then
  current="$(readlink "$DEST")"
  if [ "$current" = "$SRC" ]; then
    echo "==> Already linked: $DEST -> $SRC"
    exit 0
  fi
  echo "==> Replacing stale symlink ($current)"
  rm "$DEST"
elif [ -e "$DEST" ]; then
  if [ "$FORCE" != "--force" ]; then
    echo "error: $DEST exists and is not a symlink." >&2
    echo "       Back it up, then re-run with --force to replace it." >&2
    exit 1
  fi
  echo "==> Removing existing directory (--force)"
  rm -rf "$DEST"
fi

ln -s "$SRC" "$DEST"
echo "==> Linked $DEST -> $SRC"
echo "    Restart Claude Code to load the skill, then run /$NAME."
