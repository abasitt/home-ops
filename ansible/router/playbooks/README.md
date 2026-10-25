# Router maintenance

Host package updates may interrupt connectivity and reboot the router when required.
The single-node router is not drained: there is nowhere to reschedule its services,
and deleting Kea's pod would discard its emptyDir lease data.

```sh
task ansible:run cluster=router playbook=cluster-rollout-update
```

For existing-cluster K3s upgrades, update `k3s_release_version` in the router
inventory one minor version at a time, then run:

```sh
task ansible:run cluster=router playbook=cluster-installation -- -e k3s_upgrade=true
```

This uses the existing K3s role, skips bootstrap-only cleanup and kubeconfig
fetching, and checks the target version and API readiness after the service restart.
For a fresh installation, omit `-e k3s_upgrade=true`.
