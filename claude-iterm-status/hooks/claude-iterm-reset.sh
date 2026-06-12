#!/usr/bin/env bash
# Clears stale per-terminal state for THIS tty so a brand-new Claude Code session
# doesn't inherit a label/state left behind by a previous session on the same tty.
#
# macOS reuses tty numbers (ttys028, ...), and the status files in /tmp are keyed
# by tty name — so without this a recycled tty would show the old session's custom
# `ctab.sh` name. Wired from ~/.claude/settings.json as a SessionStart (startup)
# hook, so it only fires for genuinely new sessions, not resume/clear/compact.

# Resolve this terminal's device + key (same scheme as claude-iterm-badge.sh):
# prefer the hook's own controlling tty, fall back to the parent (claude) tty.
dev="$(tty 2>/dev/null)"
case "$dev" in
  /dev/*) : ;;
  *)
    pt="$(ps -o tty= -p "$PPID" 2>/dev/null | tr -d ' ')"
    if [ -n "$pt" ] && [ "$pt" != "?" ] && [ "$pt" != "??" ]; then
      if [ -e "/dev/$pt" ]; then dev="/dev/$pt"
      elif [ -e "/dev/tty$pt" ]; then dev="/dev/tty$pt"
      fi
    fi
    ;;
esac
key="$(basename "$dev" 2>/dev/null)"

# Nothing to clear if we couldn't resolve a tty (e.g. piped/--resume sessions).
[ -n "$key" ] && [ "$key" != "/" ] && rm -f "/tmp/claude-tab-${key}.label" "/tmp/claude-tab-${key}.state"
exit 0
