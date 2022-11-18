#!/bin/bash
#===========================================================================
# Show k9s screen shots
#===========================================================================

K9S_SCREEN_DIR="/tmp/k9s-screens-bosh"
k9sScreenShots="$(find ${K9S_SCREEN_DIR} -type f -printf "%T@ %p\n" 2> /dev/null | sort -rn | awk '{print $2}' | head -10)"
if [ "${k9sScreenShots}" != "" ] ; then
  printf "\n%bLatests screenshots :%b\n" "${REVERSE}${GREEN}" "${STD}"
  for file in ${k9sScreenShots} ; do
    printf "%b- ${file}\n" "${STD}"
  done

  printf "\n%bSelect a screenshot :%b " "${GREEN}${BOLD}" "${STD}" ; read file
  if [ -f ${file} ] ; then
    vi ${file}
  fi
else
  printf "\n%bNo available screenshots.%b\n" "${RED}" "${STD}"
fi