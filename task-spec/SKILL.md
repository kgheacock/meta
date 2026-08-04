---
name: task-spec
version: 1.0.0
description: |
  Write a short design spec for a task as a Markdown file under
  tasks/backlog, tasks/ongoing, or tasks/complete. Each spec compares three
  different approaches with pros and cons, records one decision, and gives a
  definition of done that an outside reviewer can verify. Use when the user
  says "write a spec", "design doc", "plan this task", "ADR", "definition of
  done", "task-spec", or asks to move a task to ongoing or complete. Also use
  to review a finished task against its spec.
license: MIT
compatibility: claude-code cursor codex gemini-cli opencode
metadata:
  template: MADR 4.0 (adapted)
  prose_style: ASD-STE100 through the simple-english skill
---

# Task Spec: One File Per Task, Three Approaches, One Decision

A spec is one Markdown file. It holds the problem, three approaches with pros
and cons, one decision, and a definition of done. The folder that holds the
file is the status of the task.

Two rules make this framework work. Break either one and the framework gives
no value:

1. **Three real approaches.** A straw-man option is a lie that hides the cost
   of the chosen option.
2. **A verifiable definition of done.** A person who did not write the code
   must be able to prove that the task is complete.

## Folder layout

```
<repo root>/
└── tasks/
    ├── backlog/     # written, not started
    ├── ongoing/     # in progress
    └── complete/    # done and verified
```

A spec file is named `NNNN-kebab-title.md`. `NNNN` is a zero-padded number,
for example `0007-add-rate-limit-to-login.md`. The number never changes. The
file moves between the three folders.

The issue ID is a metadata field, not part of the file name. One task can have
zero issues or many.

## Mode 1: Write a new spec

### Step 1 — Prepare the folders

Run this command from the repo root:

```bash
mkdir -p tasks/backlog tasks/ongoing tasks/complete
```

If `tasks/README.md` does not exist, copy `references/tasks-readme.md` from
this skill directory to `tasks/README.md`.

### Step 2 — Get the next ID

```bash
ls tasks/backlog tasks/ongoing tasks/complete 2>/dev/null | grep -oE '^[0-9]{4}' | sort -n | tail -1
```

Add 1 to the result. Pad the number to four digits. If the command returns
nothing, use `0001`.

### Step 3 — Collect the inputs

Get these facts from the user or from the repo. Ask only for the facts that
you cannot find:

| Field | Source |
|---|---|
| Problem | The user's request |
| Issue ID and URL | The user, or the branch name, or `gh issue list` |
| Owner | `git config user.name` |
| Constraints | The repo, `CLAUDE.md`, and the user |

If the problem statement is one line and the task is not small, ask one
question: what breaks today, and for whom?

### Step 4 — Read the code first

Read the code that the task touches before you write any approach. An approach
that ignores the current design is not an approach. Name the real files in the
Design section.

### Step 5 — Write three approaches

The three approaches must differ in mechanism, not in detail. Two variants of
one idea count as one approach.

These patterns produce three real options:

- **The small change** — the least code that solves the problem now.
- **The structural change** — a change to the design that removes the class of
  problem.
- **The outside change** — a library, a platform feature, a configuration
  change, or a change to the process instead of the code.

Give each approach at least two `Good, because` bullets and at least two
`Bad, because` bullets. An approach with no upside is a straw man. Delete it
and find a real third option.

Write the cost in the bullet. "Bad, because it is slower" is not a cost.
"Bad, because it adds one database read per request" is a cost.

### Step 6 — Decide

Name the chosen approach. Give the goal or the constraint that decides it, in
one or two sentences. Name the cost that the decision accepts.

Never write "Approach B is the best balance". That sentence carries no fact.

### Step 7 — Write the definition of done

Read `references/definition-of-done.md` before you write this section. Every
item states an observable result and a proof. Five to ten items suit most
tasks.

### Step 8 — Simplify the prose

Run the `simple-english` skill on the prose of the spec, in pragmatic mode.
Leave file paths, commands, identifiers, and issue IDs exact.

The prose limits are 20 words for an instruction and 25 words for an
explanation. The whole spec must stay under two printed pages. A longer spec
hides its own definition of done.

### Step 9 — Write the file

Copy `templates/spec-template.md` from this skill directory. Replace every
`{placeholder}`. Delete the sections that hold no content, except Problem,
Approaches considered, Decision, and Definition of done. Those four sections
are mandatory.

Write the file to `tasks/backlog/NNNN-kebab-title.md`.

### Step 10 — Report

Print the path of the new file. Then print the command that starts the task:

```bash
git mv tasks/backlog/NNNN-kebab-title.md tasks/ongoing/
```

## Mode 2: Move a spec

The folder is the status. The `status` field in the frontmatter must always
match the folder.

| Move | Command | Also do this |
|---|---|---|
| Start | `git mv tasks/backlog/<file> tasks/ongoing/` | Set `status: ongoing`, set `updated`, fill `branch` |
| Finish | `git mv tasks/ongoing/<file> tasks/complete/` | Set `status: complete`, set `updated`, fill `pr` |
| Stop | `git mv tasks/ongoing/<file> tasks/backlog/` | Set `status: backlog`, add a note that gives the reason |

CAUTION: Do not move a spec to `tasks/complete/` while one box in the
definition of done is empty. Run Mode 3 first.

## Mode 3: Review a spec against the work

Use this mode when the user asks to review, verify, or close a task. Act as
the outside reviewer. The implementer's report is not evidence.

1. Read the spec in `tasks/ongoing/`.
2. Read the diff: `git diff main...HEAD`, or the diff of the PR in the `pr`
   field.
3. For each item in the definition of done, run its proof. Record one of three
   results: **pass**, **fail**, or **not verifiable**.
4. Report the results as a table with the item number, the result, and the
   evidence.
5. If every item passes, tick the boxes and move the file to
   `tasks/complete/`.
6. If one item is not verifiable, the definition of done has a defect. Report
   this defect. Do not tick the box.

A reviewer that ticks a box on trust destroys the value of the framework.

## What this skill does not do

- It does not track work across tasks. The folders hold the state.
- It does not replace the issue tracker. The `issue` field links to it.
- It does not write the code. The spec comes first, then the code.

## References

- `templates/spec-template.md` — the spec template. Copy it, do not retype it.
- `references/definition-of-done.md` — how to write a verifiable item, with
  examples of good and bad items.
- `references/tasks-readme.md` — the README to copy into a new `tasks/` folder.
- `examples/0001-add-rate-limit-to-login.md` — one complete spec.
