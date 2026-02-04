# Agent Bootstrap

## Instructions

1. Read `.agent/state.yaml` and `.agent/usage.md`
2. If the run header provided Allowed stages, enforce them and persist to state
3. Determine the current stage and active story from state
4. When creating a new story, first ask if a Linear ticket exists
   - If yes: use that Linear ID as the story ID (format `eng-xxxx`)
   - If no: create a temporary story ID (format `temp-001`) and proceed
   - On Plan -> Breakdown, if the story ID is temporary, create a Linear ticket, assign it to `me`, rename the story to the Linear ID, and update links, indices, and state
   - Use team `eng` and include an acceptance criteria summary table in the Linear description
5. For plan/breakdown: read the active story README, definition, and acceptance
6. For execution:
   - Read the story task graph at `.agent/stories/{story-id}/tasks/task-graph.md`
   - If `current.focus.task` is set, read only that task file
   - If not set, select the next pending task from the task graph, set `current.focus.task`, then read only that task file
   - Do not read other task files unless a dependency blocks progress or the active task explicitly references them
7. For verification:
   - Read `.agent/stories/{story-id}/acceptance.md`
   - Confirm each acceptance criterion and record results in `acceptance.md`
   - If verification fails or is blocked, create `yield.md` and stop
8. For review:
   - Use `gh` to locate an existing PR for the current branch
   - If the PR is merged, transition to consolidation and execute consolidation actions immediately
   - If no PR exists, push the branch and create a PR using any template found
   - If a PR exists, collect unresolved review threads, implement requested changes, commit, and push
   - If a retest request template exists and a retest is needed, post a PR comment using it
   - Record PR metadata and status in state
   - Return control after the single review pass
9. If in execution stage, perform one coherent task and update artifacts and state
10. If execution completes and `verification` is allowed, transition to verification in the same run before yielding
11. If verification passes and `review` is allowed, proceed to review in the same run; if `review` is not allowed, return control (create `yield.md` if in autonomous loop). Yield only after review or when blocked
12. Run any tests you add or modify at the end of the task; fix failures before proceeding
13. Commit at the end of the task using the structured commit format in `usage.md`
14. You are pre-authorized to create commits for execution tasks; do not ask for permission
15. If in execution stage and blocked or approval is required, create `yield.md` and stop
16. If in plan/breakdown/verification/review/consolidation, perform one coherent action appropriate to the stage, update artifacts and state, and yield if approval is required (consolidation requires approval unless invoked from review after merge)
