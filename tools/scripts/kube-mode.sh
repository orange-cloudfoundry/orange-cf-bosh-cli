#!/bin/bash
#===========================================================================
# Set/unset k9s and kubectl editor in read-only mode
#===========================================================================

#--- Set k9s and kubectl editor in read-only/write mode
if [ -z "${KUBE_EDITOR}" ] ; then
  printf "\n%bSet k9s and kubectl editor in \"read-only\" mode%b\n" "${REVERSE}${YELLOW}" "${STD}"
  export K9S_RUN_MODE="--readonly"
  export KUBE_EDITOR="/usr/local/bin/kubectl-ro-editor.sh"
else
  printf "\n%bSet k9s and kubectl editor in \"write\" mode%b\n" "${REVERSE}${YELLOW}" "${STD}"
  unset K9S_RUN_MODE
  unset KUBE_EDITOR
fi

set_prompt