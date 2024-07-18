#!/bin/bash
#===========================================================================
# Log with shield cli
#===========================================================================

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
flagError=0
flag=$(credhub f > /dev/null 2>&1)
if [ $? != 0 ] ; then
  printf "\n%bLDAP user and password :%b\n" "${REVERSE}${GREEN}" "${STD}"
  printf "username: " ; read LDAP_USER
  credhub login --server=https://credhub.internal.paas:8844 -u ${LDAP_USER}
  if [ $? != 0 ] ; then
    printf "\n%bERROR : LDAP authentication failed with \"${LDAP_USER}\" account.%b\n\n" "${RED}" "${STD}" ; flagError=1
  fi
fi

#--- Log to CF
if [ ${flagError} = 0 ] ; then
  export SHIELD_CORE="paas-templates"
  getCredhubValue "OPS_DOMAIN" "/secrets/cloudfoundry_ops_domain"

  if [ ${flagError} = 0 ] ; then
    shield api -k https://shieldv8-webui.${OPS_DOMAIN} paas-templates
    if [ $? != 0 ] ; then
      printf "\n\n%bERROR : Config shield api failed.%b\n\n" "${RED}" "${STD}" ; flagError=1
    fi
  fi

  if [ ${flagError} = 0 ] ; then
    getCredhubValue "ADMIN_PASSWORD" "/bosh-master/shieldv8/failsafe-password"
  fi

  if [ ${flagError} = 0 ] ; then
    shield login -u admin -p ${ADMIN_PASSWORD}
    if [ $? != 0 ] ; then
      printf "\n\n%bERROR : Shield login failed.%b\n\n" "${RED}" "${STD}" ; flagError=1
    fi
  fi
fi

printf "\n"