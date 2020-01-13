#!/bin/bash
#===========================================================================
# Init pynsxv cli configuration
#===========================================================================

#--- Display information
display() {
  case "$1" in
    "INFO")  printf "\n%b%s...%b\n" "${REVERSE}${YELLOW}" "$2" "${STD}" ;;
    "ERROR") printf "\n%bERROR: %s.%b\n\n" "${REVERSE}${RED}" "$2" "${STD}" ; exit 1 ;;
  esac
}

#--- Get a parameter in credhub
getCredhubValue() {
  value=$(credhub g -n $2 | grep 'value:' | awk '{print $2}')
  if [ "${value}" = "" ] ; then
    printf "\n\n%bERROR : \"$2\" credhub value unknown.%b\n\n" "${RED}" "${STD}" ; flagError=1
  else
    eval "$1=${value}"
  fi
}

#--- Catch a parameter
catchValue() {
  flag=0
  while [ ${flag} = 0 ] ; do
    printf "\n%b%s :%b " "${REVERSE}${GREEN}" "$2" "${STD}" ; read value
    if [ "${value}" != "" ] ; then
      flag=1
    fi
  done
  eval "$1=${value}"
}

#--- Check prerequisistes
if [ "${iaas_type}" != "vsphere" ] ; then
  display "ERROR" "pynsxv is only available for vsphere context"
fi

#--- Log to credhub
log-credhub.sh

#--- Delete unused mc aliases
display "INFO"  "Configure pynsxv cli..."

getCredhubValue "VCENTER_IP" "/secrets/vsphere_vcenter_ip"
getCredhubValue "VCENTER_USER" "/secrets/vsphere_vcenter_user"
getCredhubValue "VCENTER_PASSWORD" "/secrets/vsphere_vcenter_password"
getCredhubValue "VCENTER_DATACENTER" "/secrets/vsphere_vcenter_dc"
getCredhubValue "VCENTER_DATASTORE" "/secrets/vsphere_vcenter_ds"
getCredhubValue "VCENTER_CLUSTER" "/secrets/vsphere_vcenter_cluster"

catchValue "NSX_MANAGER_IP" "NSX manager ip"
catchValue "NSX_PASSWORD" "NSX admin password"
catchValue "TRANSPORT_ZONE" "NSX transport zone"

#--- Create configuration file for nsxv cli
cat > $HOME/.nsx.ini <<EOF
# Uncomment the above section and add the path to the raml spec you want to use instead of the bundled version
# [nsxraml]
# nsxraml_file = ${NSX_RAML_FILE}

[nsxv]
nsx_manager = ${NSX_MANAGER_IP}
nsx_username = admin
nsx_password = ${NSX_PASSWORD}

[vcenter]
vcenter = ${VCENTER_IP}
vcenter_user = ${VCENTER_USER}
vcenter_passwd = ${VCENTER_PASSWORD}

[defaults]
transport_zone = ${TRANSPORT_ZONE}
datacenter_name = ${VCENTER_DATACENTER}
edge_datastore = ${VCENTER_DATASTORE}
edge_cluster = ${VCENTER_CLUSTER}
EOF
