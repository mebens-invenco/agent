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
- If planning is complete, create `yield.md` for approval and stop

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
- Run any tests you add or modify at the end of the task; fix failures before proceeding
- Commit at the end of the task using the structured commit format in `usage.md` (see Commit Authorization below)
- If blocked or approval is required, create `yield.md` and stop

### Verification

- Read `.agent/stories/{story-id}/acceptance.md`
- Confirm each acceptance criterion and record results in `acceptance.md`
- Run automated tests where possible and document manual verification requirements
- If verification fails or is blocked, create `yield.md` and stop

### Review

- Use `gh` to locate an existing PR for the current branch
- If the PR is merged, transition to consolidation and execute consolidation actions immediately
- If no PR exists, push the branch and create a PR using any template found
- If a PR exists, collect unresolved review threads and implement requested changes
  - Commit and push changes only if authorized
- Record PR metadata and status in state
- Return control after the single review pass

### Consolidation

- Archive superseded/completed stories to `_archive/`
- Merge overlapping research artifacts (with user approval)
- Consolidate research learnings and clean up indices
- If consolidation is complete, create `yield.md` for approval and stop

## Common Post-steps (always)

1. Update relevant indices for any artifacts created or updated
2. Update `.agent/state.yaml` (current stage, focus, review metadata, allowed stages)

Commit Authorization: This prompt invocation is the user's explicit request to commit ONLY execution-stage task changes. Do not commit in other stages unless the user explicitly requests it. If unsure whether a change is execution-stage work, do not commit and ask.

## Flow Control

- If execution completes and `verification` is allowed, proceed to verification in the same run
- If verification passes and `review` is allowed, proceed to review in the same run; if `review` is not allowed, return control (create `yield.md` if in autonomous loop)
- Yield only after review or when blocked
