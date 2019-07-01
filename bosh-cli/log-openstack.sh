#!/bin/bash
#===========================================================================
# Log with openstack cli tools
#===========================================================================

#--- Colors and styles
export RED='\033[1;31m'
export YELLOW='\033[1;33m'
export GREEN='\033[1;32m'
export STD='\033[0m'
export BOLD='\033[1m'
export REVERSE='\033[7m'

#--- Get a propertie value in credhub
getCredhubValue() {
  value=$(credhub g -n $1 | grep 'value: ' | awk '{print $2}')
  if [ $? = 0 ] ; then
    echo "${value}"
  else
    printf "\n\n%bERROR : \"$2\" credhub value unknown.%b\n\n" "${RED}" "${STD}" ; flagError=1
  fi
}

#--- Log to credhub and get properties
flagError=0
flag=$(credhub f > /dev/null 2>&1)
if [ $? != 0 ] ; then
  printf "\n%bEnter LDAP user and password :%b\n" "${REVERSE}${YELLOW}" "${STD}"
  credhub api --server=https://credhub.internal.paas:8844 > /dev/null 2>&1
  printf "username: " ; read LDAP_USER
  credhub login -u ${LDAP_USER}
  if [ $? != 0 ] ; then
    printf "\n%bERROR : Bad LDAP authentication with \"${LDAP_USER}\" account.%b\n\n" "${RED}" "${STD}" ; flagError=1
  fi
fi

#--- Log to openstack
if [ "${flagError}" = "0" ] ; then
  #--- Common keystone parameters V2/V3
  export OS_AUTH_URL="$(getCredhubValue "/secrets/openstack_auth_url")"
  export OS_USERNAME="$(getCredhubValue "/secrets/openstack_username")"
  export OS_PASSWORD="$(getCredhubValue "/secrets/openstack_password")"

  unset OS_PROJECT_NAME
  OS_PROJECT_NAME="$(getCredhubValue "/secrets/openstack_project")"
  if [ ${flagError} = 0 ] ; then
    #--- Specific keystone V3
    export OS_PROJECT_NAME
    export OS_IDENTITY_API_VERSION="3"
    export OS_PROJECT_DOMAIN_NAME="$(getCredhubValue "/secrets/openstack_domain")"
    export OS_USER_DOMAIN_NAME="${OS_PROJECT_DOMAIN_NAME}"
  else
    #--- Specific keystone V2
    flagError=0
    export OS_TENANT_NAME="$(getCredhubValue "/secrets/openstack_tenant")"
    export OS_REGION_NAME="$(getCredhubValue "/secrets/openstack_region")"
  fi

  printf "\n"
fi