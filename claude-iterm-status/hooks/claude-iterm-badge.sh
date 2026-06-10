#!/usr/bin/env bash
# Shows Claude Code session state in TWO places in iTerm2 so concurrent sessions
# are easy to tell apart:
#   * the pane BADGE (always-on overlay), and
#   * the TAB TITLE as "<emoji> <label>" (scannable across the tab strip)
# States:  🟡 working   🔴 needs you (permission / input)   🟢 done
#
# Wired from ~/.claude/settings.json hooks (UserPromptSubmit / Notification / Stop).
#   $1 = state emoji
#   $2 = "attention" (optional) -> also bounce the Dock icon until the window is focused
#
# The <label> (the name part of the title) is yours, resolved in priority order:
#   1. per-terminal override set with `ctab.sh "name"`  (rename on the fly)
#   2. $CLAUDE_TAB_LABEL exported before launching `claude`
#   3. the current folder name (default)

emoji="${1:-•}"
mode="${2:-}"
payload="$(cat)"

# Resolve the terminal device this session owns: prefer the hook's own controlling
# tty, fall back to the parent (claude) process's tty.
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

# Resolve the label: per-terminal override file > launch env var > folder name.
label=""
[ -n "$key" ] && [ -f "/tmp/claude-tab-${key}.label" ] && label="$(cat "/tmp/claude-tab-${key}.label" 2>/dev/null)"
[ -z "$label" ] && label="${CLAUDE_TAB_LABEL:-}"
if [ -z "$label" ]; then
  cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)"
  label="$(basename "${cwd:-$PWD}")"
fi

# Persist the last state emoji so `ctab.sh` can repaint the title immediately on rename.
[ -n "$key" ] && printf '%s' "$emoji" > "/tmp/claude-tab-${key}.state" 2>/dev/null

# Diagnostic log — confirms the hook fired AND whether it found a usable tty.
# Remove this line (and the log file) once you've verified everything works.
echo "$(date '+%H:%M:%S') emoji=${emoji} label=${label} mode=${mode:-none} dev=${dev:-NONE} term=${TERM_PROGRAM:-?}" >> /tmp/claude-iterm-badge.log

# Build escape sequences:
#   OSC 1337 SetBadgeFormat  -> pane badge (base64 value)
#   OSC 0                    -> tab/window title "<emoji> <label>"
#   OSC 1337 RequestAttention-> Dock bounce (only for "attention" mode)
b64="$(printf '%s' "$emoji" | base64 | tr -d '\n')"
seq="$(printf '\033]1337;SetBadgeFormat=%s\007' "$b64")"
seq="${seq}$(printf '\033]0;%s %s\007' "$emoji" "$label")"
if [ "$mode" = "attention" ]; then
  seq="${seq}$(printf '\033]1337;RequestAttention=yes\007')"
fi

# Tab color by state (iTerm2 proprietary OSC 6). Tints the whole tab so state is
# scannable across the tab strip even without reading the emoji.
case "$emoji" in
  '🔴') cr=200; cg=40;  cb=40  ;;  # red   - needs you
  '🟡') cr=210; cg=150; cb=0   ;;  # amber - working
  '🟢') cr=40;  cg=160; cb=70  ;;  # green - done
  *)    cr=''   ; cg=''   ; cb=''   ;;
esac
if [ -n "$cr" ]; then
  seq="${seq}$(printf '\033]6;1;bg;red;brightness;%s\007'   "$cr")"
  seq="${seq}$(printf '\033]6;1;bg;green;brightness;%s\007' "$cg")"
  seq="${seq}$(printf '\033]6;1;bg;blue;brightness;%s\007'  "$cb")"
fi

# Emit to the resolved terminal device.
if [ -n "$dev" ] && [ -w "$dev" ]; then
  printf '%s' "$seq" > "$dev" 2>/dev/null
else
  printf '%s' "$seq" > /dev/tty 2>/dev/null
fi
exit 0
