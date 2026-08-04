# meta

Personal meta repo — reproducible setup for my local tooling and workflows.

## Contents

| Folder | What it is |
|--------|------------|
| [`claude-iterm-status/`](./claude-iterm-status/) | At-a-glance status indicator for Claude Code in iTerm2 — each session shows 🟡 working / 🔴 needs you / 🟢 done as a pane badge, tab title, and tab color. |
| [`pr-todo-tracker/`](./pr-todo-tracker/) | Claude Code skill: commit changes, open a PR with `gh`, then keep a local plain-Markdown TODO/epic ledger in sync with the work. |
| [`simple-english/`](./simple-english/) | Claude Code skill: write or rewrite technical text under the rules of ASD-STE100 Simplified Technical English. Vendored from [SimpleEnglish](https://github.com/kgheacock/SimpleEnglish). |
| [`task-spec/`](./task-spec/) | Claude Code skill: write a short design spec per task under `tasks/{backlog,ongoing,complete}` — three compared approaches, one decision, and a definition of done an outside reviewer can verify. |
| [`task-implement/`](./task-implement/) | Claude Code skill: deliver a task-spec — branch, move it to `tasks/ongoing`, implement it, raise a PR to main that links back to the spec, and push that link into the spec. |

## Claude Code skills — quick bootstrap

Every skill folder carries the same `install.sh`. It symlinks
`~/.claude/skills/<folder name>` to the folder, so this repo stays the source of
truth and an edit takes effect with no copy step:

```bash
git clone https://github.com/kgheacock/meta.git
cd meta
./simple-english/install.sh
./task-spec/install.sh
./task-implement/install.sh
```

The script is safe to re-run. It refuses to replace a real directory at the
destination unless you pass `--force`. Then restart Claude Code to load the
skills.

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
