#!/bin/bash
#================================================================================
# Get vm properties (log-govc before)
#================================================================================

if [ "${GOVC_URL}" = "" ] ; then
  printf "\n%bERROR : You must log to govc before using this script.%b\n" "${RED}" "${STD}" ; exit 1
fi

#--- Check scripts options
nbParameters=$# ; vm_ip="" ; vm_name="" ; vm_macaddress=""
usage() {
  printf "\n%bUSAGE:" "${RED}"
  printf "\n  vm-info [OPTIONS]\n\nOPTIONS:"
  printf "\n  %-40s %s" "-d, --disk-id <vm disk id>" "Get vm informations by disk id"
  printf "\n  %-40s %s" "-i, --ip <vm ip>" "Get vm informations by ip"
  printf "\n  %-40s %s" "-m, --macaddress <vm mac address>" "Get vm informations by mac address"
  printf "\n  %-40s %s" "-n, --name <vm name>" "Get vm informations by name"
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
        vm_ids="$(govc object.collect -json -type m / guest | jq -r '.|select(.changeSet[].val.ipAddress == "'$vm_ip'") | [.obj.type, .obj.value] | join(":")')"
        for vm_id in ${vm_ids} ; do
          result="$(echo "${vm_id}" | xargs govc ls -L | xargs -I {} -n 1 echo "{}" | grep "${GOVC_RESOURCE_POOL}")"
          if [ "${result}" != "" ] ; then
            vm_ipath="${result}"
          fi
        done

        if [ "${vm_ipath}" = "" ] ; then
          printf "\n%bERROR : No existing vm with ip \"${vm_ip}\".%b\n" "${RED}" "${STD}" ; exit 1
        fi
        vm_name="$(govc vm.info -vm.ipath="${vm_ipath}" | grep "Name:" | awk '{print $2}')"
      fi ;;

    "-d"|"--disk-id") vm_disk_id="$2" ; shift ; shift ; nbParameters=$#
      if [ "${vm_disk_id}" = "" ] ; then
        usage
      else
        vm_disk_id="$(echo "${vm_disk_id}" | tr [:upper:] [:lower:])"
        vm_id="$(govc object.collect -json -type m / config.hardware.device | jq -r '.|select(.changeSet[].val._value[].backing.fileName|tostring|match("'$vm_disk_id'")) | [.obj.type, .obj.value] | join(":")')"
        if [ "${vm_id}" = "" ] ; then
          printf "\n%bERROR :  No existing vm with disk id \"${vm_disk_id}\".%b\n" "${RED}" "${STD}" ; exit 1
        fi
        vm_ipath="$(echo "${vm_id}" | xargs govc ls -L | xargs -I {} -n 1 echo "{}")"
        vm_name="$(govc vm.info -vm.ipath="${vm_ipath}" | grep "Name:" | awk '{print $2}')"
      fi ;;

    "-m"|"--macaddress") vm_macaddress="$2" ; shift ; shift ; nbParameters=$#
      if [ "${vm_macaddress}" = "" ] ; then
        usage
      else
        vm_macaddress="$(echo "${vm_macaddress}" | tr [:upper:] [:lower:])"
        vm_id="$(govc object.collect -json -type m / guest | jq -r '.|select(.changeSet[].val.net[]?.macAddress == "'$vm_macaddress'") | [.obj.type, .obj.value] | join(":")')"
        if [ "${vm_id}" = "" ] ; then
          printf "\n%bERROR :  No existing vm with mac address \"${vm_macaddress}\".%b\n" "${RED}" "${STD}" ; exit 1
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
  printf "\n%bERROR : No existing vm with name \"${vm_name}\".%b\n" "${RED}" "${STD}" ; exit 1
fi

vm_host="$(govc vm.info ${vm_name} | awk '/Host/ {print $2}' 2> /dev/null)"
hw_version="$(echo "${vm_info}" | jq -r '.config.version' 2> /dev/null)"
vm_ephemeral_datastore="$(echo "${vm_info}" | jq -r '.config.files.vmPathName' 2> /dev/null | sed -e "s+\[++" -e "s+\].*++g")"
vm_persistent_datastore="$(echo "${vm_info}" | jq -r '.config.vAppConfig.property[].value' 2> /dev/null | sed -e "s+\[++" -e "s+\].*++g")"
vm_disk_persistent_id="$(echo "${vm_info}" | jq -r '.config.vAppConfig.property[].id' 2> /dev/null)"
power_state="$(echo "${vm_info}" | jq -r '.summary.runtime.powerState' 2> /dev/null)"
vm_created="$(echo "${vm_info}"| jq -r '.config.createDate|select(. != null)' 2> /dev/null)"
vm_uptime="$(echo "${vm_info}" | jq -r '.summary.quickStats.uptimeSeconds' 2> /dev/null)"
vm_uptime_days="$(expr ${vm_uptime} / 86400)"
vm_uptime_hours="$(expr ${vm_uptime} % 86400 / 3600)"
vm_uptime_mn="$(expr ${vm_uptime} % 3600 / 60)"
vm_uptime="$(printf "%d days %d hours %d mn\n" ${vm_uptime_days} ${vm_uptime_hours} ${vm_uptime_mn})"
nb_cpus="$(echo "${vm_info}" | jq -r '.summary.config.numCpu' 2> /dev/null)"
memory_size="$(echo "${vm_info}" | jq -r '.summary.config.memorySizeMB' 2> /dev/null)"
nb_diks="$(echo "${vm_info}" | jq -r '.summary.config.numVirtualDisks' 2> /dev/null)"
nb_ethernet="$(echo "${vm_info}" | jq -r '.summary.config.numEthernetCards' 2> /dev/null)"
vm_ips="$(echo "${vm_info}" | jq -r '.guest.net[]|select(.network!=null)|.network + " (" + .macAddress + ") " + .ipConfig.ipAddress[].ipAddress')"
vm_ips="$(echo "${vm_ips}" | sed -e "2,\$s+^+                          +g")"

bosh_properties="$(echo "${vm_info}" | jq -r '.value')"
if [ "${bosh_properties}" != "null" ] ; then
  tags="$(echo "${vm_info}" | jq -r '.availableField[]' 2> /dev/null)"
  key="$(echo "${tags}" | jq -r '.|select(.name == "director")|.key')"
  director="$(echo "${bosh_properties}" | jq -r --arg KEY "${key}" '.[]|select(.key|tostring == $KEY)|.value')"
  key="$(echo "${tags}" | jq -r '.|select(.name == "deployment")|.key')"
  deployment="$(echo "${bosh_properties}" | jq -r --arg KEY "${key}" '.[]|select(.key|tostring == $KEY)|.value')"
  key="$(echo "${tags}" | jq -r '.|select(.name == "name")|.key')"
  instance="$(echo "${bosh_properties}" | jq -r --arg KEY "${key}" '.[]|select(.key|tostring == $KEY)|.value')"
  key="$(echo "${tags}" | jq -r '.|select(.name == "created_at")|.key')"
  deployed="$(echo "${bosh_properties}" | jq -r --arg KEY "${key}" '.[]|select(.key|tostring == $KEY)|.value')"
  printf "bosh director           : ${director}\n"
  printf "bosh deployment         : ${deployment}\n"
  printf "bosh instance           : ${instance}\n"
  printf "bosh deployed           : ${deployed}\n\n"
fi

printf "vm name                 : ${vm_name}\n"
printf "vm host                 : ${vm_host}\n"
printf "vm ephemeral datastore  : ${vm_ephemeral_datastore}\n"
if [ "${vm_disk_persistent_id}" != "" ] ; then
  printf "vm persistent datastore : ${vm_persistent_datastore}\n"
  printf "persistent disk id      : ${vm_disk_persistent_id}\n"
fi
printf "vm hw version           : ${hw_version}\n"
printf "vm power state          : ${power_state}\n"
printf "vm created              : ${vm_created}\n"
printf "vm uptime               : ${vm_uptime}\n"
printf "cpus                    : ${nb_cpus}\n"
printf "memory size Mb          : ${memory_size}\n"
printf "ethernet cards          : ${nb_ethernet}\n"
printf "ips segments            : ${vm_ips}\n"
printf "disks                   : ${nb_diks}\n"
govc guest.df -vm ${vm_name} | grep -E "Filesystem|/home|/var/vcap/data|/var/vcap/store"
