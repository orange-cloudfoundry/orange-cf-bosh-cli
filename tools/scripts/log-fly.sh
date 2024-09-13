#!/bin/bash
#===========================================================================
# Log with fly (concourse) cli
#===========================================================================

TEAMS="main micro-depls master-depls ops-depls coab-depls gcp-depls remote-r2-depls remote-r4-depls"
flagError=0 ; flag_interactive=1 ; nbParameters=$#

if [ ! -s "${BOSH_CA_CERT}" ] ; then
  printf "\n%bERROR : CA cert file \"${BOSH_CA_CERT}\" unknown.%b\n\n" "${RED}" "${STD}" ; flagError=1
fi

#--- Check scripts options
usage() {
  printf "\n%bUSAGE:" "${RED}${BOLD}"
  printf "\n  log-fly [OPTIONS]\n\nOPTIONS:"
  printf "\n  %-15s %s" "--team, -t" "concourse team (${TEAMS})"
  printf "%b\n\n" "${STD}"
  nbParameters=0 ; flagError=1
}

if [ ${flagError} = 0 ] ; then
  while [ ${nbParameters} -gt 0 ] ; do
    case "$1" in
      "-t"|"--team") flag_interactive=0 ; TEAM="$2" ; shift ; shift ; nbParameters=$#
        if [ "${TEAM}" = "" ] ; then
          usage
        else
          flag_team="$(echo " ${TEAMS} " | grep " ${TEAM} ")"
          if [ "${flag_team}" = "" ] ; then
            usage
          fi
        fi ;;
      *) usage ;;
    esac
  done
fi

if [ ${flagError} = 0 ] ; then
  #--- Log to credhub
  flag=$(credhub f > /dev/null 2>&1)
  if [ $? != 0 ] ; then
    printf "\n%bLDAP user and password :%b\n" "${REVERSE}${GREEN}" "${STD}"
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
fi

#--- Choose concourse team
if [ ${flagError} = 0 ] ; then
  if [ ${flag_interactive} = 1 ] ; then
    flag=0
    while [ ${flag} = 0 ] ; do
      flag=1
      printf "\n%bTeam concourse :%b\n\n" "${REVERSE}${GREEN}" "${STD}"
      printf "%b1%b   : main\n" "${GREEN}${BOLD}" "${STD}"
      printf "%b2%b   : micro-depls\n" "${GREEN}${BOLD}" "${STD}"
      printf "%b3%b   : master-depls\n" "${GREEN}${BOLD}" "${STD}"
      printf "%b4%b   : ops-depls\n" "${GREEN}${BOLD}" "${STD}"
      printf "%b5%b   : coab-depls\n" "${GREEN}${BOLD}" "${STD}"
      printf "%b6%b   : gcp-depls\n" "${GREEN}${BOLD}" "${STD}"
      printf "%b7%b   : remote-r2-depls\n" "${GREEN}${BOLD}" "${STD}"
      printf "%b8%b   : remote-r4-depls\n" "${GREEN}${BOLD}" "${STD}"
      printf "\n%bYour choice :%b " "${GREEN}${BOLD}" "${STD}" ; read choice
      case "${choice}" in
        1) TEAM="main" ;;
        2) TEAM="micro-depls" ;;
        3) TEAM="master-depls" ;;
        4) TEAM="ops-depls" ;;
        5) TEAM="coab-depls" ;;
        6) TEAM="gcp-depls" ;;
        7) TEAM="remote-r2-depls" ;;
        8) TEAM="remote-r4-depls" ;;
        *) flag=0 ; clear ;;
      esac
    done
  fi

  #--- Log to concourse and display builds
  fly -t concourse login -c https://elpaaso-concourse.${OPS_DOMAIN} -u ${FLY_USER} -p ${FLY_PASSWORD} -n ${TEAM}
  if [ $? = 0 ] ; then
    fly -t concourse workers
    printf "\n"
  else
    printf "\n\n%bERROR : Fly login failed.%b\n\n" "${RED}" "${STD}"
  fi
fi