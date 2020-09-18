#!/bin/bash
#===========================================================================
# Switch to bosh deployment within the same bosh director
#===========================================================================

bosh env > /dev/null 2>&1
if [ $? != 0 ] ; then
  printf "\n\n%bERROR : You are not connected to bosh director.%b\n\n" "${RED}" "${STD}"
else
  #--- Select specific deployment (BOSH_DEPLOYMENT variable)
  deployments=$(bosh deployments --column=Name | grep -vE "^Name$|^Succeeded$|^[0-9]* deployments$")
  if [ "$1" != "" ] ; then
    flag=$(echo "${deployments}" | grep "$1")
    if [ "${flag}" = "" ] ; then
      unset BOSH_DEPLOYMENT
    else
      export BOSH_DEPLOYMENT="$1"
      bosh instances
    fi
  else
    printf "\n%bSelect a specific deployment in the list:%b\n%s" "${REVERSE}${GREEN}" "${STD}" "${deployments}"
    printf "\n\n%bYour choice (<Enter> to select all) :%b " "${GREEN}${BOLD}" "${STD}" ; read choice
    if [ "${choice}" = "" ] ; then
      unset BOSH_DEPLOYMENT
    else
      flag=$(echo "${deployments}" | grep "${choice}")
      if [ "${flag}" = "" ] ; then
        unset BOSH_DEPLOYMENT
      else
        export BOSH_DEPLOYMENT="${choice}"
        bosh instances
      fi
    fi
  fi
  printf "\n"
fi