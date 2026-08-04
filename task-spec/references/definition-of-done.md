# How to Write a Definition of Done

The definition of done is a contract. A reviewer who did not write the code
uses it to prove that the task is complete. The reviewer never asks the
implementer whether the work is done.

## The test for one item

An item is good when it passes all four tests:

1. **Observable.** It names a result that a person outside the code can see.
2. **Binary.** The answer is yes or no. There is no percentage.
3. **Proved.** It names the command, the file, or the log line that shows the
   result.
4. **Owned by this task.** The task can deliver it. It does not wait for
   another team.

## The format

```markdown
- [ ] **DoD-1** — {observable result}. **Proof:** {command, file, or log line}
```

The number never changes after review starts. If you must add an item during
the work, append it with the next number.

## Cover these five kinds

Most tasks need one item from each kind. Delete a kind when the task does not
touch it.

| Kind | Question it answers |
|---|---|
| Behavior | What does the system do now that it did not do before? |
| Boundary | What does the system do with bad input, or at the limit? |
| Test | Which automatic test fails without this change? |
| Document | Where does a future reader learn about this change? |
| Trace | Which PR and which issue hold this work? |

## Examples

### Behavior

Bad: `- [ ] Rate limiting works`

The word "works" is not observable. There is no proof and no number.

Good:

```markdown
- [ ] **DoD-1** — The 6th failed login in 60 s returns HTTP 429 with a
  `Retry-After` header. **Proof:** `pytest tests/test_login_ratelimit.py::test_429`
```

### Boundary

Bad: `- [ ] Handles errors gracefully`

"Gracefully" hides the behavior. Two reviewers will disagree.

Good:

```markdown
- [ ] **DoD-2** — When Redis is unreachable, login succeeds and the service
  writes one WARN line. **Proof:** stop Redis, then run
  `scripts/smoke_login.sh`
```

### Test

Bad: `- [ ] Tests added`

Any test satisfies this item, including a test that passes before the change.

Good:

```markdown
- [ ] **DoD-3** — The new test fails on `main` and passes on this branch.
  **Proof:** `git stash && pytest tests/test_login_ratelimit.py` fails
```

### Document

Good:

```markdown
- [ ] **DoD-4** — `docs/auth.md` records the limit and the window.
  **Proof:** `docs/auth.md`, section "Login limits"
```

### Trace

Good:

```markdown
- [ ] **DoD-5** — The PR body links to this spec and closes ENG-123.
  **Proof:** the PR in the `pr` field
```

## Words that make an item unverifiable

Delete these words from every item. Each one replaces a fact with an opinion:

| Word | Write instead |
|---|---|
| works, correct, proper | the exact output or status code |
| gracefully, cleanly, safely | the exact behavior in that case |
| performant, fast | the number and the unit, for example `p99 < 200 ms` |
| robust, solid | the input that it survives |
| refactored, improved, clean | the measurable property that changed |
| as needed, where appropriate | the condition, in full |
| tested, covered | the test command and the case |

## How many items

Five to ten items suit most tasks. Two items mean that the task is under-
specified. Twenty items mean that the task is two tasks. If a spec needs more
than twelve items, split it into two specs and link them in the `related`
field.
