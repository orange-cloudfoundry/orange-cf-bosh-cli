#!/bin/bash
#============================================================================================
# Disable user ssh password authentication, change and set password to an infinite validity
# This script is installed in "/usr/local/bin"
#============================================================================================

echo "Disabling ssh password authentication..."
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication no/g' /etc/ssh/sshd_config
pwd="$(echo "bosh:$(date +%s | sha256sum | base64 | head -c 32)")"
sudo sh -c "echo ${pwd} | chpasswd"
chage -I -1 -m 0 -M 99999 -E -1 bosh
echo "Disabling ssh password authentication done."