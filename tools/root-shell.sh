#!/bin/bash
#===========================================================================
# Open root shell from node
#===========================================================================

export NAME="$1"
kubectl run tmp-shell --rm -i --tty --overrides='{"spec": {"hostNetwork": true, "hostIPC": true, "hostPID": true, "nodeSelector": {"k3s.io/hostname":"'"$NAME"'"}, "volumes": [{"name": "root-mount", "hostPath": {"path": "/"}}], "containers": [{"name":"tmp-shell", "stdin": true, "stdinOnce": true, "image":"nicolaka/netshoot:v0.11", "tty":true, "volumeMounts": [{"name": "root-mount", "mountPath": "/host-root"}], "securityContext": {"privileged": true, "allowPrivilegeEscalation": true}}]}}' --image nicolaka/netshoot
sleep 7