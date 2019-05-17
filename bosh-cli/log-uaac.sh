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

getCredhub() {
  #--- Test if parameter exist with non empty value, else get it from credhub
  if [ "${!1}" = "" ] ; then
    credhubGet=$(credhub g -n $2 -j | jq .value -r)
    if [ $? = 0 ] ; then
      eval $1=$(echo "${credhubGet}")
    else
      printf "\n\n%bERROR : \"$2\" credhub value unknown.%b\n\n" "${RED}" "${STD}"
      flagError=1
    fi
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
      printf "%b5%b : kubo (master-depls/bosh-kubo)\n" "${GREEN}${BOLD}" "${STD}"
      printf "%b6%b : coab (master-depls/bosh-coab)\n" "${GREEN}${BOLD}" "${STD}"
      printf "\n%bYour choice :%b " "${GREEN}${BOLD}" "${STD}" ; read choice
      case "${choice}" in
        1) getCredhub "SYSTEM_DOMAIN" "/secrets/cloudfoundry_system_domain"
          UAA_TARGET="https://uaa.${SYSTEM_DOMAIN}" ; ADMIN_CLIENT_SECRET="/bosh-master/cf/uaa_admin_client_secret" ;;
        2) UAA_TARGET="https://192.168.10.10:8443" ; ADMIN_CLIENT_SECRET="/secrets/bosh_admin_password" ;;
        3) UAA_TARGET="https://192.168.116.158:8443" ; ADMIN_CLIENT_SECRET="/micro-bosh/bosh-master/admin_password" ;;
        4) UAA_TARGET="https://192.168.99.152:8443" ; ADMIN_CLIENT_SECRET="/bosh-master/bosh-ops/admin_password" ;;
        5) UAA_TARGET="https://192.168.99.154:8443" ; ADMIN_CLIENT_SECRET="/bosh-master/bosh-kubo/admin_password" ;;
        6) UAA_TARGET="https://192.168.99.155:8443" ; ADMIN_CLIENT_SECRET="/bosh-master/bosh-coab/admin_password" ;;
        *) flag=0 ; clear ;;
      esac
    done

    getCredhub "ADMIN_PASSWORD" "${ADMIN_CLIENT_SECRET}"
    if [ ${flagError} = 0 ] ; then
      uaac token delete --all
      uaac target ${UAA_TARGET} --ca-cert ${BOSH_CA_CERT} > /dev/null 2>&1
      if [ $? = 0 ] ; then
        uaac token client get admin -s ${ADMIN_PASSWORD}
      else
        printf "\n%bERROR : Connexion failed.%b\n\n" "${RED}" "${STD}"
      fi
    f
  fi
fi
printf "\n"