#!/bin/bash
#===========================================================================
# Log to kubernetes clusters for clis (kubectl, helm, k9s)
# Parameters :
# --context, -c  : Select k8s context
# --proxy, -p    : Set proxy
#===========================================================================

#--- Check scripts options
flagError=0 ; PROXY_MODE=0 ; context="" ; nbParameters=$#
usage() {
  printf "\n%bUSAGE:" "${RED}"
  printf "\n  log-k8s [OPTIONS]\n\nOPTIONS:"
  printf "\n  %-40s %s" "--context, -c \"cluster context name\"" "Set k8s cluster context"
  printf "\n  %-40s %s" "--proxy, -p " "Set proxy in kubeconfig"
  printf "%b\n\n" "${STD}" ; flagError=1
}

#--- Update propertie value from KUBECONFIG file
updateKubeConfig() {
  key_path="$1"
  key_value="$2"
  yaml_file="${KUBECONFIG}"
  new_file="${KUBECONFIG}.tmp"

  if [ ! -s ${yaml_file} ] ; then
    printf "\n%bERROR : File \"${yaml_file}\" unknown.%b\n" "${RED}" "${STD}" ; flagError=1
  else
    > ${new_file}
    awk -v new_file="${new_file}" -v refpath="${key_path}" -v value="${key_value}" 'BEGIN {nb = split(refpath, path, ".") ; level = 1 ; flag = 0 ; string = ""}
    {
      line = $0
      currentLine = $0 ; gsub("^ *", "", currentLine) ; gsub("^ *- *", "", currentLine)
      key = path[level]":"
      if (index(currentLine, key) == 1) {
        if(level == nb) {
          level = level + 1 ; path[level] = "@" ; flag = 1
          sub("^ *", "", value) ; sub(" *$", "", value)
          gsub(":.*", ": "value, line)
        }
        else {level = level + 1}
        string = string "\n" line
      }
      printf("%s\n", line) >> new_file
    }
    END {if(flag == 0){exit 1}}' ${yaml_file}

    if [ $? != 0 ] ; then
      printf "\n%bERROR: Unknown key [${key_path}] in file \"${yaml_file}\".%b\n" "${RED}" "${STD}" ; flagError=1
    else
      cp ${new_file} ${yaml_file}
    fi
    rm -f ${new_file} > /dev/null 2>&1
    chmod 600 ${yaml_file} > /dev/null 2>&1
  fi
}

#--- Check scripts options
while [ ${nbParameters} -gt 0 ] ; do
  case "$1" in
    "-c"|"--context")
      if [ "$2" = "" ] ; then
        usage ; nbParameters=0
      else
        context="$2" ; shift ; shift ; nbParameters=$#
      fi ;;
    "-p"|"--proxy") PROXY_MODE=1 ; shift ; nbParameters=$# ;;
    *) usage ; nbParameters=0 ;;
  esac
done

#--- Log to credhub
if [ ${flagError} = 0 ] ; then
  #--- Create k8s configration directory
  if [ ! -d ${HOME}/.kube ] ; then
    mkdir ${HOME}/.kube > /dev/null 2>&1
  fi

  #--- Log to credhub
  flag=$(credhub f > /dev/null 2>&1)
  if [ $? != 0 ] ; then
    printf "\n%bLDAP user and password :%b\n" "${REVERSE}${GREEN}" "${STD}"
    printf "username: " ; read LDAP_USER
    credhub login --server=https://credhub.internal.paas:8844 -u ${LDAP_USER}
    if [ $? != 0 ] ; then
      printf "\n%bERROR : LDAP authentication failed with \"${LDAP_USER}\" account.%b\n" "${RED}" "${STD}" ; flagError=1
    fi
  fi
fi

#--- Generate kubeconfig files for all clusters
if [ ${flagError} = 0 ] ; then
  clear
  printf "\n%bGet clusters properties...%b\n" "${YELLOW}${REVERSE}" "${STD}"

  #--- Get clusters list
  TARGET_KUBECONFIG="" ; K8S_CONTEXTS=""
  cluster_paths="$(credhub f | grep -E "name: /kubeconfigs/|name: /secrets/kubeconfigs/" | awk '{print $3}' | sort)"

  for path in ${cluster_paths} ; do
    K8S_CLUSTER="$(echo "${path}" | sed -e "s+.*kubeconfigs\/++")"
    K8S_CONTEXT="$(echo "${path}" | sed -e "s+.*kubeconfigs\/++" -e "s+-k8s++" -e "s+00-++")"
    K8S_CONTEXTS="${K8S_CONTEXTS} ${K8S_CONTEXT}"
    export KUBECONFIG="${HOME}/.kube/${K8S_CONTEXT}.yml"

    #--- Get k8s cluster configuration from credhub
    credhub g -n ${path} -j 2> /dev/null | jq -r '.value' > ${KUBECONFIG}
    if [ -s ${KUBECONFIG} ] ; then
      updateKubeConfig "clusters.name" "${K8S_CLUSTER}"
      updateKubeConfig "contexts.context.cluster" "${K8S_CLUSTER}"
      updateKubeConfig "contexts.name" "${K8S_CONTEXT}"
      updateKubeConfig "users.name" "${K8S_CONTEXT}"
      updateKubeConfig "contexts.context.user" "${K8S_CONTEXT}"
      updateKubeConfig "current-context" "${K8S_CONTEXT}"
      TARGET_KUBECONFIG="${TARGET_KUBECONFIG}:${KUBECONFIG}"
    else
      rm -f ${KUBECONFIG} > /dev/null 2>&1
    fi
  done

  K8S_CONTEXTS="$(echo "${K8S_CONTEXTS}" | sed -e "s+^ ++" | tr " " "\n")"

  #--- Concatenate all clusters config files
  export KUBECONFIG="$(echo "${TARGET_KUBECONFIG}" | sed -e "s+^:++")"
  kubectl config view --flatten > ${HOME}/.kube/config
  export KUBECONFIG="${HOME}/.kube/config"

  #--- Add proxy-url config if select option
  if [ ${PROXY_MODE} = 1 ] ; then
    sed -i "/^    server: .*/i \ \ \ \ proxy-url: http://localhost:8888" ${KUBECONFIG}
    printf "\n%b\"${KUBECONFIG}\" clusters configuration file with proxy available.%b\n" "${YELLOW}${REVERSE}" "${STD}" ; flagError=1
  fi
fi

#--- Select a cluster
if [ ${flagError} = 0 ] ; then
  export KUBECONFIG="${HOME}/.kube/config"

  if [ "${context}" = "" ] ; then
    contexts="$(kubectl config view -o json | jq -r ".contexts[].name" | sort | pr -3t -W 130)"
    printf "\n%bSelect a cluster :%b\n%s" "${REVERSE}${GREEN}" "${STD}" "${contexts}"
    printf "\n\n%bYour choice (<Enter> to select none) :%b " "${GREEN}${BOLD}" "${STD}" ; read context
  fi

  if [ "${context}" != "" ] ; then
    check_selected="$(echo "${K8S_CONTEXTS}" | grep "^${context}$")"
    if [ "${check_selected}" = "" ] ; then
      printf "\n%bERROR : Cluster \"${context}\" unknown...%b\n" "${RED}" "${STD}"
    else
      kctx ${context}
    fi
  fi
fi
