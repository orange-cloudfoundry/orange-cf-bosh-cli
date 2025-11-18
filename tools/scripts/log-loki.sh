#!/bin/bash
#===========================================================================
# Log to supervision cluster for loki cli
#===========================================================================

#--- Set logcli service ip
export KUBECONFIG="${HOME}/.kube/config"
kubectl config use-context supervision > /dev/null 2>&1
LOKI_SERVICE_IP="$(kubectl get svc -n 40-loki-microservice loki-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2> /dev/null)"
export LOKI_ADDR=http://${LOKI_SERVICE_IP}
