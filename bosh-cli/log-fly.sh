#!/bin/bash
#===========================================================================
# Log with fly (concourse) cli
#===========================================================================

#--- Colors and styles
export RED='\033[1;31m'
export GREEN='\033[1;32m'
export STD='\033[0m'
export BOLD='\033[1m'
export REVERSE='\033[7m'

#--- Log to credhub
flagError=0
flag=$(credhub f > /dev/null 2>&1)
if [ $? != 0 ] ; then
  printf "\n%bEnter LDAP user and password :%b\n" "${REVERSE}${YELLOW}" "${STD}"
  printf "username: " ; read LDAP_USER
  credhub login --server=https://credhub.internal.paas:8844 -u ${LDAP_USER}
  if [ $? != 0 ] ; then
    printf "\n%bERROR : LDAP authentication failed with \"${LDAP_USER}\" account.%b\n\n" "${RED}" "${STD}" ; flagError=1
  fi
fi

#--- Get user and password account for login
content=$(credhub g -n /micro-bosh/concourse/local_user)
FLY_USER=$(echo "${content}" | grep 'username: ' | awk '{print $2}')
if [ "${FLY_USER}" = "" ] ; then
  printf "\n\n%bERROR : fly user credhub value unknown.%b\n\n" "${RED}" "${STD}" ; flagError=1
fi
FLY_PASSWORD=$(echo "${content}"  | grep 'password: ' | awk '{print $2}')
if [ "${FLY_PASSWORD}" = "" ] ; then
  printf "\n\n%bERROR : fly password credhub value unknown.%b\n\n" "${RED}" "${STD}" ; flagError=1
fi

#--- Choose concourse team
if [ ${flagError} = 0 ] ; then
  flag=0
  while [ ${flag} = 0 ] ; do
    flag=1
    printf "\n%bTeam concourse :%b\n\n" "${REVERSE}${GREEN}" "${STD}"
    printf "%b1%b : main\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b2%b : upload\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b3%b : micro-depls\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b4%b : master-depls\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b5%b : ops-depls\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b6%b : coab-depls\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b7%b : kubo-depls\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b8%b : utils\n" "${GREEN}${BOLD}" "${STD}"
    printf "\n%bYour choice :%b " "${GREEN}${BOLD}" "${STD}" ; read choice
    case "${choice}" in
      1) TEAM="main" ;;
      2) TEAM="upload" ;;
      3) TEAM="micro-depls" ;;
      4) TEAM="master-depls" ;;
      5) TEAM="ops-depls" ;;
      6) TEAM="coab-depls" ;;
      7) TEAM="kubo-depls" ;;
      8) TEAM="utils" ;;
      *) flag=0 ; clear ;;
    esac
  done

  #--- Log to concourse and display builds
  fly -t concourse login -c https://elpaaso-concourse.${OPS_DOMAIN} -u ${FLY_USER} -p ${FLY_PASSWORD} -n ${TEAM}
  if [ $? = 0 ] ; then
    fly -t concourse builds
    printf "\n"
  else
    printf "\n\n%bERROR : Fly login failed.%b\n\n" "${RED}" "${STD}"
  fi
fi