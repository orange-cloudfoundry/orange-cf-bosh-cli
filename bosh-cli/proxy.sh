#!/bin/bash
#===========================================================================
# Internet-proxy activation/deactivation
#===========================================================================

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

proxyStatus=`env | grep -i "http_proxy"`
if [ "${proxyStatus}" = "" ] ; then
  printf "%bActivate \"internet-proxy\"%b\n" "${YELLOW}${BOLD}" "${STD}"
  export http_proxy="http://system-internet-http-proxy.internal.paas:3128"
  export no_proxy="127.0.0.1,localhost,169.254.0.0/16,192.168.0.0/16,172.17.11.0/24,.internal.paas..intraorange,.ftgroup,.francetelecom.fr"
  export https_proxy=${http_proxy}
  export HTTP_PROXY=${http_proxy}
  export HTTPS_PROXY=${http_proxy}
  export NO_PROXY=${no_proxy}
  export PS1="\[\033[32m\]\h@${SITE_NAME}\[\033[33m\][proxy]\[\033[36m\]\$(parse_git_branch)\[\033[0m\]:\[\033[34m\]\w\[\033[0m\]\$ "
else
  printf "%bDeactivate \"internet-proxy\"%b\n" "${YELLOW}${BOLD}" "${STD}"
  unset http_proxy https_proxy no_proxy
  unset HTTP_PROXY HTTPS_PROXY NO_PROXY
  export PS1="\[\033[32m\]\h@${SITE_NAME}\[\033[36m\]\$(parse_git_branch)\[\033[0m\]:\[\033[34m\]\w\[\033[0m\]\$ "
fi
