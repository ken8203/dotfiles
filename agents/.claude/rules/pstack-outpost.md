A worker, whose working directory is under `/home/outpost`, ignores this file.

# pstack on outpost

A poteto-mode coordinator that delegates with the `outpost-delegate` skill maps the playbooks this way. That skill holds the mechanics.

- Feature steps 1–3 (trace, `architect`, the throughput checkpoint) and the design options run locally.
- Feature step 4, and the steps where Bug fix and Refactoring delegate the fix, go to outpost workers, which run as poteto-mode delegates.
- `architect`, `interrogate`, `arena`, `reflect`, and `swarm` panel runners stay local `Agent`s, since they are short-lived, read-only, and multi-model.
- Verification is the PR's `rv<n>-<task>` worker plus your own read of the diff at the PR head.
- Opening a PR becomes the worker's job, since it owns the draft PR.
- Post a status digest each time a wait returns, not when asked.
- A program's tracker is its cairn trail.
