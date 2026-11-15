---
name: outpost-delegate
description: Delegate a research or implementation task to a worker on outpost. Use when a task should run on outpost, or to follow up on, clean up, or prune delegated tasks and merged worktrees on outpost.
---

The local session is the **coordinator**; an agent on outpost is the **worker**. The **backend** carries control and state. `start` picks it from the coordinator's terminal and the task keeps it for life:

| Backend | Picked in | Worker | The user follows it | Unreachable |
|---|---|---|---|---|
| `hc` | Herdr (`HC_TERMINAL_SOCKET`) | a herdr-core terminal `<task>` | under the Herdr machine `outpost` | run `outpost-hc` |
| `rex` | Rex (`REX_SESSION`) | a Rex session `<task>` | under the Rex host `outpost` | run `outpost-rex` |
| `ssh` | anywhere else | a headless `claude -p` or `codex exec`, one run per turn | only through `scripts/delegate read <task>`; never `blocked` | nothing to bring up |

`outpost-hc` and `outpost-rex` are zsh functions. If the instance itself is stopped or released, hand back to the user, since claiming an instance is their call.

Files carry content: every task has a **mailbox** on outpost holding the brief going out and the report coming back. Code travels over git: `outpost:<path>` is a normal ssh remote.

[`scripts/delegate`](scripts/delegate) runs the mechanical steps. Run it instead of its parts. On failure it names the stage it stopped at.

A new task runs steps 1–5 in order; an existing task jumps to [Follow-up round](#follow-up-round) or [Clean up](#clean-up).

## Layout on outpost

```
/home/outpost/code/
  <repo>/                        main clone; worker cwd for research on that repo
  <repo>.<task>/                 implement worktree, worker cwd
  delegate/<task>/               mailbox; worker cwd only for research tied to no repo
    brief.md                     coordinator → worker
    review-<n>.md                coordinator → worker, follow-up rounds
    REPORT.md                    worker → coordinator
    .task.json                   the script's record of repo, clone, branch, base, and backend
    .worker/                     ssh backend only: the runs' log, last exit code, and pid
  delegate/<project>/common.md   optional context shared by one initiative's tasks
```

The worker runs inside the repo it works on, so it picks up that repo's instructions, skills, and Hindsight bank; the mailbox only carries files. Every worker cwd needs folder trust, kept per git repo: the mailbox inherits it from `~/code`, but a clone never does, and its worktrees take it from the clone. So each repo's main clone is set up once by the user, never by the script: `gh repo clone <owner>/<repo> ~/code/<repo>` on outpost, then run `claude` there and accept the trust prompt. The script's default clone is `~/code/<repo>`; pass `--clone` for one that lives elsewhere.

`<task>` is one slug reused as the mailbox and the worker's name in Herdr or Rex, so it matches `[a-z][a-z0-9_-]{0,31}` and names no existing mailbox, since mailboxes outlive their tasks. The script refuses both.

A failed stage can still have applied, so inspect remote state before rerunning it.

## 1. Pick the worker

Mirror the coordinator's harness and model, at `medium` effort, unless the user named another. The coordinator keeps the higher effort for planning and review.

## 2. Write the brief

Draft `brief.md` in a local temp directory from [`brief-template.md`](brief-template.md). The worker cannot ask mid-task, so settle open decisions with the user first. An implement brief keeps the template's Authorization, which makes the worker its PR's owner ([Owner and verifier](#owner-and-verifier)). Done when every section is filled and Deliver names the exact branch or file coming back.

When several tasks belong to one initiative, write their shared context and decisions once in `delegate/<project>/common.md` and point each brief at it.

## 3. Start

```bash
scripts/delegate start <task> --brief <local-dir> --kind claude|codex --model <model> --effort <effort> [--heavy] \
  [--repo <local-repo> [--clone <clone>] [--branch <branch> [--base <base>]]]
```

`--branch` makes it an implement task on a worktree of the clone, based on `<base>` (default: `HEAD` of `<local-repo>`); `--repo` alone is research in the clone; neither is research in the mailbox. `--heavy` marks test-heavy work, such as a full suite or Testcontainers, and is kept in `.task.json`. Done when it prints a `status`, normally `"working"`.

Parallel workers have run outpost out of memory, so before it touches anything `start` counts the active workers, those `working` or `blocked` on any backend. It refuses with exit code 75 and lists them when 3 or more are active, when the new task is heavy and a heavy one is active, or when outpost's 1-minute load is above its core count. Queue a refused task and start it again after a wait returns.

Failed at `check` with no main clone or an untrusted one: hand the one-time setup above to the user. Reported no state within 30s: the worker is held at startup; look with `scripts/delegate read <task>` and bring it to the user. Backend unreachable: see the table.

## 4. Wait

```bash
scripts/delegate wait <task> <timeout-ms>
```

In Claude Code, run it with `run_in_background`, so the coordinator is woken on completion and stays free to delegate more. It reconnects on its own when the tunnel drops.

It returns only on an outcome, as one JSON line such as `{"status":"done","report":"done"}`. It joins the agent's state from the backend with the report's outcome: `done`, `partial`, or `blocked` when `REPORT.md` is newer than `brief.md` and every `review-*.md` and its Outcome within the first 8 lines reads so, `none` otherwise. The template asks for `Outcome: done` as the first line, and the heading form workers drift to, `## 1. Outcome` over `**Done.** …`, counts too.

| `status` | When | Next |
|---|---|---|
| `done` | the agent settled with a report for this round | `report: done`: step 5; `partial` or `blocked`: read its open questions and bring them to the user |
| `blocked` | a question or approval UI holds it | read it and bring it to the user |
| `error`, `exited` | the agent failed or quit; `report` says whether it finished first | read it; with a report other than `none`, as for `done` |
| `stalled` | idle 15 minutes with no final report; under `ssh`, a run that ended without one | read it and decide |

A working agent, or an idle one inside those 15 minutes, keeps it waiting: a worker idles while its background shells run, such as a CI watch, and wakes when they finish. Read any state but `done` with `scripts/delegate read <task>`.

## 5. Collect and verify

```bash
scripts/delegate collect <task> <local-dir>
```

For implement it also fetches the branch into `refs/remotes/outpost/<branch>` and prints its log and diffstat against the base.

The report is the worker's claim; the evidence is the fact. Done when:

- Implement: a verifier passed at the PR's current head SHA, and you read that head's diff (`gh pr diff <n>`) and it matches the report. A push moves the head and needs both again.
- Research: every conclusion the user will act on traces to a source you opened.

## Owner and verifier

An implement worker owns its PR. It pushes its branch, opens a draft PR, and keeps it green through rebases, CI reds, and bot review comments, force-pushing only its own branch and only with `--force-with-lease`. It never merges and never marks the PR ready. Its report names the PR URL and head SHA.

Each reported PR head gets a fresh verifier at `high` from the other model family: Codex (`gpt-6-astra`, outpost's Codex default) verifies a Claude author, and Claude verifies a Codex author. Mailboxes outlive their tasks, so name it per round, `rv<n>-<task>`, shortening the task part to fit the 32-character limit. Fetch the PR head locally, then start it on a worktree there with `--repo <repo> --branch rv<n>-<task> --base <head-sha>`. Its brief makes it research: it runs `/code-review` (Codex: `/review`), plus `/security-review` when the change touches auth, permissions, external input, or secrets, and reports findings without editing, pushing, or commenting. Triage the findings and send the real ones to the owner as a [follow-up round](#follow-up-round). Clean the verifier once triaged and delete its `rv<n>-<task>` branch on outpost.

Ask for merge authority once, at the design gate, as one of the numbered decisions. It stands for the whole program: the coordinator merges a PR once its required checks are green and a verifier passed at its current head SHA. Deploys and force-pushes to shared branches still pause for the user.

## Follow-up round

Once the worker has settled, write `review-<n>.md` locally, then:

```bash
scripts/delegate followup <task> <path>/review-<n>.md
```

Continue from step 4.

## Clean up

Once the user accepts the result:

```bash
scripts/delegate clean <task>
```

It ends the worker and removes the worktree, keeping the branch, the mailbox as the task's record, and the main clone. Delete the branch on outpost once it is merged or pushed.

To sweep everything already merged, including worktrees no task made:

```bash
scripts/delegate prune            # dry run: one line per worktree and leftover worker
scripts/delegate prune --apply
```

A worktree is pruned (worker, worktree, `refs/delegate/<task>`, branch) when gh on outpost finds its branch's PR merged, it has no uncommitted changes, nothing was committed after the merge, and its worker is not `working` or `blocked`. A worker with no worktree is ended once its task's `REPORT.md` is a day old and it is not `working` or `blocked`. Worktrees whose branch has no PR, sessions with no mailbox, and mailboxes are never touched. Run the dry run first and bring anything listed as `skip` to the user.
