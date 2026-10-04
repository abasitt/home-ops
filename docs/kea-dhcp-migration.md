# Router Kea app-template migration

This branch retains DHCPv4 only, all five host interfaces, all reservations,
subnets, pools, DNS options, and lease timers. Lease storage remains an `emptyDir`
at `/var/lib/kea`; no PVC or storage-class change is involved. The official image
requires that lease directory; the previous third-party image used `/data`.

The official ISC image is pinned to the verified 3.0.3 digest. The registry did
not publish a 3.0.4 tag at the time of preparation. Renovate is limited to 3.0.x
and requires review for image and digest changes.

The StatefulSet keeps its existing name, selector, headless Service name,
OrderedReady policy, and revision-history limit. Flux's `InPlaceUpdate` strategy
avoids uninstalling the Helm release just because the chart name changes.
An init container checks the exact configuration before starting DHCP.

## Preflight without affecting home DHCP

- Compare the old values and new native config: reservations, subnets, options,
  and timers must match (apart from explicit subnet IDs).
- Render the Flux Kustomization and app-template chart.
- Run server-side dry-runs of the Flux objects and post-rendered StatefulSet.
  Preserve immutable selector/serviceName fields as specified in the HelmRelease.
- Run the official image with `kea-dhcp4 -t` in a temporary, non-host-network
  Job, using a dedicated ConfigMap and emptyDirs. Do not start a second DHCP
  server on the router host network.
- Clean up only the temporary validation Job and its ConfigMap.

Configuration parsing does not prove that DHCP broadcasts work on the VLANs.
The following cutover is still required before declaring the migration complete.

## Controlled cutover (not executed during preparation)

Keep a wired management session from a device with a reserved/static address.
Before deployment, record the old Helm revision:

```sh
helm --kubeconfig kubernetes/router/kubeconfig -n default history kea-dhcp
```

Deploy only this prepared Kea change during an agreed window; do not point the
entire router Flux source at an experimental branch. Expect a brief DHCP gap
while the single pod is replaced. Existing clients normally retain addresses
and internet access, but renewals and new clients may temporarily fail.
The current ephemeral lease behavior is unchanged: the replacement pod loses
the old lease journal.

Watch the rollout and logs, then renew one expendable client on each relevant
VLAN. Check its assigned address, gateway, DNS, and connectivity. Test a reserved
client too. Avoid releasing the address on the management device.

```sh
KUBECONFIG=kubernetes/router/kubeconfig kubectl -n default rollout status statefulset/kea-dhcp --timeout=120s
KUBECONFIG=kubernetes/router/kubeconfig kubectl -n default logs statefulset/kea-dhcp -c kea --tail=100
```

Do not merge until the real DHCP trial succeeds.

## Live trial result (2026-10-04)

The replacement is deployed and Flux reports Helm revision 32 successfully
running app-template 3.7.3 and official Kea 3.0.3. The new pod has zero restarts,
and two reserved VLAN20 clients have received their expected leases and DHCPACKs.
Renewals on the other VLANs have not yet been observed.

The initial startup failed because the official image requires its lease files
under `/var/lib/kea`; the parser-only check does not open the lease database.
The branch and live deployment now use the corrected path and directory permissions.

The Kea HelmRelease is active. Its Git Kustomization is temporarily suspended,
with `kustomize.toolkit.fluxcd.io/ssa=Ignore` and
`kustomize.toolkit.fluxcd.io/reconcile=disabled` annotations protecting the trial
from parent reconciliation. After committing, merging, and pushing the branch,
verify the router GitRepository has fetched the new commit, then remove both
temporary annotations and resume only the Kea Kustomization:

```sh
KUBECONFIG=kubernetes/router/kubeconfig flux reconcile source git flux-system -n flux-system
KUBECONFIG=kubernetes/router/kubeconfig kubectl -n flux-system annotate kustomization kea-dhcp kustomize.toolkit.fluxcd.io/ssa- kustomize.toolkit.fluxcd.io/reconcile-
KUBECONFIG=kubernetes/router/kubeconfig flux resume kustomization kea-dhcp -n flux-system
KUBECONFIG=kubernetes/router/kubeconfig flux reconcile kustomization kea-dhcp -n flux-system
```

Original rollback manifests are saved locally in `/tmp/kea-cutover.86bQyk`.
The pre-migration Helm revision is 27. These temporary paths should be retained
until the migration has been accepted and is managed from Git.

## Rollback

If the rollout or client renewal fails, suspend the HelmRelease to stop Flux
from immediately reapplying the candidate, then use the recorded numeric Helm
revision:

```sh
KUBECONFIG=kubernetes/router/kubeconfig kubectl -n default patch helmrelease kea-dhcp --type=merge -p '{"spec":{"suspend":true}}'
helm --kubeconfig kubernetes/router/kubeconfig -n default rollback kea-dhcp OLD_REVISION --wait --timeout 2m
```

Verify the original pod and client renewals. Restore the original Git manifests
and chart reference before resuming Flux. A chart-reference rollback also needs
the HelmRelease suspended until the intended chart/values are restored.
Keep the original HTTP chart source available until the live trial is accepted;
prune protection may leave that source in place after migration.
