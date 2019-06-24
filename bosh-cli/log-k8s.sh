#!/bin/bash
#===========================================================================
# Log with kubernetes cli (kubectl, helm)
#===========================================================================

#--- Colors and styles
export RED='\033[1;31m'
export YELLOW='\033[1;33m'
export GREEN='\033[1;32m'
export STD='\033[0m'
export BOLD='\033[1m'
export REVERSE='\033[7m'

#--- Get a propertie value in credhub
getCredhubValue() {
  value=$(credhub g -n $1 | grep 'value: ' | awk '{print $2}')
  if [ $? = 0 ] ; then
    echo "${value}"
  else
    printf "\n\n%bERROR : \"$2\" credhub value unknown.%b\n\n" "${RED}" "${STD}"
    flagError=1
  fi
}

#--- Log to credhub
flagError=0
flag=$(credhub f > /dev/null 2>&1)
if [ $? != 0 ] ; then
  printf "\n%bEnter LDAP user and password :%b\n" "${REVERSE}${YELLOW}" "${STD}"
  credhub api --server=https://credhub.internal.paas:8844 > /dev/null 2>&1
  credhub login
  if [ $? != 0 ] ; then
    printf "\n%bERROR : Bad LDAP authentication.%b\n\n" "${RED}" "${STD}"
    flagError=1
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
    printf "%b3%b : ops\n" "${GREEN}${BOLD}" "${STD}"
    printf "\n%bYour choice :%b " "${GREEN}${BOLD}" "${STD}" ; read choice
    case "${choice}" in
      1) CFCR_DEPLOYMENT="micro-bosh" ; CFCR_CLUSTER="micro" ;;
      2) CFCR_DEPLOYMENT="bosh-master" ; CFCR_CLUSTER="master" ;;
      3) CFCR_DEPLOYMENT="bosh-kubo" ; CFCR_CLUSTER="ops" ;;
      *) flag=0 ; clear ;;
    esac
  done

  #--- Check if bosh dns exists
  CFCR_HOST="cfcr-api-${CFCR_CLUSTER}.internal.paas"
  CFCR_ALIAS="cfcr-${CFCR_CLUSTER}"
  flag_host="$(host ${CFCR_HOST} | awk '{print $4}')"
  if [ "${flag_host}" = "found:" ] ; then
    printf "\n\n%bERROR : Kubernetes cluster endpoint \"${CFCR_HOST}\" unknown (no dns record).%b\n\n" "${RED}" "${STD}"
  else
    #--- Set kubernetes configuration
    printf "\n"
    CRT_DIR=~/.crt
    if [ ! -d ${CRT_DIR} ] ; then
      mkdir ${CRT_DIR}
    fi
    bosh int <(credhub get -n "/${CFCR_DEPLOYMENT}/cfcr/tls-kubernetes" --output-json) --path=/value/ca > ${CRT_DIR}/${CFCR_CLUSTER}.crt
    kubectl config set-cluster ${CFCR_ALIAS} --server="https://${CFCR_HOST}" --certificate-authority=${CRT_DIR}/${CFCR_CLUSTER}.crt --embed-certs=true
    if [ $? != 0 ] ; then
      printf "\n\n%bERROR : Config cluster failed.%b\n\n" "${RED}" "${STD}"
    else
      CFCR_PASSWORD="$(getCredhubValue "/${CFCR_DEPLOYMENT}/cfcr/kubo-admin-password")"
      if [ ${flagError} = 0 ] ; then
        kubectl config set-credentials ${CFCR_ALIAS}-admin --token=${CFCR_PASSWORD}
        if [ $? != 0 ] ; then
          printf "\n\n%bERROR : Config cluster credentials failed.%b\n\n" "${RED}" "${STD}"
        else
          kubectl config set-context ${CFCR_ALIAS} --cluster=${CFCR_ALIAS} --user=${CFCR_ALIAS}-admin
          if [ $? != 0 ] ; then
            printf "\n\n%bERROR : Config cluster context failed.%b\n\n" "${RED}" "${STD}"
          else
            #--- Log to kubernetes cluster
            kubectl config use-context ${CFCR_ALIAS}

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