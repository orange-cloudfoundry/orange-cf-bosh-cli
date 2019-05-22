#!/bin/bash
#===========================================================================
# Log with uaac cli
#===========================================================================

#--- Colors and styles
export RED='\033[1;31m'
export YELLOW='\033[1;33m'
export GREEN='\033[1;32m'
export STD='\033[0m'
export BOLD='\033[1m'
export REVERSE='\033[7m'

#--- Get a parameter value in credhub
getCredhubValue() {
  value=$(credhub g -n $1 | grep 'value:' | awk '{print $2}')
  if [ "${value}" = "" ] ; then
    printf "\n\n%bERROR : Propertie \"$1\" unknown in \"credhub\".%b\n\n" "${RED}" "${STD}"
  else
    echo "${value}"
  fi
}

if [ ! -s "${BOSH_CA_CERT}" ] ; then
  printf "\n%bERROR : CA cert file \"${BOSH_CA_CERT}\" unknown. Connexion failed.%b\n\n" "${RED}" "${STD}"
else
  #--- Log to credhub
  flagError=0
  flag=$(credhub f > /dev/null 2>&1)
  if [ $? != 0 ] ; then
    printf "\n%bEnter CF LDAP user and password :%b\n" "${REVERSE}${YELLOW}" "${STD}"
    credhub api --server=https://credhub.internal.paas:8844 > /dev/null 2>&1
    credhub login
    if [ $? != 0 ] ; then
      printf "\n%bERROR : Bad LDAP authentication.%b\n\n" "${RED}" "${STD}"
      flagError=1
    fi
  fi

  #--- Log to uaa
  if [ "${flagError}" = "0" ] ; then
    #--- Identify UAA
    flag=0
    while [ ${flag} = 0 ] ; do
      flag=1
      printf "%bTarget UAA :%b\n\n" "${REVERSE}${GREEN}" "${STD}"
      printf "%b1%b : cf (master-depls/cf)\n" "${GREEN}${BOLD}" "${STD}"
      printf "%b2%b : micro (micro-depls/credhub-ha)\n" "${GREEN}${BOLD}" "${STD}"
      printf "%b3%b : master (micro-depls/bosh-master)\n" "${GREEN}${BOLD}" "${STD}"
      printf "%b4%b : ops (master-depls/bosh-ops)\n" "${GREEN}${BOLD}" "${STD}"
      printf "%b5%b : coab (master-depls/bosh-coab)\n" "${GREEN}${BOLD}" "${STD}"
      printf "%b6%b : kubo (master-depls/bosh-kubo)\n" "${GREEN}${BOLD}" "${STD}"
      printf "\n%bYour choice :%b " "${GREEN}${BOLD}" "${STD}" ; read choice
      case "${choice}" in
        1) SYSTEM_DOMAIN=$(getCredhubValue "/secrets/cloudfoundry_system_domain")
           UAA_TARGET="https://uaa.${SYSTEM_DOMAIN}" ; UAA_USER="admin" ; ADMIN_CLIENT_SECRET=$(getCredhubValue "/bosh-master/cf/uaa_admin_client_secret") ;;
        2) UAA_TARGET="https://192.168.10.10:8443" ; UAA_USER="uaa_admin" ; ADMIN_CLIENT_SECRET=$(getCredhubValue "/micro-bosh/uaa_admin_client_secret") ;;
        3) UAA_TARGET="https://192.168.116.158:8443" ; UAA_USER="uaa_admin" ; ADMIN_CLIENT_SECRET=$(getCredhubValue "/micro-bosh/bosh-master/uaa_admin_client_secret") ;;
        4) UAA_TARGET="https://192.168.99.152:8443" ; UAA_USER="uaa_admin" ; ADMIN_CLIENT_SECRET=$(getCredhubValue "/bosh-master/bosh-ops/uaa_admin_client_secret") ;;
        5) UAA_TARGET="https://192.168.99.155:8443" ; UAA_USER="uaa_admin" ; ADMIN_CLIENT_SECRET=$(getCredhubValue "/bosh-master/bosh-coab/uaa_admin_client_secret") ;;
        6) UAA_TARGET="https://192.168.99.154:8443" ; UAA_USER="uaa_admin" ; ADMIN_CLIENT_SECRET=$(getCredhubValue "/bosh-master/bosh-kubo/uaa_admin_client_secret") ;;
        *) flag=0 ; clear ;;
      esac
    done

    if [ ${flagError} = 0 ] ; then
      uaac token delete --all > /dev/null 2>&1
      uaac target ${UAA_TARGET} --ca-cert ${BOSH_CA_CERT} > /dev/null 2>&1
      if [ $? = 0 ] ; then
        uaac token client get ${UAA_USER} -s ${ADMIN_CLIENT_SECRET}
      else
        printf "\n%bERROR : Connexion failed.%b\n\n" "${RED}" "${STD}"
      fi
    fi
  fi
fi
printf "\n"