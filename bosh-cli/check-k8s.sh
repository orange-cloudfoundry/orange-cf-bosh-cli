#!/bin/bash
#===========================================================================
# Check k8s clusters (uses kubeconfig to select clusters to check)
#===========================================================================

#--- Check cluster resources in error
checkClusterResources() {
  context="$1"
  printf "\n%b\"${context}\" suspended/failed resources...%b\n" "${REVERSE}${YELLOW}" "${STD}"

  #--- Check not ready nodes
  result="$(kubectl get nodes -A --context ${context} --request-timeout=1s --no-headers=true 2>&1)"
  flagTimeout="$(echo "${result}" | grep "Unable to connect to the server")"
  if [ "${flagTimeout}" != "" ] ; then
    printf "\n%bCluster \"${context}\" not available...%b\n" "${RED}" "${STD}"
  else
    result="$(echo "${result}" | grep -v "Ready" | awk '{printf "%-18s %s\n", $2, $1}' | sort)"
    if [ "${result}" != "" ] ; then
      printf "\n%bSTATUS             NODE                                                                                        %b\n${result}\n" "${REVERSE}${GREEN}" "${STD}"
    fi

    #--- Check pods
    result="$(kubectl get pods -A --context ${context} --no-headers=true | grep -vE "Running|Completed" | awk '{printf "%-18s %-6s %s\n", $4, $3, $1"/"$2}' | sort)"
    if [ "${result}" != "" ] ; then
      printf "\n%bSTATUS             READY  POD                                                                                  %b\n${result}\n" "${REVERSE}${GREEN}" "${STD}"
    fi

    #--- Check suspended/not ready flux resources (kustomization, helmchart, helmrelease, helmrepository, gitrepository)
    result="$(flux get all -A --context ${context} | awk '{print $1 " " $2 " " $3 " " $4 " " $5}' | grep -E " False | True " | awk '{
      if ($3 == "False" || $3 == "True") {
        if($4 == "False" || $4 == "True") {ts=$3 ; tr=$4} else {ts="False" ; tr=$3}
      } else {ts=$4 ; tr=$5}

      if (ts == "True" || tr == "False") {
        k=$2 ; gsub("/.*", "", k) ; n=$2 ; gsub(".*/", "", n)
        printf "%-6s %-6s %-16s %s \n", tr, ts, k, $1"/"n
      }
    }')"

    if [ "${result}" != "" ] ; then
      printf "\n%bREADY  SUSP.  KIND             NAMESPACE/NAME                                                                  %b\n${result}\n" "${REVERSE}${GREEN}" "${STD}"
    fi
  fi
}

#===================================================================================
#--- Check k8s cluster status
#===================================================================================
unset https_proxy http_proxy no_proxy
export KUBECONFIG="${HOME}/.kube/config"
CLUSTER_CTX="$(kubectl config view -o json | jq -r ".contexts[].name")"
printf "\n%bSelect a k8s context :%b\n${CLUSTER_CTX}" "${REVERSE}${GREEN}" "${STD}"
printf "\n\n%bYour choice (<Enter> to select all) :%b " "${GREEN}${BOLD}" "${STD}" ; read choice

if [ "${choice}" = "" ] ; then
  for ctx in ${CLUSTER_CTX} ; do
    checkClusterResources "${ctx}"
  done
else
  checkClusterResources "${choice}"
fi
