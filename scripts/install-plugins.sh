#!/usr/bin/env bash

CONTEXT=neo

#install binaries in neo
echo "install cni binaries..."
kubectl --context="$CONTEXT" apply -f https://raw.githubusercontent.com/abasitt/kube6/main/calico/ipv6_multus/kind/cni-manifest.yaml

# Wait for all DaemonSet pods to be in the Running state
echo "Waiting for DaemonSet pods to be ready..."
kubectl --context="$CONTEXT" rollout status ds/install-cni-plugins -n kube-system

# Delete the DaemonSet after all pods are running
echo "Deleting the DaemonSet..."
kubectl --context="$CONTEXT" delete -f https://raw.githubusercontent.com/abasitt/kube6/main/calico/ipv6_multus/kind/cni-manifest.yaml
