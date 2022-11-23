#!/bin/bash
#===========================================================================
# Show k9s screen shots
#===========================================================================

K9S_SCREEN_DIR="/tmp/k9s-screens-bosh"
RES_FILE="/tmp/k9s-screens-bosh.txt"
find ${K9S_SCREEN_DIR} -type f -printf "%T@ %p\n" 2> /dev/null | sort -rn | awk '{print strftime("%Y-%m-%d %H:%M:%S", $1) " => " $2}' | head -10 > ${RES_FILE}
if [ ! -s ${RES_FILE} ] ; then
  printf "\n%bNo available screenshots.%b\n" "${RED}" "${STD}"
else
  printf "\n%bLatests screenshots :%b\n" "${REVERSE}${GREEN}" "${STD}"
  latestFile="$(head -1 ${RES_FILE} | awk '{print $4}')"
  cat ${RES_FILE} ; rm -f ${RES_FILE} > /dev/null 2>&1
  printf "\n%bSelect a screenshot (latest by default) :%b " "${GREEN}${BOLD}" "${STD}" ; read file
  if [ "${file}" = "" ] ; then
    file="${latestFile}"
  fi

  if [ -f ${file} ] ; then
    vi ${file}
  fi
fi