#!/bin/bash
#===========================================================================
# Log with fly (concourse) cli
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

if [ ${flagError} = 0 ] ; then
  #--- Choose which team to access
  flag=0
  while [ ${flag} = 0 ] ; do
    flag=1
    printf "\n%bTeam concourse :%b\n\n" "${REVERSE}${GREEN}" "${STD}"
    printf "%b1%b : main\n" "${GREEN}${BOLD}" "${STD}"
    printf "%b2%b : upload\n" "${GREEN}${BOLD}" "${STD}"
    printf "\n%bYour choice :%b " "${GREEN}${BOLD}" "${STD}" ; read choice
    case "${choice}" in
      1) TEAM="main" ;;
      2) TEAM="upload" ;;
      *) flag=0 ; clear ;;
    esac
  done

  #--- Log to fly
  OPS_DOMAIN="$(getCredhubValue "/secrets/cloudfoundry_ops_domain")"
  if [ ${flagError} = 0 ] ; then
    #--- Log to fly
    FLY_PASSWORD="$(getCredhubValue "/secrets/atc_password")"
    if [ ${flagError} = 1 ] ; then
      if [ "${FLY_PASSWORD}" = "" ] ; then
      flag=0
      while [ ${flag} = 0 ] ; do
        printf "\n%bEnter concourse \"atc\" password :%b " "${REVERSE}${YELLOW}" "${STD}" ; read -s FLY_PASSWORD
        if [ "${FLY_PASSWORD}" != "" ] ; then
          flag=1
        fi
      done
    fi
    else
      fly login -c https://elpaaso-concourse-micro.${OPS_DOMAIN} -k -u atc -p ${FLY_PASSWORD} -n ${TEAM}
      if [ $? != 0 ] ; then
        printf "\n\n%bERROR : Connexion failed. Bad \"atc\" password.%b\n\n" "${RED}" "${STD}"
        FLY_PASSWORD=""
      else
        fly builds
        printf "\n"
      fi
    fi
  fi
fi