#!/bin/bash
#===========================================================================
# Set/unset internet/intranet proxy
# Parameters :
# --intranet, -a : Set intranet proxy
# --internet, -e : Set internet proxy
#===========================================================================

#--- Check scripts options
usage() {
  printf "\n%bUSAGE:" "${RED}"
  printf "\n  proxy [OPTIONS]\n\nOPTIONS:"
  printf "\n  %-40s %s" "--intranet, -a " "Set intranet proxy"
  printf "\n  %-40s %s" "--internet, -e" "Set internet proxy"
  printf "%b\n\n" "${STD}"
  flagError=1
}

flagError=0
PROXY=""
proxyStatus=`env | grep -i "http_proxy"`

case "$1" in
  "-a"|"--intranet")
      PROXY_TYPE="intranet"
      PROXY="http://intranet-http-proxy.internal.paas:3129"
      NO_PROXY="127.0.0.1,localhost,169.254.0.0/16,192.168.0.0/16,172.17.11.0/24,.internal.paas" ;;

  "-e"|"--internet")
    PROXY_TYPE="internet"
    PROXY="http://system-internet-http-proxy.internal.paas:3128"
    NO_PROXY="127.0.0.1,localhost,169.254.0.0/16,192.168.0.0/16,172.17.11.0/24,.internal.paas,${INTRANET_DOMAINS}" ;;

  "") if [ "${proxyStatus}" = "" ] ; then
        PROXY_TYPE="internet"
        PROXY="http://system-internet-http-proxy.internal.paas:3128"
        NO_PROXY="127.0.0.1,localhost,169.254.0.0/16,192.168.0.0/16,172.17.11.0/24,.internal.paas,${INTRANET_DOMAINS}"
      fi ;;

  *) usage ;;
esac

if [ ${flagError} = 0 ] ; then
  if [ "${proxyStatus}" = "" ] ; then
    printf "\n%bSet \"${PROXY_TYPE}\" proxy%b\n\n" "${REVERSE}${YELLOW}" "${STD}"
    export http_proxy=${PROXY}
    export HTTP_PROXY=${PROXY}
    export https_proxy=${PROXY}
    export HTTPS_PROXY=${PROXY}
    export no_proxy=${NO_PROXY}
    export NO_PROXY
  else
    printf "\n%bUnset proxy...%b\n\n" "${REVERSE}${YELLOW}" "${STD}"
    unset PROXY_TYPE http_proxy HTTP_PROXY https_proxy HTTPS_PROXY no_proxy NO_PROXY
  fi
  set_prompt
fi