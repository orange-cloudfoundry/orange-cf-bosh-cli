#!/bin/bash
#===========================================================================
# Set/unset kubectl read-only editor
#===========================================================================

if [ -z ${KUBE_EDITOR} ] ; then
  printf "\n%bSet kubectl editor in \"read-only\" mode%b\n" "${REVERSE}${YELLOW}" "${STD}"
  export KUBE_EDITOR="/usr/local/bin/kubectl-ro-editor.sh"
else
  printf "\n%bSet kubectl editor in \"write\" mode%b\n" "${REVERSE}${YELLOW}" "${STD}"
  unset KUBE_EDITOR
fi
set_prompt