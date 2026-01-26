#!/bin/bash
#===========================================================================
# Get loki logs
#===========================================================================

#--- Parameters
CONTEXT="$1"
CLUSTER="$2"
NAMESPACE="$3"
NAME="$4"

#--- Get loki service ip for logcli
export KUBECONFIG="${HOME}/.kube/config"
kubectl config use-context supervision > /dev/null 2>&1
LOKI_SERVICE_IP="$(kubectl get svc -n 40-loki-microservice loki-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2> /dev/null)"

if [ "${LOKI_SERVICE_IP}" = "" ] ; then
  printf "\n%bLoki service ip unavailable to collect logs.%b" "${REVERSE}${RED}" "${STD}" ; read next
else
  #--- Set time interval (nb hours) for collecting logs
  clear
  printf "\n%bLogs interval in hours (default: 1):%b " "${REVERSE}${YELLOW}" "${STD}" ; read INTERVAL
  if [ "${INTERVAL}" = "" ] ; then
    INTERVAL=1
  fi

  checkInterval="$(echo "${INTERVAL}" | grep -E '^[0-9]*$')"
  if [ "${checkInterval}" = "" ] ; then
    printf "\n%bUnknown interval value.%b" "${REVERSE}${RED}" "${STD}" ; read next
  else
    #--- Run logcli command with preset parameters
    if [ "${NAMESPACE}" = "-" ] ; then
      QUERY="{cluster=~\"${CLUSTER}\",namespace=~\"${NAME}\"}"
    else
      QUERY="{cluster=~\"${CLUSTER}\",namespace=~\"${NAMESPACE}\",pod=~\"${NAME}\"}"
    fi

    export LOKI_ADDR=http://${LOKI_SERVICE_IP}
    FROM="$(date --date="${INTERVAL} hours ago" +"%Y-%m-%dT%H:%M:%SZ")"
    TO="$(date --date="now" +"%Y-%m-%dT%H:%M:%SZ")"
    logcli query "${QUERY}" -q --limit=0 --output=jsonl --timezone=UTC --from=${FROM} --to=${TO} | jq -r .line |& less -KR
  fi
fi