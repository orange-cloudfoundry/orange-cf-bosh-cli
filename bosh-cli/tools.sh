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
  printf "%b%-18s%b: %s\n" "${GREEN}${BOLD}" "$1" "${STD}" "$2"
}

clear
printf "%bTOOLS%b\n" "${GREEN}${BOLD}${REVERSE}" "${STD}"
display "bbr" "Bosh backup and restore cli"
display "credhub-get" "Get credhub propertie value"
display "f" "Search for a string in sub-trees"
display "gitlog" "Display git commits in nice format"
display "go3fr" "S3 cli"
display "helm" "Kubernetes package manager cli"
display "jq" "Commandline json processor"
display "kubectl" "Kubernetes cluster manager cli"
display "log-bosh" "Log with bosh cli"
display "log-cf" "Log with cf cli"
display "log-credhub" "Log with credhub cli"
display "log-fly" "Log with concourse cli"
display "log-mc" "Log with minio S3 cli"
display "log-openstack" "Log with openstack cli"
display "log-uaac" "Log with uaac cli"
display "mc-config" "Init mc config for minio access"
display "prune-workers" "Prune concourse stalled workers (used with log-fly)"
display "shield" "Shield cli"
display "show-cert" "Show certificate (subject, issuer and expiry)"
display "show-csr" "Show certificate signing request"
display "smctl" "Service Manager instance cli"
display "spruce" "Commandline yaml processor"
display "switch" "Switch to new bosh deployment in the same director"
display "terraform" "Terraform cli"
printf "\n"