#!/bin/bash
#===========================================================================
# Creates directories wich should be shared accross several containers
# This script is installed in "/etc/profile.d"
#===========================================================================

function create_dir() {
  DIR="$1"
  DEST_DIR="/data/${DIR}"
  if [ ! -e ${HOME}/${DIR} ] ; then
    if [ ! -e ${DEST_DIR} ] ; then
      mkdir -p ${DEST_DIR}
    fi
    ln -s ${DEST_DIR} ${HOME}/${DIR}
  fi
}

if [ "`id -gn`" == "users" ] ; then
  create_dir "shared"
  sudo /usr/local/bin/check_ssh_security loggin
fi
