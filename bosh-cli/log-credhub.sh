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
flag=$(credhub f > /dev/null 2>&1)
if [ $? != 0 ] ; then
  printf "\n%bEnter LDAP user and password :%b\n" "${REVERSE}${YELLOW}" "${STD}"
  credhub api --server=https://credhub.internal.paas:8844 > /dev/null 2>&1
  printf "username: " ; read LDAP_USER
  credhub login -u ${LDAP_USER}
  if [ $? = 0 ] ; then
    printf "\n\n"
  else
    printf "\n%bERROR : Bad LDAP authentication with \"${LDAP_USER}\" account.%b\n\n" "${RED}" "${STD}"
  fi
fi