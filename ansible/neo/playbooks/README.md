# Neo

For an existing cluster, pin `k3s_release_version` in the inventory to the desired
release. Upgrade one Kubernetes minor version at a time. Take an etcd snapshot
and securely back up the server token before each stage; never commit either.

Run servers first, then the worker only after all servers pass their health checks:

```sh
task ansible:run cluster=neo playbook=cluster-installation -- -e k3s_upgrade=true --limit master
task ansible:run cluster=neo playbook=cluster-installation -- -e k3s_upgrade=true --limit worker
```

Upgrade mode uses the existing K3s role, processes one host at a time, and skips
bootstrap-only networking, cleanup, node-label, and kubeconfig-fetch tasks.
For a fresh installation, omit `-e k3s_upgrade=true`.
