# Agent Bootstrap

## Instructions

1. Read `.agent/state.yaml` and `.agent/usage.md`
2. If the run header provided Allowed stages, enforce them and persist to state
3. Determine the current stage and active story from state
4. For plan/breakdown: read the active story README, definition, and acceptance
5. For execution:
   - Read the story task graph at `stories/{story-id}/tasks/task-graph.md`
   - If `current.focus.task` is set, read only that task file
   - If not set, select the next pending task from the task graph, set `current.focus.task`, then read only that task file
   - Do not read other task files unless a dependency blocks progress or the active task explicitly references them
6. For verification:
   - Read `stories/{story-id}/acceptance.md`
   - Confirm each acceptance criterion and record results in `acceptance.md`
   - If verification fails or is blocked, create `yield.md` and stop
7. For review:
   - Use `gh` to locate an existing PR for the current branch
   - If the PR is merged, transition to consolidation and execute consolidation actions immediately
   - If no PR exists, push the branch and create a PR using any template found
   - If a PR exists, collect unresolved review threads, implement requested changes, commit, and push
   - If a retest request template exists and a retest is needed, post a PR comment using it
   - Record PR metadata and status in state
   - Return control after the single review pass
8. If in execution stage, perform one coherent task and update artifacts and state
9. If execution completes and `verification` is allowed, transition to verification in the same run before yielding
10. If verification passes and `review` is allowed, proceed to review in the same run; if `review` is not allowed, return control (create `yield.md` if in autonomous loop). Yield only after review or when blocked
11. Run any tests you add or modify at the end of the task; fix failures before proceeding
12. Commit at the end of the task using the structured commit format in `usage.md`
13. You are pre-authorized to create commits for execution tasks; do not ask for permission
14. If in execution stage and blocked or approval is required, create `yield.md` and stop
15. If in plan/breakdown/verification/review/consolidation, perform one coherent action appropriate to the stage, update artifacts and state, and yield if approval is required (consolidation requires approval unless invoked from review after merge)
