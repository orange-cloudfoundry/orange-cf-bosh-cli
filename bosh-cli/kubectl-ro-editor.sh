#!/bin/bash
#===========================================================================
# Substitute default vi editor with read-only editor for kubectl edit
#===========================================================================
YAML_FILE="$1"
API_VERSION="$(grep "^apiVersion:" ${YAML_FILE} | awk '{print $2}' | head -n 1)"
NAMESPACE="$(grep " namespace:" ${YAML_FILE} | awk '{print $2}' | head -n 1)"
NAME="$(grep " name:" ${YAML_FILE} | awk '{print $2}' | head -n 1)"
KIND="$(egrep "^kind:" ${YAML_FILE} | awk '{print $2}' | head -n 1)"
FLUX_TRACE="$(flux trace ${NAME} --kind ${KIND} --api-version ${API_VERSION} --namespace ${NAMESPACE} 2> /dev/null | grep "Path:" | sed -e "s+Path: *+  Path: +")"
printf "%b" "${YELLOW}"
cat << EOF

kubectl edit is disabled to avoid flux failing track and revert changes.
(See https://github.com/orange-cloudfoundry/paas-templates/issues/1419 for full details).
For update, use a feature branch instead.
EOF

if [ "${FLUX_TRACE}" != "" ] ; then
  cat << EOF

If really need to run a short ephemeral low latency test:

  1. Pause k8s-config pipeline (avoid flux to overwrite)
  2. Edit fluxcd path (<t> in k9s) and commit/push updates to "gitops-fluxcd-repo"
EOF
  echo "   ${FLUX_TRACE}"
fi

printf "\n%b<Enter> to get back...%b" "${REVERSE}${YELLOW}" "${STD}"
read next