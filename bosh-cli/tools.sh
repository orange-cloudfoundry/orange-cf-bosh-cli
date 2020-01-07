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
display "bbr" "Bosh backup/restore cli"
display "bt" "Filter unnecessary information on bosh task logs display"
display "log-bosh" "Log with bosh cli"
display "switch" "Switch to bosh deployment in the same bosh director"

printf "\n%bKUBERNETES TOOLS%b\n" "${GREEN}${BOLD}${REVERSE}" "${STD}"
display "helm" "Kubernetes package manager cli"
display "log-k8s" "Log with kubernetes cli (kubectl, helm)"
display "kubectl" "Cluster manager cli"
display "k9s" "Cluster manager cli"
display "smctl" "Service Manager instance cli"
display "velero" "Cluster resources, persistent volumes backup/restore"

printf "\n%bOTHER CLI TOOLS%b\n" "${GREEN}${BOLD}${REVERSE}" "${STD}"
display "cg" "Get credhub propertie value"
display "go3fr" "Parallelized and pipelined streaming access to S3 bucket cli"
display "init-mc" "Init mc config for minio access"
display "init-pynsxv" "Init pynsxv config for nsx-v access"
display "log-cf" "Log with cf cli"
display "log-credhub" "Log with credhub cli"
display "log-fly" "Log with concourse cli"
display "log-openstack" "Log with openstack cli"
display "log-shield" "Log with shield cli"
display "log-uaac" "Log with uaac cli"
display "mc" "minio cli"
display "pynsxv" "nsx-v cli"
display "pw" "Prune concourse stalled workers (used with log-fly)"
display "shield" "Shield cli"
display "terraform" "Terraform cli"

printf "\n%bGIT TOOLS%b\n" "${GREEN}${BOLD}${REVERSE}" "${STD}"
display "co" "Checkout on specific branch"
display "commit" "Commit updates"
display "gitlog" "Display git commits in nice format"
display "init-git" "Init minimal git config"
display "prune" "Prune git resources"
display "pull" "Pull updates from remote repository"
display "push" "Push updates to remote repository"

printf "\n%bGENERIC TOOLS%b\n" "${GREEN}${BOLD}${REVERSE}" "${STD}"
display "gp" "Generate password (30 characters)"
display "f" "Search for a string in sub-trees"
display "proxy" "Activate/deactivate internet proxy"
display "show-cert" "Show certificate (subject, issuer and expiry)"
display "show-csr" "Show certificate signing request"
display "tn" "Set terminal name"

printf "\n"