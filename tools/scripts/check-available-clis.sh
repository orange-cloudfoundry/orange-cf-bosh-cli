#!/bin/bash
#===========================================================================
# Check clis/tools
#===========================================================================

set -e
printf "\n====================================================\n=> Check if ruby is available...\n====================================================\n"
ruby -e 'puts "Ruby is installed"'
printf "\n====================================================\n=> Check if python is available...\n====================================================\n"
python3 --version
printf "\n====================================================\n=> Check if expected system tools are available...\n====================================================\n"
tabulate --help > /dev/null
printf "\n====================================================\n=> Check if expected clis are available...\n====================================================\n"
printf '\n=> Check ARGO-CLI\n' ; argo version
printf '\n=> Check BBR-CLI\n' ; bbr --version
printf '\n=> Check BOSH-CLI\n' ; bosh --version
printf '\n=> Check CF-CLI\n' ; cf --version
printf '\n=> Check CILIUM-CLI\n' ; cilium version
printf '\n=> Check CNPG-CLI\n' ; cnpg version
printf '\n=> Check CREDHUB-CLI\n' ; credhub --version
printf '\n=> Check FLUX-CLI\n' ; flux --version
printf '\n=> Check FLY-CLI\n' ; fly --version
printf '\n=> Check GCLOUD-CLI\n' ; gcloud --version
printf '\n=> Check GITLAB-CLI\n' ; glab version
printf '\n=> Check GITHUB-CLI\n' ; gh version
printf '\n=> Check GOSS-CLI\n' ; goss --version
printf '\n=> Check GOVC-CLI\n' ; govc version
printf '\n=> Check HELM-CLI\n' ; helm version
printf '\n=> Check HUBBLE-CLI\n' ; hubble version
printf '\n=> Check JQ-CLI\n' ; jq --version
printf '\n=> Check JWT-CLI\n' ; jwt --version
printf '\n=> Check KCTRL-CLI\n' ; kctrl version
printf '\n=> Check KLBD-CLI\n' ; klbd --version
printf '\n=> Check KUBECTL-CLI\n' ; kubectl version --client --output=yaml
printf '\n=> Check KUBECTX-CLI\n' ; switcher --version
printf '\n=> Check KUBENS-CLI\n' ; kubens --version
printf '\n=> Check KYVERNO-CLI\n' ; kyverno version
printf '\n=> Check K9S-CLI\n' ; k9s version --short
printf '\n=> Check LOKI-CLI\n' ; logcli --version
printf '\n=> Check MINIO-CLI\n' ; mc --version
printf '\n=> Check MONGO_BOSH_CLI\n' ; mongo --version
printf '\n=> Check MONGO_SHELL_CLI\n' ; mongosh --version
printf '\n=> Check MYSQL-SHELL-CLI\n' ; mysqlsh --version
printf '\n=> Check NU-SHELL-CLI\n' ; nu --version
printf '\n=> Check OC-CLI\n' ; oc version
printf '\n=> Check OCM-CLI\n' ; ocm version
printf '\n=> Check PINNIPED-CLI\n' ; pinniped version
printf '\n=> Check POPEYE-CLI\n' ; popeye version
printf '\n=> Check RBAC-TOOL-CLI\n' ; rbac-tool version
printf '\n=> Check REDIS-CLI\n' ; redis --version
printf '\n=> Check SHIELD-CLI\n' ; shield --version
printf '\n=> Check SPICEDB-CLI\n' ; zed version
printf '\n=> Check SPRUCE-CLI\n' ; spruce --version
printf '\n=> Check TASK-CLI\n' ; task --version
printf '\n=> Check TERRAFORM-BOSH-CLI\n' ; terraform --version
printf '\n=> Check TERRAFORM-K8S-CLI\n' ; tf-k8s -version
printf '\n=> Check VAULT-CLI\n' ; vault version
printf '\n=> Check VCLUSTER-CLI\n' ; vcluster --version
printf '\n=> Check VENDIR-CLI\n' ; vendir -v
printf '\n=> Check YQ-CLI\n' ; yq --version
printf '\n=> Check YTT-CLI\n' ; ytt --version
printf "\n====================================================\n=> Check complete.\n"
set +e