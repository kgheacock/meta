---
id: "{NNNN}"
title: "{short title that names the problem and the solution}"
status: "{backlog | ongoing | complete}"
created: "{YYYY-MM-DD}"
updated: "{YYYY-MM-DD}"
owner: "{who implements this}"
issue: "{issue ID, for example ENG-123. Use null when there is no issue.}"
issue_url: "{link to the issue. Use null when there is none.}"
pr: "{link to the pull request. Use null until the PR exists.}"
branch: "{git branch name. Use null until the branch exists.}"
related: []
tags: []
---

# {NNNN} — {short title}

## Problem

{Two or three sentences. State what is wrong now and who it hurts. Do not
propose a solution here.}

## Goals

- {Observable result 1}
- {Observable result 2}

## Non-goals

- {Work that a reader can expect here, but that this task excludes}

## Approaches considered

Three approaches follow. Each one solves the problem in a different way.

### Approach A — {name}

{One or two sentences on how it works.}

- Good, because {argument}
- Good, because {argument}
- Bad, because {argument}
- Bad, because {argument}

### Approach B — {name}

{One or two sentences on how it works.}

- Good, because {argument}
- Good, because {argument}
- Bad, because {argument}
- Bad, because {argument}

### Approach C — {name}

{One or two sentences on how it works.}

- Good, because {argument}
- Good, because {argument}
- Bad, because {argument}
- Bad, because {argument}

## Decision

Chosen: **Approach {X} — {name}**.

{One or two sentences. Give the goal or the constraint that decides it. Name
the cost that this choice accepts.}

## Design

{How the chosen approach works. Keep it under 200 words. Name the files, the
interfaces, and the data that change. Use a vertical list when there are more
than three items.}

Files to change:

- `{path}` — {what changes}
- `{path}` — {what changes}

## Definition of done

An outside reviewer verifies each item without help from the implementer. Each
item names its proof. The task moves to `complete/` only when every box is
ticked.

- [ ] **DoD-1** — {observable behavior}. **Proof:** {command, file, or log line}
- [ ] **DoD-2** — {observable behavior}. **Proof:** {command, file, or log line}
- [ ] **DoD-3** — Tests cover {case}. **Proof:** `{test command}` passes
- [ ] **DoD-4** — {Document or comment} records the change. **Proof:** {path}
- [ ] **DoD-5** — The PR in the `pr` field links to this spec. **Proof:** PR body

## Risks

- {Risk} → {what removes it or reduces it}

## Open questions

- [ ] {Question} — {who answers it}

## Notes

{Links, measurements, and prior art. Delete this section when it is empty.}
