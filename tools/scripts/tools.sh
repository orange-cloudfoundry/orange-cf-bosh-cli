#!/bin/bash
#===========================================================================
# List available tools and aliases
#===========================================================================

display() {
  printf "%b%-23s%b: %s\n" "${GREEN}${BOLD}" "$1" "${STD}" "$2"
}

clear
printf "%bBOSH TOOLS (to use with log-bosh)%b\n" "${GREEN}${BOLD}${REVERSE}" "${STD}"
display "bosh" "Bosh cli"
display "bbr" "Bosh backup/restore cli"
display "bosh-depls-failed" "Get bosh failed deployments for current bosh-director"
display "bosh-events" "Get bosh events for selected bosh director or selected deployment"
display "bosh-task" "Filter unnecessary logs when display bosh task logs"
display "cf" "Cloud Foundry cli"
display "credhub" "Credhub cli"
display "fly" "Concourse cli"
display "hm-bosh-tasks" "Get Health Manager tasks for selected bosh director or selected deployment"
display "clean-prometheus-tasks" "Clean queued bosh tasks generated by prometheus"
display "log-bosh" "Log with bosh cli"
display "log-cf" "Log with cf cli"
display "log-credhub" "Log with credhub cli"
display "log-fly" "Log with concourse cli"
display "log-shield" "Log with shield cli"
display "log-uaac" "Log with uaac cli"
display "prune-workers" "Prune concourse workers (to use with log-fly)"
display "recreate-workers" "Recreate concourse workers (after login on concourse deployment)"
display "shield" "Shield cli"
display "switch" "Switch to bosh deployment in usual bosh director"
display "terraform" "Terraform cli for bosh"
display "uaac" "Cloud Foundry UAA cli"

printf "\n%bKUBERNETES TOOLS (to use with log-k8s)%b\n" "${GREEN}${BOLD}${REVERSE}" "${STD}"
display "check-k8s" "Check kubernetes clusters (uses kubeconfig to select clusters)"
display "check-internet-proxy" "Check internet-proxy logs"
display "check-intranet-proxy" "Check intranet-proxy logs"
display "check-switch-proxy" "Check switch-proxy logs"
display "kctrl" "Kubernetes kapp-controller tool"
display "klbd" "Kubernetes image build orchestrator tool"
display "kubectl/k" "Kubernetes cli"
display "kubectx/kctx" "Kubernetes switch context cli"
display "kubens/kns" "Kubernetes switch namespace cli"
display "kube-mode" "Set k9s and kubectl editor in read-only or read-write mode"
display "kube-tail/kt" "Tail on kubernetes logs"
display "k9s" "Cluster manager cli"
display "k9s-screen" "Show latests k9s screenshots"
display "log-k8s" "Log with kubernetes cli"
display "logcli" "Loki log access cli"
display "pinniped" "Identity services cli"
display "popeye" "Check k8s cluster cli"
display "rbac-tool" "Kubernetes rbac cli"
display "tfctl" "Kubernetes terraform-controller tool"
display "tf-k8s" "Terraform cli for kubernetes"
display "vcluster" "Vcluster cli"

printf "\n%bOTHER CLI TOOLS%b\n" "${GREEN}${BOLD}${REVERSE}" "${STD}"
display "gh" "Github cli"
display "glab" "Gitlab cli"
display "goss" "Goss cli"
display "govc" "vSphere cli"
display "go3fr" "Parallelized and pipelined streaming access to S3 bucket cli"
display "jq" "JSON editing Tool"
display "jwt" "JWT built in decoding/encoding tool"
display "log-govc" "Log with govc vSphere cli"
display "mc" "minio cli"
display "nu" "nushell cli"
display "task" "Task runner cli"
display "vendir" "Fetch components to target directory cli"
display "yq" "YAML editing Tool"
display "ytt" "YAML Templating Tool"

printf "\n%bSERVICE TOOLS%b\n" "${GREEN}${BOLD}${REVERSE}" "${STD}"
display "mongo" "MongoDB shell cli for bosh"
display "mongosh" "MongoDB shell cli for k8s"
display "mongostat" "MongoDB stat for bosh"
display "mongotop" "MongoDB top for bosh"
display "mysqlsh" "MySQL shell cli"
display "redis" "Redis cli"

printf "\n%bGIT TOOLS%b\n" "${GREEN}${BOLD}${REVERSE}" "${STD}"
display "checkout" "Checkout on specific branch"
display "commit" "Commit updates"
display "git-filter-repo" "Squash git history on repositories"
display "gitlog" "Display git commits in nice format"
display "init-git" "Init git configuration and clone repositories"
display "prune" "Prune git resources"
display "pull" "Pull updates from remote repository"
display "push" "Push updates to remote repository"
display "status" "Display local repository status"

printf "\n%bGENERIC TOOLS%b\n" "${GREEN}${BOLD}${REVERSE}" "${STD}"
display "generate-password" "Generate password (30 characters)"
display "f" "Search for a string in sub-trees"
display "ps1-clear" "Clear PS1 prompt"
display "proxy" "Activate/deactivate intranet/internet proxy"
display "show-cert" "Show certificate (subject, issuer and expiry)"
display "show-csr" "Show certificate signing request"
display "tn" "Set terminal name"
display "vm-info" "Get vm informations (log-govc before)"
