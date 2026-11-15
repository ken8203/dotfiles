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

<Exactly what is allowed beyond local work. Research: "none". Implement, by default:>

- Commit on `<branch>`, push it to origin, and open a draft PR for it.
- Own the PR until it is green: rebase it, fix CI reds, and handle bot review comments. Force-push only `<branch>`, and only with `--force-with-lease`.
- Never merge the PR, never mark it ready for review, and never deploy.

## Verify

<Tests, commands, or sources that prove the goal is met.>

## Deliver

- Implement: commits on `<branch>`, grouped by meaning, pushed, with its draft PR green and its bot review comments handled. `REPORT.md` names the PR URL and its head SHA.
- Research: the findings, with a source for every claim, go in `REPORT.md`.

Then write `/home/outpost/code/delegate/<task>/REPORT.md`, last, once the work is finished. The coordinator's wait returns on its first line, so that line is exactly `Outcome: done`, `Outcome: partial`, or `Outcome: blocked`. A note you leave before then, such as progress, must not start with `Outcome:`. After that line:

1. What changed or what was found.
2. Verification: commands run and their results.
3. Open questions and anything out of scope you noticed.

When a decision outside this brief blocks you, record it under Open questions and stop there.
