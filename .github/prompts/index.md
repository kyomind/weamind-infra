# Prompt Index

> 由 `make update-prompt-index` 從各檔 `description:` 產生，不要手改。

- `check-serious-leaks` — Check this public repo for serious secret leaks only, without flagging low-risk environment details.
- `generate-flashcards` — Generate or refine one lesson's flashcards from completed QA, command drill, notes, and report, then update lesson progress context.
- `generate-preworks` — Generate standalone Kubernetes or DevOps prework files only after the user explicitly provides a topic or source material.
- `release` — Release weamind-infra: check that main matches the cluster, suggest a version, ask Kyo to choose it, then finalize CHANGELOG.md, tag, push, and verify the GitHub Release.
- `review-mode` — Enter WeaMind infra review mode: answer only the user's review questions and append each Q&A to review/notes.md.
- `rotate-review-notes` — Rotate review/notes.md into the next numbered notes-XX.md archive, back up to raw/, add a rotation date, reset notes.md to the review template, and verify the result.
