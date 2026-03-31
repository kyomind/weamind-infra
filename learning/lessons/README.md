# Lessons README

## Purpose

`learning/lessons/` stores the internal learning records created inside VS Code.

This is the second-layer rule file under `learning/`, and it assumes two things are already true:

1. `learning/README.md` has been read first.
2. The prework decision for today has already been made.

Only open this file when one of these is true:

1. Today does not need prework, so the work can go straight into a lesson.
2. Today's prework is already finished, and the work is now moving into repo-backed learning.

If that decision has not been made yet, go back to `learning/README.md` first.

## Boundary With Prework

This file defines lesson rules. It does not decide whether prework is needed; that decision belongs to `learning/README.md`.

`learning/prework/` is for:

1. external AI prework
2. pure concept scaffolding
3. understanding that is not yet tightly tied to repo reality

`learning/lessons/` is for:

1. direct comparison against WeaMind manifests, docs, and incidents
2. why the repo is designed this way
3. traffic paths, trade-offs, and debug stories
4. project-specific explanations the user should be able to give in interviews

## Boundary With lesson-template

`lesson-template.md` is a skeleton tool, not a second rules document.

Use the split below consistently:

1. `README.md` defines rules, boundaries, and workflow.
2. `lesson-template.md` provides the file skeleton and minimal examples.

If the question is about structure or behavior, use this README.
If the question is about the starting file skeleton, use the template.

## When To Create a Lesson

Create a lesson when:

1. meaningful project-specific learning happened inside VS Code
2. general concepts were mapped onto real YAML, docs, architecture, or operations
3. the session produced reviewable why, trade-off, or debug material
4. prework is either unnecessary or already complete

If the day only contained pure concept prework and no repo-backed work, a lesson is usually unnecessary.

## Start Check

Before starting a lesson, confirm at least these points:

1. `learning/README.md` was used to decide the path, and prework was completed if required
2. the lesson file structure matches this README and `lesson-template.md`
3. the internal flow is still `QA -> command -> report`, unless `01-outline.md` clearly explains an exception
4. if `03-command.md` exists, it is a real command drill document rather than a raw command list
5. `04-report.md` is left open for later consolidation rather than prefilled with answers

## Standard Structure

Each lesson uses its own folder:

`learning/lessons/YYYY-MM-DD-slug/`

Use lowercase English and hyphens for the slug. The slug should describe the actual topic learned that day, not a vague category.

Default files:

1. `01-outline.md`
2. `02-qa.md`
3. `04-report.md`
4. `05-note.md`

Optional file:

5. `03-command.md`

`03-command.md` should exist only when the lesson needs command drill or hands-on verification.

## File Responsibilities

### `01-outline.md`

Purpose: define the topic, scope, and sequence of the lesson.

It should usually include:

1. today's topic
2. the concrete project questions to solve
3. repo files to compare
4. suggested learning order
5. the why / how questions worth pressing on
6. completion criteria

Default assumption: write the sequence as `QA -> command -> report`.

Only make command-first flow an exception when the lesson clearly benefits from observation before explanation, and state that reason explicitly.

### `02-qa.md`

Purpose: record repo-backed questions, the user's answer summary, and AI corrections.

Default scope:

1. 3 to 5 focused questions
2. a repo file or observation target for each question
3. user answer summary
4. AI correction or refinement
5. a clear status for each question

Formatting expectations:

1. use `## Q1`, `## Q2`, and so on
2. use H3 sections such as `### Question`, `### Reference Files`, `### User Answer Summary`, `### AI Corrections and Additions`
3. keep questions small and directly comparable against the repo
4. highlight key conclusions or key terms inside AI corrections, but do not turn the whole section into bold text
5. use inline code for technical terms such as commands, resource names, states, fields, and env keys

QA style:

1. start with one full question
2. let the user answer in their own words first
3. if the user is stuck, split that same question into 2 or 3 smaller prompts
4. after smaller prompts, always collapse back into the full answer

If extra questions appear during QA:

1. keep them in `02-qa.md` only if they are necessary to finish the current question
2. if they are independent, higher-branching, or would make QA harder to review later, move the detailed treatment into `05-note.md`
3. leave only the minimum conclusion needed to complete the current QA item inside `02-qa.md`

### `03-command.md`

Purpose: record command drill in a review-friendly way, preserving what was being tested, what mattered in the output, and what conclusion was reached.

Terminology:

1. `command drill` is the name of the whole lesson stage recorded in `03-command.md`.
2. `command loop` is one small closed round inside that drill.
3. In command documents, prefer section labels like `Command 1`, `Command 2`, and `Command 3` for individual units.
4. When speaking to the user, prefer `command drill` for the stage; avoid making `loop` sound like the main public term.

It should usually include:

1. today's command goal
2. the path or problem being verified
3. each command loop as a small closed unit inside the overall command drill, typically rendered as `Command 1`, `Command 2`, and so on: question, command, key output, AI reading, one-line takeaway, status
4. a final consolidation of what the commands helped clarify

Default rhythm:

1. present one concrete situation
2. usually offer 3 candidate commands
3. let the user choose and run one in the real environment
4. use the output to refine the reasoning and collapse the loop into a reusable conclusion

Command drill principles:

1. the point is interpretation and correction, not memorizing commands
2. keep the record compact and reviewable
3. keep only the key output when raw output is long
4. if the valuable part is the correction of an initial wrong guess, preserve that briefly
5. if AI runs commands for verification, mark them as support work rather than completed user drill

If extra questions appear during command drill:

1. keep them in `03-command.md` only if they are necessary to complete that loop
2. if they are independent, higher-branching, or would damage reviewability, move the detailed treatment into `05-note.md`
3. leave only the minimum conclusion needed to complete that command loop inside `03-command.md`

### `04-report.md`

Purpose: consolidate what the lesson actually produced. This is the lesson-level conclusion page for `02-qa.md` and `03-command.md` when command drill exists.

Recommended order:

1. today's topic
2. status
3. what QA clarified
4. what the user was originally stuck on
5. command drill consolidation, if command drill happened
6. the core takeaway that should remain after the lesson
7. what the user can now explain clearly
8. what still needs reinforcement
9. next step

Principles:

1. fill this mainly at the end of the lesson
2. it can be updated during the lesson if conclusions are already stable
3. do not prefill it with standard answers before the lesson happens
4. do not restate full QA details; keep only the lesson-level understanding
5. omit the command section entirely if there was no command drill

### `05-note.md`

Purpose: hold extensions, temporary conclusions, and flashcards.

Fixed structure:

1. `## 學習注意事項`
2. `## Notes`
3. `## Flashcards`

Use `05-note.md` for:

1. extra user questions and AI answers
2. stable but not yet fully consolidated conclusions
3. valuable explanations that do not belong inside one QA item or one command loop
4. final flashcards

Rules:

1. create `05-note.md` by default with every lesson
2. use H3 grouping inside both `學習注意事項` and `Notes`
3. let `學習注意事項` hold lesson boundaries, repo reference files with observation targets, and items not expanded today
4. during initialization, only `學習注意事項` may be prefilled
5. keep `Notes` and `Flashcards` empty at initialization, except for placeholder comments
6. if extra QA or command questions do not belong in the main lesson flow, expand them here instead

Flashcards are part of the fixed lesson structure, but detailed flashcard-generation rules are maintained outside this README.

If flashcards need to be generated or refined, use:

1. `.github/prompts/generate-flashcards.prompt.md`

This README defines lesson structure. The dedicated prompt defines flashcard extraction and refinement strategy.

## Default Flow

The default lesson flow is:

`QA -> command -> report`

This is an internal lesson flow, not the global `learning/` entry flow.

Typical sequence:

1. use `01-outline.md` to define scope
2. use `02-qa.md` to align the conceptual and repo-backed skeleton
3. if needed, use `03-command.md` to test the skeleton against real output
4. move extensions and temporary conclusions into `05-note.md` during the process
5. finish by consolidating the lesson into `04-report.md`

If the day required prework, the order is still external prework first, then this internal lesson flow.

## Content Principles

### 1. Prefer project-specific knowledge

If a point applies to almost any Kubernetes project equally, it may belong better in prework or general notes than in a lesson.

### 2. Favor why and real paths

Lessons should mainly answer:

1. how WeaMind actually works
2. why it is designed this way
3. how to debug it when it breaks

### 3. Keep command records review-friendly

`03-command.md` should make it easy to see:

1. what each loop was testing
2. which output mattered most
3. what conclusion the loop produced

### 4. Do not turn lessons into textbooks

Each lesson should stay focused enough that later review is fast and practical.

### 5. Do not prewrite the report

`04-report.md` should reflect what the lesson actually produced, not an ideal answer written in advance.

## Maintenance

After adding or completing a lesson:

1. update `.privatedocs/28day-progress.md` when it helps record what the user actually learned
2. update `.privatedocs/ai-memories.md` only for high-level handoff context
3. treat `.privatedocs/五週版學習計畫.md` as the formal progress anchor

## Handoff in a New Conversation

If the user says only "continue" in a new conversation:

1. read `.privatedocs/五週版學習計畫.md` first
2. then read the current lesson's `02-qa.md`
3. use `01-outline.md` only when scope needs to be checked
4. use `04-report.md` when already-learned content needs to be summarized

One-line rule: progress comes from the main plan, but execution resumes from `02-qa.md`.
