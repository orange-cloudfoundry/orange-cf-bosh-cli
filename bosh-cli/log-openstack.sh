#!/bin/bash
#===========================================================================
# Log with openstack cli tools
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

#--- Select openstack region
flag=0
while [ ${flag} = 0 ] ; do
  flag=1
  printf "\n%bOpenstack :%b\n\n" "${REVERSE}${GREEN}" "${STD}"
  printf "%b1%b : region 1\n" "${GREEN}${BOLD}" "${STD}"
  printf "%b2%b : region 2\n" "${GREEN}${BOLD}" "${STD}"
  printf "%b3%b : region 3\n" "${GREEN}${BOLD}" "${STD}"
  printf "\n%bYour choice :%b " "${GREEN}${BOLD}" "${STD}" ; read choice
  case "${choice}" in
    1) OPENSTACK_PREFIX="openstack" ;;
    2) OPENSTACK_PREFIX="openstack_2" ;;
    3) OPENSTACK_PREFIX="openstack_3" ;;
    *) flag=0 ; clear ;;
  esac
done

#--- Log to openstack
if [ "${flagError}" = "0" ] ; then
  #--- Common keystone parameters V2/V3
  getCredhubValue "OS_AUTH_URL" "/secrets/${OPENSTACK_PREFIX}_auth_url"
  OS_AUTH_URL="$(echo "${OS_AUTH_URL}" | sed -e "s+/$++")"
  getCredhubValue "OS_USERNAME" "/secrets/${OPENSTACK_PREFIX}_username"
  getCredhubValue "OS_PASSWORD" "/secrets/${OPENSTACK_PREFIX}_password"
  export OS_AUTH_URL
  export OS_USERNAME
  export OS_PASSWORD

  unset OS_PROJECT_NAME
  getCredhubValue "OS_PROJECT_NAME" "/secrets/${OPENSTACK_PREFIX}_project"
  if [ ${flagError} = 0 ] ; then
    #--- Specific keystone V3
    export OS_PROJECT_NAME
    export OS_IDENTITY_API_VERSION="3"
    getCredhubValue "OS_PROJECT_DOMAIN_NAME" "/secrets/${OPENSTACK_PREFIX}_domain"
    export OS_PROJECT_DOMAIN_NAME
    export OS_USER_DOMAIN_NAME="${OS_PROJECT_DOMAIN_NAME}"
  else
    #--- Specific keystone V2
    flagError=0
    getCredhubValue "OS_TENANT_NAME" "/secrets/${OPENSTACK_PREFIX}_tenant"
    getCredhubValue "OS_REGION_NAME" "/secrets/${OPENSTACK_PREFIX}_region"
    export OS_TENANT_NAME
    export OS_REGION_NAME
  fi

  printf "\n"
fi