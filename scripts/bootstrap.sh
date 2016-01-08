# This script should be placed in /etc/profile.d
# It allows the homedir to be a docker volume
container_login=<container_login>
tag_file=/home/${container_login}/.homedir_already_initalized.donotdelete
ARCHIVE=${container_login}.tar.gz
ARCHIVE_MIGRATION=${container_login}_migration.tar.gz

if [ ! -f ${tag_file} ]; then
  # Case container first deploy: we redeploy home directory
  if [ -f /home/${ARCHIVE} ]; then
    tar -zxpf /home/${ARCHIVE} --directory /home
    sudo rm /home/${ARCHIVE}
    touch ${tag_file}
    chmod 400 ${tag_file}
  fi
else
  # Case container upgrade: we don't redeploy home directory
  if [ -f /home/${ARCHIVE} ]; then
    sudo rm /home/${ARCHIVE}
  fi
fi

# We migrate usefull installed tools
if [ -f /home/${ARCHIVE_MIGRATION} ]; then
  tar -zxpf /home/${ARCHIVE_MIGRATION} --directory /home
  rm /home/${ARCHIVE_MIGRATION}
fi

# We setup rights
sudo chown ${container_login}:users /home/${container_login}
sudo chmod 700 /home/${container_login}
sudo chown ${container_login}:users /data
sudo chmod 700 /home/${container_login}

# Drop of this script as it should be launched only once during container deploy/upgrade
sudo rm /etc/profile.d/bootstrap.sh