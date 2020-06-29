#!/bin/bash
#===========================================================================
# Log with uaac cli
#===========================================================================

#--- Micro-bos credentials file
MICRO_BOSH_CREDENTIALS="${HOME}/bosh/secrets/bootstrap/micro-bosh/creds.yml"

#--- Get a parameter in specified yaml file
getValue() {
  value=$(bosh int $1 --path $2 2> /dev/null)
  if [ $? != 0 ] ; then
    printf "\n%bERROR: Propertie \"$2\" unknown in \"$1\".%b\n\n" "${REVERSE}${RED}" "${STD}" ; flagError=1
  else
    printf "${value}"
  fi
}

#--- Get a parameter in credhub
getCredhubValue() {
  value=$(credhub g -n $2 | grep 'value:' | awk '{print $2}')
  if [ "${value}" = "" ] ; then
    printf "\n\n%bERROR : \"$2\" credhub value unknown.%b\n\n" "${RED}" "${STD}" ; flagError=1
  else
    eval "$1=${value}"
  fi
}

#--- Check Prerequisites
flagError=0
if [ ! -s "${BOSH_CA_CERT}" ] ; then
  printf "\n%bERROR : CA cert file \"${BOSH_CA_CERT}\" unknown.%b\n\n" "${RED}" "${STD}" ; flagError=1
fi

if [ ! -s ${MICRO_BOSH_CREDENTIALS} ] ; then
  printf "\n%bFile \"${MICRO_BOSH_CREDENTIALS}\" unavailable.%b\n\n" "${REVERSE}${RED}" "${STD}" ; flagError=1
fi

#--- Log to credhub
if [ ${flagError} = 0 ] ; then
  flag=$(credhub f > /dev/null 2>&1)
  if [ $? != 0 ] ; then
    printf "\n%bLDAP user and password :%b\n" "${REVERSE}${GREEN}" "${STD}"
    printf "username: " ; read LDAP_USER
    credhub login --server=https://credhub.internal.paas:8844 -u ${LDAP_USER}
    if [ $? != 0 ] ; then
      printf "\n%bERROR : LDAP authentication failed with \"${LDAP_USER}\" account.%b\n\n" "${RED}" "${STD}" ; flagError=1
    fi
  fi
fi

#--- Log to uaa
if [ ${flagError} = 0 ] ; then
  #--- Identify UAA
  flag=0
  while [ ${flag} = 0 ] ; do
    flag=1
    printf "%bTarget UAA :%b\n\n" "${REVERSE}${GREEN}" "${STD}"
    printf "%b1%b : micro-bosh\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b2%b : bosh-master\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b3%b : bosh-ops\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b4%b : bosh-coab\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b5%b : bosh-remote-r2\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b6%b : bosh-remote-r3\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b7%b : cf (master-depls/cf)\n" "${GREEN}${BOLD}" "${STD}"
    printf "\n%bYour choice :%b " "${GREEN}${BOLD}" "${STD}" ; read choice
    case "${choice}" in
      1) UAA_TARGET="https://192.168.10.10:8443" ; UAA_USER="uaa_admin" ; ADMIN_CLIENT_SECRET="$(getValue ${MICRO_BOSH_CREDENTIALS} /uaa_admin_client_secret)" ;;
      2) UAA_TARGET="https://192.168.116.158:8443" ; UAA_USER="uaa_admin" ; getCredhubValue "ADMIN_CLIENT_SECRET" "/micro-bosh/bosh-master/uaa_admin_client_secret" ;;
      3) UAA_TARGET="https://192.168.99.152:8443" ; UAA_USER="uaa_admin" ; getCredhubValue "ADMIN_CLIENT_SECRET" "/bosh-master/bosh-ops/uaa_admin_client_secret" ;;
      4) UAA_TARGET="https://192.168.99.155:8443" ; UAA_USER="uaa_admin" ; getCredhubValue "ADMIN_CLIENT_SECRET" "/bosh-master/bosh-coab/uaa_admin_client_secret" ;;
      5) UAA_TARGET="https://192.168.99.153:8443" ; UAA_USER="uaa_admin" ; getCredhubValue "ADMIN_CLIENT_SECRET" "/bosh-master/bosh-remote-r2/uaa_admin_client_secret" ;;
      6) UAA_TARGET="https://192.168.99.156:8443" ; UAA_USER="uaa_admin" ; getCredhubValue "ADMIN_CLIENT_SECRET" "/bosh-master/bosh-remote-r3/uaa_admin_client_secret" ;;
      7) UAA_TARGET="https://uaa.${SYSTEM_DOMAIN}" ; UAA_USER="admin" ; getCredhubValue "ADMIN_CLIENT_SECRET" "/bosh-master/cf/uaa_admin_client_secret" ;;
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

printf "\n"