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

#--- Set user prompt
parse_git_branch()
{
  local BRANCH=$(git symbolic-ref HEAD --short 2> /dev/null)
  if [ ! -z "${BRANCH}" ] ; then
    echo "(${BRANCH})"
  else
    echo ""
  fi
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
    NO_PROXY="127.0.0.1,localhost,169.254.0.0/16,192.168.0.0/16,172.17.11.0/24,.internal.paas,.intraorange,.ftgroup,.francetelecom.fr" ;;

  "") if [ "${proxyStatus}" = "" ] ; then
        PROXY_TYPE="internet"
        PROXY="http://system-internet-http-proxy.internal.paas:3128"
        NO_PROXY="127.0.0.1,localhost,169.254.0.0/16,192.168.0.0/16,172.17.11.0/24,.internal.paas,.intraorange,.ftgroup,.francetelecom.fr"
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
    export PS1="\[\033[32m\]\h@${SITE_NAME}\[\033[33m\][${PROXY_TYPE} proxy]\[\033[36m\]\$(parse_git_branch)\[\033[0m\]:\[\033[34m\]\w\[\033[0m\]\$ "
  else
    printf "\n%bUnset proxy...%b\n\n" "${REVERSE}${YELLOW}" "${STD}"
    unset http_proxy HTTP_PROXY https_proxy HTTPS_PROXY no_proxy NO_PROXY
    export PS1="\[\033[32m\]\h@${SITE_NAME}\[\033[36m\]\$(parse_git_branch)\[\033[0m\]:\[\033[34m\]\w\[\033[0m\]\$ "
  fi
fi