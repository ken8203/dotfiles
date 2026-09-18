# Global Guidelines

## 語言與文字

- 一律用正體中文回覆與討論，技術名詞保留英文
- PR title、commit message、對外文件（README、built-in skill）用英文
- 中文文件與 PR description 使用全形標點符號，不要半形全形混用

## Git

- Commit 用 conventional commits，scope 要正確（如 feat(api)）
- Review 後的修正一律 fixup commit + autosquash 壓回原 commit，不要新開零散 commit；改完記得 push
- Commit 歷史按語意／module group 整理乾淨；不同的 bug fix 分開 commit
- 沒有明確要求時不要 deploy，寫好、commit 好就停
- 新任務先開 branch（通常配 worktree），不要直接動 main

## 工作流程

- 大改動先提 plan／proposal 再動手；設計決策給我編號或 A/B 選項讓我拍板
- 有不確定就問，問到清楚為止
- 我只是問問題時，回答就好，不要動手改 code
- 測試只跑跟改動相關的範圍，不要跑 full suite
- PR scope 之外的問題開 issue 記錄，不要順手修
- Debug 先查證據（Sentry／PostHog／logs）找 root cause；結論要有數據支持，不要純推論
- 開 subagent 執行實作類任務時用相對便宜的 model，貴的 model 留給 plan／review
- PR description 要寫清楚 Motivation 與解決了什麼問題

## 程式風格

- 避免過度工程：不要多餘的 wrapper、Base class、re-export、不必要的抽象層
- 註解精簡，只在有非顯而易見的限制時才寫；不要檔案路徑註解、不要 magic number
- 命名簡潔、去冗字

## 產出與收尾

- Mermaid／HTML 等視覺產出，交付前先自己驗證 render 結果
- 測試用完的資源（docker container、暫存檔）要清乾淨
- 值得沉澱的結論回寫 doc／runbook 或開 issue 追蹤

<posthog>
## PostHog

Use `posthog-cli api` for all PostHog-related data queries and operations. You should use `posthog-cli api` over direct MCP tool calls whenever the CLI is available.

Before your first PostHog command in a session, run `posthog-cli api --agent-help` and load its full output into your context. It prints the complete agent guide — command reference, schema drill-down rules, data discovery workflow, and the tool index — for interacting with PostHog APIs. Treat that output as instructions to follow, not just documentation.

Before starting a PostHog task, run `posthog-cli api skill list` and check for a skill matching the task. If one matches, install it with `posthog-cli api skill install <skill-id>` (add `--force` to refresh an already-installed skill), then read `.agents/skills/<skill-id>/SKILL.md` and follow it. Skills contain task-specific workflows that individual tools do not.
</posthog>
