#!/bin/bash
#===========================================================================
# Log with govc cli to vsphere vcenter
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

#--- Select vcenter
flag=0
while [ ${flag} = 0 ] ; do
  flag=1
  printf "\n%bVcenter :%b\n\n" "${REVERSE}${GREEN}" "${STD}"
  printf "%b1%b : region 1\n" "${GREEN}${BOLD}" "${STD}"
  printf "%b2%b : region 2\n" "${GREEN}${BOLD}" "${STD}"
  printf "\n%bYour choice :%b " "${GREEN}${BOLD}" "${STD}" ; read choice
  case "${choice}" in
    1) GOVC_TARGET="vcenter" ;;
    2) GOVC_TARGET="2_vcenter" ; export GOVC_INSECURE=1 ;;  #--- vcenter region 2 is not trusted with pki
    *) flag=0 ; clear ;;
  esac
done

#--- Set environment variables
getCredhubValue "GOVC_URL" "/secrets/vsphere_${GOVC_TARGET}_ip"
getCredhubValue "GOVC_USERNAME" "/secrets/vsphere_${GOVC_TARGET}_user"
getCredhubValue "GOVC_PASSWORD" "/secrets/vsphere_${GOVC_TARGET}_password"
getCredhubValue "GOVC_DATACENTER" "/secrets/vsphere_${GOVC_TARGET}_dc"
getCredhubValue "GOVC_DATASTORE" "/secrets/vsphere_${GOVC_TARGET}_ds"
getCredhubValue "GOVC_CLUSTER" "/secrets/vsphere_${GOVC_TARGET}_cluster"
getCredhubValue "GOVC_RESOURCE_POOL" "/secrets/vsphere_${GOVC_TARGET}_resource_pool"

export GOVC_URL GOVC_USERNAME GOVC_PASSWORD GOVC_DATACENTER GOVC_DATASTORE GOVC_CLUSTER GOVC_RESOURCE_POOL

printf "\n"