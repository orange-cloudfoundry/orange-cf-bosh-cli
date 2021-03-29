#!/bin/bash
#===========================================================================
# Log to kubernetes clusters for clis (kubectl, helm, k9s)
#===========================================================================

#--- Log to bosh director
logToBosh() {
  case "$1" in
    "micro-bosh") director_dns_name="bosh-micro" ; credhub_bosh_password="/secrets/bosh_admin_password" ;;
    "bosh-master") director_dns_name="$1" ; credhub_bosh_password="/micro-bosh/$1/admin_password" ;;
    *) director_dns_name="$1" ; credhub_bosh_password="/bosh-master/$1/admin_password" ;;
  esac
  export BOSH_ENVIRONMENT=$(host ${director_dns_name}.internal.paas | awk '{print $4}')
  flag=$(credhub f | grep "${credhub_bosh_password}")
  if [ "${flag}" = "" ] ; then
    printf "\n%bERROR: bosh director \"$1\" password unknown.%b\n\n" "${REVERSE}${RED}" "${STD}" ; flagError=1
  else
    export BOSH_CLIENT_SECRET="$(credhub g -n ${credhub_bosh_password} -j | jq -r '.value')"
    bosh alias-env $1 > /dev/null 2>&1
    bosh logout > /dev/null 2>&1
    bosh -n log-in > /dev/null 2>&1
    if [ $? = 1 ] ; then
      printf "\n%bERROR: Log to \"$1\" director failed.%b\n\n" "${REVERSE}${RED}" "${STD}" ; flagError=1
    fi
  fi
}

#--- Log to credhub
flagError=0
flag=$(credhub f > /dev/null 2>&1)
if [ $? != 0 ] ; then
  printf "\n%bLDAP user and password :%b\n" "${REVERSE}${GREEN}" "${STD}"
  printf "username: " ; read LDAP_USER
  credhub login --server=https://credhub.internal.paas:8844 -u ${LDAP_USER}
  if [ $? != 0 ] ; then
    printf "\n%bERROR : LDAP authentication failed with \"${LDAP_USER}\" account.%b\n\n" "${RED}" "${STD}" ; flagError=1
  fi
fi

#--- Log to K8S
if [ ${flagError} = 0 ] ; then
  #--- Install svcat plugin and auto-completion for kubectl (need to unset KUBECONFIG for using default path ${HOME}/.kube)
  unset KUBECONFIG
  svcat install plugin > /dev/null 2>&1
  source <(svcat completion bash)

  #--- Select kubernetes cluster
  flag=0
  while [ ${flag} = 0 ] ; do
    flag=1
    printf "\n%bKubernetes cluster :%b\n\n" "${REVERSE}${GREEN}" "${STD}"
    printf "%b1%b  : k3s core connectivity\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b2%b  : k3s ci\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b3%b  : k3s gitops management\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b4%b  : k3s rundeck\n" "${GREEN}${BOLD}" "${STD}"
    if [ "${SITE_NAME}" = "fe-int" ] ; then
      printf "%b5%b  : k3s logs\n" "${GREEN}${BOLD}" "${STD}"
      printf "%b6%b  : k3s sandbox\n" "${GREEN}${BOLD}" "${STD}"
    fi
    printf "%b10%b : k8s services\n" "${GREEN}${BOLD}" "${STD}"
    printf "\n%bYour choice :%b " "${GREEN}${BOLD}" "${STD}" ; read choice
    case "${choice}" in
      1) K8S_TYPE="k3s" ; K8S_DIRECTOR="micro-bosh" ; BOSH_K8S_DEPLOYMENT="00-core-connectivity-k8s" ; K8S_CLUSTER="core-connectivity" ;;
      2) K8S_TYPE="k3s" ; K8S_DIRECTOR="micro-bosh" ; BOSH_K8S_DEPLOYMENT="01-ci-k8s" ; K8S_CLUSTER="ci" ;;
      3) K8S_TYPE="k3s" ; K8S_DIRECTOR="micro-bosh" ; BOSH_K8S_DEPLOYMENT="00-gitops-management" ; K8S_CLUSTER="gitops-management" ;;
      4) K8S_TYPE="k3s" ; K8S_DIRECTOR="bosh-master" ; BOSH_K8S_DEPLOYMENT="rundeck" ; K8S_CLUSTER="rundeck" ;;
      5) K8S_TYPE="k3s" ; K8S_DIRECTOR="bosh-master" ; BOSH_K8S_DEPLOYMENT="00-logs-ops" ; K8S_CLUSTER="logs-ops" ;;
      6) K8S_TYPE="k3s" ; K8S_DIRECTOR="bosh-master" ; BOSH_K8S_DEPLOYMENT="k3s-sandbox" ; K8S_CLUSTER="sandbox" ;;
      10) K8S_TYPE="k8s" ; K8S_DIRECTOR="bosh-coab" ; BOSH_K8S_DEPLOYMENT="10-k8s" ; K8S_CLUSTER="k8s-serv" ;;
      *) flag=0 ; clear ;;
    esac
  done

  if [ ! -d ${HOME}/.kube ] ; then
    mkdir ${HOME}/.kube > /dev/null 2>&1
  fi

  if [ "${K8S_TYPE}" = "k8s" ] ; then
    #--- Check if bosh dns exists
    K8S_API_ENDPOINT="${K8S_CLUSTER}-api.internal.paas"
    flag_host="$(host ${K8S_API_ENDPOINT} | awk '{print $4}')"
    if [ "${flag_host}" = "found:" ] ; then
      printf "\n\n%bERROR : Kubernetes cluster endpoint \"${K8S_API_ENDPOINT}\" unknown (no dns record).%b\n\n" "${RED}" "${STD}" ; flagError=1
    else
      #--- Set kubernetes configuration
      printf "\n"
      CRT_DIR=${HOME}/.kube/certs
      if [ ! -d ${CRT_DIR} ] ; then
        mkdir ${CRT_DIR} > /dev/null 2>&1
      fi

      bosh int <(credhub get -n "/${K8S_DIRECTOR}/${BOSH_K8S_DEPLOYMENT}/tls-ca" --output-json) --path=/value/ca > ${CRT_DIR}/${K8S_CLUSTER}_ca.pem
      bosh int <(credhub get -n "/${K8S_DIRECTOR}/${BOSH_K8S_DEPLOYMENT}/tls-admin" --output-json) --path=/value/certificate > ${CRT_DIR}/${K8S_CLUSTER}_cert.pem
      bosh int <(credhub get -n "/${K8S_DIRECTOR}/${BOSH_K8S_DEPLOYMENT}/tls-admin" --output-json) --path=/value/private_key > ${CRT_DIR}/${K8S_CLUSTER}_key.pem
      export KUBECONFIG=${HOME}/.kube/config

      kubectl config set-cluster "${K8S_CLUSTER}" --server="https://${K8S_API_ENDPOINT}" --certificate-authority="${CRT_DIR}/${K8S_CLUSTER}_ca.pem" --embed-certs=true > /dev/null 2>&1
      if [ $? != 0 ] ; then
        printf "\n\n%bERROR : Set cluster \"${K8S_CLUSTER}\" configuration failed.%b\n\n" "${RED}" "${STD}" ; flagError=1
      else
        kubectl config set-credentials "admin" --client-key ${CRT_DIR}/${K8S_CLUSTER}_key.pem --client-certificate ${CRT_DIR}/${K8S_CLUSTER}_cert.pem --embed-certs > /dev/null 2>&1
        if [ $? != 0 ] ; then
          printf "\n\n%bERROR : Set cluster \"${K8S_CLUSTER}\" credentials failed.%b\n\n" "${RED}" "${STD}" ; flagError=1
        else
          kubectl config set-context "${K8S_CLUSTER}" --cluster="${K8S_CLUSTER}" --user="admin" > /dev/null 2>&1
          if [ $? != 0 ] ; then
            printf "\n\n%bERROR : Set cluster \"${K8S_CLUSTER}\" context failed.%b\n\n" "${RED}" "${STD}" ; flagError=1
          else
            kubectl config use-context "${K8S_CLUSTER}" > /dev/null 2>&1
          fi
        fi
      fi
    fi
  else
    #--- Get k3s cluster configuration
    export BOSH_CLIENT="admin"
    export BOSH_CA_CERT="/etc/ssl/certs/ca-certificates.crt"
    logToBosh "${K8S_DIRECTOR}"
    if [ ${flagError} = 0 ] ; then
      export KUBECONFIG=${HOME}/.kube/${K8S_CLUSTER}.yml
      instance="$(bosh -d ${BOSH_K8S_DEPLOYMENT} is | grep "server/" | awk '{print $1}')"
      bosh -d ${BOSH_K8S_DEPLOYMENT} scp ${instance}:/var/vcap/store/k3s-server/kubeconfig.yml ${KUBECONFIG} > /dev/null 2>&1
      if [ $? != 0 ] ; then
        printf "\n\n%bERROR : Get cluster configuration failed.%b\n\n" "${RED}" "${STD}" ; flagError=1
      fi
      chmod 600 ${KUBECONFIG} > /dev/null 2>&1
    fi
  fi
fi

#--- Install svcat plugin and auto-completion for kubectl
if [ ${flagError} = 0 ] ; then
  #--- Display admin token (used for web ui portals)
  admin_token_name="$(kubectl -n kube-system get secret | grep admin | awk '{print $1}')"
  if [ "${admin_token_name}" = "" ] ; then
    printf "\n%bk8s token:%b\nNo \"admin\" token available for cluster \"${K8S_CLUSTER}\".\n" "${YELLOW}${REVERSE}" "${STD}"
  else
    token="$(kubectl -n kube-system describe secret ${admin_token_name} | grep "token:" | sed -e "s+token: *++g")"
    printf "\n%bk8s token:%b\n${token}\n" "${YELLOW}${REVERSE}" "${STD}"
  fi

  #--- Display cluster nodes
  printf "\n%bCluster nodes:%b\n" "${YELLOW}${REVERSE}" "${STD}"
  kubectl get nodes
fi