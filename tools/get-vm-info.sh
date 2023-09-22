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
        vm_id="$(govc object.collect -json -type m / config.hardware.device | jq -r '. | select(.ChangeSet[].Val.VirtualDevice[].MacAddress == "'$vm_macaddress'") | [.Obj.Type, .Obj.Value] | join(":")')"
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
printf "\n%bvm properties...%b\n" "${REVERSE}${YELLOW}" "${STD}"
vm_info="$(govc vm.info -json ${vm_name} | jq -r '.VirtualMachines[]' 2> /dev/null)"
if [ "${vm_info}" = "" ] ; then
  printf "\n%bERROR : No existing vm with name \"${vm_name}\".%b\n\n" "${RED}" "${STD}" ; exit 1
fi

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
macAddress="$(echo "${vm_info}" | jq -r '.Config.Hardware.Device[]|.MacAddress' | grep -v "^$" | grep -v "null" | tr '\n' ' ')"

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
printf "vm macAddress   : ${macAddress}\n"
printf "disks           : ${nb_diks}\n"
govc guest.df -vm ${vm_name}
