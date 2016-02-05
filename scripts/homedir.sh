#!/bin/bash
# This script should be placed in /etc/profile.d
# It creates sample DEST_DIRectories wich should be shared accross several containers

function create_dir() {
  DIR=$1
  DEST_DIR=/data/${DIR}
  if [ ! -e ${HOME}/${DIR} ]; then
    if [ ! -e ${DEST_DIR} ]; then
      mkdir -p ${DEST_DIR}
    fi
    ln -s ${DEST_DIR} ${HOME}/${DIR}
  fi
}

if [ "`id -gn`" == "users" ]; then
  create_dir ".bosh"
  create_dir ".bosh_init"
  create_dir "stemcells"
  create_dir "releases"
  create_dir "shared"
  sudo /usr/local/bin/check_ssh_security loggin
fi
