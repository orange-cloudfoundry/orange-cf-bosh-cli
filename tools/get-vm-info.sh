#!/bin/bash
#================================================================================
# Get vm properties from its ip (log-govc before)
#================================================================================

if [ "${GOVC_URL}" = "" ] ; then
  printf "\n%bERROR : You must log to govc before using this script.%b\n\n" "${RED}" "${STD}" ; exit 1
fi

vm_ip="$1"
if [ "${vm_ip}" = "" ] ; then
  printf "\n%bUSAGE: $(basename -- $0) [vm_ip]%b\n\n" "${RED}" "${STD}" ; exit 1
fi

#--- Get vm properties
vm_name="$(govc vm.info -vm.ip=${vm_ip} | grep "Name:" | sed -e "s+^Name: *++g")"
if [ "${vm_name}" = "" ] ; then
  printf "\n%bERROR : No existing vm with ip \"${vm_ip}\".%b\n\n" "${RED}" "${STD}" ; exit 1
fi

#--- Get bosh properties
printf "\n%bvm properties...%b\n" "${REVERSE}${YELLOW}" "${STD}"
vm_info="$(govc vm.info -json ${vm_name} | jq -r '.VirtualMachines[]' 2> /dev/null)"
if [ "${vm_info}" = "" ] ; then
  printf "\n%bERROR : No informations for ip \"${vm_ip}\".%b\n\n" "${RED}" "${STD}" ; exit 1
fi

#--- Get vms properties
vm_host="$(govc vm.info ${vm_name} | awk '/Host/ {print $2}')"
datastore="$(echo "${vm_info}" | jq -r '.Config.DatastoreUrl[].Name')"
power_state="$(echo "${vm_info}" | jq -r '.Summary.Runtime.PowerState')"
vm_uptime="$(echo "${vm_info}" | jq -r '.Summary.QuickStats.UptimeSeconds')"
vm_uptime="$(printf "%d days %d hours %d mn\n" $((vm_uptime/86400)) $((vm_uptime%86400/3600)) $((vm_uptime%3600/60)))"
nb_cpus="$(echo "${vm_info}" | jq -r '.Summary.Config.NumCpu')"
memory_size="$(echo "${vm_info}" | jq -r '.Summary.Config.MemorySizeMB')"
nb_diks="$(echo "${vm_info}" | jq -r '.Summary.Config.NumVirtualDisks')"
nb_ethernet="$(echo "${vm_info}" | jq -r '.Summary.Config.NumEthernetCards')"
vm_ips="$(echo "${vm_info}" | jq -r '.Guest?.Net[]?.IpAddress[]' | tr '\n' ' ')"
if [ "${vm_ips}" =  "" ] ; then
  vm_ips="$(echo "${vm_info}" | jq -r '.Guest.IpAddress')"
fi

bosh_properties="$(echo "${vm_info}" | jq -r '.Value')"
if [ "${bosh_properties}" != "null" ] ; then
  tags="$(echo "${vm_info}" | jq -r '.AvailableField[]')"
  key="$(echo "${tags}" | jq -r '.|select(.Name == "director")|.Key')"
  director="$(echo "${bosh_properties}" | jq -r --arg KEY "${key}" '.[]|select(.Key|tostring == $KEY)|.Value')"
  key="$(echo "${tags}" | jq -r '.|select(.Name == "deployment")|.Key')"
  deployment="$(echo "${bosh_properties}" | jq -r --arg KEY "${key}" '.[]|select(.Key|tostring == $KEY)|.Value')"
  key="$(echo "${tags}" | jq -r '.|select(.Name == "name")|.Key')"
  instance="$(echo "${bosh_properties}" | jq -r --arg KEY "${key}" '.[]|select(.Key|tostring == $KEY)|.Value')"
  key="$(echo "${tags}" | jq -r '.|select(.Name == "created_at")|.Key')"
  created="$(echo "${bosh_properties}" | jq -r --arg KEY "${key}" '.[]|select(.Key|tostring == $KEY)|.Value')"
  printf "bosh director   : ${director}\n"
  printf "bosh deployment : ${deployment}\n"
  printf "bosh instance   : ${instance}\n"
  printf "bosh created    : ${created}\n\n"
fi

printf "vm name         : ${vm_name}\n"
printf "vm host         : ${vm_host}\n"
printf "vm datastore    : ${datastore}\n"
printf "vm power state  : ${power_state}\n"
printf "vm uptime       : ${vm_uptime}\n"
printf "cpus            : ${nb_cpus}\n"
printf "memory size Mb  : ${memory_size}\n"
printf "ethernet cards  : ${nb_ethernet}\n"
printf "vm ips          : ${vm_ips}\n"
printf "disks           : ${nb_diks}\n"
govc guest.df -vm ${vm_name}
