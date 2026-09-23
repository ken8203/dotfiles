# <task>: <one-line goal>

You are a worker on outpost. A coordinator session on the user's local machine owns scope, decisions, and review. It reads only `REPORT.md` and whatever you deliver below.

## Context

<Why this task exists and what it is part of. Link `/home/outpost/code/delegate/<project>/common.md` when the initiative has one; read it first.>

## Goal

<What done looks like, as a checkable outcome.>

## Scope

- In: <what to touch or investigate>
- Out: <what to leave alone>

## Decisions already made

<Choices the user settled, so they are not reopened. "None" if none.>

## Authorization

<Exactly what is allowed beyond local work, e.g. "commit on `<branch>`; no push, no PR, no deploy".>

## Verify

<Tests, commands, or sources that prove the goal is met.>

## Deliver

- Implement: commits on `<branch>` in this worktree, grouped by meaning; the coordinator fetches them from here.
- Research: the findings, with a source for every claim, go in `REPORT.md`.

Then write `/home/outpost/code/delegate/<task>/REPORT.md`:

1. Outcome: done, partial, or blocked, in one line.
2. What changed or what was found.
3. Verification: commands run and their results.
4. Open questions and anything out of scope you noticed.

When a decision outside this brief blocks you, record it under Open questions and stop there.
