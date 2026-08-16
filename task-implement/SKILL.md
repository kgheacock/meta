---
name: task-implement
version: 1.0.0
description: |
  Deliver a task spec written by the task-spec skill: check out or create its
  branch, move the spec from tasks/backlog to tasks/ongoing, push the branch
  upstream, implement the task, tick each Definition of done item you can
  confirm, then raise a pull request to main that links back to the spec,
  push that link into the spec on the same branch, and move the spec to
  tasks/complete once every item is ticked. Use when the user says
  "implement task NNNN", "start task NNNN", "deliver this task", "pick up
  task NNNN", "work the spec", or "raise a PR for task NNNN".
license: MIT
compatibility: claude-code cursor codex gemini-cli opencode
metadata:
  pairs_with: task-spec
---

# Task Implement: Runbook From Spec to Linked PR

This skill is a checklist. It carries one task-spec file from
`tasks/backlog/` (or `tasks/ongoing/`) to a pull request that links back to
it.

This skill does not tell you how to write the code. Read the spec's Design
and Definition of done sections. Then implement the task the way you
implement any other change in this repo.

## Before you start

Confirm the task file exists and is not yet delivered:

```bash
ls tasks/backlog tasks/ongoing 2>/dev/null | grep NNNN
```

If the file is in `tasks/complete/`, stop. Tell the user there is nothing to
deliver.

Check the working tree before you touch branches:

```bash
git status
```

If it shows changes from outside this session, stop. Ask the user before you
continue. Do not discard work you did not create.

## Step 1 — Set up the branch

Read the `branch` field in the spec's frontmatter.

| Condition | Command |
|---|---|
| The branch exists locally | `git switch <branch>` |
| The branch exists only on `origin` | `git fetch origin && git switch <branch>` |
| The field is null, or the branch does not exist | Create it (below) |

To create the branch, start from an up-to-date `main`:

```bash
git switch main
git pull
git switch -c NNNN-kebab-title
```

Use the spec's file name, minus `.md`, as the branch name. This matches the
existing convention in this repo and keeps the frontmatter `branch` field
equal to the git branch name.

## Step 2 — Move the spec to ongoing

If the file is already in `tasks/ongoing/`, skip this step.

```bash
git mv tasks/backlog/NNNN-kebab-title.md tasks/ongoing/
```

Set these frontmatter fields:

- `status: "ongoing"`
- `updated:` today's date, `YYYY-MM-DD`
- `branch:` the branch name from Step 1

Commit this change alone, before any code change:

```bash
git add tasks/
git commit -m "Mark NNNN ongoing, set branch field"
```

## Step 3 — Push the branch upstream

Run `gh auth status` first. If it fails, stop and tell the user to fix `gh`
authentication. Do not push to an unexpected remote.

```bash
git push -u origin HEAD
```

## Step 4 — Implement the task

Read the spec's Design and Definition of done sections in
`tasks/ongoing/NNNN-kebab-title.md`. Write the code, the tests, and the docs
that the spec names. Commit one logical change at a time, in this repo's
usual style.

## Step 5 — Check the definition of done

Compare your diff (`git diff main...HEAD`) against every item in the spec's
Definition of done. For each item, run its proof.

- If the proof confirms the item, tick its box (`- [ ]` → `- [x]`).
- If it does not, leave the box empty and add a one-line note under the item
  that states what is missing.

Commit this change with the rest of your work, before Step 6.

## Step 6 — Raise the pull request to main

```bash
gh pr create --base main --title "<title>" --body "<body>"
```

Name the spec's file path in the body, for example: `Implements
tasks/ongoing/NNNN-kebab-title.md`. A file path survives a task
renumbering. A bare task ID does not.

Get the PR number and URL:

```bash
gh pr view --json number,url -q '"\(.number) \(.url)"'
```

## Step 7 — Push the link back into the spec

Set this frontmatter field:

- `pr:` the PR URL from Step 6

Check the Definition of done section you ticked in Step 5.

| Condition | Also do this |
|---|---|
| Every box is ticked | Move the spec to `tasks/complete/` and set `status: "complete"` and `updated:` today's date, `YYYY-MM-DD` |
| One or more boxes are still empty | Leave the spec in `tasks/ongoing/`; `status` stays `"ongoing"` |

```bash
# only when every Definition of done box is ticked
git mv tasks/ongoing/NNNN-kebab-title.md tasks/complete/
```

Commit and push this change on the same branch. This step adds a commit to
the open pull request. It does not open a new one.

```bash
git add tasks/
git commit -m "Link PR #<number> in NNNN task spec"
git push
```

## Step 8 — Report

Tell the user:

- the pull request URL
- the branch name
- whether the spec moved to `tasks/complete/`, or stayed in `tasks/ongoing/`
- any Definition of done item that Step 5 could not confirm, and why

## What this skill does not do

- It does not write the implementation. Step 4 defers to the spec and to
  normal engineering judgment.
- It does not give an independent review. The ticks in Step 5 and the move
  in Step 7 are the implementer's own check, run against the diff. Anyone
  who wants a check from someone other than the implementer still runs the
  task-spec skill's Mode 3 against the merged PR.
- It does not merge the pull request.

## Prerequisites and safety

- `gh` must be authenticated (`gh auth status`) before Step 3.
- Never force-push. Step 7 only ever adds a commit.
- Do not skip the clean-tree check before Step 1 — a branch switch with
  uncommitted work can strand it or overwrite it.

## References

- The `task-spec` skill defines the spec file format and the folder-as-status
  rule. Its Mode 3 gives an independent review of a spec already marked
  complete, for anyone who does not want to trust the implementer's own
  ticks from Step 5.
