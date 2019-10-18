#!/bin/bash
#===========================================================================
# List available tools and aliases
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
printf "%bBOSH TOOLS%b\n" "${GREEN}${BOLD}${REVERSE}" "${STD}"
display "bbr" "Bosh backup and restore cli"
display "log-bosh" "Log with bosh cli"
display "switch" "Switch to new bosh deployment in the same director"

printf "\n%bKUBERNETES TOOLS%b\n" "${GREEN}${BOLD}${REVERSE}" "${STD}"
display "helm" "Kubernetes package manager cli"
display "log-k8s" "Log with kubernetes cli (kubectl, helm)"
display "kubectl" "Kubernetes cluster manager cli"
display "smctl" "Service Manager instance cli"

printf "\n%bOTHER CLI TOOLS%b\n" "${GREEN}${BOLD}${REVERSE}" "${STD}"
display "credhub-get" "Get credhub propertie value"
display "go3fr" "S3 cli"
display "init-mc" "Init mc config for minio access"
display "init-pynsxv" "Init pynsxv config for nsx-v access"
display "log-cf" "Log with cf cli"
display "log-credhub" "Log with credhub cli"
display "log-fly" "Log with concourse cli"
display "log-openstack" "Log with openstack cli"
display "log-uaac" "Log with uaac cli"
display "prune-workers" "Prune concourse stalled workers (used with log-fly)"
display "pynsxv" "nsx-v cli"
display "shield" "Shield cli"
display "terraform" "Terraform cli"

printf "\n%bGENERIC TOOLS%b\n" "${GREEN}${BOLD}${REVERSE}" "${STD}"
display "f" "Search for a string in sub-trees"
display "gitlog" "Display git commits in nice format"
display "init-git" "Init minimal git config"
display "jq" "Command line json processor"
display "proxy" "Activate/deactivate internet proxy"
display "show-cert" "Show certificate (subject, issuer and expiry)"
display "show-csr" "Show certificate signing request"
display "spruce" "Command line yaml processor"
display "tn" "Set terminal name"

printf "\n"