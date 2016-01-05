container_login=<container_login>
if [ -e /home/${container_login}/deployments ]; then
  if [ -e /home/${container_login}.tar ];
    sudo rm /home/${container_login}.tar
  fi
  sudo rm /etc/profile.d/bootstrap.sh
else
  if [ -e /home/${container_login}.tar ]; then
    tar -xpf /home/${container_login}.tar --directory /home
    sudo rm /home/${container_login}.tar
  fi
fi