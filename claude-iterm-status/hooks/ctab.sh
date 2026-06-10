#!/usr/bin/env bash
# Rename THIS Claude/iTerm2 terminal's tab. The status emoji is preserved, and the
# badge + tab title repaint immediately.
#
# Usage from inside a Claude session:   ! ~/.claude/hooks/ctab.sh "Auth API"
#        from a plain iTerm2 shell:        ~/.claude/hooks/ctab.sh "Auth API"
#
# The label persists for this terminal; the status hooks keep reusing it.

label="$*"
if [ -z "$label" ]; then
  echo "usage: ctab.sh \"new tab name\"" >&2
  exit 2
fi

# Resolve this terminal's device + key (same scheme as claude-iterm-badge.sh).
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
if [ -z "$key" ] || [ "$key" = "/" ]; then
  echo "ctab: could not determine this terminal's tty" >&2
  exit 1
fi

# Save the label for the status hooks to keep using.
printf '%s' "$label" > "/tmp/claude-tab-${key}.label"

# Repaint now using the last known state emoji (falls back to a neutral dot).
emoji="$(cat "/tmp/claude-tab-${key}.state" 2>/dev/null)"
[ -z "$emoji" ] && emoji="•"
b64="$(printf '%s' "$emoji" | base64 | tr -d '\n')"
printf '\033]1337;SetBadgeFormat=%s\007\033]0;%s %s\007' "$b64" "$emoji" "$label" > "$dev" 2>/dev/null

echo "ctab: this tab is now \"$label\""
