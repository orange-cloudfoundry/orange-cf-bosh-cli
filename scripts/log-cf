#!/bin/bash
#===========================================================================
# Log with CF cli
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

#--- Log to CF
if [ ${flagError} = 0 ] ; then
  flag=0
  while [ ${flag} = 0 ] ; do
    printf "\n%bEnter CF User :%b " "${REVERSE}${YELLOW}" "${STD}" ; read CF_USER
    if [ "${CF_USER}" = "" ] ; then
      clear
    else
      flag=1
    fi
  done

  getCredhub "SYSTEM_DOMAIN" "/secrets/cloudfoundry_system_domain"
  if [ ${flagError} = 0 ] ; then
    cf login -a https://api.${SYSTEM_DOMAIN} -u ${CF_USER}
    if [ $? != 0 ] ; then
      printf "\n%bERROR : Connexion failed.%b\n\n" "${RED}" "${STD}"
    else
      printf "\n\n"
    fi
  fi
fi