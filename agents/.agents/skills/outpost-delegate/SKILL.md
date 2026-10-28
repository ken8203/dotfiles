---
name: outpost-delegate
description: Delegate a research or implementation task to outpost through Rex. Use when a task should run on outpost, or to follow up on or clean up a delegated task.
---

The local session is the **coordinator**; an agent on outpost is the **worker**. Rex carries control and state: each task is a Rex session on outpost's Rex server, reached locally as the Rex host `outpost`. Files carry content: every task has a **mailbox** on outpost holding the brief going out and the report coming back. Code travels over git: `outpost:<path>` is a normal ssh remote.

[`scripts/delegate`](scripts/delegate) runs the mechanical steps: `rex -S outpost` for the worker, one ssh connection for files and git. Run it instead of its parts. On failure it names the stage it stopped at.

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
    .task.json                   the script's record of repo, clone, branch, and base
  delegate/<project>/common.md   optional context shared by one initiative's tasks
```

The worker runs inside the repo it works on, so it picks up that repo's instructions, skills, and Hindsight bank; the mailbox only carries files. Every worker cwd needs folder trust, kept per git repo: the mailbox inherits it from `~/code`, but a clone never does, and its worktrees take it from the clone. So each repo's main clone is set up once by the user, never by the script: `gh repo clone <owner>/<repo> ~/code/<repo>` on outpost, then run `claude` there and accept the trust prompt. The script's default clone is `~/code/<repo>`; pass `--clone` for one that lives elsewhere.

`<task>` is one slug reused as the mailbox and the Rex session's label, so it matches `[a-z][a-z0-9_-]{0,31}` and names no existing mailbox, since mailboxes outlive their tasks. The script refuses both.

A failed stage can still have applied, so inspect remote state before rerunning it.

## 1. Pick the worker

Mirror the coordinator's harness and model, at `medium` effort, unless the user named another. The coordinator keeps the higher effort for planning and review.

## 2. Write the brief

Draft `brief.md` in a local temp directory from [`brief-template.md`](brief-template.md). The worker cannot ask mid-task, so settle open decisions with the user first. Done when every section is filled and Deliver names the exact branch or file coming back.

When several tasks belong to one initiative, write their shared context and decisions once in `delegate/<project>/common.md` and point each brief at it.

## 3. Start

```bash
scripts/delegate start <task> --brief <local-dir> --kind claude|codex --model <model> --effort <effort> \
  [--repo <local-repo> [--clone <clone>] [--branch <branch> [--base <base>]]]
```

`--branch` makes it an implement task on a worktree of the clone, based on `<base>` (default: `HEAD` of `<local-repo>`); `--repo` alone is research in the clone; neither is research in the mailbox. Done when it prints a `status`, normally `"working"`.

The user follows the worker in the Rex app under the `outpost` host: the session `<task>` shows working, blocked, or done there, and opening it attaches.

Failed at `check` with no main clone or an untrusted one: hand the one-time setup above to the user. Reported no state within 30s: the worker is held at startup; look with `scripts/delegate read <task>` and bring it to the user. Rex on outpost unreachable: run `outpost-rex` (zsh function) once; if the instance is stopped or released, hand back to the user, since claiming an instance is their call.

## 4. Wait

```bash
scripts/delegate wait <task> <timeout-ms>
```

In Claude Code, run it with `run_in_background`, so the coordinator is woken on completion and stays free to delegate more. It reconnects on its own when the tunnel drops. Done when the worker settles on `idle` or `done`. `blocked` means a question or approval UI: read it with `scripts/delegate read <task>` and bring it to the user to answer.

## 5. Collect and verify

```bash
scripts/delegate collect <task> <local-dir>
```

For implement it also fetches the branch into `refs/remotes/outpost/<branch>` and prints its log and diffstat against the base.

The report is the worker's claim; the evidence is the fact. Done when:

- Implement: the fetched diff against the base is reviewed locally and matches the report.
- Research: every conclusion the user will act on traces to a source you opened.

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

It ends the Rex session and removes the worktree, keeping the branch, the mailbox as the task's record, and the main clone. Delete the branch on outpost once it is merged or pushed.
