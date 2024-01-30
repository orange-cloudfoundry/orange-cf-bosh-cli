#!/bin/bash
#===========================================================================
# Open root shell from node
#===========================================================================

export NAME="$1"
POD_NAME="${NAME}-tmp-shell"
flag_existing_pod="$(kubectl get pods 2>&1 | grep "${POD_NAME}")"
if [ "${flag_existing_pod}" != "" ] ; then
  kubectl delete ${POD_NAME}
fi

kubectl run ${POD_NAME} --rm -i --tty --restart=Never --image nicolaka/netshoot --overrides='{"spec": {"hostNetwork": true, "hostIPC": true, "hostPID": true, "nodeSelector": {"k3s.io/hostname":"'"$NAME"'"}, "volumes": [{"name": "root-mount", "hostPath": {"path": "/"}}], "containers": [{"name":"tmp-shell", "stdin": true, "stdinOnce": true, "image":"nicolaka/netshoot:v0.11", "tty":true, "volumeMounts": [{"name": "root-mount", "mountPath": "/host-root"}], "securityContext": {"privileged": true, "allowPrivilegeEscalation": true}}]}}'
sleep 7