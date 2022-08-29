#!/bin/bash
#===========================================================================
# Log with cf cli
#===========================================================================

#--- Log to CF
flag=0
while [ ${flag} = 0 ] ; do
  printf "\n%bCF User :%b " "${REVERSE}${GREEN}" "${STD}" ; read CF_USER
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