# Agent Bootstrap

## Instructions

1. Read `.agent/state.yaml` and `.agent/usage.md`
2. If the run header provided Allowed stages, enforce them and persist to state
3. Determine the current stage and active story from state
4. For discovery/design/breakdown: read the active story README, definition, and acceptance
5. For execution:
   - Read the story task graph at `stories/{story-id}/tasks/task-graph.md`
   - If `current.focus.task` is set, read only that task file
   - If not set, select the next pending task from the task graph, set `current.focus.task`, then read only that task file
   - Do not read other task files unless a dependency blocks progress or the active task explicitly references them
6. For verification: read the active story acceptance and verification README; read individual verification files only when needed
7. If in execution stage, perform one coherent task and update artifacts and state
8. Run any tests you add or modify at the end of the task; fix failures before proceeding
9. Commit at the end of the task using the structured commit format in `usage.md`
10. You are pre-authorized to create commits for execution tasks; do not ask for permission
11. If in execution stage and blocked or approval is required, create `yield.md` and stop
12. If not in execution stage, perform one coherent action appropriate to the stage, update artifacts and state, and yield if approval is required
