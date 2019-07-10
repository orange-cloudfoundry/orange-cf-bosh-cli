#!/bin/bash
#===========================================================================
# Log with credhub cli
#===========================================================================

#--- Colors and styles
export RED='\033[1;31m'
export YELLOW='\033[1;33m'
export STD='\033[0m'
export REVERSE='\033[7m'

#--- Log to credhub
flagError=0
flag=$(credhub f > /dev/null 2>&1)
if [ $? != 0 ] ; then
  printf "\n%bEnter LDAP user and password :%b\n" "${REVERSE}${YELLOW}" "${STD}"
  printf "username: " ; read LDAP_USER
  credhub login --server=https://credhub.internal.paas:8844 -u ${LDAP_USER}
  if [ $? != 0 ] ; then
    printf "\n%bERROR : LDAP authentication failed with \"${LDAP_USER}\" account.%b\n\n" "${RED}" "${STD}"
  fi
fi