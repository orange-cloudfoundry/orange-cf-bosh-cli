#!/bin/bash
#===========================================================================
# Log with bosh cli V2
# Parameters :
# --target, -t      : Bosh director target (micro, master, ops...)
# --deployment, -d  : Bosh deployment name
# --uaa, -u         : Use uaa client to log with bosh director
#===========================================================================

#--- Unset uaa bosh login credentials
unset BOSH_CLIENT BOSH_CLIENT_SECRET

#--- Check Prerequisites
flagError=0 ; flag_interactive=1 ; flag_use_uaa=0 ; nbParameters=$#
if [ ! -s "${BOSH_CA_CERT}" ] ; then
  printf "\n%bERROR : CA cert file \"${BOSH_CA_CERT}\" unknown.%b\n\n" "${RED}" "${STD}" ; flagError=1
fi

#--- Check scripts options
usage() {
  printf "\n%bUSAGE:" "${RED}${BOLD}"
  printf "\n  log-bosh [OPTIONS]\n\nOPTIONS:"
  printf "\n  %-40s %s" "--target, -t \"bosh target (micro...)\"" "Bosh director target"
  printf "\n  %-40s %s" "--deployment, -d \"deployment name\"" "Bosh deployment name"
  printf "\n  %-40s %s" "--uaa, -u" "Use uaa client to log with bosh director"
  printf "%b\n\n" "${STD}"
  nbParameters=0 ; flagError=1
}

if [ ${flagError} = 0 ] ; then
  while [ ${nbParameters} -gt 0 ] ; do
    case "$1" in
      "-t"|"--target") flag_interactive=0 ; BOSH_TARGET="$2" ; shift ; shift ; nbParameters=$#
        if [ "${BOSH_TARGET}" = "" ] ; then
          usage
        fi ;;
      "-d"|"--deployment") flag_interactive=0 ; export BOSH_DEPLOYMENT="$2" ; shift ; shift ; nbParameters=$#
        if [ "${BOSH_DEPLOYMENT}" = "" ] ; then
          usage
        fi ;;
      "-u"|"--uaa") flag_interactive=1 ; flag_use_uaa=1 ; shift ; nbParameters=$# ;;
      *) usage ;;
    esac
  done
fi

#--- Log to bosh director
if [ ${flagError} = 0 ] ; then
  if [ ${flag_interactive} = 1 ] ; then
    flag=0
    while [ ${flag} = 0 ] ; do
      flag=1
      printf "\n%bDirector BOSH :%b\n\n" "${REVERSE}${GREEN}" "${STD}"
      printf "%b1%b : micro\n" "${GREEN}${BOLD}" "${STD}"
      printf "%b2%b : master\n" "${GREEN}${BOLD}" "${STD}"
      printf "%b3%b : ops\n" "${GREEN}${BOLD}" "${STD}"
      printf "%b4%b : coab\n" "${GREEN}${BOLD}" "${STD}"
      printf "%b5%b : remote-r2\n" "${GREEN}${BOLD}" "${STD}"
      printf "%b6%b : remote-r3\n" "${GREEN}${BOLD}" "${STD}"
      printf "\n%bYour choice :%b " "${GREEN}${BOLD}" "${STD}" ; read choice
      case "${choice}" in
        1) BOSH_TARGET="micro" ;;
        2) BOSH_TARGET="master" ;;
        3) BOSH_TARGET="ops" ;;
        4) BOSH_TARGET="coab" ;;
        5) BOSH_TARGET="remote-r2" ;;
        6) BOSH_TARGET="remote-r3" ;;
        *) flag=0 ; clear ;;
      esac
    done
  fi

  #--- Check bosh dns record
  export BOSH_ENVIRONMENT=$(host bosh-${BOSH_TARGET}.internal.paas | awk '{print $4}')
  if [ "${BOSH_ENVIRONMENT}" = "found:" ] ; then
    printf "\n\n%bERROR : Bosh director \"${BOSH_TARGET}\" unknown (no dns record).%b\n\n" "${RED}" "${STD}"
  else
    #--- Check if bosh director instance is available
    nc -vz -w 1 ${BOSH_ENVIRONMENT} 25250 > /dev/null 2>&1
    if [ $? != 0 ] ; then
      printf "\n\n%bERROR : Bosh director \"${BOSH_TARGET}\" unreachable.%b\n\n" "${RED}" "${STD}"
    else
      #--- Check if token access expired, then log out
      bosh env > /dev/null 2>&1
      if [ $? != 0 ] ; then
        bosh log-out > /dev/null 2>&1
      fi

      #--- Create bosh alias
      bosh alias-env ${BOSH_TARGET} > /dev/null 2>&1

      #--- Check if user is already connected
      isUserNotConnected=$(bosh env | grep "not logged in")
      if [ "${isUserNotConnected}" != "" ] ; then
        if [ ${flag_use_uaa} = 1 ] ; then
          printf "\n%buaa \"admin\" client password :%b " "${REVERSE}${GREEN}" "${STD}" ; read BOSH_CLIENT_SECRET
          if [ "${BOSH_CLIENT_SECRET}" = "" ] ; then
            printf "\n\n%bERROR : Empty password.%b\n\n" "${RED}" "${STD}"
            flagError=1
          else
            export BOSH_CLIENT="admin"
            export BOSH_CLIENT_SECRET
          fi
        else
          printf "\n%bLDAP user and password :%b\n" "${REVERSE}${GREEN}" "${STD}"
        fi

        #--- Log to bosh director
        if [ ${flagError} = 0 ] ; then
          bosh log-in
          if [ $? != 0 ] ; then
            printf "\n\n%bERROR : Log to bosh director \"${BOSH_TARGET}\" failed.%b\n\n" "${RED}" "${STD}"
            flagError=1
          fi
        fi
      fi

      #--- Display selected bosh deployment status
      if [ ${flagError} = 0 ] ; then
        if [ ${flag_interactive} = 1 ] ; then
          deployments=$(bosh deployments --column=Name | grep -vE "^Name$|^Succeeded$|^[0-9]* deployments$")
          printf "\n%bSelect a specific deployment in the list, or suffix your bosh commands with -d <deployment_name>:%b\n%s" "${REVERSE}${GREEN}" "${STD}" "${deployments}"
          printf "\n\n%bYour choice (<Enter> to select all) :%b " "${GREEN}${BOLD}" "${STD}" ; read BOSH_DEPLOYMENT

          if [ "${BOSH_DEPLOYMENT}" = "" ] ; then
            unset BOSH_DEPLOYMENT
          else
            flag=$(echo "${deployments}" | grep "${BOSH_DEPLOYMENT}")
            if [ "${flag}" = "" ] ; then
              unset BOSH_DEPLOYMENT
            else
              export BOSH_DEPLOYMENT
              bosh instances
            fi
          fi
        fi
      fi
    fi
  fi
fi

printf "\n"