#!/bin/bash
#===========================================================================
# Log with kubernetes cli (kubectl, helm)
#===========================================================================

#--- Get a parameter in credhub
getCredhubValue() {
  value=$(credhub g -n $2 | grep 'value:' | awk '{print $2}')
  if [ "${value}" = "" ] ; then
    printf "\n\n%bERROR : \"$2\" credhub value unknown.%b\n\n" "${RED}" "${STD}" ; flagError=1
  else
    eval "$1=${value}"
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

#--- Log to CF
if [ ${flagError} = 0 ] ; then
  #--- Identify kubernetes cluster
  flag=0
  while [ ${flag} = 0 ] ; do
    flag=1
    printf "\n%bKubernetes cluster :%b\n\n" "${REVERSE}${GREEN}" "${STD}"
    printf "%b1%b : micro\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b2%b : master\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b3%b : services\n" "${GREEN}${BOLD}" "${STD}"
    printf "\n%bYour choice :%b " "${GREEN}${BOLD}" "${STD}" ; read choice
    case "${choice}" in
      1) K8S_DIRECTOR="micro-bosh" ; K8S_DEPLOYMENT="cfcr" ; K8S_CLUSTER="micro" ;;
      2) K8S_DIRECTOR="bosh-master" ; K8S_DEPLOYMENT="cfcr" ; K8S_CLUSTER="master" ;;
      3) K8S_DIRECTOR="bosh-coab" ; K8S_DEPLOYMENT="10-cfcr" ; K8S_CLUSTER="serv" ;;
      *) flag=0 ; clear ;;
    esac
  done

  #--- Check if bosh dns exists
  K8S_HOST="cfcr-api-k8s-${K8S_CLUSTER}.internal.paas"
  K8S_ALIAS="cfcr-${K8S_CLUSTER}"
  flag_host="$(host ${K8S_HOST} | awk '{print $4}')"
  if [ "${flag_host}" = "found:" ] ; then
    printf "\n\n%bERROR : Kubernetes cluster endpoint \"${K8S_HOST}\" unknown (no dns record).%b\n\n" "${RED}" "${STD}"
  else
    #--- Set kubernetes configuration
    printf "\n"
    CRT_DIR=~/.crt
    if [ ! -d ${CRT_DIR} ] ; then
      mkdir ${CRT_DIR}
    fi

    bosh int <(credhub get -n "/${K8S_DIRECTOR}/${K8S_DEPLOYMENT}/tls-kubernetes" --output-json) --path=/value/ca > ${CRT_DIR}/${K8S_CLUSTER}.crt
    kubectl config set-cluster ${K8S_ALIAS} --server="https://${K8S_HOST}" --certificate-authority=${CRT_DIR}/${K8S_CLUSTER}.crt --embed-certs=true
    if [ $? != 0 ] ; then
      printf "\n\n%bERROR : Config cluster failed.%b\n\n" "${RED}" "${STD}"
    else
      getCredhubValue "K8S_PASSWORD" "/${K8S_DIRECTOR}/${K8S_DEPLOYMENT}/kubo-admin-password"
      if [ ${flagError} = 0 ] ; then
        kubectl config set-credentials ${K8S_ALIAS}-admin --token=${K8S_PASSWORD}
        if [ $? != 0 ] ; then
          printf "\n\n%bERROR : Config cluster credentials failed.%b\n\n" "${RED}" "${STD}"
        else
          kubectl config set-context ${K8S_ALIAS} --cluster=${K8S_ALIAS} --user=${K8S_ALIAS}-admin
          if [ $? != 0 ] ; then
            printf "\n\n%bERROR : Config cluster context failed.%b\n\n" "${RED}" "${STD}"
          else
            #--- Install svcat plugin for kubectl
            svcat install plugin

            #--- Log to kubernetes cluster
            kubectl config use-context ${K8S_ALIAS}

            #--- Display cluster nodes
            printf "\n\n%bCluster nodes:%b\n" "${YELLOW}${REVERSE}" "${STD}"
            kubectl get nodes
          fi
        fi
      fi
    fi
  fi
fi

printf "\n"