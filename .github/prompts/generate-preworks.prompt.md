---
description: "Generate one or a few standalone prework files for Kubernetes or DevOps topics by reading repo context and writing to learning/prework/."
---

# Generate Preworks

## Outcome

Create one or a few focused `learning/prework/YYYY-MM-DD-slug.md` files for a Kubernetes / DevOps / CKA concept gap the user wants to study before returning to repo-backed work.

This is a standalone generator. It does not enter the lesson workflow, reopen phase planning, create lesson skeletons, or update progress records. Its job is to turn a topic into external-AI-ready prework that fits this repo's existing prework system.

## Success Criteria

A successful run:

- produces ready-to-use prework file(s) the user can paste into an external ChatGPT-like service
- uses repo context to choose the right angle, vocabulary, scope, and deferred repo questions
- keeps the prework concept-focused, leaving WeaMind-specific YAML, implementation, and debug drills for later repo work
- avoids duplicate or overlapping prework unless the user explicitly wants a follow-up
- splits large topics into 2-3 coherent preworks when that makes the learning sharper
- follows the existing `learning/prework/` rules instead of inventing a new format

## Sources

Always read these first:

- `learning/prework/AGENTS.md`
- `learning/prework/prework-template.md`

Those files own the prework structure, naming rules, section order, report template, content principles, and self-check. If this prompt conflicts with them, follow those files.

Then inspect only the repo context needed to shape the prework. Use `rg` first.

Useful context sources:

- `learning/prework/` for existing topics and naming style
- `cka/notes.md` and `cka/notes-*.md` for CKA wording, traps, and YAML examples
- `learning/lessons/` for related completed lessons, especially `04-report.md` or `05-note.md`
- `docs/`, `manifests/`, `references/`, and `.env.example` when the topic touches actual repo architecture or configuration boundaries
- `review/notes.md` when the topic looks like a recurring review question

Do not read full phase plans unless the user asks to reconnect the topic to formal learning progress. For ordinary concept-gap prework, the current phase is background, not the driver.

## Judgment

### Frame The Topic

Infer from the user's request:

- the core topic
- the specific concept gap
- the scope that belongs in external prework
- the repo-specific questions to defer until after prework
- one or more descriptive slugs

Ask a short clarification question only when the topic is not usable enough to produce a good file.

If the topic is outside Kubernetes, DevOps, infrastructure, CKA, cloud, observability, CI/CD, or IaC, confirm before adding it to this repo.

### Decide Whether To Split

Default to one prework. Split only when one file would become too broad for a focused 45-60 minute session.

Split into 2-3 files when:

- the topic contains different mental models, such as resource metrics vs observability stack
- one prework would become a broad survey instead of a focused scaffold
- repo context already separates the subtopics
- each part has its own useful learning outcome and slug

Use meaningful slugs such as `metrics-server-hpa-basics` or `prometheus-grafana-alertmanager-basics`; avoid `part-1` / `part-2`.

If the topic needs more than 3 preworks, stop and propose the split before writing files.

### Keep The Evidence Boundary

Use repo context to shape the outline, not to outsource repo details to the external AI.

The external AI should teach the portable concept model. Repo-specific manifest edits, command drills, implementation decisions, and debug sequences happen later inside this repo.

Do not include real secrets, tokens, private operational details, or unnecessary concrete infrastructure values in prework text.

## Workflow

1. Infer the topic and split shape; ask only if ambiguity blocks a good file.
2. Read the authoritative prework rules and template.
3. Search existing prework and topic-related notes to avoid duplicates.
4. Inspect the most relevant repo evidence.
5. Create the prework file(s) under `learning/prework/`.
6. Validate the file(s) against the authoritative rules and template.

Use today's date unless the user provides a specific date.

If a target file already exists, stop unless the user explicitly asked to update or overwrite it.

## Report Back

After writing, reply briefly:

```text
已建立：
- learning/prework/YYYY-MM-DD-slug.md
主題：<topic>
拆分：<一份或多份；若多份，簡述理由>
依據：讀取了 <n> 個既有 context 來源
下一步：貼給外部 AI 預習；完成後再把學習報告回填到對應檔案
```

If stopped, state the blocker and the smallest user decision needed.

## Final Check

Before finishing, verify:

- every new file is under `learning/prework/`
- filenames follow the repo's date + slug convention
- each file follows `learning/prework/AGENTS.md` and `learning/prework/prework-template.md`
- the content is concept prework, not a lesson, implementation plan, or progress update
- any split has a clear reason and each file can stand alone
- no unnecessary private repo details were included
