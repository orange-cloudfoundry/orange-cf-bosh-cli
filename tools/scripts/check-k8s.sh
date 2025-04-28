#!/bin/bash
#===========================================================================
# Check k8s clusters (uses kubeconfig to select clusters to check)
#===========================================================================

#--- Check cluster resources in error
checkClusterResources() {
  context="$1"
  kubectx ${context} > /dev/null 2>&1
  printf "\n%b\"${context}\" suspended/failed resources...%b\n" "${REVERSE}${YELLOW}" "${STD}"

  #--- Check nodes
  result="$(kubectl get nodes -A --context ${context} --request-timeout=1s --no-headers=true 2>&1)"
  flagTimeout="$(echo "${result}" | grep -E "Unable to connect to the server|E0[0-9]*")"
  if [ "${flagTimeout}" != "" ] ; then
    printf "\n%bCluster \"${context}\" not available or needs credentials to be accessed...%b\n" "${RED}" "${STD}"
  else
    result="$(echo "${result}" | grep -v " Ready " | awk '{print $2" "$1}' | sort)"
    if [ "${result}" != "" ] ; then
      printf "\n%bSTATUS NODE%b\n${result}\n" "${GREEN}" "${STD}" | column -t
    fi

    #--- Check pvcs
    result="$(kubectl get pvc -A --no-headers=true 2>&1 | grep -vE "Bound|No resources found" | awk '{print $3" "$4" "$1"/"$2}' | sort)"
    if [ "${result}" != "" ] ; then
      printf "\n%bSTATUS PVC NAMESPACE/POD%b\n${result}\n" "${GREEN}" "${STD}" | column -t
    fi

    #--- Check pvs
    result="$(kubectl get pv -A --no-headers=true 2>&1 | grep -vE "Bound|No resources found" | awk '{print $5" "$1" "$6}' | sort)"
    if [ "${result}" != "" ] ; then
      printf "\n%bSTATUS PV NAMESPACE/POD%b\n${result}\n" "${GREEN}" "${STD}" | column -t
    fi

    #--- Check longhorn volumes attachment
    result="$(kubectl get volumes.longhorn.io -n 02-longhorn -o json 2>&1)"
    if [ $? = 0 ] ; then
      result="$(echo "${result}" | jq -r '.items[]|.status.state + "/" + .status.robustness + " " + .metadata.name + " " + (.spec.nodeID // "" | if . == "" then "-" end) + "/" + .metadata.namespace + "/" + .status.kubernetesStatus.workloadsStatus[].podName' | grep -v "attached/healthy" | awk '{print $1" "$2" "$3" "$4}')"
      if [ "${result}" != "" ] ; then
        printf "\n%bSTATUS PVC NODE/NAMESPACE/POD%b\n${result}\n" "${GREEN}" "${STD}" | column -t
      fi
    fi

    #--- Check suspended/not ready flux resources (kustomization, helmchart, helmrelease, helmrepository, gitrepository)
    failed_suspended_resources="$(flux get all -A --context ${context} | tr -s '\t' ' ' | grep -E "kustomization/|helmchart/|helmrelease/|helmrepository/|gitrepository/" | grep -E " False | True | Unknown " | sed -e "s+ +|+" | sed -E "s+ (False|True|Unknown) (False|True|Unknown)(.*)+|\1 \2+" | sed -e "s+ .*|+|+" -e "s+|+ +g" | awk '{
      namespace=$1 ; kind=$2 ; gsub("/.*", "", kind) ; name=$2 ; gsub(".*/", "", name) ; suspended=$3 ; ready=$4
      if (suspended == "True" || ready == "False") {print ready" "suspended" "kind" "namespace"/"name}
    }')"

    if [ "${failed_suspended_resources}" != "" ] ; then
      printf "\n%bREADY SUSP. KIND NAMESPACE/NAME%b\n${failed_suspended_resources}\n" "${GREEN}" "${STD}" | column -t
    fi

    #--- Check drift events on helmreleases
    result=""
    drifted_helmReleases="$(kubectl events -A --types=Warning --no-headers=true | grep " DriftDetected *HelmRelease" | sed -e "s+.* state of release ++g" -e "s+ .*++g" -e "s+\.v.*++g" | sort)"
    if [ "${drifted_helmReleases}" != "" ] ; then
      #--- Check if HelmRelease status is failed/suspended
      for helmrelease in ${drifted_helmReleases} ; do
        status="$(echo "${failed_suspended_resources}" | grep "helmrelease" | grep "${helmrelease}")"
        if [ "${status}" != "" ] ; then
          result="${result}\nDriftDetected ${helmrelease}"
        fi
      done

      if [ "${result}" != "" ] ; then
        printf "\n%bSTATUS KIND%b\n${result}\n" "${GREEN}" "${STD}" | column -t
      fi
    fi

    #--- Check pending services
    pending_services="$(kubectl get svc -A --context ${context} --request-timeout=1s --no-headers=true 2>&1 | grep " LoadBalancer " | grep -E "<none>|<pending>" | awk '{print $1"/"$2}')"
    if [ "${pending_services}" != "" ] ; then
      printf "\n%bPending services%b" "${GREEN}" "${STD}"
      printf "\n${pending_services}\n" "${GREEN}" "${STD}" | column -t
    fi

    #--- Check pods (except vcluster ones)
     failed_pods="$(kubectl get pods -A -o wide -l 'vcluster.loft.sh/managed-by notin (vcluster)' --context ${context} --no-headers=true | grep -vE "Completed|ContainerCreating|Terminating" | sed -e "s+(.*)++g" | awk '{ready=$3;gsub("/.*","",ready);total=$3;gsub(".*/","",total);if(ready != total){print $4" "$3" "$1"/"$2" "$8}}' | sort)"
    if [ "${failed_pods}" != "" ] ; then
      printf "\n%bSTATUS READY NAMESPACE/POD NODE%b\n${failed_pods}\n" "${GREEN}" "${STD}" | column -t
    fi

    #--- Get custom resources definitions with existing "deletionTimestamp"
    result="$(kubectl get crds -o json 2>/dev/null | jq -r '.items[]?.metadata|select(.deletionTimestamp != null)|.name')"
    if [ "${result}" != "" ] ; then
      printf "\n%bCustom resources definitions with \"deletionTimestamp\"%b" "${GREEN}" "${STD}"
      printf "\n${result}\n" "${GREEN}" "${STD}" | column -t
    fi
  fi
}

#===================================================================================
#--- Check k8s cluster status
#===================================================================================
#--- Get clusters contexts (exclude virtual clusters with limited access)
unset https_proxy http_proxy no_proxy
current_context="$(kubectx -c 2> /dev/null)"
export KUBECONFIG="${HOME}/.kube/config"
contexts="$(kubectl config view -o json | jq -r ".contexts[].name" | grep -v "sm-consumer-")"
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

#--- Set inital context
if [ "${current_context}" != "" ] ; then
  kubectx ${current_context} > /dev/null 2>&1
fi
