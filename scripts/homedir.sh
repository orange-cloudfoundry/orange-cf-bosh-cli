# This script should be placed in /etc/profile.d
# It creates sample directories wich should be shared accross several containers
if [ ! -e ${HOME}/.bosh ]; then
  mkdir -p /data/.bosh
  ln -s /data/.bosh ${HOME}/.bosh
fi
if [ ! -e ${HOME}/.bosh_init ]; then
  mkdir -p /data/.bosh_init
  ln -s /data/.bosh_init ${HOME}/.bosh_init
fi
if [ ! -e ${HOME}/stemcells ]; then
  mkdir -p /data/stemcells
  ln -s /data/stemcells ${HOME}/stemcells
fi
if [ ! -e ${HOME}/releases ]; then
  mkdir -p /data/releases
  ln -s /data/releases ${HOME}/releases
fi
if [ ! -e ${HOME}/shared ]; then
  mkdir -p /data/shared
  ln -s /data/shared ${HOME}/shared
fi
