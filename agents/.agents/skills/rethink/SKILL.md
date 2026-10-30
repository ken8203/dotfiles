---
name: rethink
description: Step back from the current approach — a PR, a plan, or an issue's proposed fix — and look for a better, simpler, more elegant, or more systematic way to solve the same problem. Use when the user asks whether there is a better or simpler way, whether a PR or design can be simplified, or to rethink an approach.
---

`/rethink → restate the problem → clean-slate design → compare → propose and wait → apply the picks`

The current approach is one answer to the problem, not the problem itself.
Rethinking means solving the problem again from a **clean slate**, then making the
current approach earn every part the clean-slate design does without. Line-level
polish of the current code is `/simplify-review`'s job.

## 1. Restate the problem

Read what the work is for before how it does it: the PR description, the linked
issue, any plan, spec, or ADR, and the code the change plugs into. Note the real
constraints (settled decisions, acceptance criteria, compatibility) and what the
codebase, libraries, and platform already provide.

Done when you can state the problem in one or two sentences without naming the
current approach's mechanisms.

## 2. Sketch a clean-slate design

Sketch how you would solve the problem today, before studying the current
approach in detail. Aim for:

- the fewest **moving parts** — states, switches, layers, code paths, lists
  someone must keep in sync;
- one source of truth per fact;
- consistency guaranteed by structure, not by discipline;
- one fix to the underlying mechanism instead of a special case per situation;
- reuse of what the codebase or platform already does.

Keep at most two sketches when more than one is plausible.

Done when each sketch is concrete enough to name its main types, functions, or
data flow.

## 3. Compare

Read the current approach whole. For a PR, read every production file diffed
against its merge-base with main, so pre-existing code is not blamed on the PR.
Line it up against the sketch:

- Where the two match, the current approach is confirmed.
- Every moving part the current approach has and the sketch lacks must earn its
  place. Find why it exists (`git log -S`, commit messages, the plan) and check
  in code whether the scenario it guards against actually happens.
- Where the sketch missed a constraint the current approach handles, the current
  approach wins.

Signs a part will not earn its place: the same transition or check in two
places; a list mirrored across modules; one capability spread over several
layers; optional fields that are always set; a knob nobody can reach, or one a
stricter global setting shadows; machinery that costs more than it saves; a
re-implementation of something that already exists.

Done when every difference is resolved as confirmed, kept with a reason, or a
finding, each backed by `file:line`.

## 4. Propose, then wait

Lean toward the simpler option. When its cost is a bounded window that heals on
its own (a deadline fires, the next poll catches up), recommend it and state the
window. When a finding would overturn a settled decision, say so and leave the
call to the user.

Reply in this shape, with the code untouched:

- **Verdict** — keep the direction, reshape parts of it, or take a different
  approach. When the sketch differs, show it in a few lines.
- **Do now** — numbered, most moving parts removed first. Each item: what goes
  away (`file:line`), the better form, and its cost. Where there is a real
  choice, give A/B with a recommendation.
- **Follow-up issue** — rethinks too big for this change.
- **Looks removable, keep** — each with the reason.

Mark anything inferred from reading rather than verified. Then wait for the user
to pick.

## 5. Apply the picks

For a PR, apply each picked item as a fixup into the commit that introduced the
code, run the tests covering it, then autosquash and push. For a plan or issue,
update it in place. Open an issue for each follow-up the user approved.

Done when every picked item is applied and, for a PR, the covering tests pass and
the branch is pushed.
