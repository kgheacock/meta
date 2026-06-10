# Claude Code — iTerm2 status indicator

A small, local setup that shows the live state of each Claude Code session at a
glance, so you can run several at once and instantly see which one needs you.

Each session reports its state in **three places in iTerm2**:

- a **pane badge** (always-on overlay in the top-right of the pane),
- the **tab title** as `<emoji> <name>` (scannable across the whole tab strip), and
- the **tab color** (a whole-tab tint, the strongest at-a-glance signal).

| State | Emoji | Tab color | When | Extra |
|-------|:-----:|:---------:|------|-------|
| Working | 🟡 | amber | you submit a prompt, or a tool finishes running | — |
| Needs you | 🔴 | red | a permission prompt / input is waiting | Dock icon bounces |
| Done | 🟢 | green | the turn finished | — |

When you **approve** a waiting prompt, the alert clears back to 🟡 as soon as the
tool finishes (a `PostToolUse` hook) — it doesn't stay red until the turn ends. See
the [detailed doc](./claude-iterm-status-indicator.md#why-posttooluse-exists--clearing-the-alert-after-you-approve)
for why.

Tabs stay renameable — the emoji and your custom name coexist. Rename with:

```bash
! ~/.claude/hooks/ctab.sh "Auth API"
```

## Requirements

- **iTerm2** (badges are an iTerm2 feature; this does nothing in Terminal.app or VS Code).
- `jq` and `base64` (both standard on macOS).

## Quick start

1. Confirm you're in iTerm2: `echo $TERM_PROGRAM` → `iTerm.app`.
2. Start a fresh `claude` session — the hooks are global, so it just works.
3. Watch the pane badge and tab title change as the session runs.

Full details, including how it works, how to verify, and troubleshooting, are in
**[claude-iterm-status-indicator.md](./claude-iterm-status-indicator.md)**.

## Files (all under `~/.claude/`)

| Path | Purpose |
|------|---------|
| `hooks/claude-iterm-badge.sh` | Sets the badge + tab title + tab color (and Dock bounce on 🔴) |
| `hooks/ctab.sh` | Renames the current tab, preserving the state emoji |
| `hooks/TERMINAL-PLAYBOOK.md` | How to detect your terminal / switch to iTerm2 |
| `settings.json` | Registers the `UserPromptSubmit` / `PostToolUse` / `Notification` / `Stop` hooks |

> **Fresh machine?** These scripts live only here and in `~/.claude/` (neither is a
> git repo), so the [detailed doc](./claude-iterm-status-indicator.md) carries the
> full script source in an appendix and a self-contained setup recipe.
