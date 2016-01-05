container_login=<container_login>
tag_file=/home/${container_login}/.homedir_already_initalized.donotdelete
if [ ! -f ${tag_file} ]
then
  # Case container first deploy: we redeploy home directory
  if [ -f /home/${container_login}.tar ]
  then
    tar -xpf /home/${container_login}.tar --directory /home
    sudo rm /home/${container_login}.tar
    sudo rm /etc/profile.d/bootstrap.sh
    touch ${tag_file}
    chmod 400 ${tag_file}
  fi
else
  # Case container upgrade: we don't redeploy home directory
  if [ -f /home/${container_login}.tar ]
  then
    sudo rm /home/${container_login}.tar
  fi
  sudo rm /etc/profile.d/bootstrap.sh
fi