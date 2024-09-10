#!/bin/bash
#===========================================================================
# Set/unset k9s and kubectl editor in read-only mode
#===========================================================================

#--- Set k9s and kubectl editor in read-only/write mode
if [ -z "${KUBE_EDITOR}" ] ; then
  printf "\n%bSet k9s and kubectl editor in \"read-only\" mode%b\n" "${REVERSE}${YELLOW}" "${STD}"
  export KUBE_EDITOR="/usr/local/bin/kubectl-ro-editor.sh"
  export K9S_RUN_MODE="--readonly"
else
  printf "\n%bSet k9s and kubectl editor in \"write\" mode%b\n" "${REVERSE}${YELLOW}" "${STD}"
  unset KUBE_EDITOR
  unset K9S_RUN_MODE
fi

set_prompt