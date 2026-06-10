# meta

Personal meta repo — reproducible setup for my local tooling and workflows.

## Contents

| Folder | What it is |
|--------|------------|
| [`claude-iterm-status/`](./claude-iterm-status/) | At-a-glance status indicator for Claude Code in iTerm2 — each session shows 🟡 working / 🔴 needs you / 🟢 done as a pane badge, tab title, and tab color. |

## claude-iterm-status — quick bootstrap

On a fresh machine (iTerm2 + `jq` required):

```bash
git clone https://github.com/kgheacock/meta.git
cd meta/claude-iterm-status
./install.sh
```

The installer copies the hook scripts into `~/.claude/hooks/` and merges the hook
config into `~/.claude/settings.json` (backing up the previous file; safe to
re-run). Then restart Claude Code, or open `/hooks` once, to load the hooks.

See [`claude-iterm-status/README.md`](./claude-iterm-status/README.md) for the
overview and [`claude-iterm-status-indicator.md`](./claude-iterm-status/claude-iterm-status-indicator.md)
for the full setup, operation, and troubleshooting guide (including full script
source in its appendix).
