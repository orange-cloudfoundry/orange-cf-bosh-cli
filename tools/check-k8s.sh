#!/bin/bash
#===========================================================================
# Check k8s clusters (uses kubeconfig to select clusters to check)
#===========================================================================

#--- Check cluster resources in error
checkClusterResources() {
  context="$1"
  printf "\n%b\"${context}\" suspended/failed resources...%b\n" "${REVERSE}${YELLOW}" "${STD}"

  #--- Check nodes
  result="$(kubectl get nodes -A --context ${context} --request-timeout=1s --no-headers=true 2>&1)"
  flagTimeout="$(echo "${result}" | grep "Unable to connect to the server")"
  if [ "${flagTimeout}" != "" ] ; then
    printf "\n%bCluster \"${context}\" not available...%b\n" "${RED}" "${STD}"
  else
    result="$(echo "${result}" | grep -v "Ready" | awk '{printf "%-18s %s\n", $2, $1}' | sort)"
    if [ "${result}" != "" ] ; then
      printf "\n%bSTATUS             NODE                                                                                        %b\n${result}\n" "${GREEN}" "${STD}"
    fi

    #--- Check pods
    result="$(kubectl get pods -A --context ${context} --no-headers=true | grep -vE "Running|Completed|ContainerCreating|Terminating" | awk '{printf "%-32s %-6s %s\n", $4, $3, $1"/"$2}' | sort)"
    if [ "${result}" != "" ] ; then
      printf "\n%bSTATUS                           READY  POD                                                                                  %b\n${result}\n" "${GREEN}" "${STD}"
    fi

    #--- Check suspended/not ready flux resources (kustomization, helmchart, helmrelease, helmrepository, gitrepository)
    result="$(flux get all -A --context ${context} | tr -s '\t' ' ' | grep -E "kustomization/|helmchart/|helmrelease/|helmrepository/|gitrepository/" | grep -E " False | True | Unknown " | sed -e "s+ +|+" | sed -E "s+ (False|True|Unknown) (False|True|Unknown)(.*)+|\1 \2+" | sed -e "s+ .*|+|+" -e "s+|+ +g" | awk '{
      namespace=$1
      kind=$2 ; gsub("/.*", "", kind)
      name=$2 ; gsub(".*/", "", name)
      suspended=$3
      ready=$4
      if (suspended == "True" || ready == "False" || ready == "Unknown") {
        printf "%-8s %-6s %-16s %s \n", ready, suspended, kind, namespace"/"name
      }
    }')"

    if [ "${result}" != "" ] ; then
      printf "\n%bREADY    SUSP.  KIND             NAMESPACE/NAME                                                                  %b\n${result}\n" "${GREEN}" "${STD}"
    fi

    #--- Check pending services
    pending_services="$(kubectl get svc -A --context ${context} --request-timeout=1s --no-headers=true 2>&1 | grep " LoadBalancer " | grep -E "<none>|<pending>" | awk '{print $1"/"$2}')"
    if [ "${pending_services}" != "" ] ; then
      printf "\n%bK8S pending services%b\n${pending_services}\n" "${GREEN}" "${STD}"
    fi
  fi
}

#===================================================================================
#--- Check k8s cluster status
#===================================================================================
unset https_proxy http_proxy no_proxy
export KUBECONFIG="${HOME}/.kube/config"
contexts="$(kubectl config view -o json | jq -r ".contexts[].name")"
display_contexts="$(echo "${contexts}" | sort | pr -3t -W 130)"

if [ "$1" = "" ] ; then
  printf "\n%bSelect a cluster :%b\n${display_contexts}" "${REVERSE}${GREEN}" "${STD}"
  printf "\n\n%bYour choice (<Enter> to select all) :%b " "${GREEN}${BOLD}" "${STD}" ; read context
else
  flagCtx="$(echo "${contexts}" | grep "^$1$")"
  if [ "${flagCtx}" = "" ] ; then
    printf "\n%bCluster \"$1\" unknown...%b\n" "${RED}" "${STD}" ; exit 1
  else
    context="$1"
  fi
fi

if [ "${context}" = "" ] ; then
  for ctx in ${contexts} ; do
    checkClusterResources "${ctx}"
  done
else
  checkClusterResources "${context}"
fi
