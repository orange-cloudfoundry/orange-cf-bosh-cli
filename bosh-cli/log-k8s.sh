#!/bin/bash
#===========================================================================
# Log to kubernetes clusters for clis (kubectl, helm, k9s)
#===========================================================================

#--- Update value form yaml file propertie
updateYaml() {
  yaml_file="$1"
  key_path="$2"
  key_value="$3"
  new_file="$1.tmp"

  if [ ! -s ${yaml_file} ] ; then
    printf "\n%bERROR : File \"${yaml_file}\" unknown.%b\n\n" "${RED}" "${STD}" ; flagError=1
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
      printf "\n%bERROR: Unknown key [${key_path}] in file \"${yaml_file}\".%b\n\n" "${RED}" "${STD}" ; flagError=1
    else
      cp ${new_file} ${yaml_file}
    fi
    rm -f ${new_file} > /dev/null 2>&1
    chmod 600 ${yaml_file} > /dev/null 2>&1
  fi
}

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

if [ ! -d ${HOME}/.kube ] ; then
  mkdir ${HOME}/.kube > /dev/null 2>&1
fi

#--- Log to K8S
if [ ${flagError} = 0 ] ; then
  #--- Select kubernetes cluster
  flag=0
  while [ ${flag} = 0 ] ; do
    flag=1
    printf "\n%bKubernetes cluster :%b\n\n" "${REVERSE}${GREEN}" "${STD}"
    printf "%b1%b : k3s core connectivity\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b2%b : k3s ci\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b3%b : k3s gitops management\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b4%b : k3s rundeck\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b5%b : k3s services\n" "${GREEN}${BOLD}" "${STD}"
    if [ "${SITE_NAME}" = "fe-int" ] ; then
      printf "%b6%b : k3s logs\n" "${GREEN}${BOLD}" "${STD}"
      printf "%b7%b : k3s sandbox\n" "${GREEN}${BOLD}" "${STD}"
    fi
    printf "\n%bYour choice :%b " "${GREEN}${BOLD}" "${STD}" ; read choice
    case "${choice}" in
      1) K8S_TYPE="k3s" ; K8S_DIRECTOR="micro-bosh" ; BOSH_K8S_DEPLOYMENT="00-core-connectivity-k8s" ; K8S_CLUSTER="core-connectivity" ;;
      2) K8S_TYPE="k3s" ; K8S_DIRECTOR="micro-bosh" ; BOSH_K8S_DEPLOYMENT="01-ci-k8s" ; K8S_CLUSTER="ci" ;;
      3) K8S_TYPE="k3s" ; K8S_DIRECTOR="micro-bosh" ; BOSH_K8S_DEPLOYMENT="00-gitops-management" ; K8S_CLUSTER="gitops-management" ;;
      4) K8S_TYPE="k3s" ; K8S_DIRECTOR="bosh-master" ; BOSH_K8S_DEPLOYMENT="rundeck" ; K8S_CLUSTER="rundeck" ;;
      5) K8S_TYPE="k3s" ; K8S_DIRECTOR="bosh-coab" ; BOSH_K8S_DEPLOYMENT="00-k3s-serv" ; K8S_CLUSTER="k3s-serv" ;;
      6) K8S_TYPE="k3s" ; K8S_DIRECTOR="bosh-master" ; BOSH_K8S_DEPLOYMENT="00-logs-ops" ; K8S_CLUSTER="logs-ops" ;;
      7) K8S_TYPE="k3s" ; K8S_DIRECTOR="bosh-master" ; BOSH_K8S_DEPLOYMENT="k3s-sandbox" ; K8S_CLUSTER="sandbox" ;;
      *) flag=0 ; clear ;;
    esac
  done

  if [ "${K8S_TYPE}" = "k8s" ] ; then
    #--- Check if bosh dns exists
    K8S_API_ENDPOINT="${K8S_CLUSTER}-api.internal.paas"
    flag_host="$(host ${K8S_API_ENDPOINT} | awk '{print $4}')"
    if [ "${flag_host}" = "found:" ] ; then
      printf "\n%bERROR : Kubernetes cluster endpoint \"${K8S_API_ENDPOINT}\" unknown (no dns record).%b\n\n" "${RED}" "${STD}" ; flagError=1
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
      updateYaml "${KUBECONFIG}" "clusters.name" "${K8S_CLUSTER}"
      updateYaml "${KUBECONFIG}" "contexts.context.cluster" "${K8S_CLUSTER}"
    fi
  fi
fi

if [ ${flagError} = 0 ] ; then
  #--- Install svcat plugin and auto-completion (need to unset KUBECONFIG for using default path ${HOME}/.kube)
  svcat install plugin > /dev/null 2>&1
  source <(svcat completion bash)

  #--- Display admin token (used for web ui portals)
  admin_token_name="$(kubectl -n kube-system get secret | grep admin | awk '{print $1}')"
  if [ "${admin_token_name}" = "" ] ; then
    printf "\n%bk8s token:%b\nNo \"admin\" token available for cluster \"${K8S_CLUSTER}\".\n" "${YELLOW}${REVERSE}" "${STD}"
  else
    token="$(kubectl -n kube-system describe secret ${admin_token_name} | grep "token:" | sed -e "s+token: *++g")"
    printf "\n%bk8s token:%b\n${token}\n" "${YELLOW}${REVERSE}" "${STD}"
  fi

  #--- Display cluster nodes
  printf "\n%bCluster namespaces:%b\n" "${YELLOW}${REVERSE}" "${STD}"
  kubectl get namespaces
fi