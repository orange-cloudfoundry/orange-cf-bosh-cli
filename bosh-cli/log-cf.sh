#!/bin/bash
#===========================================================================
# Log with cf cli
#===========================================================================

#--- Colors and styles
export RED='\033[1;31m'
export YELLOW='\033[1;33m'
export GREEN='\033[1;32m'
export STD='\033[0m'
export BOLD='\033[1m'
export REVERSE='\033[7m'

#--- Log to CF
flag=0
while [ ${flag} = 0 ] ; do
  printf "\n%bCF User :%b " "${REVERSE}${YELLOW}" "${STD}" ; read CF_USER
  if [ "${CF_USER}" = "" ] ; then
    clear
  else
    flag=1
  fi
done

#--- Log to cf
cf login -a https://api.${SYSTEM_DOMAIN} -u ${CF_USER}
if [ $? = 0 ] ; then
  printf "\n\n"
else
  printf "\n%bERROR : Connexion failed.%b\n\n" "${RED}" "${STD}"
fi