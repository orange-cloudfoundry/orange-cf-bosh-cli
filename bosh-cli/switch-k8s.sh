#!/bin/bash
#===========================================================================
# Switch to kubernetes cluster for clis (kubectl, helm, k9s)
#===========================================================================

#--- Select k8s cluster
selectCluster() {
  case "$1" in
    "1") K8S_DEPLOYMENT="00-core-connectivity-k8s" ; K8S_CLUSTER="core-connectivity" ;;
    "2") K8S_DEPLOYMENT="01-ci-k8s" ; K8S_CLUSTER="ci-k8s" ;;
    "3") K8S_DEPLOYMENT="00-gitops-management" ; K8S_CLUSTER="gitops-management" ;;
    "4") K8S_DEPLOYMENT="00-supervision" ; K8S_CLUSTER="supervision" ;;
    "5") K8S_DEPLOYMENT="00-marketplace" ; K8S_CLUSTER="marketplace" ;;
    "6") K8S_DEPLOYMENT="00-shared-services" ; K8S_CLUSTER="shared-services" ;;
    "7") K8S_DEPLOYMENT="k3s-sandbox" ; K8S_CLUSTER="sandbox" ;;
    *) flag=0 ; clear ;;
  esac
}

#--- Check k8s configration directory
flagError=0
export KUBECONFIG="${HOME}/.kube/config"
if [ ! -f ${KUBECONFIG} ] ; then
  printf "\n%bERROR : \"${KUBECONFIG}\" unknown.\nPlease log-k8s before.%b\n" "${RED}" "${STD}" ; flagError=1
fi

#--- Select kubernetes cluster to work with
if [ ${flagError} = 0 ] ; then
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
    fi
    printf "\n%bYour choice :%b " "${GREEN}${BOLD}" "${STD}" ; read choice
    selectCluster "${choice}"
  done

  #--- Set current context to selected cluster
  kubectl config use-context ${K8S_CLUSTER} > /dev/null 2>&1
  result=$?
  if [ ${result} = 0 ] ; then
    printf "\n%bCluster \"${K8S_CLUSTER}\" namespaces:%b\n" "${YELLOW}${REVERSE}" "${STD}"
    kubectl get namespaces
  else
    printf "\n%bERROR : Cluster \"${K8S_DEPLOYMENT}\" is not available.%b\n" "${RED}" "${STD}"
  fi
fi