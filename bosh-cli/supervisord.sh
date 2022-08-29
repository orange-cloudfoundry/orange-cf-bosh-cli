#!/bin/bash
#===========================================================================
# Entry point for docker container startup
#===========================================================================

#--- Push the public key if required
if [ -n "${SSH_PUBLIC_KEY}" ] ; then
  if [[ "${SSH_PUBLIC_KEY}" != "ssh-rsa"* ]] ; then
    SSH_PUBLIC_KEY="ssh-rsa ${SSH_PUBLIC_KEY}"
  fi
  echo "${SSH_PUBLIC_KEY}" > /home/bosh/.ssh/authorized_keys
  chmod 600 /home/bosh/.ssh/authorized_keys
  chown bosh:users /home/bosh/.ssh/authorized_keys
  /usr/local/bin/disable_ssh_password_auth.sh
fi

#--- Check ssh security
/usr/local/bin/check_ssh_security.sh "container_init"

#---  Launch ssh daemon
echo "Starting sshd..."
/usr/bin/supervisord -c /etc/supervisor/supervisord.conf