# Agent Bootstrap

## Common Pre-steps (always)

1. Read `.agent/state.yaml` and `.agent/usage.md`
2. If the run header provided Allowed stages, enforce them and persist to state
3. Determine the current stage and active story from state

## Stage-Specific Steps

### Plan

- If creating a new story, first ask if a Linear ticket exists
  - If yes: use that Linear ID as the story ID (format `eng-xxxx`)
  - If no: create a temporary story ID (format `temp-001`) and proceed
- Create/update `.agent/stories/{story-id}/README.md`, `.agent/stories/{story-id}/definition.md`, and `.agent/stories/{story-id}/acceptance.md`
- Perform one coherent planning action and update artifacts, indices, and state
- If planning is complete, create `.agent/yield.md` for approval and stop

### Breakdown

- If the story ID is temporary, create a Linear ticket (team `eng`, assignee `me`), rename the story to the Linear ID, and update links, indices, and state
  - Include an acceptance criteria summary table from `acceptance.md` in the Linear description
- Create tasks and `.agent/stories/{story-id}/tasks/task-graph.md`
- Perform one coherent breakdown action and update artifacts, indices, and state

### Execution

- Read the task graph at `.agent/stories/{story-id}/tasks/task-graph.md`
- If `current.focus.task` is set, read only that task file
- If not set, select the next pending task from the task graph, set `current.focus.task`, then read only that task file
- Implement one coherent task, update task status and code changes
- Hard limit: execute exactly one task per invocation/run; do not implement additional tasks in the same run
- Run relevant automated checks at the end of the task (for example: added/modified tests, lint, type checks); fix failures before proceeding
- If manual verification remains, document it as pending/deferred for the Verification stage; do not block Execution on manual verification
- Commit at the end of the task using the structured commit format in `usage.md` (see Commit Authorization below)
- After committing the task, do not select or read another task file in this run
- If blocked or approval is required, create `.agent/yield.md` and stop

### Verification

- Read `.agent/stories/{story-id}/acceptance.md`
- Confirm each acceptance criterion and record results in `acceptance.md`
- Run automated tests where possible and document manual verification requirements
- If verification fails or is blocked, create `.agent/yield.md` and stop

### Review

- Use `gh` to locate an existing PR for the current branch
- If the PR is merged, transition to consolidation and execute consolidation actions immediately
- If no PR exists (including when only closed PRs exist), push the branch and create a PR using any template found (search `.github/` case-insensitively)
- If a PR exists, collect unresolved review threads, pull issue conversation comments on the PR, and pull CI status checks via `gh pr view --json statusCheckRollup`
- If running in autonomous mode and the PR has no unresolved review threads, no unaddressed issue conversation comments, and no failing CI status checks, run `sleep 60` and return control (do not create `.agent/yield.md`)
- If a PR exists, implement requested changes from both review threads and issue conversation comments
  - Commit and push changes to update the PR
  - Mark addressed review threads as resolved after pushing fixes
  - Reply on issue conversation comments when needed to confirm a fix or explain follow-up
- Synthesize review feedback from both review threads and issue conversation comments into short summaries and abstractions in `.agent/stories/{story-id}/review-learnings.md`
  - If no actionable feedback exists in either source, record that in `review-learnings.md` with the date
- Record PR metadata and status in state
- Return control after the single review pass

### Consolidation

- Archive superseded/completed stories to `_archive/`
- Merge overlapping research artifacts (with user approval)
- Consolidate research learnings and clean up indices
- Merge review learnings from `.agent/stories/{story-id}/review-learnings.md` into research artifacts
- Synthesize merged learnings into reusable abstractions at multiple levels when applicable: story/page, page or flow archetype, and related/shared components
- Record applicability boundaries for each promoted learning (where it applies and where it does not) before updating confidence and applied count
- If consolidation is complete, create `.agent/yield.md` for approval and stop

## Common Post-steps (always)

1. Update relevant indices for any artifacts created or updated
2. Update `.agent/state.yaml` (current stage, focus, review metadata, allowed stages)

Commit Authorization: This prompt invocation is the user's explicit request to commit execution-stage task changes and review-stage fixes responding to PR feedback. Do not commit in other stages unless the user explicitly requests it. If unsure whether a change is execution or review feedback, do not commit and ask.

## Flow Control

- Execution stage runs exactly one task per invocation; if more execution tasks remain after that task, return control without transitioning stages
- If execution is fully complete and `verification` is allowed, proceed to verification in the same run
- If verification passes and `review` is allowed, proceed to review in the same run; if `review` is not allowed, return control (create `.agent/yield.md` if in autonomous loop)
- Yield only after review or when blocked
