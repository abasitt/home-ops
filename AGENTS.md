# Repository Agent Instructions

## Scope

This repository manages two Flux-based K3s clusters:

- `kubernetes/neo`: the primary application cluster
- `kubernetes/router`: the router and network-services cluster

Preserve this separation. Do not copy cluster-specific assumptions, storage classes, namespaces, or kubeconfig usage between clusters without verifying them.

## Safety

- Never print, decrypt, commit, or expose secret values, Age keys, kubeconfigs, or decrypted SOPS files.
- Kubernetes Secrets committed to Git must remain SOPS-encrypted.
- Do not delete PVCs, PVs, snapshots, VolSync resources, namespaces, or critical networking resources unless the user explicitly authorizes the exact targets.
- Preserve unrelated working-tree changes.
- Do not commit or push unless explicitly requested.
- Treat `.private/` as ignored local user state; do not add it to Git.

## Repository Workflow

- Use `rg` and `rg --files` for searches.
- Use `apply_patch` for manual file edits.
- Run `task precommit:check` before making changes. If the hook is missing, run `task precommit:init` after the Python environment is installed.
- Run `task precommit:run` when a full repository check is appropriate.
- Prefer repository Taskfile commands over ad hoc equivalents when a task already exists.

## Kubernetes and Flux

- Use the cluster-specific kubeconfig explicitly when querying a cluster:
  - Neo: `KUBECONFIG=kubernetes/neo/kubeconfig kubectl ...`
  - Router: `KUBECONFIG=kubernetes/router/kubeconfig kubectl ...`
- Validate against the cluster affected by the change. Do not assume the current kubectl context is correct.
- Each namespace-level directory under `kubernetes/<cluster>/apps/` has its own `kustomization.yaml`; there is intentionally no aggregate `apps/kustomization.yaml`.
- Render affected Kustomizations with `kustomize build <directory> --load-restrictor=LoadRestrictionsNone`.
- Validate Flux custom resources with a server-side dry-run against the correct cluster when access is available.
- Use `dependsOn` only for genuine installation or runtime dependencies.
- Prefer targeted `healthChecks` for critical controllers. Remember that `wait: true` waits for all reconciled resources and supersedes explicit health checks.
- Keep `prune: false` only for intentionally protected critical infrastructure. Data-bearing resources should use resource-level prune protection where appropriate.
- Do not enable dormant Kustomizations or repair legacy paths as a side effect of an unrelated task.

## Verification

Scale verification to risk and report what was run. At minimum for manifest changes:

1. Parse or render the affected YAML/Kustomization.
2. Run `git diff --check`.
3. Run relevant pre-commit checks.
4. For Flux dependency, health-check, or prune changes, verify referenced objects and use the correct cluster's server-side dry-run when possible.

## Future Skills

Repository-specific skills belong under `.agents/skills/<skill-name>/SKILL.md`. Add a skill only for a repeated, specialized procedure that benefits from precise reusable steps; keep ordinary repository guidance in this file.
