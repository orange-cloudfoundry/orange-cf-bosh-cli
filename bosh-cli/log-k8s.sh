#!/bin/bash
#===========================================================================
# Log to kubernetes clusters for clis (kubectl, helm, k9s)
#===========================================================================

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

#--- Get k8s cluster configuration from credhub
getClusterConfiguration() {
  credhub g -n /kubeconfigs/${K8S_CLUSTER} -j 2> /dev/null | jq -r '.value' > ${KUBECONFIG}
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
}

#--- Select k8s cluster
selectCluster() {
  case "$1" in
    "1") K8S_TYPE_CLUSTER="k3s" ; K8S_CLUSTER="00-core-connectivity-k8s" ; K8S_CONTEXT="core-connectivity" ;;
    "2") K8S_TYPE_CLUSTER="k3s" ; K8S_CLUSTER="01-ci-k8s" ; K8S_CONTEXT="ci-k8s" ;;
    "3") K8S_TYPE_CLUSTER="k3s" ; K8S_CLUSTER="00-gitops-management" ; K8S_CONTEXT="gitops-management" ;;
    "4") K8S_TYPE_CLUSTER="k3s" ; K8S_CLUSTER="00-supervision" ; K8S_CONTEXT="supervision" ;;
    "5") K8S_TYPE_CLUSTER="k3s" ; K8S_CLUSTER="00-marketplace" ; K8S_CONTEXT="marketplace" ;;
    "6") K8S_TYPE_CLUSTER="k3s" ; K8S_CLUSTER="00-shared-services" ; K8S_CONTEXT="shared-services" ;;
    "7") K8S_TYPE_CLUSTER="k3s" ; K8S_CLUSTER="k3s-sandbox" ; K8S_CONTEXT="sandbox" ;;
    "8") K8S_TYPE_CLUSTER="openshift" ; K8S_CLUSTER="openshift-gcp" ; K8S_CONTEXT="openshift-gcp" ; CREDHUB_ENDPOINT="/secrets/external/gcp_poc_openshift_cluster_api_url" ;;
    *) flag=0 ; clear ;;
  esac
}

#--- Log to credhub
flagError=0
flag=$(credhub f > /dev/null 2>&1)
if [ $? != 0 ] ; then
  printf "\n%bLDAP user and password :%b\n" "${REVERSE}${GREEN}" "${STD}"
  printf "username: " ; read LDAP_USER
  credhub login --server=https://credhub.internal.paas:8844 -u ${LDAP_USER}
  if [ $? != 0 ] ; then
    printf "\n%bERROR : LDAP authentication failed with \"${LDAP_USER}\" account.%b\n" "${RED}" "${STD}" ; flagError=1
  fi
fi

#--- Create k8s configration directory
if [ ! -d ${HOME}/.kube ] ; then
  mkdir ${HOME}/.kube > /dev/null 2>&1
fi

#--- Log to k8s
if [ ${flagError} = 0 ] ; then
  #--- Get all k3s clusters configuration
  TARGET_KUBECONFIG=""
  clear
  printf "\n%bGet clusters properties...%b\n" "${YELLOW}${REVERSE}" "${STD}"
  if [ "${SITE_NAME}" = "fe-int" ] ; then
    MAX_ITEMS=8
  else
    MAX_ITEMS=6
  fi

  for value in $(seq 1 ${MAX_ITEMS}) ; do
    selectCluster "${value}"
    if [ "${K8S_TYPE_CLUSTER}" = "k3s" ] ; then
      export KUBECONFIG="${HOME}/.kube/${K8S_CONTEXT}.yml"
      getClusterConfiguration
    fi
  done

  #--- Install svcat plugin (need to unset KUBECONFIG for using default path ${HOME}/.kube)
  unset KUBECONFIG
  svcat install plugin > /dev/null 2>&1

  #--- Select kubernetes cluster to work with
  flag=0
  while [ ${flag} = 0 ] ; do
    flag=1
    printf "\n%bKubernetes cluster :%b\n\n" "${REVERSE}${GREEN}" "${STD}"
    printf "%b1%b : core connectivity\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b2%b : ci\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b3%b : gitops management\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b4%b : supervision\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b5%b : marketplace\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b6%b : shared services\n" "${GREEN}${BOLD}" "${STD}"
    if [ "${SITE_NAME}" = "fe-int" ] ; then
      printf "%b7%b : sandbox\n" "${GREEN}${BOLD}" "${STD}"
      printf "%b8%b : openshift gcp\n" "${GREEN}${BOLD}" "${STD}"
    fi
    printf "\n%bYour choice :%b " "${GREEN}${BOLD}" "${STD}" ; read choice
    selectCluster "${choice}"
  done

  #--- Concatenate clusters config files and set current context
  export KUBECONFIG="${HOME}/.kube/${K8S_CONTEXT}.yml"
  if [ "${K8S_TYPE_CLUSTER}" = "k3s" ] ; then
    if [ ! -f ${KUBECONFIG} ] ; then
      printf "\n%bERROR : No configuration file for \"${K8S_CLUSTER}\" cluster.%b\n" "${RED}" "${STD}" ; flagError=1
    fi
  fi

  if [ ${flagError} = 0 ] ; then
    #--- Concatenate all clusters config files
    export KUBECONFIG="$(echo "${TARGET_KUBECONFIG}" | sed -e "s+^:++")"
    kubectl config view --flatten > ${HOME}/.kube/config
    export KUBECONFIG="${HOME}/.kube/config"

    #--- Connect to cluster
    if [ "${K8S_TYPE_CLUSTER}" = "openshift" ] ; then
      proxyStatus="$(env | grep "https_proxy" | grep "internet")"
      if [ "${proxyStatus}" = "" ] ; then
        printf "\n%bERROR : You need to set internet proxy to use \"${K8S_CLUSTER}\" cluster.%b\n" "${RED}" "${STD}" ; flagError=1
      else
        #--- Connect to openshift cluster
        OC_ENDPOINT="$(credhub g -n ${CREDHUB_ENDPOINT} -j 2> /dev/null | jq -r '.value')"
        message="$(oc login --server=${OC_ENDPOINT})"
        printf "\n%b${message}%b " "${YELLOW}${BOLD}" "${STD}"
        printf "\n%bOpenshift API token :%b " "${GREEN}${BOLD}" "${STD}" ; read -s API_TOKEN
        oc login --token=${API_TOKEN} --server=${OC_ENDPOINT} > /dev/null 2>&1
        flagError=$?
        if [ ${flagError} != 0 ] ; then
          printf "\n%bERROR : Invalid token \"${API_TOKEN}\".\n${message}\n%b" "${RED}" "${STD}"
        fi

        #--- Rename cluster context
        current_context="$(kubectl ctx -c)"
        kubectl config rename-context ${current_context} ${K8S_CONTEXT} > /dev/null 2>&1
      fi
    else
      #--- Set context to use for selected k3s cluster
      kubectl config use-context ${K8S_CONTEXT} > /dev/null 2>&1
      flagError=$?
      if [ ${flagError} != 0 ] ; then
        printf "\n%bERROR : Unable to set context for \"${K8S_CLUSTER}\" cluster.%b\n" "${RED}" "${STD}"
      fi
    fi

    if [ ${flagError} = 0 ] ; then
      #--- Install svcat auto-completion
      source <(svcat completion bash)
      printf "\n\n%bCluster \"${K8S_CONTEXT}\" available.%b\n" "${YELLOW}${REVERSE}" "${STD}"
    fi
  fi
fi