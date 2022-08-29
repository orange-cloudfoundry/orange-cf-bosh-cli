#!/bin/bash
#===========================================================================
# Check if container user need to disable ssh password
# This script is installed in "/usr/local/bin"
#===========================================================================

if [ -f /home/bosh/.ssh/authorized_keys ] && \
   [ $(cat /home/bosh/.ssh/authorized_keys | grep "^ssh-rsa" | wc -l) -ne 0 ] && \
   [ $(cat /etc/ssh/sshd_config | grep "^PasswordAuthentication yes" | wc -l) -eq 1 ] ; then
  /usr/local/bin/disable_ssh_password_auth.sh

  if [ "$1" != "container_init" ] ; then
    supervisorctl restart sshd
  fi
fi