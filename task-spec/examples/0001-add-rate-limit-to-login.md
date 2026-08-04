---
id: "0001"
title: "Add a rate limit to the login endpoint"
status: "ongoing"
created: "2026-08-03"
updated: "2026-08-03"
owner: "kgheacock"
issue: "ENG-123"
issue_url: "https://github.com/example/api/issues/123"
pr: "https://github.com/example/api/pull/456"
branch: "eng-123-login-rate-limit"
related: []
tags: ["auth", "security"]
---

# 0001 — Add a rate limit to the login endpoint

## Problem

`POST /login` accepts unlimited attempts from one IP address. On 2026-07-28 one
client sent 40,000 attempts in 11 minutes. The attempt filled the audit log and
added 300 ms to the p99 latency of every other endpoint.

## Goals

- One IP address gets at most 5 failed login attempts in 60 seconds.
- A legitimate user who fails twice, then succeeds, sees no change.
- The limit survives a restart of one API process.

## Non-goals

- Rate limits on other endpoints.
- A per-account lock after repeated failures. ENG-140 covers that work.

## Approaches considered

Three approaches follow. Each one solves the problem in a different way.

### Approach A — In-process counter

Each API process holds a dictionary of IP addresses and timestamps.

- Good, because it adds no dependency and no network call.
- Good, because one engineer can ship it in a day.
- Bad, because the limit multiplies by the process count. Six processes give
  an attacker 30 attempts, not 5.
- Bad, because a restart clears the counters, so an attacker can force a reset.

### Approach B — Redis counter in the application

The login handler increments a Redis key with a 60-second expiry. The handler
returns HTTP 429 when the count is more than 5.

- Good, because the limit is correct across every process and every restart.
- Good, because the same Redis instance already holds the session store, so it
  needs no new infrastructure.
- Bad, because it adds one network round trip to each login, about 1 ms.
- Bad, because a Redis failure needs a decision: fail open or fail closed.

### Approach C — Rate limit at the load balancer

The ALB or the WAF applies a rule to the `/login` path.

- Good, because no application code changes.
- Good, because the attack traffic stops before it reaches the API.
- Bad, because the rule cannot separate a failed login from a successful one,
  so it limits legitimate users too.
- Bad, because the rule lives in Terraform in another repository, so a change
  takes two reviews and one deploy window.

## Decision

Chosen: **Approach B — Redis counter in the application**.

Only Approach B counts failed attempts, and only failed attempts distinguish an
attack from a busy office behind one IP address. The decision accepts 1 ms of
added latency per login and one new failure mode in Redis. On a Redis error the
service fails open, because a login outage costs more than a slow attack.

## Design

The login handler calls `RateLimiter.hit(ip)` after the password comparison
fails. The limiter increments the key `rl:login:<ip>` and sets a 60-second
expiry on the first increment. When the count is more than 5, the handler
returns HTTP 429 with a `Retry-After` header. A successful login deletes the
key.

Files to change:

- `api/auth/login.py` — call the limiter, return 429
- `api/ratelimit.py` — new file, holds `RateLimiter`
- `tests/test_login_ratelimit.py` — new file
- `docs/auth.md` — record the limit and the window

## Definition of done

An outside reviewer verifies each item without help from the implementer. Each
item names its proof. The task moves to `complete/` only when every box is
ticked.

- [x] **DoD-1** — The 6th failed login from one IP in 60 s returns HTTP 429 with
  a `Retry-After` header. **Proof:** `pytest tests/test_login_ratelimit.py::test_sixth_attempt_429`
- [x] **DoD-2** — A successful login deletes the counter, so the next failure
  starts at 1. **Proof:** `pytest tests/test_login_ratelimit.py::test_success_resets`
- [ ] **DoD-3** — When Redis is unreachable, login succeeds and the service
  writes one WARN line per request. **Proof:** stop Redis, then run
  `scripts/smoke_login.sh`
- [ ] **DoD-4** — The new tests fail on `main`. **Proof:**
  `git stash && pytest tests/test_login_ratelimit.py` fails
- [ ] **DoD-5** — `docs/auth.md` records the limit of 5 and the window of 60 s.
  **Proof:** `docs/auth.md`, section "Login limits"
- [ ] **DoD-6** — The PR body links to this spec and closes ENG-123.
  **Proof:** the PR in the `pr` field

## Risks

- An office behind one NAT address hits the limit → the limit counts failed
  attempts only, so a correct password never counts.
- Redis latency adds to the login path → the client uses a 50 ms timeout and
  fails open.

## Open questions

- [x] Fail open or fail closed on a Redis error? — Security team, answered
  2026-08-01: fail open, and alert on the WARN line.

## Notes

- Incident report: INC-2026-07-28.
- The audit log grew by 2.1 GB during the incident.
