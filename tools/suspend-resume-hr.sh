#!/bin/bash
#===========================================================================
# Suspend/resume k9s selected helm release
#===========================================================================

context="$1"
namespace="$2"
name="$3"
LOG_FILE="/tmp/resume-hr-${context}-${namespace}-${name}.log"

#--- Check if helmrelease is suspended
status="$(kubectl get helmreleases --context ${context} --namespace ${namespace} ${name} -o=custom-columns=TYPE:.spec.suspend | tail -1)"
if [ "${status}" = "true" ] ; then
  printf "\n%bResuming \"${name}\" helmrelease in \"${namespace}\" namespace...%b\n" "${REVERSE}${YELLOW}" "${STD}"
  printf "$(date +%H:%M:%S) => Resuming \"${name}\" helmrelease in \"${namespace}\" namespace\n" > ${LOG_FILE}
  nohup flux resume hr ${name} --context ${context} --namespace ${namespace} >> ${LOG_FILE} 2>&1 &
  background_pid="$!"
  tail -f ${LOG_FILE} &
  display_pid="$!"

  #--- Wait 10s for resuming end task
  sleep 5
  check_pid="$(ps ${background_pid} | grep -v "PID")"
  if [ "${check_pid}" != "" ] ; then
    sleep 5
    check_pid="$(ps ${background_pid} | grep -v "PID")"
    if [ "${check_pid}" != "" ] ; then
      printf "\n%bResuming \"${name}\" helmrelease exceeded 10s delay.%b\n" "${REVERSE}${YELLOW}" "${STD}"
      printf "\n%bYou can follow resuming in \"${LOG_FILE}\" file.%b" "${YELLOW}" "${STD}"
    fi
  fi

  kill ${display_pid}
else
  printf "\n%bSuspending \"${name}\" helmrelease in \"${namespace}\" namespace...%b\n" "${REVERSE}${YELLOW}" "${STD}"
  flux suspend hr ${name} --context ${context} --namespace ${namespace}
fi

printf "\n%bPress \"Enter\" to quit...%b " "${YELLOW}" "${STD}" ; read next
