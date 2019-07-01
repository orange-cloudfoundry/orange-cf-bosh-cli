#!/bin/bash
#===========================================================================
# Internet-proxy activation/deactivation
#===========================================================================

#--- Colors and styles
export GREEN='\033[1;32m'
export BLUE='\033[1;34m'
export CYAN='\033[1;36m'
export YELLOW='\033[1;33m'
export STD='\033[0m'
export BOLD='\033[1m'

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
  export http_proxy=http://system-internet-http-proxy.internal.paas:3128
  export https_proxy=${http_proxy}
  export PS1="${GREEN}\h@${SITE_NAME}${YELLOW}[proxy]${CYAN}\$(parse_git_branch)${STD}:${BLUE}\w${STD}\$ "
else
  printf "%bDeactivate \"internet-proxy\"%b\n" "${YELLOW}${BOLD}" "${STD}"
  unset http_proxy
  unset https_proxy
  export PS1="${GREEN}\h@${SITE_NAME}${CYAN}\$(parse_git_branch)${STD}:${BLUE}\w${STD}\$ "
fi
