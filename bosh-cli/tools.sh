#!/bin/bash
#===========================================================================
# List available tools
#===========================================================================

#--- Colors and styles
export GREEN='\033[0;32m'
export STD='\033[0m'
export BOLD='\033[1m'
export REVERSE='\033[7m'

display() {
  printf "%b%-15s%b: %s\n" "${GREEN}${BOLD}" "$1" "${STD}" "$2"
}

clear
printf "%bTOOLS%b\n" "${GREEN}${BOLD}${REVERSE}" "${STD}"
display "f" "String search in the sub-trees"
display "gitlog" "Display git commits in nice format"
display "log-bosh" "Log with bosh CLI V2"
display "log-cf" "Log with cf CLI"
display "log-credhub" "Log with credhub CLI"
display "log-fly" "Log with concourse CLI"
display "log-mc" "Log with minio/OBOS S3 CLI"
display "log-openstack" "Log with openstack CLI tools"
display "log-uaac" "Log with uaac ruby CLI tools"
display "switch" "Switch to new bosh deployment in the same director"
printf "\n"