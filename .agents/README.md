# Repository Agent Resources

General repository instructions live in [`../AGENTS.md`](../AGENTS.md).

Future reusable agent skills belong at:

```text
.agents/skills/<skill-name>/SKILL.md
```

Create a skill only when a specialized workflow is repeated often enough to justify maintaining it. Good candidates may include validating both clusters, testing a VolSync restore, or auditing Flux dependency and pruning safety.
