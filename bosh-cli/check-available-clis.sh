#!/bin/bash
#===========================================================================
# Check clis/tools used by bosh-cli (for build image process)
#===========================================================================

set -e
printf "\n====================================================\n=> Check if ruby is available...\n====================================================\n"
ruby -e 'puts "Ruby is installed"'

printf "\n====================================================\n=> Check if python is available...\n====================================================\n"
python3 --version

printf "\n====================================================\n=> Check if expected system tools are available...\n====================================================\n"
chardetect --version
tabulate --help > /dev/null

printf "\n====================================================\n=> Check if expected clis are available...\n====================================================\n"
printf '\n=> Check BBR-CLI\n' ; bbr --version
printf '\n=> Check BOSH-CLI\n' ; bosh --version
printf '\n=> Check CF-CLI\n' ; cf --version
printf '\n=> Check CF7-CLI\n' ; cf7 --version
printf '\n=> Check CREDHUB-CLI\n' ; credhub --version
printf '\n=> Check FLY-CLI\n' ; fly --version
printf '\n=> Check GO3FR-CLI\n' ; go3fr --version
printf '\n=> Check HELM-CLI\n' ; helm version
printf '\n=> Check JQ-CLI\n' ; jq --version
printf '\n=> Check KUBECTL-CLI\n' ; kubectl version --client --short
printf '\n=> Check KUSTOMIZE-CLI\n' ; kustomize version --short
printf '\n=> Check K14S-KAPP-CLI\n' ; kapp version
printf '\n=> Check K14S-KLBD-CLI\n' ; klbd --version
printf '\n=> Check K14S-YTT-CLI\n' ; ytt --version
printf '\n=> Check K9S-CLI\n' ; k9s version --short
printf '\n=> Check MINIO-CLI\n' ; mc --version
printf '\n=> Check MYSQL-SHELL-CLI\n' ; mysqlsh --version
printf '\n=> Check SHIELD-CLI\n' ; shield --version
printf '\n=> Check SPRUCE-CLI\n' ; spruce --version
printf '\n=> Check SVCAT-CLI\n' ; svcat --help > /dev/null
printf '\n=> Check TERRAFORM-CLI\n' ; terraform --version
printf '\n=> Check VELERO-CLI\n' ; velero version --client-only

printf "\n====================================================\n=> Check complete.\n"
set +e