# Terminal playbook — Claude Code status badges

The status badges (⏳/🔔/✅) are an **iTerm2** feature. This playbook tells you
how to confirm which terminal you're in and how to get onto iTerm2 if you aren't.

---

## 1. Which terminal am I in?

Run this in the terminal you want to check:

```bash
printf 'TERM_PROGRAM = %s\nLC_TERMINAL  = %s\nTERM         = %s\nTMUX         = %s\nbundle       = %s\n' \
  "$TERM_PROGRAM" "$LC_TERMINAL" "$TERM" "${TMUX:-(not in tmux)}" "$__CFBundleIdentifier"
```

Interpret `TERM_PROGRAM` (the primary signal):

| `TERM_PROGRAM`   | Terminal            | Badges work?                          |
|------------------|---------------------|---------------------------------------|
| `iTerm.app`      | **iTerm2**          | ✅ Yes — you're set                   |
| `Apple_Terminal` | Terminal.app        | ❌ No badge support → switch          |
| `vscode`         | VS Code integrated  | ❌ No badge support → switch          |
| `ghostty`        | Ghostty             | ❌ No iTerm2 badges → switch          |
| `WezTerm`        | WezTerm             | ❌ No iTerm2 badges → switch          |
| (empty)          | tmux/screen/unknown | See the tmux note below               |

Notes:
- `LC_TERMINAL = iTerm2` confirms iTerm2 even when `TERM_PROGRAM` is masked (e.g. inside tmux).
- `__CFBundleIdentifier` is the macOS app id: `com.googlecode.iterm2`, `com.apple.Terminal`,
  `com.microsoft.VSCode`.

---

## 2. If you're already in iTerm2

Nothing to install. Just confirm the badges fire:

1. Start a **fresh** `claude` session in iTerm2 (so the hooks load), send a prompt.
2. Watch the top-right of the pane: ⏳ while working, ✅ when done, 🔔 + Dock bounce on a prompt.
3. If you don't see it, check the hook actually reached the terminal:
   ```bash
   cat /tmp/claude-iterm-badge.log
   ```
   - `dev=/dev/ttys###` → working.
   - `dev=NONE` → hook ran but couldn't find the tty (report back).
   - empty file → hooks not loading; open `/hooks` once or restart Claude.

Tune appearance (optional): iTerm2 → **Settings → Profiles → General → Badge**
(size) and **Colors → Badge** (color/opacity).

---

## 3. If you're NOT in iTerm2 — switch to it

1. **Install:**
   ```bash
   brew install --cask iterm2
   ```
   (or download from https://iterm2.com)

2. **Open iTerm2** and run `claude` from there. It uses the same `~/.zshrc`,
   same shell, same projects — nothing to migrate.

3. **The badge hooks are already global** (in `~/.claude/settings.json`), so they
   work in any iTerm2 session automatically. No per-terminal setup needed.

4. (Optional) Make iTerm2 your default: it'll ask on first launch, or set it via
   iTerm2 → **Make iTerm2 Default Term**.

5. Verify using the steps in section 2.

---

## 4. tmux caveat

If `TMUX` is set, you're inside tmux. iTerm2's badge escape codes (OSC 1337) are
swallowed by tmux unless passthrough is enabled. Add to `~/.tmux.conf`:

```
set -g allow-passthrough on
```

…and the badge script would need to wrap sequences in tmux's passthrough envelope.
Simplest path: **run `claude` in iTerm2 directly, not inside tmux.** (If you do want
the tmux route, that's a different, dashboard-style setup — ask and I'll wire it.)

---

## Files involved
- `~/.claude/hooks/claude-iterm-badge.sh` — sets the badge (and Dock bounce on 🔔)
- `~/.claude/settings.json` — `hooks.UserPromptSubmit / Notification / Stop`
- `/tmp/claude-iterm-badge.log` — diagnostic log (safe to delete once verified)
