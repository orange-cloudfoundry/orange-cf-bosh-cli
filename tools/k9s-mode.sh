#!/bin/bash
#===========================================================================
# Set/unset k9s read-only mode
#===========================================================================

if [ -z ${K9S_RUN_MODE} ] ; then
  printf "\n%bSet k9s in \"read-only\" mode%b\n" "${REVERSE}${YELLOW}" "${STD}"
  export K9S_RUN_MODE="--readonly"
else
  printf "\n%bSet k9s in \"write\" mode%b\n" "${REVERSE}${YELLOW}" "${STD}"
  unset K9S_RUN_MODE
fi
