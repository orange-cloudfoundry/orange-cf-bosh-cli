#!/bin/bash
#===========================================================================
# show kubernetes clusters token (for k8s portals use)
#===========================================================================

#--- Get k8s token
token="$(kubectl describe secret -n kube-system $(kubectl get secret -n kube-system | grep admin | awk '{print $1}') | grep "token:" | sed -e "s+token: *++g")"
printf "\n%bk8s token:%b\n${token}\n\n" "${YELLOW}${REVERSE}" "${STD}"