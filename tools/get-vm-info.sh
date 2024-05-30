#!/bin/bash
#================================================================================
# Get vm properties (log-govc before)
#================================================================================

if [ "${GOVC_URL}" = "" ] ; then
  printf "\n%bERROR : You must log to govc before using this script.%b\n\n" "${RED}" "${STD}" ; exit 1
fi

#--- Check scripts options
nbParameters=$# ; vm_ip="" ; vm_name="" ; vm_macaddress=""
usage() {
  printf "\n%bUSAGE:" "${RED}"
  printf "\n  vm-info [OPTIONS]\n\nOPTIONS:"
  printf "\n  %-40s %s" "--ip, -i <vm ip>" "Get vm informations by ip"
  printf "\n  %-40s %s" "--macaddress, -m <vm mac address>" "Get vm informations by mac address"
  printf "\n  %-40s %s" "--name, -n <vm name>" "Get vm informations by name"
  printf "%b\n\n" "${STD}" ; exit 1
}

#--- Check scripts options
if [ "$1" = "" ] ; then
  usage
fi

while [ ${nbParameters} -gt 0 ] ; do
  case "$1" in
    "-i"|"--ip") vm_ip="$2" ; shift ; shift ; nbParameters=$#
      if [ "${vm_ip}" = "" ] ; then
        usage
      else
        vm_name="$(govc vm.info -vm.ip=${vm_ip} | grep "Name:" | sed -e "s+^Name: *++g")"
        if [ "${vm_name}" = "" ] ; then
          printf "\n%bERROR : No existing vm with ip \"${vm_ip}\".%b\n\n" "${RED}" "${STD}" ; exit 1
        fi
      fi ;;

    "-m"|"--macaddress") vm_macaddress="$2" ; shift ; shift ; nbParameters=$#
      if [ "${vm_macaddress}" = "" ] ; then
        usage
      else
        vm_macaddress="$(echo "${vm_macaddress}" | tr [:upper:] [:lower:])"
        vm_id="$(govc object.collect -json -type m / config.hardware.device | jq -r '. | select(.changeSet[].val.virtualDevice[].macAddress == "'$vm_macaddress'") | [.obj.type, .obj.value] | join(":")')"
        if [ "${vm_id}" = "" ] ; then
          printf "\n%bERROR :  No existing vm with mac address \"${vm_macaddress}\".%b\n\n" "${RED}" "${STD}" ; exit 1
        fi
        vm_ipath="$(echo "${vm_id}" | xargs govc ls -L | xargs -I {} -n 1 echo "{}")"
        vm_name="$(govc vm.info -vm.ipath="${vm_ipath}" | grep "Name:" | awk '{print $2}')"
      fi ;;

    "-n"|"--name") vm_name="$2" ; shift ; shift ; nbParameters=$#
      if [ "${vm_name}" = "" ] ; then
        usage
      fi ;;

    *) usage ;;
  esac
done

#--- Get vm properties
printf "\n%bGet \"${vm_name}\" properties...%b\n" "${REVERSE}${YELLOW}" "${STD}"
vm_info="$(govc vm.info -json ${vm_name} | jq -r '.virtualMachines[]' 2> /dev/null)"
if [ "${vm_info}" = "" ] ; then
  printf "\n%bERROR : No existing vm with name \"${vm_name}\".%b\n\n" "${RED}" "${STD}" ; exit 1
fi

vm_host="$(govc vm.info ${vm_name} | awk '/Host/ {print $2}')"
hw_version="$(echo "${vm_info}" | jq -r '.config.version')"
datastore="$(echo "${vm_info}" | jq -r '.config.datastoreUrl[].name')"
power_state="$(echo "${vm_info}" | jq -r '.summary.runtime.powerState')"
vm_uptime="$(echo "${vm_info}" | jq -r '.summary.quickStats.uptimeSeconds')"
vm_uptime_days="$(expr ${vm_uptime} / 86400)"
vm_uptime_hours="$(expr ${vm_uptime} % 86400 / 3600)"
vm_uptime_mn="$(expr ${vm_uptime} % 3600 / 60)"
vm_uptime="$(printf "%d days %d hours %d mn\n" ${vm_uptime_days} ${vm_uptime_hours} ${vm_uptime_mn})"
nb_cpus="$(echo "${vm_info}" | jq -r '.summary.config.numCpu')"
memory_size="$(echo "${vm_info}" | jq -r '.summary.config.memorySizeMB')"
nb_diks="$(echo "${vm_info}" | jq -r '.summary.config.numVirtualDisks')"
nb_ethernet="$(echo "${vm_info}" | jq -r '.summary.config.numEthernetCards')"
vm_ips="$(echo "${vm_info}" | jq -r '.guest?.net[]?.ipAddress[]?' | tr '\n' ' ')"
if [ "${vm_ips}" = "" ] ; then
  vm_ips="$(echo "${vm_info}" | jq -r '.guest.ipAddress')"
fi
macAddress="$(echo "${vm_info}" | jq -r '.config.hardware.device[]|.macAddress' | grep -v "^$" | grep -v "null" | tr '\n' ' ')"

bosh_properties="$(echo "${vm_info}" | jq -r '.value')"
if [ "${bosh_properties}" != "null" ] ; then
  tags="$(echo "${vm_info}" | jq -r '.availableField[]')"
  key="$(echo "${tags}" | jq -r '.|select(.name == "director")|.key')"
  director="$(echo "${bosh_properties}" | jq -r --arg KEY "${key}" '.[]|select(.key|tostring == $KEY)|.value')"
  key="$(echo "${tags}" | jq -r '.|select(.name == "deployment")|.key')"
  deployment="$(echo "${bosh_properties}" | jq -r --arg KEY "${key}" '.[]|select(.key|tostring == $KEY)|.value')"
  key="$(echo "${tags}" | jq -r '.|select(.name == "name")|.key')"
  instance="$(echo "${bosh_properties}" | jq -r --arg KEY "${key}" '.[]|select(.key|tostring == $KEY)|.value')"
  key="$(echo "${tags}" | jq -r '.|select(.name == "created_at")|.key')"
  created="$(echo "${bosh_properties}" | jq -r --arg KEY "${key}" '.[]|select(.key|tostring == $KEY)|.value')"
  printf "bosh director   : ${director}\n"
  printf "bosh deployment : ${deployment}\n"
  printf "bosh instance   : ${instance}\n"
  printf "bosh created    : ${created}\n\n"
fi

printf "vm name         : ${vm_name}\n"
printf "vm host         : ${vm_host}\n"
printf "vm datastore    : ${datastore}\n"
printf "vm hw version   : ${hw_version}\n"
printf "vm power state  : ${power_state}\n"
printf "vm uptime       : ${vm_uptime}\n"
printf "cpus            : ${nb_cpus}\n"
printf "memory size Mb  : ${memory_size}\n"
printf "ethernet cards  : ${nb_ethernet}\n"
printf "vm ips          : ${vm_ips}\n"
printf "vm macAddress   : ${macAddress}\n"
printf "disks           : ${nb_diks}\n"
govc guest.df -vm ${vm_name}
