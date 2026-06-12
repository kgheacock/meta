# Claude Code iTerm2 status indicator — setup & operation

This document describes how the at-a-glance status indicator for Claude Code is
built, how to operate it day to day, and how to troubleshoot it.

The goal: when running several Claude Code sessions at once, immediately see which
session is **working**, which **needs you** (a permission prompt is waiting), and
which is **done** — without clicking into each one.

This doc is **self-contained**: the full source of both hook scripts is in the
[Appendix](#appendix-full-script-source), so a fresh machine can be set up from
this file alone (see [§3 Setup from scratch](#3-setup-from-scratch)).

---

## 1. How it works

Claude Code fires [hooks](https://docs.claude.com/en/docs/claude-code/hooks) at
points in a session's lifecycle. Four of them are mapped to a shell script that
writes iTerm2 escape codes to the session's terminal:

| Hook event        | Meaning                  | Emoji | Tab color | Script invocation                       |
|-------------------|--------------------------|:-----:|:---------:|-----------------------------------------|
| `UserPromptSubmit`| You sent a prompt        | 🟡    | amber     | `claude-iterm-badge.sh '🟡'`            |
| `PostToolUse`     | A tool finished running  | 🟡    | amber     | `claude-iterm-badge.sh '🟡'`            |
| `Notification`    | Waiting on you           | 🔴    | red       | `claude-iterm-badge.sh '🔴' attention`  |
| `Stop`            | Turn finished            | 🟢    | green     | `claude-iterm-badge.sh '🟢'`            |

The script renders the state in three independent iTerm2 surfaces:

- **Pane badge** — via `OSC 1337 SetBadgeFormat`. A translucent overlay in the
  top-right of the pane. Always reflects the current state.
- **Tab title** — via `OSC 0`, set to `"<emoji> <label>"`. Visible across the
  entire tab strip, so you can scan every session at once.
- **Tab color** — via iTerm2's proprietary `OSC 6` tab-color escape, which tints
  the whole tab. Strongest at-a-glance signal in a crowded tab strip:
  **amber = working**, **red = needs you**, **green = done**. (Solid colors, not
  animated — the badge/tab are text-only, so GIFs/images aren't possible here.)

For the `Notification` (🔴) state the script also emits `OSC 1337
RequestAttention=yes`, which bounces the Dock icon until the window is focused.

### Why `PostToolUse` exists — clearing the alert after you approve

The state is just "whatever the last hook wrote," and 🔴 is **sticky** — it stays
until another hook overwrites it. `Notification` fires when a permission prompt
*appears*. With only `UserPromptSubmit` / `Notification` / `Stop` wired, nothing
repaints the tab after you approve, so it stays 🔴 the whole time the session works
and only flips to 🟢 when the turn ends — it looks stuck on "needs you" even though
it's busy.

The hook that clears it is `PostToolUse`, which fires when the approved tool
**finishes** running, repainting 🔴 → 🟡. So the lifecycle is:

```
🟡 working  →  🔴 alert (prompt shown)  →  🟡 working (tool ran)  →  🟢 done
```

> **Why not `PreToolUse`?** `PreToolUse` fires *before* the permission decision —
> verified in `/tmp/claude-iterm-badge.log`, where its 🟡 lands a few seconds
> *before* the 🔴 prompt for the same tool. So it can't clear an alert that hasn't
> appeared yet. `PostToolUse` is the first hook that fires *after* approval, so
> it's the one that clears the alert. (The clear happens when the approved tool
> finishes, not at the instant you click approve — there's no hook between
> approval and execution — but for typical sub-second tools that's effectively
> immediate.)

It's a plain, stateless hook (same invocation as `UserPromptSubmit`). On every
tool it harmlessly repaints 🟡 → 🟡. A non-tool `Notification` (e.g. an idle
"waiting for input") is correctly **not** followed by a tool, so it stays 🔴 until
you actually type — which is what you want.

### Why three surfaces

The badge is *authoritative* and conflict-free — nothing else writes to it. The
tab title is a single shared string, so the state emoji and your custom name have
to share it. That's fine because renaming flows through `ctab.sh` (below) rather
than iTerm2's own rename (which would freeze the title and block emoji updates).

> **Note on concurrent sessions.** State is keyed per-tty. Two sessions in the
> same folder default to the same label, so use `ctab.sh` to give each a distinct
> name. A session with no real tty (e.g. some `--resume`/piped invocations, where
> `tty` returns `not a tty`) can't paint a tab at all — its hooks fire but have
> nowhere to write. That's expected, not a bug.

### Why iTerm2

Badges, `RequestAttention`, and reliable per-pane escape handling are iTerm2
features. Terminal.app and the VS Code integrated terminal don't support badges,
so the indicator is iTerm2-only. (A tmux-based, all-sessions-in-one-status-bar
variant is possible but is a different setup.)

---

## 2. Files

All paths are under `~/.claude/`:

| Path | Role |
|------|------|
| `hooks/claude-iterm-badge.sh` | Writes badge + tab title + tab color; bounces Dock on 🔴. Resolves the tab device, the label, and persists the last state. |
| `hooks/claude-iterm-reset.sh` | Clears this tty's stale `.label`/`.state` at session start, so a reused tty doesn't inherit a previous session's name. |
| `hooks/ctab.sh` | Renames the current tab and repaints immediately, preserving the emoji. |
| `hooks/TERMINAL-PLAYBOOK.md` | How to detect your current terminal and switch to iTerm2. |
| `settings.json` | Registers the hooks (user scope → applies to every project). |

Full source for the two scripts is in the
[Appendix](#appendix-full-script-source) — they live only here and in `~/.claude`,
so this doc is the canonical copy for re-creating them.

### Hook registration (`~/.claude/settings.json`)

```json
{
  "hooks": {
    "SessionStart": [
      { "matcher": "startup", "hooks": [{ "type": "command", "command": "\"$HOME/.claude/hooks/claude-iterm-reset.sh\"", "async": true }] }
    ],
    "UserPromptSubmit": [
      { "hooks": [{ "type": "command", "command": "\"$HOME/.claude/hooks/claude-iterm-badge.sh\" '🟡'", "async": true }] }
    ],
    "PostToolUse": [
      { "hooks": [{ "type": "command", "command": "\"$HOME/.claude/hooks/claude-iterm-badge.sh\" '🟡'", "async": true }] }
    ],
    "Notification": [
      { "hooks": [{ "type": "command", "command": "\"$HOME/.claude/hooks/claude-iterm-badge.sh\" '🔴' attention", "async": true }] }
    ],
    "Stop": [
      { "hooks": [{ "type": "command", "command": "\"$HOME/.claude/hooks/claude-iterm-badge.sh\" '🟢'", "async": true }] }
    ]
  }
}
```

`async: true` keeps the hooks from blocking the session. The hooks are at **user
scope**, so they apply across all projects automatically.

---

## 3. Setup from scratch

On a brand-new machine with a fresh Claude Code install, everything you need is in
this file:

1. **Install iTerm2** (if needed): `brew install --cask iterm2`, then make it
   default via the iTerm2 menu → *Make iTerm2 Default Term*. Ensure `jq` and
   `base64` are present (both standard on macOS; `brew install jq` if missing).
2. **Create the two scripts** in `~/.claude/hooks/` by copying their source from
   the [Appendix](#appendix-full-script-source), then make them executable:
   ```bash
   mkdir -p ~/.claude/hooks
   # paste claude-iterm-badge.sh, claude-iterm-reset.sh, and ctab.sh from the Appendix, then:
   chmod +x ~/.claude/hooks/claude-iterm-badge.sh ~/.claude/hooks/claude-iterm-reset.sh ~/.claude/hooks/ctab.sh
   ```
3. **Register the hooks** by merging the `"hooks"` block above into
   `~/.claude/settings.json` (create the file if it doesn't exist).
4. **Reload**: start a fresh `claude` session (or open `/hooks` once) so the new
   hooks load.

> Tip: to keep this reproducible across machines, store `~/.claude/hooks/` and the
> `settings.json` hooks block in a dotfiles repo. As-is, this document is the
> source of truth for both.

---

## 4. Operating it

### Reading the indicator
- **🟡** in the badge / tab → that session is working.
- **🔴** + a bouncing Dock icon → that session is waiting on you (permission or input).
- **🟢** → the last turn finished; the session is idle.

### Renaming a tab (keeps the emoji)

From inside a Claude session:

```bash
! ~/.claude/hooks/ctab.sh "Auth API"
```

From a plain iTerm2 shell:

```bash
~/.claude/hooks/ctab.sh "Auth API"
```

The name is saved per-terminal and reused by the status hooks. Label resolution
priority:

1. name set with `ctab.sh` (stored at `/tmp/claude-tab-<tty>.label`)
2. `$CLAUDE_TAB_LABEL` exported before launching `claude`
3. the current folder name (default)

> Don't use iTerm2's **Edit Session → rename** — it freezes the title and blocks
> emoji updates. Use `ctab.sh`.

### Optional convenience alias

Add to `~/.zshrc` so you can type `ctab "name"` in a plain shell:

```bash
alias ctab="~/.claude/hooks/ctab.sh"
```

### Optional: audible bell on attention

Set `"preferredNotifChannel": "iterm2_with_bell"` in `~/.claude/settings.json` to
add a bell on top of the Dock bounce.

### Tuning badge appearance

iTerm2 → **Settings → Profiles → General → Badge** (size) and
**Settings → Profiles → Colors → Badge** (color / opacity).

---

## 5. Verifying / troubleshooting

A diagnostic line in `claude-iterm-badge.sh` can log every invocation to
`/tmp/claude-iterm-badge.log`. It's **off by default**; enable it by launching
`claude` with `CLAUDE_BADGE_DEBUG=1` in the environment, then:

```bash
cat /tmp/claude-iterm-badge.log
```

Interpret the `dev=` field:

| Log shows | Meaning | Action |
|-----------|---------|--------|
| `dev=/dev/ttys###` | Hook fired and reached the terminal | Working — you should see badge/tab update |
| `dev=NONE` or `dev=not a tty` | Hook fired but couldn't find a tty (e.g. some `--resume`/piped sessions) | Nothing to paint; run `claude` in a real iTerm2 pane |
| (empty file) | Hooks not loading | Open `/hooks` once or restart Claude |

**Alert (🔴) seems stuck after you approved a prompt?** Confirm the `PostToolUse`
hook is registered (`jq '.hooks | keys' ~/.claude/settings.json` should list it).
Without it, 🔴 persists until `Stop` — see
[§1 Why `PostToolUse` exists](#why-posttooluse-exists--clearing-the-alert-after-you-approve).

**Tab colors not changing (only the emoji)?** The color logic in
`claude-iterm-badge.sh` matches the emojis 🟡 / 🔴 / 🟢 exactly. If your
`settings.json` emits a different emoji set, the badge/title update but the tab
color falls through to "no color." Keep the emoji in `settings.json` consistent
with the script's color `case`.

Other checks:
- `echo $TERM_PROGRAM` must be `iTerm.app` (or `echo $LC_TERMINAL` → `iTerm2`).
- If you're inside **tmux** (`$TMUX` set), iTerm2 escape codes are swallowed unless
  you add `set -g allow-passthrough on` to `~/.tmux.conf` (and wrap sequences).
  Simplest is to run `claude` in iTerm2 directly.

The diagnostic log is gated behind `CLAUDE_BADGE_DEBUG`, so once you've verified
everything works just unset it (the default) and delete `/tmp/claude-iterm-badge.log`.

---

## 6. State / temp files

The scripts use small per-terminal files in `/tmp`, keyed by the tty name
(e.g. `ttys028`):

| File | Written by | Purpose |
|------|------------|---------|
| `/tmp/claude-tab-<tty>.label` | `ctab.sh` | The custom tab name |
| `/tmp/claude-tab-<tty>.state` | `claude-iterm-badge.sh` | Last state emoji, so `ctab.sh` can repaint correctly |
| `/tmp/claude-iterm-badge.log` | `claude-iterm-badge.sh` | Diagnostic log (safe to delete) |

These are ephemeral and recreated as needed. At each new session, `claude-iterm-reset.sh`
(the `SessionStart` hook) deletes this tty's `.label` and `.state` so a recycled tty
number doesn't inherit the previous session's custom name.

---

## Appendix: full script source

These scripts live only in `~/.claude/hooks/` and here. Copy them verbatim
onto a new machine (then `chmod +x`).

### `~/.claude/hooks/claude-iterm-badge.sh`

```bash
#!/usr/bin/env bash
# Shows Claude Code session state in TWO places in iTerm2 so concurrent sessions
# are easy to tell apart:
#   * the pane BADGE (always-on overlay), and
#   * the TAB TITLE as "<emoji> <label>" (scannable across the tab strip)
# States:  🟡 working   🔴 needs you (permission / input)   🟢 done
#
# Wired from ~/.claude/settings.json hooks
# (UserPromptSubmit / PostToolUse / Notification / Stop).
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
# Off by default; enable by launching `claude` with CLAUDE_BADGE_DEBUG=1 in the env.
if [ -n "${CLAUDE_BADGE_DEBUG:-}" ]; then
  echo "$(date '+%H:%M:%S') emoji=${emoji} label=${label} mode=${mode:-none} dev=${dev:-NONE} term=${TERM_PROGRAM:-?}" >> /tmp/claude-iterm-badge.log
fi

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
```

### `~/.claude/hooks/ctab.sh`

```bash
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
```

### `~/.claude/hooks/claude-iterm-reset.sh`

```bash
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
```
