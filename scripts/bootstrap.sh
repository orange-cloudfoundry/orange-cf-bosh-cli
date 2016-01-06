# This script should be placed in /etc/profile.d
# It allows the homedir to be a docker volume
container_login=<container_login>
tag_file=/home/${container_login}/.homedir_already_initalized.donotdelete
if [ ! -f ${tag_file} ]
then
  # Case container first deploy: we redeploy home directory
  if [ -f /home/${container_login}.tar ]
  then
    tar -xpf /home/${container_login}.tar --directory /home
    sudo rm /home/${container_login}.tar
    touch ${tag_file}
    chmod 400 ${tag_file}
  fi
else
  # Case container upgrade: we don't redeploy home directory
  if [ -f /home/${container_login}.tar ]
  then
    sudo rm /home/${container_login}.tar
  fi
fi
sudo chown ${container_login}:users /home/${container_login}
sudo chmod 700 /home/${container_login}
sudo chown ${container_login}:users /data
sudo chmod 700 /home/${container_login}
sudo rm /etc/profile.d/bootstrap.sh