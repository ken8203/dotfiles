---
name: outpost-delegate
description: Delegate a research or implementation task to outpost through Herdr. Use when a task should run on outpost, or to follow up on or clean up a delegated task.
---

The local session is the **coordinator**; an agent on outpost is the **worker**. Herdr carries control and state (start, prompt, wait). Files carry content: every task has a **mailbox** on outpost holding the brief going out and the report coming back. Code travels over git: `outpost:<path>` is a normal ssh remote.

Every entry starts at Preflight. A new task then runs steps 2–7 in order; an existing task jumps to [Follow-up round](#follow-up-round) or [Clean up](#clean-up).

## Layout on outpost

```
/home/outpost/code/
  <repo>/                        main clone; worker cwd for research on that repo
  <repo>.<task>/                 implement worktree, worker cwd
  delegate/<task>/               mailbox; worker cwd only for research tied to no repo
    brief.md                     coordinator → worker
    review-<n>.md                coordinator → worker, follow-up rounds
    REPORT.md                    worker → coordinator
  delegate/<project>/common.md   optional context shared by one initiative's tasks
```

The worker runs inside the repo it works on, so it picks up that repo's instructions, skills, and Hindsight bank; the mailbox only carries files. Every worker cwd needs folder trust: Claude Code inherits it from a trusted parent (`~/code`) or a worktree's main clone, and never persists it for `$HOME`. A few older clones live outside `~/code` (e.g. `~/GNTC`) and are trusted on their own; `<clone>` below is the absolute path of the repo's main clone, which both `herdr --machine` and `outpost:<clone>` git remotes accept.

`<task>` is one slug reused as the mailbox, Herdr agent name, and workspace label, so it matches `[a-z][a-z0-9_-]{0,31}` and names no existing mailbox, since mailboxes outlive their tasks.

Pass remote paths to `herdr --machine` as absolute `/home/outpost/...` paths; a bare `~` expands locally first. Given a cwd that does not exist, Herdr silently falls back to the remote home. A failed `herdr --machine` call can still have applied, so inspect remote state before retrying.

## 1. Preflight

```bash
M=$(herdr machine list --json | jq -r '.[] | select(.target == "outpost") | .label')
herdr --machine "$M" agent list
```

Done when `agent list` returns JSON. If the server is unreachable, run `outpost-herdr` (zsh function) once; if the instance is stopped or released, hand back to the user, since claiming an instance is their call.

## 2. Pick the worker

Mirror the coordinator: the same harness, model, and effort as this session, unless the user named another. Step 5 passes them as agent args.

## 3. Write the brief

Draft `brief.md` in a local temp directory from [`brief-template.md`](brief-template.md). The worker cannot ask mid-task, so settle open decisions with the user first. Done when every section is filled and Deliver names the exact branch or file coming back.

When several tasks belong to one initiative, write their shared context and decisions once in `delegate/<project>/common.md` and point each brief at it.

## 4. Ship

```bash
ssh outpost mkdir -p code/delegate/<task>   # rsync creates only the last path level
outpost rsync <local-dir>/ :code/delegate/<task>/
```

When the task is on a repo, locate its main clone on outpost (`~/code/<repo>`, or an existing clone such as `~/GNTC`). With none, clone it into the trusted root: `ssh outpost gh repo clone <owner>/<repo> code/<repo>`. Then bring it up to date: `ssh outpost git -C <clone> fetch origin`, plus `git push outpost:<clone> <base>` from the local repo when the base is unpushed.

Done when `brief.md` is in the mailbox and, for a repo task, `<base>` resolves in `<clone>`.

## 5. Launch

Create the worker's workspace; both commands return its pane at `.result.root_pane`. Done when that pane's `cwd` is the path you asked for.

```bash
# implement
herdr --machine "$M" worktree create --cwd <clone> \
  --branch <branch> --base <base> --path <clone>.<task> \
  --label <task> --no-focus
# research: <clone> for a repo, /home/outpost/code/delegate/<task> otherwise
herdr --machine "$M" workspace create --cwd <research-cwd> \
  --label <task> --no-focus
```

Start the worker in a non-interactive approval mode, so it runs unattended:

```bash
herdr --machine "$M" agent start <task> --kind claude --pane <pane> -- \
  --permission-mode auto --model <model> --effort <effort>
herdr --machine "$M" agent start <task> --kind codex --pane <pane> -- \
  --approve-for-me -m <model> -c model_reasoning_effort=<effort>
```

`agent_not_ready` here is usually the folder-trust prompt: the cwd is outside `~/code`, or `~/code` is not trusted yet. Confirm with `agent read`, then ask the user to accept it once by hand.

Send a one-line pointer to the brief:

```bash
herdr --machine "$M" agent prompt <task> \
  "Read /home/outpost/code/delegate/<task>/brief.md and follow it. Reply DONE when REPORT.md is written." \
  --wait --until working --until blocked --timeout 30000
```

Done when the result's `agent.agent_status` is `working`. That proves the prompt started a turn only because the worker was idle when it arrived; prompt a worker only after it has settled.

## 6. Wait

```bash
herdr --machine "$M" agent wait <task> --timeout <ms>
```

In Claude Code, run it with `run_in_background`, so the coordinator is woken on completion and stays free to delegate more. Done when the worker settles on `idle` or `done`. `blocked` means a question or approval UI: read it with `agent read <task> --source recent-unwrapped --lines 120` and bring it to the user to answer.

## 7. Collect and verify

```bash
outpost rsync :code/delegate/<task>/REPORT.md <local-dir>/
git fetch outpost:<clone> <branch>   # implement
```

The report is the worker's claim; the evidence is the fact. Done when:

- Implement: the fetched diff against `<base>` is reviewed locally and matches the report.
- Research: every conclusion the user will act on traces to a source you opened.

## Follow-up round

Write `review-<n>.md`, ship it with `outpost rsync` to the mailbox, then run step 5's prompt with `Read /home/outpost/code/delegate/<task>/review-<n>.md and address it. Update REPORT.md, then reply DONE.` Continue from step 6.

## Clean up

Once the user accepts the result:

```bash
herdr --machine "$M" worktree remove --workspace <workspace>   # implement; keeps the branch
herdr --machine "$M" workspace close <workspace>               # research
```

Keep the mailbox as the task's record. Keep the main clone's workspace, which `worktree create` opened and every task on that repo shares. Delete the branch on outpost once it is merged or pushed.
