#!/bin/bash
#===========================================================================
# Set/unset internet/intranet proxy
# Parameters :
# -a, --intranet  : Set intranet proxy
# -i, --internet  : Set internet proxy
# -s, --switch    : Set switch proxy (use intranet/internet proxy)
# -c, --corporate : Set internet corporate proxy
#===========================================================================

#--- Check scripts options
usage() {
  printf "\n%bUSAGE:" "${RED}"
  printf "\n  proxy [OPTIONS]\n\nOPTIONS:"
  printf "\n  %-20s %s" "-a, --intranet" "Set intranet proxy"
  printf "\n  %-20s %s" "-i, --internet" "Set internet proxy"
  printf "\n  %-20s %s" "-s, --switch" "Set switch proxy (use intranet/internet proxy)"
  printf "\n  %-20s %s" "-c, --corporate" "Set internet corporate proxy"
  printf "%b\n\n" "${STD}"
  flagError=1
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

#--- Log to credhub
logToCredhub() {
  flag=$(credhub f > /dev/null 2>&1)
  if [ $? != 0 ] ; then
    printf "\n%bLDAP user and password :%b\n" "${REVERSE}${GREEN}" "${STD}"
    printf "username: " ; read LDAP_USER
    credhub login --server=https://credhub.internal.paas:8844 -u ${LDAP_USER}
    if [ $? != 0 ] ; then
      printf "\n%bERROR : LDAP authentication failed with \"${LDAP_USER}\" account.%b\n\n" "${RED}" "${STD}" ; flagError=1
    fi
  fi
}

flagError=0 ; PROXY=""
NO_PROXY_INTERNAL="127.0.0.1,localhost,169.254.0.0/16,172.17.11.0/24,192.168.0.0/16,.internal.paas"

case "$1" in
  "") PROXY_TYPE="" ;;

  "-a"|"--intranet")
    PROXY_TYPE="intranet"
    PROXY_HOST="intranet-http-proxy.internal.paas"
    PROXY_PORT="3129"
    NO_PROXY="${NO_PROXY_INTERNAL}" ;;

  "-i"|"--internet"|"")
    PROXY_TYPE="internet"
    PROXY_HOST="system-internet-http-proxy.internal.paas"
    PROXY_PORT="3128"
    NO_PROXY="${NO_PROXY_INTERNAL},${INTRANET_DOMAINS}" ;;

  "-s"|"--switch")
    PROXY_TYPE="switch"
    PROXY_HOST="switch-http-proxy.internal.paas"
    PROXY_PORT="3127"
    NO_PROXY="${NO_PROXY_INTERNAL}" ;;

  "-c"|"--corporate")
    PROXY_TYPE="corporate"
    logToCredhub
    if [ ${flagError} = 0 ] ; then
      getCredhubValue "PROXY_HOST" "/secrets/multi_region_region_1_corporate_internet_proxy_host"
      getCredhubValue "PROXY_PORT" "/secrets/multi_region_region_1_corporate_internet_proxy_port"
    fi
    NO_PROXY="${NO_PROXY_INTERNAL},${INTRANET_DOMAINS}" ;;

  *) usage ;;
esac

if [ ${flagError} = 0 ] ; then
  if [ "${PROXY_TYPE}" = "" ] ; then
    printf "\n%bUnset proxy...%b\n" "${REVERSE}${YELLOW}" "${STD}"
    unset PROXY_TYPE PROXY_HOST PROXY_PORT http_proxy HTTP_PROXY https_proxy HTTPS_PROXY no_proxy NO_PROXY
  else
    printf "\n%bSet \"${PROXY_TYPE}\" proxy%b\n" "${REVERSE}${YELLOW}" "${STD}"
    PROXY="http://${PROXY_HOST}:${PROXY_PORT}"
    export PROXY_TYPE
    export http_proxy=${PROXY}
    export HTTP_PROXY=${PROXY}
    export https_proxy=${PROXY}
    export HTTPS_PROXY=${PROXY}
    export no_proxy=${NO_PROXY}
    export NO_PROXY
  fi

  #--- Don't set prompt if NO_PROMPT var is not empty
  if [ ! "${NO_PROMPT}" ] ; then
    set_prompt
  fi
fi
