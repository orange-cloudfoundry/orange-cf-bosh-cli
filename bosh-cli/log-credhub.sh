#!/bin/bash
#===========================================================================
# Log with credhub cli
# Parameters :
# --uaa, -u       : Use uaa client to log with credhub
# -i              : Interactif (needed for credhub-get)
#===========================================================================

#--- Check scripts options
usage() {
  printf "\n%bUSAGE:" "${RED}${BOLD}"
  printf "\n  log-credhub [OPTIONS]\n\nOPTIONS:"
  printf "\n  %-40s %s" "--uaa, -u" "Use uaa client to log with credhub"
  printf "%b\n\n" "${STD}"
  nbParameters=0 ; flagError=1
}

flagError=0 ; flag_use_uaa=0 ; nbParameters=$#
while [ ${nbParameters} -gt 0 ] ; do
  case "$1" in
    "-u"|"--uaa") flag_use_uaa=1 ; shift ; nbParameters=$# ;;
    "-i") shift ; nbParameters=$# ;;
    *) usage ;;
  esac
done

#--- Delete credhub context when changing user type (LDAP/UAA)
if [ -f ~/.credhub/config.json ] ; then
  flagRefreshToken=$(cat ~/.credhub/config.json | jq -r '.RefreshToken')
  if [ ${flag_use_uaa} = 1 ] ; then
    if [ "${flagRefreshToken}" != "" ] ; then
      #--- LDAP user is connected
      rm -f ~/.credhub/config.json > /dev/null 2>&1
    fi
  else
    if [ "${flagRefreshToken}" = "" ] ; then
      #--- UAA user is connected
      rm -f ~/.credhub/config.json > /dev/null 2>&1
    fi
  fi
fi

#--- Log to credhub
if [ ${flagError} = 0 ] ; then
  flag=$(credhub f > /dev/null 2>&1)
  if [ $? != 0 ] ; then
    if [ ${flag_use_uaa} = 1 ] ; then
      #--- Log to credhub with uaa client
      printf "\n%b\"bosh_credhub_secrets\" password (from shared/secrets.yml) :%b " "${REVERSE}${GREEN}" "${STD}" ; read CREDHUB_CLIENT_SECRET
      if [ "${CREDHUB_CLIENT_SECRET}" = "" ] ; then
        printf "\n\n%bERROR : Empty password.%b\n\n" "${RED}" "${STD}"
      else
        credhub login --server=https://credhub.internal.paas:8844 --client-name=director_to_credhub --client-secret=${CREDHUB_CLIENT_SECRET}
        if [ $? != 0 ] ; then
          printf "\n%bERROR : Authentication failed with this password.%b\n\n" "${RED}" "${STD}"
        fi
      fi
    else
      #--- Log to credhub with ldap account
      printf "\n%bLDAP user and password :%b\n" "${REVERSE}${GREEN}" "${STD}"
      printf "username: " ; read LDAP_USER
      credhub login --server=https://credhub.internal.paas:8844 -u ${LDAP_USER}
      if [ $? != 0 ] ; then
        printf "\n%bERROR : LDAP authentication failed with \"${LDAP_USER}\" account.%b\n\n" "${RED}" "${STD}"
      fi
    fi
  fi
fi