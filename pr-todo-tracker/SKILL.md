---
name: pr-todo-tracker
description: >-
  Commit changes, open a pull request with the GitHub CLI (gh), then keep a
  local plain-Markdown TODO ledger in sync with the work. Use this whenever the
  user wants to "commit and open a PR", "raise a PR", "ship this change", "open
  a pull request and update the ticket/TODO", or mentions tracking work against
  a local epic/task work-ticket, definition of done (DoD), or TODO file. After
  raising the PR it finds the TODO task the PR implements (creating epic/task
  files if none exist), reviews the task's Definition of Done and marks it done
  only if the change genuinely satisfies it, links the PR into the parent epic,
  then commits those ledger updates and pushes them to the same PR. Trigger this
  even when the user only says "commit and PR this" without mentioning TODOs —
  keeping the ledger current is part of the job.
---

# PR + TODO tracker

This skill turns a finished code change into a pull request and keeps a local
work-ticket ledger honest about what that PR actually delivered. It exists
because the boring-but-important bookkeeping — opening the PR, finding the right
ticket, judging whether the work is really done, linking the PR back into the
parent — is exactly the stuff that gets skipped when done by hand, and a stale
ledger is worse than no ledger.

The ledger is plain Markdown organised as **epic folders containing task
files** (the JIRA-style epic → task hierarchy), living under a `todos/`
directory at the repo root:

```
todos/
  EPIC-3-billing/
    epic.md                       # the parent epic ticket
    TASK-7-invoices-endpoint.md   # a task under that epic
    TASK-8-refunds-endpoint.md
```

See `assets/epic-template.md` and `assets/task-template.md` for the exact shape.
A task carries a **Status**, a link to its **PR**, and a **Definition of Done**
(a checklist). An epic carries a Status and a **Tasks** list where each line has
a checkbox and a PR link.

## The workflow

Run these steps in order. Each step explains *why* so you can adapt when a repo
doesn't look exactly like the happy path.

### 1. Understand the change, then commit it

Before committing, look at what actually changed so the commit message and the
later DoD assessment are grounded in reality, not assumptions:

```bash
git status
git diff            # unstaged
git diff --staged   # already staged
```

Stage the code change and commit it with a clear, conventional message. Keep the
ledger out of this first commit — the TODO updates come *after* the PR exists, as
a second commit, because they reference the PR number.

Commit message format (Conventional Commits — the type prefix makes history
skimmable and is what most repos expect):

**Example:** change adds a JWT auth middleware → `feat(auth): add JWT auth middleware`
**Example:** change fixes an off-by-one in pagination → `fix(api): correct pagination off-by-one`

If the repo is currently on the default branch (`main`/`master`), create a
feature branch first — you cannot open a PR from a branch against itself, and
pushing straight to the default branch defeats the point of a PR:

```bash
git switch -c <type>/<short-slug>   # e.g. feat/invoices-endpoint
```

### 2. Open the pull request with gh

Push the branch and open the PR. Confirm `gh` is authenticated first (`gh auth
status`); if it isn't, stop and tell the user how to fix it rather than guessing.

```bash
git push -u origin HEAD
gh pr create --fill        # seeds title/body from the commit(s)
```

Prefer `--fill` for a sensible default, but write a real `--title`/`--body` when
the change deserves explanation. Capture the PR URL and number — you need them
for the ledger:

```bash
gh pr view --json number,url -q '"\(.number) \(.url)"'
```

### 3. Find the TODO task this PR implements — or create it

The PR delivers *something*; the ledger should have a task for it. Search the
existing ledger before creating anything, matching on the branch name, the
changed files, and the commit subject:

```bash
ls todos/ 2>/dev/null
grep -ril "<keyword from the change>" todos/ 2>/dev/null
```

- **One clear match** → use it.
- **Several plausible matches** → ask the user which task this PR implements
  rather than guessing; picking the wrong ticket quietly corrupts the ledger.
- **No match** → create one. Infer the epic from sibling tasks or the area of
  the codebase touched. If a fitting epic exists, add the task under it; if not,
  create a new epic too. Use the scaffolding script so the files and the epic's
  Tasks list are wired up correctly:

```bash
python scripts/scaffold_todo.py \
  --epic-id EPIC-3 --epic-title "Billing" \
  --task-id TASK-9 --task-title "Add invoices endpoint"
```

Then open the new task file and replace the placeholder **Summary** and
**Definition of Done** with real, checkable items that describe what *this* task
is meant to achieve. Pick the next free IDs by scanning existing ones; keep the
`EPIC-n` / `TASK-n` numbering consistent with what's already there.

### 4. Review the Definition of Done — honestly

Read the task's DoD checklist and compare each item against what the diff
actually does. This is the step that gives the ledger its value, so do not rubber
-stamp it:

- Tick a box **only** if the change genuinely satisfies that item. "The endpoint
  exists" is not "the endpoint is tested" — they are separate boxes.
- If every DoD item is met, set the task **Status** to `Done`.
- If some are met and some aren't, tick the ones that are, leave the rest, keep
  Status as `In Progress`, and tell the user what remains. A partial,
  truthful update is the goal — never mark a task Done to tidy up appearances.

Also fill in the task's **PR:** field with the PR URL so the task points back at
the work that moved it.

### 5. Update the parent epic

Open the epic file (`epic.md` in the same folder) and update the task's line in
the **Tasks** list:

- Tick its checkbox if the task is now Done.
- Replace `PR: —` with the PR URL (e.g. `PR: https://github.com/org/repo/pull/42`).

If ticking this task means every task in the epic is now done, also tick the
epic's own DoD item and consider setting the epic **Status** to `Done` — mention
this to the user rather than deciding unilaterally on a large epic.

### 6. Commit the ledger updates and push to the same PR

The ledger changes belong on the same branch as the code, so they ride along on
the existing PR as a follow-up commit:

```bash
git add todos/
git commit -m "docs(todo): update TASK-9 + epic with PR link and DoD status"
git push           # same branch → appends a commit to the PR you just opened
```

Finish by telling the user, briefly: the PR URL, which task you updated and
whether you marked it Done (or what's left), and that the epic now links the PR.

## Prerequisites and safety

- **gh must be authenticated.** Check with `gh auth status`. If not, stop and
  surface the problem — don't invent credentials or push to an unexpected remote.
- **Never force-push** and never rewrite published history here; step 6 only ever
  appends a commit.
- **Don't open a PR from the default branch.** Create a feature branch in step 1
  if needed.
- **If there's nothing to commit** in step 1, say so and stop — there's no PR to
  raise.
- **Keep the two commits separate.** Code first (before the PR), ledger second
  (after), so the ledger can reference the real PR number.

## Files

- `assets/task-template.md` — the shape of a task ticket (Status, Epic, PR, DoD).
- `assets/epic-template.md` — the shape of an epic ticket (Status, Tasks, DoD).
- `scripts/scaffold_todo.py` — creates an epic folder, epic + task files from the
  templates, and wires the task into the epic's Tasks list. Run with `--help` for
  arguments. Use it instead of hand-creating files so the structure stays
  consistent.
